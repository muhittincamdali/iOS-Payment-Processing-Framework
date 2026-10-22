// Keeps the ledger in a JSON file, so a restart does not forget a refund: the device keeps the
// signed purchase from before it, and Apple does not send the REFUND notification again.
//
// Every change rewrites the whole file through a temporary file, fsync and a rename, so the file
// holds either the ledger before the change or the one after it. A file that cannot be read
// stops the server instead of starting with an empty ledger. One process uses one file; a
// production server keeps this in a database.
import {
    closeSync,
    fsyncSync,
    mkdirSync,
    openSync,
    readFileSync,
    renameSync,
    rmSync,
    writeSync,
} from "node:fs";
import { dirname } from "node:path";

const VERSION = 1;

export class LedgerFileError extends Error {}

/**
 * The accounts saved in `file`, or none when it does not exist yet.
 * @returns {Map<string, { transactions: Map<string, object>, renewals: Map<string, object> }>}
 */
export function readLedgerFile(file) {
    let text;
    try {
        text = readFileSync(file, "utf8");
    } catch (error) {
        if (error.code === "ENOENT") return new Map();
        throw new LedgerFileError(
            `Cannot read the ledger file ${file}: ${error.message}`,
        );
    }
    let data;
    try {
        data = JSON.parse(text);
    } catch {
        throw invalid(file, "it is not JSON");
    }
    if (
        data === null ||
        typeof data !== "object" ||
        data.version !== VERSION ||
        !Array.isArray(data.accounts)
    )
        throw invalid(file, `it has no version ${VERSION} list of accounts`);

    const accounts = new Map();
    for (const entry of data.accounts) {
        if (
            typeof entry?.account !== "string" ||
            !Array.isArray(entry.transactions) ||
            !Array.isArray(entry.renewals)
        )
            throw invalid(file, "an account is malformed");
        const transactions = new Map();
        for (const record of entry.transactions) {
            if (!isTransactionRecord(record))
                throw invalid(
                    file,
                    `a transaction of ${entry.account} is malformed`,
                );
            transactions.set(record.transactionId, record);
        }
        const renewals = new Map();
        for (const record of entry.renewals) {
            if (!isRenewalRecord(record))
                throw invalid(
                    file,
                    `a renewal of ${entry.account} is malformed`,
                );
            renewals.set(record.originalTransactionId, record);
        }
        accounts.set(entry.account, { transactions, renewals });
    }
    return accounts;
}

/** Replaces `file` with `accounts` in one rename; throws and leaves the file as it was on failure. */
export function writeLedgerFile(file, accounts) {
    const data = JSON.stringify({
        version: VERSION,
        accounts: [...accounts].map(([account, entry]) => ({
            account,
            transactions: [...entry.transactions.values()],
            renewals: [...entry.renewals.values()],
        })),
    });
    mkdirSync(dirname(file), { recursive: true });
    const temporary = `${file}.${process.pid}.tmp`;
    try {
        const descriptor = openSync(temporary, "w", 0o600);
        try {
            writeSync(descriptor, data);
            fsyncSync(descriptor);
        } finally {
            closeSync(descriptor);
        }
        renameSync(temporary, file);
    } catch (error) {
        rmSync(temporary, { force: true });
        throw error;
    }
}

function isTransactionRecord(record) {
    return (
        record !== null &&
        typeof record === "object" &&
        typeof record.transactionId === "string" &&
        typeof record.productId === "string" &&
        Number.isInteger(record.quantity) &&
        typeof record.isUpgraded === "boolean" &&
        Number.isFinite(record.signedDate)
    );
}

function isRenewalRecord(record) {
    return (
        record !== null &&
        typeof record === "object" &&
        typeof record.originalTransactionId === "string" &&
        (record.gracePeriodExpiresDate === null ||
            Number.isFinite(record.gracePeriodExpiresDate)) &&
        Number.isFinite(record.signedDate)
    );
}

function invalid(file, reason) {
    return new LedgerFileError(
        `The ledger file ${file} cannot be used: ${reason}. Restore it or move it away; the server does not start with an empty ledger in its place.`,
    );
}
