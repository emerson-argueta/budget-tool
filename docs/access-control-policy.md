# Access Control Policy

**Owner:** Emerson Argueta  
**Effective Date:** April 21, 2026  
**Review Frequency:** Annually

---

## Purpose

This policy defines how access to the Budget application and its infrastructure is controlled and reviewed.

## Access Model

The Budget application is a single-user personal application. There is exactly one role: **Owner/Administrator**, held by the application owner. No other users, employees, or contractors have access to any system component.

## Authentication Requirements

| System | Authentication Method |
|---|---|
| Budget application (web) | Email + password + TOTP MFA |
| Linux server | SSH key authentication (password auth disabled) |
| Tailscale network | Tailscale device authentication |
| Plaid dashboard | Plaid account credentials + MFA |

## Access Reviews

- The application owner reviews active SSH keys and Tailscale connected devices annually.
- Any unrecognized device is removed immediately from Tailscale and SSH authorized_keys.

## De-provisioning

- There are no employees or contractors to deprovision.
- If the owner's machine is lost, stolen, or compromised: Tailscale node is revoked via the admin console, SSH authorized_keys is updated, and application credentials are rotated.

## Least Privilege

- The Linux user running the Rails application has access only to the application directory and database.
- SSH access uses a separate administrative user with sudo access.
- Plaid API keys are scoped to the minimum required permissions (read-only for transactions/accounts).

## Policy Review

This policy is reviewed annually.
