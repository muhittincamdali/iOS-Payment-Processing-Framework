// What each account owns, built only from transactions Apple's library verified.
//
// The rules match PaymentKit's EntitlementResolver on the device: refunded and upgraded
// transactions grant nothing, subscriptions last until their expiration date or, in a Billing
// Grace Period, until the grace period ends, non-consumables for good, and a lifetime purchase
// wins over a subscription.
//
// A transaction only moves forward: once a revoked copy is recorded, no other copy of it is
// recorded again, so a signed purchase kept from before a refund cannot bring the access or the
// coins back. Otherwise the copy Apple signed later wins.
//
// With a `file`, every change is saved before it counts (see ledger-file.js), so this holds
// across restarts too. Without one, as in tests, the ledger lives only as long as the process.
import {
    LedgerFileError,
    readLedgerFile,
    writeLedgerFile,
} from "./ledger-file.js";

export { LedgerFileError };

export const CATALOG = {
    "coins.100": { kind: "consumable", coins: 100 },
    "pro.monthly": { kind: "autoRenewable", entitlement: "pro" },
    "pro.yearly": { kind: "autoRenewable", entitlement: "pro" },
    "pro.lifetime": { kind: "nonConsumable", entitlement: "pro" },
};

export class LedgerFullError extends Error {}

export class Ledger {
    /** account → { transactions: Map(transactionId → record), renewals: Map(originalTransactionId → record) } */
    #accounts = new Map();
    #catalog;
    #maxAccounts;
    #maxTransactions;
    #file;

    /**
     * @param {{ catalog?: object, maxAccounts?: number, maxTransactionsPerAccount?: number, file?: string }} [options]
     *   `file` is the JSON file the ledger is read from and saved to.
     * @throws {LedgerFileError} when `file` exists but cannot be read as a ledger.
     */
    constructor({
        catalog = CATALOG,
        maxAccounts = 10_000,
        maxTransactionsPerAccount = 1_000,
        file,
    } = {}) {
        this.#catalog = catalog;
        this.#maxAccounts = maxAccounts;
        this.#maxTransactions = maxTransactionsPerAccount;
        this.#file = file ?? null;
        if (this.#file) this.#accounts = readLedgerFile(this.#file);
    }

    /** Saves the ledger after a change; when that fails, `undo` reverts the change. */
    #save(undo) {
        if (!this.#file) return;
        try {
            writeLedgerFile(this.#file, this.#accounts);
        } catch (error) {
            undo();
            throw error;
        }
    }

    isKnownProduct(productId) {
        return Object.hasOwn(this.#catalog, productId);
    }

    /** The account a transaction belongs to: the app account token, else its first purchase. */
    static accountOf(transaction) {
        return transaction.appAccountToken
            ? `token:${transaction.appAccountToken.toLowerCase()}`
            : `original:${transaction.originalTransactionId}`;
    }

    /**
     * Records a verified, decoded transaction. A copy of a recorded transaction replaces it only
     * when it moves the transaction forward (see `supersedes`), so a refund updates the purchase
     * instead of adding a second one, coins are never credited twice, and replaying an older
     * copy changes nothing.
     * @returns {{ account: string, isNew: boolean, changed: boolean }}
     */
    record(transaction) {
        const account = Ledger.accountOf(transaction);
        const existing = this.#accounts.get(account);
        if (!existing && this.#accounts.size >= this.#maxAccounts)
            throw new LedgerFullError(
                "The ledger holds its maximum number of accounts.",
            );
        const entry = existing ?? {
            transactions: new Map(),
            renewals: new Map(),
        };
        const { transactions } = entry;
        const id = transaction.transactionId;
        const stored = transactions.get(id);
        const isNew = stored === undefined;
        if (isNew && transactions.size >= this.#maxTransactions) {
            throw new LedgerFullError(
                "The account holds its maximum number of transactions.",
            );
        }
        if (!isNew && !supersedes(transaction, stored))
            return { account, isNew, changed: false };
        this.#accounts.set(account, entry);
        transactions.set(id, {
            transactionId: transaction.transactionId,
            originalTransactionId: transaction.originalTransactionId,
            productId: transaction.productId,
            purchaseDate: transaction.purchaseDate,
            expiresDate: transaction.expiresDate,
            revocationDate: transaction.revocationDate,
            isUpgraded: transaction.isUpgraded === true,
            quantity: clampQuantity(transaction.quantity),
            familyShared: transaction.inAppOwnershipType === "FAMILY_SHARED",
            signedDate: signedDateOf(transaction),
        });
        this.#save(() => {
            if (isNew) transactions.delete(id);
            else transactions.set(id, stored);
            if (!existing) this.#accounts.delete(account);
        });
        return { account, isNew, changed: true };
    }

    /**
     * Records the verified renewal information of a subscription of `account`, as a notification
     * carries it next to the subscription's transaction. Only its Billing Grace Period counts.
     * It replaces the stored information only when Apple signed it later.
     * @returns {boolean} whether it changed anything
     */
    recordRenewal(account, renewalInfo) {
        const entry = this.#accounts.get(account);
        const originalId = renewalInfo.originalTransactionId;
        if (!entry || typeof originalId !== "string") return false;
        const stored = entry.renewals.get(originalId);
        const signedDate = signedDateOf(renewalInfo);
        if (stored && signedDate <= stored.signedDate) return false;
        if (!stored && entry.renewals.size >= this.#maxTransactions) {
            throw new LedgerFullError(
                "The account holds its maximum number of subscriptions.",
            );
        }
        entry.renewals.set(originalId, {
            originalTransactionId: originalId,
            gracePeriodExpiresDate: Number.isFinite(
                renewalInfo.gracePeriodExpiresDate,
            )
                ? renewalInfo.gracePeriodExpiresDate
                : null,
            signedDate,
        });
        this.#save(() => {
            if (stored) entry.renewals.set(originalId, stored);
            else entry.renewals.delete(originalId);
        });
        return true;
    }

