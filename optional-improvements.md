# Optional improvements

## Environment configuration CLI

Add a CLI to inspect and manage configuration across the Tailscale, Arcane, and Cloudflared environment files.

- Show whether each setting is provided, empty, missing, or still a placeholder without displaying secret values. Distinguish required settings from optional settings and defaults, including the Tailscale auth key after registration.
- Flag missing environment files and check that the configured projects directory exists.
- Allow selecting a setting and updating it interactively, hiding secrets during entry and keeping environment files owner-readable only.
- Preserve existing values by default, especially Arcane's encryption key, and allow services to be skipped.
- Optionally generate an Arcane encryption key for a fresh installation and derive the projects path, UID, and GID.

Keep configuration separate from service startup. A provided value does not prove that a credential is valid or a service is reachable; connectivity and readiness checks should report those separately.
