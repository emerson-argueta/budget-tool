# Budget

A personal zero-based budgeting app built with Rails 8. Connects to your bank accounts via Plaid to automatically import transactions, and lets you assign them to budget categories each month.

## Features

- Zero-based budgeting with monthly category tracking
- Automatic transaction import via Plaid
- Manual cash transaction entry
- Sinking funds (savings goals with progress tracking)
- Spending reports and charts
- Multi-factor authentication (TOTP)
- Mobile-responsive UI

## Tech Stack

- **Ruby** 3.3.2 / **Rails** 8.1
- **SQLite** (single-user, no external database needed)
- **Plaid** for bank account connectivity
- **Devise** for authentication with TOTP MFA
- **Tailwind CSS** for styling
- **Solid Queue** for background jobs
- **Chartkick** + **Groupdate** for charts

## Setup

### 1. Install dependencies

```bash
bundle install
```

### 2. Configure environment variables

Copy the example and fill in your values:

```bash
cp .env.example .env
```

Required variables:

```
PLAID_CLIENT_ID=your_plaid_client_id
PLAID_SECRET=your_plaid_secret
PLAID_ENV=sandbox              # sandbox | development | production
PLAID_REDIRECT_URI=https://your-host/plaid/link   # required for OAuth banks
```

### 3. Set up the database

```bash
bin/rails db:create db:migrate
```

### 4. Run the app

```bash
bin/rails server
```

## Plaid Setup

1. Create a free account at [plaid.com](https://plaid.com)
2. Get your Client ID and Secret from the Plaid dashboard
3. Set `PLAID_ENV=sandbox` for testing with fake data
4. For real banks, apply for Production access in the Plaid dashboard

OAuth banks (Chase, SoFi, Bank of America, etc.) require a registered redirect URI and full Production access.

## Running with HTTPS (Tailscale)

Use `tailscale serve` to expose the app with automatic HTTPS on your Tailnet:

```bash
tailscale serve --bg 3000
```

This proxies `https://your-machine-name.your-tailnet.ts.net` to the Rails server on port 3000. Tailscale handles TLS cert issuance and renewal automatically.

## MFA Setup

On first login, you'll be prompted to scan a QR code with an authenticator app (Google Authenticator, Authy, etc.). MFA is required for all logins.

## Background Jobs

Transaction syncing runs as a background job via Solid Queue. It starts automatically with Puma in development via `SOLID_QUEUE_IN_PUMA=true`.