    /** The account's entitlements at `now` (milliseconds since 1970), sorted by name. */
    entitlements(account, now = Date.now()) {
        const entry = this.#accounts.get(account);
        if (!entry) return [];
        const latest = latestPeriods(entry.transactions.values());
        const best = new Map();
        for (const transaction of entry.transactions.values()) {
            const product = this.#catalog[transaction.productId];
            if (
                !product?.entitlement ||
                isRevoked(transaction) ||
                transaction.isUpgraded
            )
                continue;
            let expiresDate = null;
            if (product.kind === "autoRenewable") {
                if (typeof transaction.expiresDate !== "number") continue;
                expiresDate = transaction.expiresDate;
                // A grace period extends only the subscription's latest period: the one whose
                // renewal failed. It never shortens it: the stored grace period is stale once a
                // renewal paid for a period that ends later, until Apple's next renewal
                // information replaces it.
                const original = transaction.originalTransactionId;
                const grace =
                    entry.renewals.get(original)?.gracePeriodExpiresDate;
                if (
                    latest.get(original) === transaction &&
                    typeof grace === "number"
                )
                    expiresDate = Math.max(expiresDate, grace);
                if (expiresDate <= now) continue;
            }
            const candidate = {
                name: product.entitlement,
                productId: transaction.productId,
                transactionId: transaction.transactionId,
                expiresDate,
            };
            const current = best.get(candidate.name);
            if (!current || isBetter(candidate, current))
                best.set(candidate.name, candidate);
        }
        return [...best.values()].sort((a, b) => a.name.localeCompare(b.name));
    }

    /** Coins bought with consumables and not refunded. */
    coins(account) {
        let total = 0;
        for (const transaction of this.#accounts
            .get(account)
            ?.transactions.values() ?? []) {
            const product = this.#catalog[transaction.productId];
            if (product?.kind !== "consumable" || isRevoked(transaction))
                continue;
            total += product.coins * transaction.quantity;
        }
        return total;
    }

    has(account) {
        return this.#accounts.has(account);
    }
}

/**
 * Whether `incoming` replaces the stored copy of the same transaction. A revocation is final:
 * nothing replaces a revoked copy, not even one Apple signed later without a revocation date
 * (as after a reversed refund). A revocation replaces any other copy whenever it was signed,
 * because notifications can arrive out of order. Any other copy replaces only an older one.
 */
function supersedes(incoming, stored) {
    if (isRevoked(stored)) return false;
    if (isRevoked(incoming)) return true;
    return signedDateOf(incoming) > stored.signedDate;
}

/** The transaction of each subscription whose period ends last, revoked ones included. */
function latestPeriods(transactions) {
    const latest = new Map();
    for (const transaction of transactions) {
        if (typeof transaction.expiresDate !== "number") continue;
        const current = latest.get(transaction.originalTransactionId);
        if (!current || transaction.expiresDate > current.expiresDate)
            latest.set(transaction.originalTransactionId, transaction);
    }
    return latest;
}

function isRevoked(transaction) {
    return transaction.revocationDate !== undefined;
}

// Apple signs every transaction with a signedDate; a payload without one counts as the oldest.
function signedDateOf(transaction) {
    return Number.isFinite(transaction.signedDate) ? transaction.signedDate : 0;
}

function isBetter(candidate, current) {
    if (candidate.expiresDate === null) return current.expiresDate !== null;
    if (current.expiresDate === null) return false;
    return candidate.expiresDate > current.expiresDate;
}

// StoreKit sells at most 10 units at once; anything else in a payload is not trusted.
function clampQuantity(quantity) {
    return Number.isInteger(quantity) && quantity >= 1 && quantity <= 10
        ? quantity
        : 1;
}
