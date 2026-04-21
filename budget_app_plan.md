# Personal Budget App — Build Plan
> Rails 8 · PostgreSQL · Hotwire · Tailwind · Plaid

---

## Overview

A zero-based budgeting app for personal use, inspired by EveryDollar.
Every dollar of income gets assigned to a category. Income − assigned = $0.
Bank transactions auto-imported via Plaid (free Development tier, up to 100 accounts).

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Rails 8 |
| Database | PostgreSQL |
| Frontend | Hotwire (Turbo + Stimulus) + Tailwind CSS |
| Background Jobs | Sidekiq + Redis |
| Bank Connectivity | Plaid (Development tier — free) |
| Auth | Devise (single user, just lock it down) |

---

## Phase 1 — Rails App Setup

### Steps
1. `rails new budget_app -d postgresql --css tailwind`
2. Add gems: `devise`, `plaid`, `sidekiq`, `pagy` (pagination)
3. Set up PostgreSQL database
4. Install and configure Devise — single user, disable registration after setup
5. Configure Sidekiq + Redis for background jobs
6. Configure Tailwind
7. Set up environment variables (`.env`) for Plaid credentials

### Plaid Setup
1. Sign up at https://dashboard.plaid.com
2. Create an app — select **Development** environment (free, up to 100 items)
3. Grab your `PLAID_CLIENT_ID` and `PLAID_SECRET`
4. Add to `.env`:
   ```
   PLAID_CLIENT_ID=your_client_id
   PLAID_SECRET=your_secret
   PLAID_ENV=development
   ```

---

## Phase 2 — Data Models

### Models & Relationships

```
User
  has_many :plaid_items
  has_many :accounts, through: :plaid_items
  has_many :budgets
  has_many :transactions

PlaidItem
  belongs_to :user
  has_many :accounts
  fields: access_token, item_id, institution_name, institution_id, cursor (for sync)

Account
  belongs_to :plaid_item
  has_many :transactions
  fields: plaid_account_id, name, official_name, type, subtype, 
          current_balance, available_balance, mask

Budget
  belongs_to :user
  has_many :budget_categories
  fields: month (date — store as first of month), total_income

BudgetCategory
  belongs_to :budget
  has_many :transactions
  belongs_to :category_group
  fields: name, planned_amount, emoji

CategoryGroup
  has_many :budget_categories
  fields: name, position (for ordering)
  examples: Housing, Food, Transport, Personal, Debt, Savings

Transaction
  belongs_to :account
  belongs_to :budget_category (nullable — unassigned until categorized)
  fields: plaid_transaction_id, amount, date, name, merchant_name,
          pending, plaid_category, notes

SinkingFund
  belongs_to :user
  fields: name, goal_amount, current_amount, target_date, emoji
```

### Key Migrations Notes
- `budgets.month` — store as `date`, always use first of month (e.g. 2024-03-01)
- `transactions.amount` — Plaid returns negative for credits, positive for debits. Normalize on import.
- Add indexes on `plaid_transaction_id` (unique), `transactions.date`, `transactions.budget_category_id`

---

## Phase 3 — Plaid Integration

### How Plaid Works
1. **Link** — User connects bank via Plaid Link (a JS widget Plaid provides)
2. **Access Token** — Plaid returns a `public_token`, you exchange it for a permanent `access_token` (store this securely)
3. **Sync** — Use `/transactions/sync` endpoint to pull new/modified/removed transactions incrementally using a `cursor`

### Controllers & Jobs Needed

**PlaidController**
- `POST /plaid/create_link_token` — generates a link token to initialize Plaid Link widget
- `POST /plaid/exchange_token` — exchanges public_token for access_token, creates PlaidItem
- `POST /plaid/webhook` — receives Plaid webhooks (optional but useful)

**SyncTransactionsJob** (Sidekiq)
- Runs on schedule (e.g. every hour via `sidekiq-cron`)
- Calls `/transactions/sync` with stored cursor for each PlaidItem
- Creates/updates/removes transactions in DB
- Normalizes amounts (flip sign so spending is positive)
- Auto-matches transactions to budget categories based on merchant name rules

**PlaidService** (plain Ruby service object)
- Wraps all Plaid API calls
- Methods: `create_link_token`, `exchange_public_token`, `sync_transactions(item)`

### Transaction Sync Logic
```ruby
# Pseudocode for sync
def sync(plaid_item)
  cursor = plaid_item.cursor
  loop do
    response = plaid_client.transactions_sync(access_token, cursor: cursor)
    
    create_or_update(response.added + response.modified)
    remove(response.removed)
    
    cursor = response.next_cursor
    break unless response.has_more
  end
  
  plaid_item.update!(cursor: cursor)
end
```

---

## Phase 4 — Budget Management

### BudgetsController
- `GET /budgets/:month` — show budget for a given month (default: current month)
- `POST /budgets` — create new monthly budget (can copy from previous month)
- `PATCH /budgets/:id` — update income

### BudgetCategoriesController
- CRUD for categories within a budget
- `PATCH /budget_categories/:id/planned_amount` — inline edit via Turbo

