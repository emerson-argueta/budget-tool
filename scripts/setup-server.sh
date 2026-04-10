#!/usr/bin/env bash
# =============================================================================
# Budget App — Server Setup Script
# Arch Linux / Omarchy
# Run as your normal user (not root). Uses sudo where needed.
# =============================================================================

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$REPO_DIR/budget_app"
SERVICE_NAME="budget"
APP_PORT=3000
CURRENT_USER="$(whoami)"

echo ""
echo "=================================================="
echo " Budget App Server Setup"
echo "=================================================="
echo " App dir   : $APP_DIR"
echo " User      : $CURRENT_USER"
echo " Port      : $APP_PORT"
echo "=================================================="
echo ""

# --- 1. Tailscale -----------------------------------------------------------
echo "→ Installing Tailscale..."
if command -v tailscale &>/dev/null; then
  echo "  Tailscale already installed, skipping."
else
  curl -fsSL https://tailscale.com/install.sh | sh
fi

sudo systemctl enable --now tailscaled
echo ""
echo "→ Authenticating with Tailscale..."
echo "  A browser URL will appear below. Open it to log in."
echo ""
sudo tailscale up
echo ""
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "unavailable")
echo "  ✓ Tailscale IP: $TAILSCALE_IP"

# --- 2. System dependencies --------------------------------------------------
echo ""
echo "→ Installing system packages..."
sudo pacman -Sy --noconfirm --needed \
  ruby \
  rbenv \
  ruby-build \
  git \
  base-devel \
  sqlite \
  nginx \
  redis

# --- 3. Ruby / rbenv ---------------------------------------------------------
echo ""
echo "→ Setting up rbenv..."
if ! grep -q 'rbenv init' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> "$HOME/.bashrc"
  echo 'eval "$(rbenv init -)"'               >> "$HOME/.bashrc"
fi
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)" 2>/dev/null || true

RUBY_VERSION="3.3.2"
if rbenv versions | grep -q "$RUBY_VERSION"; then
  echo "  Ruby $RUBY_VERSION already installed."
else
  echo "  Installing Ruby $RUBY_VERSION (this takes a few minutes)..."
  rbenv install "$RUBY_VERSION"
fi
rbenv global "$RUBY_VERSION"

# --- 4. App dependencies -----------------------------------------------------
echo ""
echo "→ Installing gems..."
cd "$APP_DIR"
gem install bundler --no-document 2>/dev/null || true
bundle install --without development test

# --- 5. Production env -------------------------------------------------------
echo ""
echo "→ Generating production secrets..."
SECRET=$(cd "$APP_DIR" && bundle exec rails secret)

ENV_FILE="$APP_DIR/.env"
if grep -q "SECRET_KEY_BASE" "$ENV_FILE" 2>/dev/null; then
  echo "  SECRET_KEY_BASE already set in .env, skipping."
else
  echo "" >> "$ENV_FILE"
  echo "SECRET_KEY_BASE=$SECRET" >> "$ENV_FILE"
  echo "  ✓ SECRET_KEY_BASE written to .env"
fi

if grep -q "RAILS_ENV=production" "$ENV_FILE" 2>/dev/null; then
  echo "  RAILS_ENV already set in .env, skipping."
else
  echo "RAILS_ENV=production" >> "$ENV_FILE"
  echo "  ✓ RAILS_ENV=production written to .env"
fi

# --- 6. Database + assets ----------------------------------------------------
echo ""
echo "→ Setting up database and assets..."
cd "$APP_DIR"
RAILS_ENV=production bundle exec rails db:migrate
RAILS_ENV=production bundle exec rails db:seed
RAILS_ENV=production bundle exec rails assets:precompile
RAILS_ENV=production bundle exec rails tailwindcss:build

# --- 7. systemd service ------------------------------------------------------
echo ""
echo "→ Creating systemd service..."
RUBY_BIN="$(rbenv which ruby)"
RAILS_BIN="$APP_DIR/bin/rails"

sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null <<EOF
[Unit]
Description=Budget App (Rails)
After=network.target

[Service]
Type=simple
User=${CURRENT_USER}
WorkingDirectory=${APP_DIR}
EnvironmentFile=${APP_DIR}/.env
Environment=RAILS_ENV=production
ExecStart=${RUBY_BIN} ${RAILS_BIN} server -p ${APP_PORT} -b 127.0.0.1
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now "$SERVICE_NAME"
echo "  ✓ budget.service enabled and started"

# --- 8. nginx ----------------------------------------------------------------
echo ""
echo "→ Configuring nginx..."

HOSTNAME=$(hostname)

sudo mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

sudo tee /etc/nginx/sites-available/budget > /dev/null <<EOF
server {
    listen 80;
    server_name ${HOSTNAME} ${TAILSCALE_IP};

    # Increase timeouts for slow queries
    proxy_read_timeout 120;
    proxy_connect_timeout 120;
    proxy_send_timeout 120;

    location / {
        proxy_pass http://127.0.0.1:${APP_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/budget /etc/nginx/sites-enabled/budget

# Add sites-enabled include to nginx.conf if not already there
if ! grep -q "sites-enabled" /etc/nginx/nginx.conf; then
  sudo sed -i '/http {/a\    include /etc/nginx/sites-enabled/*;' /etc/nginx/nginx.conf
fi

sudo nginx -t && sudo systemctl enable --now nginx
echo "  ✓ nginx configured and started"

# --- 9. Disable SSL (private VPN only) ---------------------------------------
echo ""
echo "→ Disabling force_ssl for private VPN use..."
PROD_CONFIG="$APP_DIR/config/environments/production.rb"
if grep -q "config.force_ssl = true" "$PROD_CONFIG"; then
  sed -i 's/config.force_ssl = true/config.force_ssl = false/' "$PROD_CONFIG"
  echo "  ✓ force_ssl disabled"
else
  echo "  Already disabled or not set, skipping."
fi

# --- Done --------------------------------------------------------------------
echo ""
echo "=================================================="
echo " ✓ Setup complete!"
echo "=================================================="
echo ""
echo " App is running at:"
echo "   http://${TAILSCALE_IP}"
echo "   http://${HOSTNAME}  (from Tailscale devices)"
echo ""
echo " Useful commands:"
echo "   sudo systemctl status budget    # app status"
echo "   sudo systemctl restart budget   # restart app"
echo "   sudo journalctl -u budget -f    # live logs"
echo "   sudo systemctl status nginx     # nginx status"
echo ""
echo " Next: install Tailscale on your phone/laptop and"
echo " sign in with the same account."
echo "=================================================="
