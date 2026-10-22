// Test helpers: a certificate chain shaped like Apple's (root → WWDR intermediate → receipt
// signer, with Apple's marker extensions), JWS signing with its leaf key, and a running server.
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { sign } from "node:crypto";
import { createReceiptServer } from "../src/server.js";

const WWDR_INTERMEDIATE_OID = "1.2.840.113635.100.6.2.1";
const RECEIPT_SIGNER_OID = "1.2.840.113635.100.6.11.1";

function openssl(args, cwd) {
    execFileSync("openssl", args, { cwd, stdio: ["ignore", "ignore", "pipe"] });
}

/**
 * Creates a three-certificate chain in a temporary folder with openssl.
 * @returns {{ rootDir: string, x5c: string[], leafKey: string, cleanup: () => void }}
 */
export function makeChain(name) {
    const dir = mkdtempSync(join(tmpdir(), `receipt-chain-${name}-`));
    writeFileSync(
        join(dir, "ext.cnf"),
        [
            "[ca]",
            "basicConstraints = critical, CA:TRUE",
            "keyUsage = critical, keyCertSign, cRLSign",
            "",
            "[intermediate]",
            "basicConstraints = critical, CA:TRUE, pathlen:0",
            "keyUsage = critical, keyCertSign, cRLSign",
            `${WWDR_INTERMEDIATE_OID} = ASN1:NULL`,
            "",
            "[leaf]",
            "basicConstraints = critical, CA:FALSE",
            "keyUsage = critical, digitalSignature",
            `${RECEIPT_SIGNER_OID} = ASN1:NULL`,
            "",
        ].join("\n"),
    );
    for (const role of ["root", "intermediate", "leaf"]) {
        openssl(
            [
                "ecparam",
                "-name",
                "prime256v1",
                "-genkey",
                "-noout",
                "-out",
                `${role}.key`,
            ],
            dir,
        );
    }
    openssl(
        [
            "req",
            "-x509",
            "-new",
            "-key",
            "root.key",
            "-subj",
            `/CN=${name} Test Root`,
            "-days",
            "3650",
            "-sha256",
            "-extensions",
            "ca",
            "-config",
            "ext.cnf",
            "-out",
            "root.pem",
        ],
        dir,
    );
    for (const [role, issuer, extensions] of [
        ["intermediate", "root", "intermediate"],
        ["leaf", "intermediate", "leaf"],
    ]) {
        openssl(
            [
                "req",
                "-new",
                "-key",
                `${role}.key`,
                "-subj",
                `/CN=${name} Test ${role}`,
                "-config",
                "ext.cnf",
                "-out",
                `${role}.csr`,
            ],
            dir,
        );
        openssl(
            [
                "x509",
                "-req",
                "-in",
                `${role}.csr`,
                "-CA",
                `${issuer}.pem`,
                "-CAkey",
                `${issuer}.key`,
                "-CAcreateserial",
                "-days",
                "3650",
                "-sha256",
                "-extfile",
                "ext.cnf",
                "-extensions",
                extensions,
                "-out",
                `${role}.pem`,
            ],
            dir,
        );
    }
    const rootDir = join(dir, "roots");
    execFileSync("mkdir", [rootDir]);
    openssl(
        [
            "x509",
            "-in",
            "root.pem",
            "-outform",
            "DER",
            "-out",
            join(rootDir, "root.cer"),
        ],
        dir,
    );
    const der = (role) => {
        openssl(
            [
                "x509",
                "-in",
                `${role}.pem`,
                "-outform",
                "DER",
                "-out",
                `${role}.der`,
            ],
            dir,
        );
        return readFileSync(join(dir, `${role}.der`)).toString("base64");
    };
    return {
        rootDir,
        x5c: [der("leaf"), der("intermediate"), der("root")],
        leafKey: readFileSync(join(dir, "leaf.key"), "utf8"),
        cleanup: () => rmSync(dir, { recursive: true, force: true }),
    };
}

const base64url = (value) => Buffer.from(value).toString("base64url");

/** Signs `payload` as an ES256 compact JWS with the chain's leaf key. */
export function signJWS(payload, chain, { x5c = chain.x5c } = {}) {
    const header = base64url(JSON.stringify({ alg: "ES256", x5c }));
    const body = base64url(JSON.stringify(payload));
    const signature = sign("sha256", Buffer.from(`${header}.${body}`), {
        key: chain.leafKey,
        dsaEncoding: "ieee-p1363",
    });
    return `${header}.${body}.${signature.toString("base64url")}`;
}

export const BUNDLE_ID = "io.github.muhittincamdali.PaymentLab";
export const ACCOUNT_TOKEN = "6f1c2f5e-2b7a-4c55-9d0e-0b9f3c1d2a44";

let nextTransactionId = 2_000_000_000;

/** A decoded App Store transaction, as Apple signs it. */
export function transaction(overrides = {}) {
    const id = String(nextTransactionId++);
    const now = Date.now();
    return {
        transactionId: id,
        originalTransactionId: id,
        bundleId: BUNDLE_ID,
        productId: "pro.monthly",
        purchaseDate: now - 60_000,
        originalPurchaseDate: now - 60_000,
        expiresDate: now + 30 * 86_400_000,
        quantity: 1,
        type: "Auto-Renewable Subscription",
        appAccountToken: ACCOUNT_TOKEN,
        inAppOwnershipType: "PURCHASED",
        signedDate: now,
        environment: "Sandbox",
        transactionReason: "PURCHASE",
        storefront: "USA",
        currency: "USD",
        price: 4990,
        ...overrides,
    };
}

/** Decoded renewal information of a subscription, as Apple signs it. */
export function renewalInfo(overrides = {}) {
    const now = Date.now();
    return {
        originalTransactionId: "0",
        autoRenewProductId: "pro.monthly",
        productId: "pro.monthly",
        autoRenewStatus: 1,
        signedDate: now,
        environment: "Sandbox",
        renewalDate: now + 30 * 86_400_000,
        ...overrides,
    };
}

/**
 * An App Store Server Notification V2 payload around a signed transaction; `extra` adds fields
 * such as `subtype` and `signedRenewalInfo`.
 */
export function notification(
    type,
    signedTransactionInfo,
    environment = "Sandbox",
    { subtype, signedRenewalInfo } = {},
) {
    return {
        notificationType: type,
        ...(subtype ? { subtype } : {}),
        notificationUUID: "0c9a1b52-4b8f-4e43-9d5a-2f0d7f3e8a11",
        version: "2.0",
        signedDate: Date.now(),
        data: {
            bundleId: BUNDLE_ID,
            environment,
            signedTransactionInfo,
            ...(signedRenewalInfo ? { signedRenewalInfo } : {}),
            status: 1,
        },
    };
}

/** Starts a server on a free port and returns its base URL and a close function. */
export async function startServer(config, options) {
    const server = createReceiptServer(config, options);
    await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
    const { port } = server.address();
    return {
        url: `http://127.0.0.1:${port}`,
        close: () => new Promise((resolve) => server.close(resolve)),
    };
}

export async function post(
    url,
    body,
    headers = { "content-type": "application/json" },
) {
    const response = await fetch(url, {
        method: "POST",
        headers,
        body: typeof body === "string" ? body : JSON.stringify(body),
    });
    return { status: response.status, body: await response.json() };
}