### UI: Budget Page Layout
```
[ Month Selector: < March 2024 > ]

INCOME
  Monthly Take-Home Pay:  $5,000     [ edit ]
  
  To Budget:  $0  ✓  (or show red if over/under)

GIVING          Planned    Spent    Left
  Charity       $200       $150     $50

HOUSING
  Rent/Mortgage $1,500     $1,500   $0
  Electric      $100       $87      $13

FOOD
  Groceries     $400       $320     $80
  Restaurants   $100       $143     -$43  ← over budget (red)

...

[ + Add Category ]
```

### Zero-Based Logic
```ruby
# On budget page
@total_income = @budget.total_income
@total_assigned = @budget.budget_categories.sum(:planned_amount)
@to_assign = @total_income - @total_assigned  # should equal 0
```

---

## Phase 5 — Transaction Management

### TransactionsController
- `GET /transactions` — list all, filterable by month/account/category
- `PATCH /transactions/:id` — assign to budget category
- `GET /transactions/unassigned` — show unassigned transactions

### UI: Transactions Page
- Table view: Date | Merchant | Amount | Account | Category (dropdown to assign)
- Filter bar: month picker, account filter, category filter, search
- Unassigned count badge in nav
- Bulk assign: select multiple → assign to category

### Auto-Categorization
- Store a `merchant_rules` table: merchant_name pattern → budget_category
- On sync, attempt auto-match before saving
- User can correct, which optionally saves a new rule

---

## Phase 6 — Dashboard

### What to Show
- **Monthly snapshot**: income vs spent vs remaining
- **Category progress bars**: each category shows % spent
- **Recent transactions**: last 10, with quick-assign if unassigned
- **Account balances**: current balance for each connected account
- **Sinking funds**: progress toward each fund goal

### Dashboard Stats (computed)
```ruby
@spent_this_month = current_budget.transactions.sum(:amount)
@remaining = current_budget.total_income - @spent_this_month
@over_budget_categories = current_budget.budget_categories.select(&:over_budget?)
@unassigned_count = current_user.transactions.where(budget_category: nil).count
```

---

## Phase 7 — Sinking Funds

Sinking funds = saving up for irregular expenses (car registration, vacation, new laptop, etc.)

### Model
```
SinkingFund: name, goal_amount, current_amount, target_date, emoji, notes
```

### UI
- Card grid of funds
- Progress bar per fund (current / goal)
- Quick add/withdraw amount
- Shows months until target date

---

## Phase 8 — Reports

- **Spending by category** — bar chart, current month vs last month
- **Monthly spending trend** — line chart, last 6 months total spending
- **Net worth snapshot** — sum of all account balances (assets − liabilities)
- **Top merchants** — where you spend the most

Use a charting library — **Chartkick** (works great with Rails, zero JS needed in views).

---

## File & Folder Structure

```
app/
  controllers/
    budgets_controller.rb
    budget_categories_controller.rb
    transactions_controller.rb
    plaid_controller.rb
    accounts_controller.rb
    sinking_funds_controller.rb
    reports_controller.rb
  
  models/
    user.rb
    budget.rb
    budget_category.rb
    category_group.rb
    transaction.rb
    plaid_item.rb
    account.rb
    sinking_fund.rb
    merchant_rule.rb
  
  services/
    plaid_service.rb
    transaction_categorizer.rb
    budget_calculator.rb
  
  jobs/
    sync_transactions_job.rb
  
  views/
    budgets/
    transactions/
    dashboard/
    reports/
    sinking_funds/
    plaid/
  
  javascript/
    controllers/
      budget_category_controller.js   # inline editing
      transaction_controller.js       # quick assign
      plaid_controller.js             # Plaid Link widget
```

---

## Gems to Add

```ruby
# Gemfile
gem 'devise'              # authentication
gem 'plaid'               # Plaid API client
gem 'sidekiq'             # background jobs
gem 'sidekiq-cron'        # scheduled jobs
gem 'redis'               # required by sidekiq
gem 'pagy'                # pagination
gem 'chartkick'           # charts for reports
gem 'groupdate'           # group by month/week for chartkick
gem 'dotenv-rails'        # .env support
```

---

## Build Order (Recommended)

1. ✅ Rails new + gems + DB setup
2. ✅ Devise single-user auth
3. ✅ Models + migrations (all at once, get the schema right)
4. ✅ Budget CRUD + zero-based UI (hardcode income first, no Plaid yet)
5. ✅ Manual transaction entry (so you can test assigning to categories)
6. ✅ Plaid Link integration + token exchange
7. ✅ Transaction sync job
8. ✅ Auto-categorization
9. ✅ Dashboard
10. ✅ Sinking funds
11. ✅ Reports + charts

---

## Prompts to Use in Claude Code

Start with this in your terminal:

```
Create a new Rails 8 app called budget_app with PostgreSQL and Tailwind. 
Set up Devise for single-user auth. Add gems: plaid, sidekiq, sidekiq-cron, 
redis, pagy, chartkick, groupdate, dotenv-rails. Create all the models from 
this schema: [paste Phase 2 models section]. Run migrations.
```

Then phase by phase, paste the relevant section of this plan.
