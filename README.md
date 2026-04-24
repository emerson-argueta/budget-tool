# Budget Tool

A personal zero-based budgeting app inspired by EveryDollar. Built with Rails 8, Hotwire, Tailwind CSS, and Plaid for automatic bank transaction sync.

## Features

- **Zero-based budgeting** — assign every dollar of income to a category
- **Bank sync via Plaid** — automatically import transactions from connected accounts
- **Manual transactions** — add cash or off-bank expenses manually
- **Income tracking** — mark transactions as income sources; they count toward your monthly budget
- **Category groups** — organize budget categories into custom groups (Housing, Food, etc.)
- **Copy budget** — copy categories and planned amounts from the previous month
- **Transaction categorization** — assign transactions to budget categories per month
- **Reports** — spending by category, monthly trend, net worth snapshot, top merchants
- **Sinking funds** — track savings goals with deposit/withdraw history
- **Private access** — runs on your home server, accessible via Tailscale VPN

## Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Rails 8.1 |
| Database | SQLite3 |
| Frontend | Hotwire (Turbo + Stimulus), Tailwind CSS v4 |
| Auth | Devise (single-user, registration locked after first account) |
| Bank data | Plaid Ruby SDK |
| Charts | Chartkick + Chart.js |
| Pagination | Pagy |
| Job queue | Solid Queue (Rails default) |
| Deployment | systemd + nginx + Tailscale VPN |

## Local Development

### Prerequisites

- Ruby 3.3.2
- Bundler
- A [Plaid developer account](https://dashboard.plaid.com/signup) (free sandbox)

### Setup

```bash
git clone git@github.com:emerson-argueta/budget-tool.git
cd budget-tool/budget_app
bundle install
cp .env.example .env   # fill in your Plaid credentials
bundle exec rails db:create db:migrate db:seed
bundle exec rails tailwindcss:watch &
bundle exec rails server
```

Visit `http://localhost:3000` and sign up. Registration is locked after the first user is created.

### Environment Variables

Create `budget_app/.env`:

```
PLAID_CLIENT_ID=your_client_id
PLAID_SECRET=your_secret
PLAID_ENV=sandbox
```

## Server Deployment

The app is designed to run privately on a home server, accessible only over Tailscale VPN.

See [SERVER_SETUP.md](SERVER_SETUP.md) for the full setup guide (Arch Linux / Omarchy).

**One-command setup:**

```bash
bash scripts/setup-server.sh
```

**Update after pushing changes:**

```bash
bash scripts/update.sh
```

## Project Structure

```
budget-tool/
├── budget_app/          # Rails application
│   ├── app/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── views/
│   │   └── javascript/  # Stimulus controllers
│   ├── config/
│   ├── db/
│   └── ...
├── scripts/
│   ├── setup-server.sh  # Full server setup (Tailscale, nginx, systemd)
│   └── update.sh        # Pull + migrate + restart
└── SERVER_SETUP.md      # Deployment documentation
```

## Usage Notes

- **Budgeting**: Navigate to *Budget* and select a month. Add category groups and categories, set planned amounts, then assign transactions.
- **Transactions**: Transactions sync automatically from connected banks. You can also add cash transactions manually. Each transaction is categorized against its own month's budget.
- **Income**: Mark a transaction as income using the "+ Income" button — it will count toward that month's available balance.
- **Reports**: View spending breakdowns, trends, and net worth under *Reports*.

## License

This project is licensed under the GNU General Public License v3.0.
See the LICENSE file for details.
