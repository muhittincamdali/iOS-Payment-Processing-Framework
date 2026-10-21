// An HTTP server that verifies StoreKit transactions with Apple's App Store Server Library
// and keeps each account's entitlements.
//
//   POST /v1/transactions     {"signedTransaction": "<Transaction.jwsRepresentation>"}
//   POST /v1/notifications    App Store Server Notifications V2: {"signedPayload": "..."}
//   GET  /v1/accounts/:id     entitlements and coins of an account
//   GET  /health
import { createServer } from "node:http";
import {
    SignedDataVerifier,
    VerificationException,
} from "@apple/app-store-server-library";
import { Ledger, LedgerFullError } from "./ledger.js";

export const MAX_BODY_BYTES = 64 * 1024;
export const MAX_JWS_LENGTH = 16 * 1024;
const JWS_PATTERN = /^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*$/;
const ACCOUNT_PATTERN = /^(token:[0-9a-f-]{36}|original:[0-9]{1,20})$/;

class HttpError extends Error {
    constructor(status, code, message) {
        super(message);
        this.status = status;
        this.code = code;
    }
}

/**
 * @param {ReturnType<import('./config.js').loadConfig>} config
 * @param {{ ledger?: Ledger, now?: () => number, log?: (line: string) => void }} [options]
 */
export function createReceiptServer(
    config,
    { ledger = new Ledger(), now = Date.now, log = () => {} } = {},
) {
    const verifier = new SignedDataVerifier(
        config.rootCertificates,
        config.onlineChecks,
        config.environment,
        config.bundleId,
        config.appAppleId,
    );

    async function recordTransaction(signedTransaction) {
        const transaction =
            await verifier.verifyAndDecodeTransaction(signedTransaction);
        if (!ledger.isKnownProduct(transaction.productId)) {
            throw new HttpError(
                422,
                "unknown_product",
                `The product ${String(transaction.productId).slice(0, 64)} is not sold by this server.`,
            );
        }
        const { account, isNew, changed } = ledger.record(transaction);
        const action = isNew ? "recorded" : changed ? "updated" : "kept";
        log(
            `${action} transaction ${transaction.transactionId} (${transaction.productId}) for ${account}`,
        );
        return { account, transaction };
    }

    /** The verified renewal information of the notification's subscription, if it has one. */
    async function verifyRenewal(signedRenewalInfo, transaction) {
        if (signedRenewalInfo === undefined) return null;
        const renewal = await verifier.verifyAndDecodeRenewalInfo(
            requireJWS(signedRenewalInfo, "signedRenewalInfo"),
        );
        if (renewal.originalTransactionId !== transaction.originalTransactionId)
            throw new HttpError(
                422,
                "renewal_mismatch",
                "The renewal information belongs to another subscription.",
            );
        return renewal;
    }

    function accountSummary(account) {
        return {
            account,
            entitlements: ledger.entitlements(account, now()),
            coins: ledger.coins(account),
        };
    }

    async function route(request) {
        const url = new URL(request.url ?? "/", "http://localhost");
        const path = url.pathname;

        if (path === "/health") {
            requireMethod(request, "GET");
            return {
                status: 200,
                body: { status: "ok", environment: config.environment },
            };
        }

        if (path === "/v1/transactions") {
            requireMethod(request, "POST");
            const body = await readJSON(request);
            const signedTransaction = requireJWS(
                body.signedTransaction,
                "signedTransaction",
            );
            const { account, transaction } =
                await recordTransaction(signedTransaction);
            return {
                status: 200,
                body: {
                    transactionId: transaction.transactionId,
                    productId: transaction.productId,
                    environment: transaction.environment,
                    ...accountSummary(account),
                },
            };
        }

        if (path === "/v1/notifications") {
            requireMethod(request, "POST");
            const body = await readJSON(request);
            const notification = await verifier.verifyAndDecodeNotification(
                requireJWS(body.signedPayload, "signedPayload"),
            );
            const signedTransaction = notification.data?.signedTransactionInfo;
            if (typeof signedTransaction === "string") {
                // The verified transaction counts on its own, so a refund is recorded even when
                // the renewal information beside it is refused.
                const { account, transaction } = await recordTransaction(
                    requireJWS(signedTransaction, "signedTransactionInfo"),
                );
                const renewal = await verifyRenewal(
                    notification.data.signedRenewalInfo,
                    transaction,
                );
                if (renewal && ledger.recordRenewal(account, renewal))
                    log(
                        `renewal of ${renewal.originalTransactionId} for ${account}: grace period until ${renewal.gracePeriodExpiresDate ?? "none"}`,
                    );
                log(
                    `notification ${notification.notificationType} for ${account}`,
                );
            }
            return {
                status: 200,
                body: { received: notification.notificationType ?? "unknown" },
            };
        }

        const match = path.match(/^\/v1\/accounts\/([^/]+)$/);
        if (match) {
            requireMethod(request, "GET");
            const account = safeDecode(match[1]);
            if (!ACCOUNT_PATTERN.test(account))
                throw new HttpError(
                    400,
                    "invalid_account",
                    "The account identifier is malformed.",
                );
            if (!ledger.has(account))
                throw new HttpError(
                    404,
                    "unknown_account",
                    "No transactions were recorded for this account.",
                );
            return { status: 200, body: accountSummary(account) };
        }

        throw new HttpError(
            404,
            "not_found",
            "There is nothing at this address.",
        );
    }

    return createServer(async (request, response) => {
        let result;
        try {
            result = await route(request);
        } catch (error) {
            result = errorResponse(error);
            if (result.status >= 500) log(`error: ${error?.stack ?? error}`);
        }
        const payload = JSON.stringify(result.body);
        response.writeHead(result.status, {
            "content-type": "application/json; charset=utf-8",
            "content-length": Buffer.byteLength(payload),
            "cache-control": "no-store",
        });
        response.end(payload);
    });
}

