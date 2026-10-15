// What each account owns, built only from transactions Apple's library verified.
//
// The rules match PaymentKit's EntitlementResolver on the device: refunded and upgraded
// transactions grant nothing, subscriptions last until their expiration date, non-consumables
// for good, and a lifetime purchase wins over a subscription.

export const CATALOG = {
    "coins.100": { kind: "consumable", coins: 100 },
    "pro.monthly": { kind: "autoRenewable", entitlement: "pro" },
    "pro.yearly": { kind: "autoRenewable", entitlement: "pro" },
    "pro.lifetime": { kind: "nonConsumable", entitlement: "pro" },
};

export class LedgerFullError extends Error {}

export class Ledger {
    #accounts = new Map();
    #catalog;
    #maxAccounts;
    #maxTransactions;

    constructor({
        catalog = CATALOG,
        maxAccounts = 10_000,
        maxTransactionsPerAccount = 1_000,
    } = {}) {
        this.#catalog = catalog;
        this.#maxAccounts = maxAccounts;
        this.#maxTransactions = maxTransactionsPerAccount;
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
     * Records a verified, decoded transaction. Recording the same transaction again replaces it,
     * so a refund updates the purchase instead of adding a second one, and coins are never
     * credited twice.
     * @returns {{ account: string, isNew: boolean }}
     */
    record(transaction) {
        const account = Ledger.accountOf(transaction);
        let transactions = this.#accounts.get(account);
        if (!transactions) {
            if (this.#accounts.size >= this.#maxAccounts)
                throw new LedgerFullError(
                    "The ledger holds its maximum number of accounts.",
                );
            transactions = new Map();
            this.#accounts.set(account, transactions);
        }
        const isNew = !transactions.has(transaction.transactionId);
        if (isNew && transactions.size >= this.#maxTransactions) {
            throw new LedgerFullError(
                "The account holds its maximum number of transactions.",
            );
        }
        transactions.set(transaction.transactionId, {
            transactionId: transaction.transactionId,
            productId: transaction.productId,
            purchaseDate: transaction.purchaseDate,
            expiresDate: transaction.expiresDate,
            revocationDate: transaction.revocationDate,
            isUpgraded: transaction.isUpgraded === true,
            quantity: clampQuantity(transaction.quantity),
            familyShared: transaction.inAppOwnershipType === "FAMILY_SHARED",
        });
        return { account, isNew };
    }

    /** The account's entitlements at `now` (milliseconds since 1970), sorted by name. */
    entitlements(account, now = Date.now()) {
        const best = new Map();
        for (const transaction of this.#accounts.get(account)?.values() ?? []) {
            const product = this.#catalog[transaction.productId];
            if (
                !product?.entitlement ||
                transaction.revocationDate !== undefined ||
                transaction.isUpgraded
            )
                continue;
            let expiresDate = null;
            if (product.kind === "autoRenewable") {
                if (
                    typeof transaction.expiresDate !== "number" ||
                    transaction.expiresDate <= now
                )
                    continue;
                expiresDate = transaction.expiresDate;
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
        for (const transaction of this.#accounts.get(account)?.values() ?? []) {
            const product = this.#catalog[transaction.productId];
            if (
                product?.kind !== "consumable" ||
                transaction.revocationDate !== undefined
            )
                continue;
            total += product.coins * transaction.quantity;
        }
        return total;
    }

    has(account) {
        return this.#accounts.has(account);
    }
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
