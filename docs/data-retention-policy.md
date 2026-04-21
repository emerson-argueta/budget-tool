# Data Retention and Deletion Policy

**Owner:** Emerson Argueta  
**Effective Date:** April 21, 2026  
**Review Frequency:** Annually

---

## Purpose

This policy defines how financial data collected via the Plaid API is retained and deleted.

## Data Categories and Retention

| Data Type | Retention Period | Rationale |
|---|---|---|
| Bank account metadata (name, type, mask) | Indefinite while account is connected | Required for budgeting functionality |
| Transaction history | Indefinite | Required for budgeting and historical reporting |
| Account balances | Indefinite | Required for net worth tracking |
| Plaid access tokens | Until bank connection is removed | Required to sync data |
| Application user account | Until deleted by owner | Required for authentication |

## Deletion

- When a bank connection is removed via the app, the associated Plaid access token and all synced account/transaction data for that connection are deleted from the database.
- The application owner may delete all data at any time by dropping the database or deleting the Rails application.
- Plaid access tokens are also revoked via the Plaid API upon disconnection.

## Consent and Legal Basis

- The sole user of this application is the application owner, who consents to data collection and retention for personal budgeting purposes.
- No data is retained beyond what is necessary for the application's budgeting functionality.
- No data is shared with third parties except Plaid (which is the data source).

## Backups

- If database backups are maintained, they are subject to the same retention policy. Backups older than 90 days are deleted.

## Policy Review

This policy is reviewed annually or when Plaid data handling requirements change.
