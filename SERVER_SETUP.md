# Server Setup — Budget App

Private access via Tailscale VPN. The app runs on your home server and is only reachable from devices on your Tailscale account.

---

## Prerequisites

- Arch Linux / Omarchy server
- A [Tailscale account](https://tailscale.com) (free)
- The repo cloned on the server

---

## One-command setup

```bash
git clone <your-repo-url>
cd budget-tool
bash scripts/setup-server.sh
```

The script handles everything:

| Step | What it does |
|------|-------------|
| Tailscale | Installs, enables, prompts you to authenticate |
| System packages | `sqlite`, `nginx`, `rbenv`, `ruby-build` |
| Ruby | Installs Ruby 3.3.2 via rbenv |
| Gems | `bundle install` |
| Secrets | Generates `SECRET_KEY_BASE`, writes to `.env` |
| Database | Runs migrations and seeds category groups |
| Assets | Precompiles CSS and JS for production |
| systemd | Creates and enables `budget.service` (auto-starts on boot) |
| nginx | Configures reverse proxy on port 80 |

When it finishes, the app is live at `http://<tailscale-ip>`.

---

## Accessing the app

### From your other devices

Install Tailscale and sign in with the **same account**:

- **iPhone / Android** — App Store or Play Store → "Tailscale"
- **Mac** — [tailscale.com/download](https://tailscale.com/download)
- **Windows** — [tailscale.com/download](https://tailscale.com/download)

Once connected, open a browser and go to:

```
http://<your-server-tailscale-ip>
```

Find your server's Tailscale IP:
```bash
tailscale ip -4
```

### Friendly hostname (optional)

In the [Tailscale admin panel](https://login.tailscale.com/admin/machines), rename your server to something like `homeserver`. Then access it at:

```
http://homeserver
```

---

## Credentials setup

Before running the setup script, make sure `.env` in `budget_app/` has your Plaid credentials:

```
PLAID_CLIENT_ID=your_client_id
PLAID_SECRET=your_secret
PLAID_ENV=sandbox
```

The setup script will append `SECRET_KEY_BASE` and `RAILS_ENV=production` automatically.

---

## First login

On first visit, go to `/users/sign_up` to create your account. Registration is automatically locked after the first user is created.

---

## Updating the app

When you make changes on your dev machine, push them, then on the server run:

```bash
bash scripts/update.sh
```

This pulls the latest code, runs migrations, recompiles assets, and restarts the service.

---

## Useful commands

```bash
# App status
sudo systemctl status budget

# Live logs
sudo journalctl -u budget -f

# Restart app
sudo systemctl restart budget

# nginx status
sudo systemctl status nginx

# nginx logs
sudo journalctl -u nginx -f

# Tailscale status
tailscale status
```

---

## How it works

```
Your phone/laptop
  │  (Tailscale VPN)
  └─→ Home server (Tailscale IP: 100.x.x.x)
        │
        nginx :80
        │
        Rails :3000 (127.0.0.1 only)
```

- **Tailscale** encrypts all traffic between your devices — nobody outside your account can reach the server
- **nginx** handles HTTP and proxies to Rails, so you use port 80 (no `:3000` in the URL)
- **Rails** binds to `127.0.0.1` only — not reachable directly from the network
- **Devise** provides a second layer of auth (username + password)
