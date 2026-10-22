#!/usr/bin/env node
// Starts the receipt server with settings from the environment. See Examples/README.md.
import { ConfigError, loadConfig } from "./config.js";
import { Ledger, LedgerFileError } from "./ledger.js";
import { createReceiptServer } from "./server.js";

let config;
let ledger;
try {
    config = loadConfig(process.env);
    ledger = new Ledger({ file: config.ledgerFile });
} catch (error) {
    if (error instanceof ConfigError || error instanceof LedgerFileError) {
        console.error(error.message);
        process.exit(2);
    }
    throw error;
}

const server = createReceiptServer(config, {
    ledger,
    log: (line) => console.log(line),
});
server.listen(config.port, config.host, () => {
    const { port } = server.address();
    console.log(
        `Receipt server for ${config.bundleId} (${config.environment}) on http://${config.host}:${port}, ledger in ${config.ledgerFile}`,
    );
});

for (const signal of ["SIGINT", "SIGTERM"]) {
    process.on(signal, () => server.close(() => process.exit(0)));
}
