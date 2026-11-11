# Architecture Decision Records

Decisions behind the login screen. Format and statuses: [0001](0001-record-decisions-as-adr-files.adr).

| # | Decision | Status |
|---|---|---|
| [0001](0001-record-decisions-as-adr-files.adr) | Record architecture decisions as .adr files | Accepted |
| [0002](0002-greetd-and-quickshell-in-a-greeter-only-hyprland.adr) | greetd + a Quickshell greeter in a greeter-only Hyprland; no SDDM | Accepted |
| [0003](0003-agreety-safety-net.adr) | Safety net: fall back to a text login, never lock the user out | Accepted |
| [0004](0004-take-over-any-display-manager-reversibly.adr) | Take over from any display manager, record it, give it back on revert | Accepted |
| [0005](0005-password-and-state-stay-private.adr) | The password goes only to a hidden PAM prompt; logs and state stay private | Accepted |
| [0006](0006-install-layout-system-files-replaced-settings-kept.adr) | Install layout: shipped files replaced, user settings never touched | Accepted |
| [0007](0007-copied-from-sddm-login-into-a-new-repo.adr) | A new repo, archminimal-greeter, copied from sddm-login | Accepted |
| [0008](0008-ci-lint-in-an-arch-container.adr) | CI lints in an Arch container, including the greeter's Hyprland config | Accepted |
