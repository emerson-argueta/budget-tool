# Information Security Policy

**Owner:** Emerson Argueta  
**Effective Date:** April 21, 2026  
**Review Frequency:** Annually

---

## Purpose

This policy defines how the Budget personal finance application and its underlying infrastructure are secured to protect financial data accessed via the Plaid API.

## Scope

This policy applies to the Budget application, the Linux server it runs on, and all financial data stored in the SQLite database.

## Access Control

- The application server is not exposed to the public internet.
- All access is through Tailscale VPN, which uses zero-trust networking and device-level authentication.
- Server login requires SSH key authentication. Password authentication is disabled.
- The application requires email/password plus TOTP-based multi-factor authentication.
- Only the application owner has access to any system component.

## Data Protection

- All data in transit is encrypted via TLS (Tailscale/HTTPS).
- The server disk uses full-disk encryption.
- The SQLite database file has restricted filesystem permissions (readable only by the application user).
- Plaid API credentials are stored as environment variables, not in source code.

## Vulnerability Management

- Application dependencies are audited using `bundler-audit` on a monthly basis.
- Static analysis is performed using `brakeman` on a monthly basis.
- Critical vulnerabilities (CVSS ≥ 9.0) are patched within 7 days of discovery.
- High vulnerabilities (CVSS 7.0–8.9) are patched within 30 days.
- Ruby and Rails versions are kept on supported releases. End-of-life versions are updated within 90 days of EOL announcement.

## Incident Response

- If a security incident is suspected (e.g. unauthorized access, credential compromise), Plaid API keys are rotated immediately via the Plaid dashboard.
- Tailscale node keys are revoked if device compromise is suspected.
- The application owner is the sole responder and decision-maker for all incidents.

## Policy Review

This policy is reviewed annually or after any significant infrastructure change.
