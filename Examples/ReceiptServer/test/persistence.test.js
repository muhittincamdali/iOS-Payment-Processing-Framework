// The ledger outlives the process: a restart must not forget a refund, or the signed purchase the
// device kept from before it would grant the access and the coins again.
import { after, before, describe, test } from "node:test";
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import {
    chmodSync,
    mkdtempSync,
    readdirSync,
    rmSync,
    writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { Ledger, LedgerFileError } from "../src/ledger.js";
import {
    ACCOUNT_TOKEN,
    BUNDLE_ID,
    makeChain,
    notification,
    post,
    signJWS,
    transaction,
} from "./support.js";

const MAIN = fileURLToPath(new URL("../src/main.js", import.meta.url));
const now = 1_800_000_000_000;
const account = "token:aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee";
let id = 1;
const tx = (overrides = {}) => {
    const transactionId = String(id++);
    return {
        transactionId,
        originalTransactionId: transactionId,
        appAccountToken: "AAAAAAAA-BBBB-4CCC-8DDD-EEEEEEEEEEEE",
        quantity: 1,
        signedDate: now,
        ...overrides,
    };
};

describe("ledger file", () => {
    let dir;
    let file;

    before(() => {
        dir = mkdtempSync(join(tmpdir(), "receipt-ledger-"));
    });
    after(() => rmSync(dir, { recursive: true, force: true }));

    test("a refund and a grace period survive a restart", () => {
        file = join(dir, "data", "refund.json");
        const ledger = new Ledger({ file });
        const lifetime = tx({ productId: "pro.lifetime" });
        const coins = tx({ productId: "coins.100", quantity: 3 });
        for (const purchase of [lifetime, coins]) {
            ledger.record(purchase);
            ledger.record({
                ...purchase,
                revocationDate: now + 1,
                signedDate: now + 1,
            });
        }
        const monthly = tx({ productId: "pro.monthly", expiresDate: now - 1 });
        ledger.record(monthly);
        ledger.recordRenewal(account, {
            originalTransactionId: monthly.originalTransactionId,
            gracePeriodExpiresDate: now + 5_000,
            signedDate: now + 2,
        });

        const restarted = new Ledger({ file });
        for (const purchase of [lifetime, coins])
            assert.equal(restarted.record(purchase).changed, false);
        assert.equal(restarted.coins(account), 0);
        assert.deepEqual(
            restarted.entitlements(account, now).map((e) => e.productId),
            ["pro.monthly"],
        );
        assert.deepEqual(readdirSync(join(dir, "data")), ["refund.json"]);
    });

    test("a change that cannot be saved is not kept", () => {
        const readOnly = mkdtempSync(join(dir, "read-only-"));
        const ledger = new Ledger({ file: join(readOnly, "ledger.json") });
        const purchase = tx({ productId: "coins.100" });
        ledger.record(purchase);
        chmodSync(readOnly, 0o500);
        try {
            const refund = { ...purchase, revocationDate: now };
            assert.throws(() => ledger.record(refund));
            assert.equal(ledger.coins(account), 100);
            assert.throws(() => ledger.record(tx({ productId: "coins.100" })));
            assert.equal(ledger.coins(account), 100);
        } finally {
            chmodSync(readOnly, 0o700);
        }
        // Sent again, the refund is recorded and saved.
        assert.equal(
            ledger.record({ ...purchase, revocationDate: now }).changed,
            true,
        );
        assert.equal(
            new Ledger({ file: join(readOnly, "ledger.json") }).coins(account),
            0,
        );
    });

    test("a file the ledger cannot read stops it instead of starting empty", () => {
        const bad = join(dir, "bad.json");
        for (const content of [
            "{",
            "[]",
            JSON.stringify({ version: 2, accounts: [] }),
            JSON.stringify({ version: 1, accounts: [{ account }] }),
            JSON.stringify({
                version: 1,
                accounts: [
                    {
                        account,
                        transactions: [{ transactionId: 5 }],
                        renewals: [],
                    },
                ],
            }),
        ]) {
            writeFileSync(bad, content);
            assert.throws(
                () => new Ledger({ file: bad }),
                LedgerFileError,
                content,
            );
        }
    });
});

describe("receipt server restarted with the same LEDGER_FILE", () => {
    let chain;
    let dir;

    before(() => {
        chain = makeChain("restart");
        dir = mkdtempSync(join(tmpdir(), "receipt-restart-"));
    });
    after(() => {
        chain.cleanup();
        rmSync(dir, { recursive: true, force: true });
    });

    /** Runs src/main.js as `npm start` would and waits until it listens. */
    async function start() {
        const child = spawn(process.execPath, [MAIN], {
            env: {
                PATH: process.env.PATH,
                BUNDLE_ID,
                APPLE_ENVIRONMENT: "Sandbox",
                ROOT_CERTS_DIR: chain.rootDir,
                ONLINE_CHECKS: "0",
                PORT: "0",
                LEDGER_FILE: join(dir, "ledger.json"),
            },
            stdio: ["ignore", "pipe", "pipe"],
        });
        const url = await new Promise((resolve, reject) => {
            let output = "";
            const read = (chunk) => {
                output += chunk;
                const match = output.match(/ on (http:\/\/[^\s,]+)/);
                if (match) resolve(match[1]);
            };
            child.stdout.on("data", read);
            child.stderr.on("data", read);
            child.on("exit", (code) =>
                reject(new Error(`exited with ${code}: ${output}`)),
            );
        });
        const stop = () =>
            new Promise((resolve) => {
                child.on("exit", resolve);
                child.kill("SIGTERM");
            });
        return { url, stop };
    }

    test("posting the purchases signed before a refund after a restart brings nothing back", async () => {
        const purchases = [
            transaction({
                productId: "pro.lifetime",
                type: "Non-Consumable",
                expiresDate: undefined,
            }),
            transaction({
                productId: "coins.100",
                type: "Consumable",
                expiresDate: undefined,
            }),
        ];
        const signed = purchases.map((purchase) => signJWS(purchase, chain));

        const first = await start();
        try {
            for (const signedTransaction of signed)
                await post(`${first.url}/v1/transactions`, {
                    signedTransaction,
                });
            for (const purchase of purchases) {
                const refund = signJWS(
                    {
                        ...purchase,
                        revocationDate: Date.now(),
                        signedDate: purchase.signedDate + 1_000,
                    },
                    chain,
                );
                const { status } = await post(`${first.url}/v1/notifications`, {
                    signedPayload: signJWS(
                        notification("REFUND", refund),
                        chain,
                    ),
                });
                assert.equal(status, 200);
            }
        } finally {
            await first.stop();
        }

        const second = await start();
        try {
            for (const signedTransaction of signed) {
                const { status, body } = await post(
                    `${second.url}/v1/transactions`,
                    { signedTransaction },
                );
                assert.equal(status, 200);
                assert.equal(body.account, `token:${ACCOUNT_TOKEN}`);
                assert.deepEqual(body.entitlements, []);
                assert.equal(body.coins, 0);
            }
        } finally {
            await second.stop();
        }
    });

    test("a ledger file it cannot read stops the server", async () => {
        writeFileSync(join(dir, "ledger.json"), "not json");
        let server;
        try {
            await assert.rejects(async () => {
                server = await start();
            }, /exited with 2/);
        } finally {
            await server?.stop();
        }
    });
});
