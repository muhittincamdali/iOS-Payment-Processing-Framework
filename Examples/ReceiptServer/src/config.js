// Reads the server's settings from environment variables and refuses unsafe combinations.
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

export const ENVIRONMENTS = ["Production", "Sandbox", "Xcode", "LocalTesting"];

// Transactions from Xcode and local tests are not signed by the App Store, so Apple's library
// cannot verify them. Accepting them is for development only.
const UNVERIFIABLE = new Set(["Xcode", "LocalTesting"]);

const DEFAULT_CERTS = fileURLToPath(new URL("../certs/", import.meta.url));

export class ConfigError extends Error {}

/**
 * @param {Record<string, string | undefined>} env usually process.env
 */
export function loadConfig(env) {
    const bundleId = env.BUNDLE_ID ?? "";
    if (!/^[A-Za-z0-9.-]{1,155}$/.test(bundleId)) {
        throw new ConfigError(
            "BUNDLE_ID must be the app bundle identifier, such as com.example.shop.",
        );
    }

    const environment = env.APPLE_ENVIRONMENT ?? "";
    if (!ENVIRONMENTS.includes(environment)) {
        throw new ConfigError(
            `APPLE_ENVIRONMENT must be one of ${ENVIRONMENTS.join(", ")}.`,
        );
    }

    let appAppleId;
    if (env.APP_APPLE_ID !== undefined && env.APP_APPLE_ID !== "") {
        if (!/^[0-9]{1,15}$/.test(env.APP_APPLE_ID))
            throw new ConfigError(
                "APP_APPLE_ID must be the numeric Apple ID of the app.",
            );
        appAppleId = Number(env.APP_APPLE_ID);
    }
    if (environment === "Production" && appAppleId === undefined) {
        throw new ConfigError("APP_APPLE_ID is required in Production.");
    }

    if (UNVERIFIABLE.has(environment)) {
        if (env.NODE_ENV === "production") {
            throw new ConfigError(
                `${environment} transactions cannot be verified; this environment is refused when NODE_ENV=production.`,
            );
        }
        if (env.ALLOW_UNVERIFIED_TRANSACTIONS !== "1") {
            throw new ConfigError(
                `${environment} transactions cannot be verified; set ALLOW_UNVERIFIED_TRANSACTIONS=1 to accept them during development.`,
            );
        }
    }

    const certsDir = env.ROOT_CERTS_DIR || DEFAULT_CERTS;
    const rootCertificates = readdirSync(certsDir)
        .filter((name) => /\.(cer|der)$/i.test(name))
        .sort()
        .map((name) => readFileSync(join(certsDir, name)));
    if (rootCertificates.length === 0) {
        throw new ConfigError(`No root certificates (.cer) in ${certsDir}.`);
    }

    const port = parsePort(env.PORT ?? "8787");
    const host = env.HOST || "127.0.0.1";
    // OCSP checks need network access to Apple; tests turn them off.
    const onlineChecks = env.ONLINE_CHECKS !== "0";

    return {
        bundleId,
        environment,
        appAppleId,
        rootCertificates,
        port,
        host,
        onlineChecks,
    };
}

function parsePort(text) {
    if (!/^[0-9]{1,5}$/.test(text))
        throw new ConfigError("PORT must be a number from 0 to 65535.");
    const port = Number(text);
    if (port > 65535)
        throw new ConfigError("PORT must be a number from 0 to 65535.");
    return port;
}
