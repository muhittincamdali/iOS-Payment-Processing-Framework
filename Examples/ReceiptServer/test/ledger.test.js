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

    test("a revocation is final: no replayed or later copy undoes it", () => {
        const ledger = new Ledger();
        const lifetime = tx({ productId: "pro.lifetime", signedDate: now });
        const coins = tx({ productId: "coins.100", signedDate: now });
        for (const purchase of [lifetime, coins]) {
            ledger.record(purchase);
            ledger.record({
                ...purchase,
                revocationDate: now + 1,
                signedDate: now + 1,
            });
        }

        // The device keeps the copy signed before the refund, and Apple can sign a later copy
        // without a revocation date, as after a reversed refund.
        for (const purchase of [lifetime, coins]) {
            for (const copy of [
                purchase,
                { ...purchase, signedDate: now + 9_000 },
            ])
                assert.equal(ledger.record(copy).changed, false);
        }
        assert.deepEqual(ledger.entitlements(account, now), []);
        assert.equal(ledger.coins(account), 0);
    });

    test("a revocation counts whenever it was signed, other copies only when signed later", () => {
        const ledger = new Ledger();
        const yearly = tx({
            productId: "pro.yearly",
            expiresDate: now + 5_000,
            signedDate: now,
        });
        ledger.record(yearly);
        const older = { ...yearly, expiresDate: now + 9_000, signedDate: 1 };
        assert.equal(ledger.record(older).changed, false);
        assert.equal(ledger.record({ ...yearly }).changed, false);
        assert.deepEqual(
            ledger.entitlements(account, now).map((e) => e.expiresDate),
            [now + 5_000],
        );

        const upgraded = { ...yearly, isUpgraded: true, signedDate: now + 1 };
        assert.equal(ledger.record(upgraded).changed, true);
        ledger.record(yearly); // the copy from before the upgrade
        assert.deepEqual(ledger.entitlements(account, now), []);

        // A refund that arrives after a copy Apple signed later still takes the coins back.
        const coins = tx({ productId: "coins.100", signedDate: now + 3_000 });
        ledger.record(coins);
        const refund = { ...coins, revocationDate: now, signedDate: now };
        assert.equal(ledger.record(refund).changed, true);
        assert.equal(ledger.coins(account), 0);
    });

    test("a Billing Grace Period extends the subscription's latest period until it ends", () => {
        const day = 86_400_000;
        const ledger = new Ledger();
        const first = tx({
            productId: "pro.monthly",
            expiresDate: now - 31 * day,
            signedDate: 1,
        });
        const original = first.originalTransactionId;
        const latest = tx({
            productId: "pro.monthly",
            originalTransactionId: original,
            expiresDate: now - 3_600_000,
            signedDate: 2,
        });
        ledger.record(first);
        ledger.record(latest);
        assert.deepEqual(ledger.entitlements(account, now), []);

        const grace = {
            originalTransactionId: original,
            gracePeriodExpiresDate: now + 6 * day,
            signedDate: 10,
        };
        assert.equal(ledger.recordRenewal(account, grace), true);
        assert.deepEqual(
            ledger
                .entitlements(account, now)
                .map((e) => [e.transactionId, e.expiresDate]),
            [[latest.transactionId, now + 6 * day]],
        );
        assert.deepEqual(ledger.entitlements(account, now + 6 * day), []);

        // Renewal information signed earlier changes nothing; a later one without a grace period
        // ends it, and sending the earlier one again does not bring it back.
        const older = { originalTransactionId: original, signedDate: 9 };
        assert.equal(ledger.recordRenewal(account, older), false);
        const later = { originalTransactionId: original, signedDate: 11 };
        assert.equal(ledger.recordRenewal(account, later), true);
        assert.equal(ledger.recordRenewal(account, grace), false);
        assert.deepEqual(ledger.entitlements(account, now), []);
    });

    test("a grace period never gives access to a refunded period or to another subscription", () => {
        const day = 86_400_000;
        const ledger = new Ledger();
        const older = tx({
            productId: "pro.monthly",
            expiresDate: now - 31 * day,
        });
        const original = older.originalTransactionId;
        ledger.record(older);
        ledger.record(
            tx({
                productId: "pro.monthly",
                originalTransactionId: original,
                expiresDate: now - 3_600_000,
                revocationDate: now - 1,
            }),
        );
        ledger.record(
            tx({ productId: "pro.yearly", expiresDate: now - 3_600_000 }),
        );
        const grace = (originalTransactionId) => ({
            originalTransactionId,
            gracePeriodExpiresDate: now + 6 * day,
            signedDate: 10,
        });
        ledger.recordRenewal(account, grace(original));
        ledger.recordRenewal(account, grace("424242"));
        assert.deepEqual(ledger.entitlements(account, now), []);
        assert.equal(
            ledger.recordRenewal("token:nobody", grace(original)),
            false,
        );
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
