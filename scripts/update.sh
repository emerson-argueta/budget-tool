#!/usr/bin/env bash
# =============================================================================
# Budget App — Update Script
# Pull latest code and restart the service.
# =============================================================================

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$REPO_DIR/budget_app"

echo "→ Pulling latest code..."
cd "$REPO_DIR"
git pull

echo "→ Installing gems..."
cd "$APP_DIR"
bundle install --without development test

echo "→ Running migrations..."
RAILS_ENV=production bundle exec rails db:migrate

echo "→ Recompiling assets..."
RAILS_ENV=production bundle exec rails assets:precompile
RAILS_ENV=production bundle exec rails tailwindcss:build

echo "→ Restarting app..."
sudo systemctl restart budget

echo ""
echo "✓ Done. App restarted."
sudo systemctl status budget --no-pager
