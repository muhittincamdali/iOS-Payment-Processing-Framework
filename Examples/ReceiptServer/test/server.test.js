import { after, before, describe, test } from "node:test";
import assert from "node:assert/strict";
import { request as httpRequest } from "node:http";
import { loadConfig } from "../src/config.js";
import { MAX_BODY_BYTES } from "../src/server.js";
import {
    ACCOUNT_TOKEN,
    BUNDLE_ID,
    makeChain,
    notification,
    post,
    signJWS,
    startServer,
    transaction,
} from "./support.js";

const account = `token:${ACCOUNT_TOKEN}`;

describe("receipt server in Sandbox, with a test root in place of Apple Root CA - G3", () => {
    let trusted;
    let rogue;
    let server;

    before(async () => {
        trusted = makeChain("trusted");
        rogue = makeChain("rogue");
        const config = loadConfig({
            BUNDLE_ID,
            APPLE_ENVIRONMENT: "Sandbox",
            ROOT_CERTS_DIR: trusted.rootDir,
            ONLINE_CHECKS: "0",
        });
        server = await startServer(config);
    });

    after(async () => {
        await server.close();
        trusted.cleanup();
        rogue.cleanup();
    });

    test("a verified subscription grants its entitlement", async () => {
        const payload = transaction({
            productId: "pro.yearly",
            appAccountToken: "11111111-2222-4333-8444-555555555555",
        });
        const { status, body } = await post(`${server.url}/v1/transactions`, {
            signedTransaction: signJWS(payload, trusted),
        });
        assert.equal(status, 200);
        assert.equal(
            body.account,
            "token:11111111-2222-4333-8444-555555555555",
        );
        assert.equal(body.productId, "pro.yearly");
        assert.equal(body.environment, "Sandbox");
        assert.deepEqual(
            body.entitlements.map((e) => [e.name, e.productId, e.expiresDate]),
            [["pro", "pro.yearly", payload.expiresDate]],
        );
    });

    test("the same consumable sent twice is credited once", async () => {
        const payload = transaction({
            productId: "coins.100",
            type: "Consumable",
            expiresDate: undefined,
            quantity: 3,
        });
        const signed = signJWS(payload, trusted);
        const first = await post(`${server.url}/v1/transactions`, {
            signedTransaction: signed,
        });
        const second = await post(`${server.url}/v1/transactions`, {
            signedTransaction: signed,
        });
        assert.equal(first.status, 200);
        assert.equal(second.body.coins, first.body.coins);
        assert.ok(first.body.coins >= 300);
    });

    test("a refund notification removes the entitlement it granted", async () => {
        const token = "99999999-8888-4777-8666-555555555555";
        const purchase = transaction({
            productId: "pro.lifetime",
            type: "Non-Consumable",
            expiresDate: undefined,
            appAccountToken: token,
        });
        const granted = await post(`${server.url}/v1/transactions`, {
            signedTransaction: signJWS(purchase, trusted),
        });
        assert.deepEqual(
            granted.body.entitlements.map((e) => e.name),
            ["pro"],
        );

        const refunded = signJWS(
            { ...purchase, revocationDate: Date.now(), revocationReason: 0 },
            trusted,
        );
        const { status, body } = await post(`${server.url}/v1/notifications`, {
            signedPayload: signJWS(notification("REFUND", refunded), trusted),
        });
        assert.equal(status, 200);
        assert.equal(body.received, "REFUND");

        const summary = await (
            await fetch(`${server.url}/v1/accounts/token:${token}`)
        ).json();
        assert.deepEqual(summary.entitlements, []);
    });

    test("data signed by another chain is rejected", async () => {
        const { status, body } = await post(`${server.url}/v1/transactions`, {
            signedTransaction: signJWS(transaction(), rogue),
        });
        assert.equal(status, 422);
        assert.equal(body.error, "verification_failed");
    });

    test("a trusted chain with a forged signature is rejected", async () => {
        const forged = signJWS(transaction(), rogue, { x5c: trusted.x5c });
        const { status, body } = await post(`${server.url}/v1/transactions`, {
            signedTransaction: forged,
        });
        assert.equal(status, 422);
        assert.equal(body.error, "verification_failed");
    });

    test("a payload changed after signing is rejected", async () => {
        const [header, , signature] = signJWS(transaction(), trusted).split(
            ".",
        );
        const changed = Buffer.from(
            JSON.stringify(transaction({ productId: "pro.lifetime" })),
        ).toString("base64url");
        const { status } = await post(`${server.url}/v1/transactions`, {
            signedTransaction: `${header}.${changed}.${signature}`,
        });
        assert.equal(status, 422);
    });

    test("a chain without the intermediate is rejected", async () => {
        const short = signJWS(transaction(), trusted, {
            x5c: [trusted.x5c[0], trusted.x5c[2]],
        });
        assert.equal(
            (
                await post(`${server.url}/v1/transactions`, {
                    signedTransaction: short,
                })
            ).status,
            422,
        );
    });

    test("another app or environment is rejected", async () => {
        for (const overrides of [
            { bundleId: "com.example.other" },
            { environment: "Production" },
        ]) {
            const { status, body } = await post(
                `${server.url}/v1/transactions`,
                { signedTransaction: signJWS(transaction(overrides), trusted) },
            );
            assert.equal(status, 422, JSON.stringify(overrides));
            assert.equal(body.error, "verification_failed");
        }
    });

    test("a product the server does not sell is rejected", async () => {
        const { status, body } = await post(`${server.url}/v1/transactions`, {
            signedTransaction: signJWS(
                transaction({ productId: "gems.999" }),
                trusted,
            ),
        });
        assert.equal(status, 422);
        assert.equal(body.error, "unknown_product");
    });

    test("malformed requests get 4xx answers", async () => {
        const url = `${server.url}/v1/transactions`;
        assert.equal((await post(url, "not json")).status, 400);
        assert.equal((await post(url, "[]")).status, 400);
        assert.equal((await post(url, "null")).status, 400);
        assert.equal((await post(url, {})).status, 400);
        assert.equal((await post(url, { signedTransaction: 42 })).status, 400);
        assert.equal(
            (await post(url, { signedTransaction: "a.b" })).status,
            400,
        );
        assert.equal(
            (await post(url, { signedTransaction: "a.b.c$" })).status,
            400,
        );
        assert.equal(
            (
                await post(url, {
                    signedTransaction: `${"a".repeat(20_000)}.b.c`,
                })
            ).status,
            400,
        );
        assert.equal(
            (await post(url, { signedTransaction: "e30.e30." })).status,
            422,
        );
        assert.equal(
            (
                await post(
                    url,
                    { signedTransaction: "x" },
                    { "content-type": "text/plain" },
                )
            ).status,
            415,
        );
        assert.equal((await fetch(url)).status, 405);
        assert.equal((await fetch(`${server.url}/v2/anything`)).status, 404);
    });

    test("a body over the limit is refused, declared or streamed", async () => {
        const big = JSON.stringify({
            signedTransaction: "a".repeat(MAX_BODY_BYTES),
        });
        assert.equal(
            (await post(`${server.url}/v1/transactions`, big)).status,
            413,
        );

        // Chunked transfer has no content-length; the server stops reading at the limit.
        const status = await new Promise((resolve, reject) => {
            const request = httpRequest(
                `${server.url}/v1/transactions`,
                {
                    method: "POST",
                    headers: { "content-type": "application/json" },
                },
                (response) => {
                    response.resume();
                    resolve(response.statusCode);
                },
            );
            request.on("error", reject);
            for (let i = 0; i < 80; i += 1) request.write("x".repeat(1024));
            request.end();
        });
        assert.equal(status, 413);
    });

    test("accounts are looked up by a validated identifier", async () => {
        assert.equal(
            (
                await fetch(
                    `${server.url}/v1/accounts/${encodeURIComponent("token:../../etc")}`,
                )
            ).status,
            400,
        );
        assert.equal(
            (await fetch(`${server.url}/v1/accounts/%E0%A4%A`)).status,
            400,
        );
        assert.equal(
            (await fetch(`${server.url}/v1/accounts/original:123`)).status,
            404,
        );
        await post(`${server.url}/v1/transactions`, {
            signedTransaction: signJWS(transaction(), trusted),
        });
        const response = await fetch(`${server.url}/v1/accounts/${account}`);
        assert.equal(response.status, 200);
        assert.deepEqual(
            (await response.json()).entitlements.map((e) => e.name),
            ["pro"],
        );
    });

    test("health reports the environment", async () => {
        const response = await fetch(`${server.url}/health`);
        assert.deepEqual(await response.json(), {
            status: "ok",
            environment: "Sandbox",
        });
    });
});

describe("receipt server for Xcode transactions", () => {
    let server;
    let chain;

    before(async () => {
        chain = makeChain("xcode");
        const config = loadConfig({
            BUNDLE_ID,
            APPLE_ENVIRONMENT: "Xcode",
            ALLOW_UNVERIFIED_TRANSACTIONS: "1",
        });
        server = await startServer(config);
    });

    after(async () => {
        await server.close();
        chain.cleanup();
    });

    test("accepts transactions Xcode signed and nothing from the App Store environments", async () => {
        const xcode = await post(`${server.url}/v1/transactions`, {
            signedTransaction: signJWS(
                transaction({ environment: "Xcode" }),
                chain,
            ),
        });
        assert.equal(xcode.status, 200);
        assert.deepEqual(
            xcode.body.entitlements.map((e) => e.name),
            ["pro"],
        );
        const sandbox = await post(`${server.url}/v1/transactions`, {
            signedTransaction: signJWS(transaction(), chain),
        });
        assert.equal(sandbox.status, 422);
    });
});
