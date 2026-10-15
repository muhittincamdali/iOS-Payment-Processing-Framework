import { describe, test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { Ledger, LedgerFullError } from "../src/ledger.js";
import { ConfigError, loadConfig } from "../src/config.js";

const now = 1_800_000_000_000;
let id = 1;
const tx = (overrides = {}) => {
    const transactionId = String(id++);
    return {
        transactionId,
        originalTransactionId: transactionId,
        appAccountToken: "AAAAAAAA-BBBB-4CCC-8DDD-EEEEEEEEEEEE",
        quantity: 1,
        ...overrides,
    };
};
const account = "token:aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee";

describe("ledger", () => {
    test("subscriptions last until they expire and a lifetime purchase wins", () => {
        const ledger = new Ledger();
        ledger.record(
            tx({ productId: "pro.monthly", expiresDate: now + 1_000 }),
        );
        assert.deepEqual(
            ledger.entitlements(account, now).map((e) => e.expiresDate),
            [now + 1_000],
        );
        assert.deepEqual(ledger.entitlements(account, now + 1_000), []);

        ledger.record(
            tx({ productId: "pro.yearly", expiresDate: now + 9_000 }),
        );
        assert.equal(
            ledger.entitlements(account, now)[0].productId,
            "pro.yearly",
        );
        ledger.record(tx({ productId: "pro.lifetime" }));
        assert.deepEqual(
            ledger
                .entitlements(account, now)
                .map((e) => [e.productId, e.expiresDate]),
            [["pro.lifetime", null]],
        );
    });

    test("refunded, upgraded and expiry-less subscriptions grant nothing", () => {
        const ledger = new Ledger();
        ledger.record(
            tx({ productId: "pro.lifetime", revocationDate: now - 1 }),
        );
        ledger.record(
            tx({
                productId: "pro.yearly",
                expiresDate: now + 5_000,
                isUpgraded: true,
            }),
        );
        ledger.record(tx({ productId: "pro.monthly" }));
        ledger.record(
            tx({ productId: "pro.monthly", expiresDate: "9999999999999" }),
        );
        assert.deepEqual(ledger.entitlements(account, now), []);
    });

    test("coins count once per transaction and drop when refunded", () => {
        const ledger = new Ledger();
        const purchase = tx({ productId: "coins.100", quantity: 2 });
        ledger.record(purchase);
        assert.equal(ledger.record(purchase).isNew, false);
        assert.equal(ledger.coins(account), 200);
        ledger.record({ ...purchase, revocationDate: now });
        assert.equal(ledger.coins(account), 0);
    });

    test("quantities outside StoreKit limits count as one", () => {
        const ledger = new Ledger();
        for (const quantity of [0, -5, 11, 2.5, 1e308, "3", null])
            ledger.record(tx({ productId: "coins.100", quantity }));
        assert.equal(ledger.coins(account), 700);
    });

    test("accounts fall back to the first purchase without an app account token", () => {
        const ledger = new Ledger();
        const { account: fallback } = ledger.record(
            tx({
                productId: "pro.lifetime",
                appAccountToken: undefined,
                originalTransactionId: "42",
            }),
        );
        assert.equal(fallback, "original:42");
        assert.equal(ledger.entitlements(fallback, now).length, 1);
    });

    test("the ledger is bounded", () => {
        const ledger = new Ledger({
            maxAccounts: 1,
            maxTransactionsPerAccount: 2,
        });
        ledger.record(tx({ productId: "coins.100" }));
        ledger.record(tx({ productId: "coins.100" }));
        assert.throws(
            () => ledger.record(tx({ productId: "coins.100" })),
            LedgerFullError,
        );
        assert.throws(
            () =>
                ledger.record(
                    tx({
                        productId: "coins.100",
                        appAccountToken: "00000000-0000-4000-8000-000000000000",
                    }),
                ),
            LedgerFullError,
        );
    });

    test("catalog lookups ignore inherited properties", () => {
        const ledger = new Ledger();
        assert.equal(ledger.isKnownProduct("constructor"), false);
        assert.equal(ledger.isKnownProduct("__proto__"), false);
        assert.equal(ledger.isKnownProduct("pro.monthly"), true);
    });
});

describe("configuration", () => {
    const base = {
        BUNDLE_ID: "com.example.shop",
        APPLE_ENVIRONMENT: "Sandbox",
    };

    test("valid settings load with defaults", () => {
        const config = loadConfig(base);
        assert.equal(config.port, 8787);
        assert.equal(config.host, "127.0.0.1");
        assert.equal(config.onlineChecks, true);
        assert.equal(config.rootCertificates.length, 1); // Apple Root CA - G3
    });

    test("unsafe or malformed settings are refused", () => {
        const cases = [
            {},
            { ...base, BUNDLE_ID: "com.example/shop" },
            { ...base, APPLE_ENVIRONMENT: "sandbox" },
            { ...base, APPLE_ENVIRONMENT: "Production" },
            { ...base, APPLE_ENVIRONMENT: "Production", APP_APPLE_ID: "12ab" },
            { ...base, APPLE_ENVIRONMENT: "Xcode" },
            {
                ...base,
                APPLE_ENVIRONMENT: "LocalTesting",
                ALLOW_UNVERIFIED_TRANSACTIONS: "yes",
            },
            {
                ...base,
                APPLE_ENVIRONMENT: "Xcode",
                ALLOW_UNVERIFIED_TRANSACTIONS: "1",
                NODE_ENV: "production",
            },
            { ...base, PORT: "70000" },
            { ...base, PORT: "-1" },
            { ...base, PORT: "80 " },
        ];
        for (const env of cases)
            assert.throws(
                () => loadConfig(env),
                ConfigError,
                JSON.stringify(env),
            );
    });

    test("production needs the app Apple ID", () => {
        const config = loadConfig({
            ...base,
            APPLE_ENVIRONMENT: "Production",
            APP_APPLE_ID: "1234567890",
        });
        assert.equal(config.appAppleId, 1234567890);
    });

    test("a certificate folder without certificates is refused", () => {
        const empty = mkdtempSync(join(tmpdir(), "receipt-empty-"));
        try {
            assert.throws(
                () => loadConfig({ ...base, ROOT_CERTS_DIR: empty }),
                ConfigError,
            );
        } finally {
            rmSync(empty, { recursive: true, force: true });
        }
    });
});