function errorResponse(error) {
    if (error instanceof HttpError)
        return {
            status: error.status,
            body: { error: error.code, message: error.message },
        };
    if (error instanceof VerificationException) {
        return {
            status: 422,
            body: {
                error: "verification_failed",
                status: error.status,
                message: "Apple could not verify the signed data.",
            },
        };
    }
    if (error instanceof LedgerFullError)
        return {
            status: 503,
            body: { error: "ledger_full", message: error.message },
        };
    return {
        status: 500,
        body: {
            error: "internal",
            message: "The server failed to handle the request.",
        },
    };
}

function requireMethod(request, method) {
    if (request.method !== method)
        throw new HttpError(405, "method_not_allowed", `Use ${method}.`);
}

function requireJWS(value, field) {
    if (
        typeof value !== "string" ||
        value.length === 0 ||
        value.length > MAX_JWS_LENGTH ||
        !JWS_PATTERN.test(value)
    ) {
        throw new HttpError(
            400,
            "invalid_jws",
            `${field} must be a compact JWS of at most ${MAX_JWS_LENGTH} characters.`,
        );
    }
    return value;
}

function safeDecode(component) {
    try {
        return decodeURIComponent(component);
    } catch {
        return "";
    }
}

/** Reads a JSON object body of at most MAX_BODY_BYTES, stopping as soon as it is too large. */
async function readJSON(request) {
    const type = request.headers["content-type"] ?? "";
    if (!/^application\/json(\s*;|$)/i.test(type))
        throw new HttpError(
            415,
            "unsupported_media_type",
            "Send application/json.",
        );
    const declared = Number(request.headers["content-length"]);
    if (Number.isFinite(declared) && declared > MAX_BODY_BYTES) {
        request.resume();
        throw new HttpError(
            413,
            "body_too_large",
            `The body is larger than ${MAX_BODY_BYTES} bytes.`,
        );
    }
    const chunks = [];
    let size = 0;
    for await (const chunk of request) {
        size += chunk.length;
        if (size > MAX_BODY_BYTES) {
            request.resume();
            throw new HttpError(
                413,
                "body_too_large",
                `The body is larger than ${MAX_BODY_BYTES} bytes.`,
            );
        }
        chunks.push(chunk);
    }
    let body;
    try {
        body = JSON.parse(Buffer.concat(chunks).toString("utf8"));
    } catch {
        throw new HttpError(400, "invalid_json", "The body is not valid JSON.");
    }
    if (body === null || typeof body !== "object" || Array.isArray(body)) {
        throw new HttpError(
            400,
            "invalid_json",
            "The body must be a JSON object.",
        );
    }
    return body;
}
