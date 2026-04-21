# Role-Based Access Control and Identity & Access Management Policy

**Owner:** Emerson Argueta  
**Effective Date:** April 21, 2026  
**Review Frequency:** Annually

---

## Roles

The Budget application has a single role:

| Role | User | Permissions |
|---|---|---|
| Owner/Administrator | Application owner | Full access to all application features, data, and infrastructure |

There are no other roles, user groups, or external collaborators.

## Identity and Access Management

Access management is centralized through the following systems:

- **Tailscale** — All access to the application server flows through Tailscale. Tailscale acts as the centralized IAM layer for network access, enforcing device-level authentication before any connection reaches the server.
- **SSH keys** — Server access uses public key authentication managed in `~/.ssh/authorized_keys`. This is the single authoritative list of permitted identities for server access.
- **Application authentication** — The Budget web application uses Devise with email/password + TOTP MFA. There is one application account.

## Access Provisioning

- No provisioning process is required as there is only one user.
- New SSH keys are added to `authorized_keys` manually by the owner when a new device is set up.
- New Tailscale devices are approved via the Tailscale admin console.

## Access De-provisioning

- Lost or compromised devices: revoke via Tailscale admin console and remove SSH key from `authorized_keys`.
- Compromised application credentials: reset password via Devise password reset flow; rotate TOTP secret via the application settings.

## Periodic Review

The owner reviews the following annually:
- Active Tailscale devices (Tailscale admin console)
- `~/.ssh/authorized_keys` entries
- Active application sessions

## Policy Review

This policy is reviewed annually.
