# archminimal-greeter — run `make help`.
#
# Login screen = greetd + a Quickshell greeter in a minimal Hyprland.
# No SDDM anywhere.
#
#   make deps            # greetd, Hyprland, Quickshell, font
#   make preview         # try it in a window from your desktop
#   sudo make install    # copy files (does not change the login manager yet)
#   sudo make enable     # greetd takes over from whatever display manager is active
#   sudo make revert     # give it back (or boot to a text login if there was none)

SHELL := /bin/bash
.DEFAULT_GOAL := help

NAME        := archminimal-greeter
DESTDIR     ?=
SHARE_DIR   := $(DESTDIR)/usr/share/$(NAME)
ETC_DIR     := $(DESTDIR)/etc/$(NAME)
BIN_DIR     := $(DESTDIR)/usr/local/bin
TMPFILES    := $(DESTDIR)/usr/lib/tmpfiles.d/$(NAME).conf
GREETD_CONF := $(DESTDIR)/etc/greetd/config.toml
BACKUP      := $(GREETD_CONF).pre-$(NAME)
STATE_DIR   := /var/cache/$(NAME)
PREVIEW_DIR := $(or $(XDG_RUNTIME_DIR),/tmp)/$(NAME)-preview

.PHONY: help deps check lint preview install uninstall enable revert remove-sddm status logs diagnose

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

define need_root
	@if [ "$$(id -u)" -ne 0 ] && [ -z "$(DESTDIR)" ]; then echo "error: run with sudo: sudo make $@"; exit 1; fi
endef

deps: ## Install dependencies (all from the official repos)
	sudo pacman -S --needed greetd hyprland quickshell qt6-svg ttf-jetbrains-mono

check: ## Verify that everything the greeter needs is installed
	@ok=1; \
	for c in greetd agreety Hyprland hyprctl qs systemctl; do \
		if command -v $$c >/dev/null 2>&1; then printf "  ok       %s\n" $$c; \
		else printf "  MISSING  %s\n" $$c; ok=0; fi; \
	done; \
	if fc-list 2>/dev/null | grep -qi "JetBrains Mono"; then echo "  ok       JetBrains Mono font"; \
	else echo "  warn     JetBrains Mono not found (sudo pacman -S ttf-jetbrains-mono)"; fi; \
	if getent passwd greeter >/dev/null; then echo "  ok       greeter user"; \
	else echo "  MISSING  greeter user (comes with the greetd package)"; ok=0; fi; \
	ls /usr/share/wayland-sessions/*.desktop >/dev/null 2>&1 && echo "  ok       wayland sessions: $$(ls /usr/share/wayland-sessions | tr '\n' ' ')" \
		|| { echo "  MISSING  no session in /usr/share/wayland-sessions"; ok=0; }; \
	[ $$ok -eq 1 ] || { echo "fix the items above first"; exit 1; }

lint: ## Static checks (JSON, shell, QML if the tools are installed)
	@python3 -c 'import json; json.load(open("config/config.json"))' && echo "  ok  config/config.json"
	@if command -v shellcheck >/dev/null; then shellcheck system/$(NAME) system/display-manager.sh system/diagnose.sh greeter/list-sessions.sh && echo "  ok  shellcheck"; \
	else echo "  skip shellcheck (not installed)"; fi
	@if command -v qmllint6 >/dev/null || command -v qmllint >/dev/null; then \
		$$(command -v qmllint6 || command -v qmllint) greeter/*.qml || true; \
	else echo "  skip qmllint (not installed)"; fi

preview: ## Open the greeter in a window (no login, no power actions; Esc quits)
	@mkdir -p $(PREVIEW_DIR)
	ARCHMINIMAL_CONFIG=$(CURDIR)/config/config.json ARCHMINIMAL_STATE_DIR=$(PREVIEW_DIR) \
		qs -p $(CURDIR)/greeter

install: ## Install or update files (sudo). Keeps your config.json and local.lua. Does not switch login managers
	$(need_root)
	install -d $(SHARE_DIR) $(ETC_DIR) $(BIN_DIR) $(dir $(TMPFILES))
	install -m 644 greeter/*.qml greeter/background.png system/hyprland.lua $(SHARE_DIR)/
	install -m 755 greeter/list-sessions.sh $(SHARE_DIR)/
	install -m 755 system/$(NAME) $(BIN_DIR)/$(NAME)
	install -m 644 system/tmpfiles.conf $(TMPFILES)
	@if [ -e $(ETC_DIR)/config.json ]; then echo "keeping your $(ETC_DIR)/config.json"; \
	else install -m 644 config/config.json $(ETC_DIR)/config.json; echo "installed $(ETC_DIR)/config.json"; fi
	@# Older versions copied the greeter's Hyprland config to /etc and never updated it.
	@if [ -e $(ETC_DIR)/hyprland.lua ]; then \
		mv $(ETC_DIR)/hyprland.lua $(ETC_DIR)/hyprland.lua.unused; \
		echo "moved the old $(ETC_DIR)/hyprland.lua aside (now unused; it is kept as hyprland.lua.unused)"; \
		echo "  put your own settings in $(ETC_DIR)/local.lua instead"; fi
	@if [ -z "$(DESTDIR)" ]; then systemd-tmpfiles --create $(TMPFILES); fi
	@grep -q start-hyprland $(BIN_DIR)/$(NAME) && grep -q disable_watchdog_warning $(SHARE_DIR)/hyprland.lua \
		&& echo "✓ installed: launcher starts Hyprland via start-hyprland, no warning banner" \
		|| { echo "✗ install check failed: $(BIN_DIR)/$(NAME) or $(SHARE_DIR)/hyprland.lua is not the new version"; exit 1; }
	@echo "Next: 'sudo make enable' (first time only), then reboot."

uninstall: ## Remove installed files (sudo). Run 'sudo make revert' first if enabled
	$(need_root)
	@if grep -qs "$(NAME)" $(GREETD_CONF); then echo "error: still enabled; run 'sudo make revert' first"; exit 1; fi
	rm -rf $(SHARE_DIR) $(BIN_DIR)/$(NAME) $(TMPFILES) $(STATE_DIR)
	@echo "Kept $(ETC_DIR) (your settings). Remove it manually if you like."

enable: ## Make this the login screen: greetd replaces the active display manager (sudo; next boot)
	$(need_root)
	@test -x $(BIN_DIR)/$(NAME) || { echo "error: run 'sudo make install' first"; exit 1; }
	@$(MAKE) --no-print-directory check
	install -d $(dir $(GREETD_CONF))
	@if [ -f $(GREETD_CONF) ] && ! grep -qs "$(NAME)" $(GREETD_CONF) && [ ! -f $(BACKUP) ]; then \
		cp -a $(GREETD_CONF) $(BACKUP); echo "backed up $(GREETD_CONF) -> $(BACKUP)"; fi
	install -m 644 system/greetd.toml $(GREETD_CONF)
	@sh system/display-manager.sh enable
	@echo
	@echo "Reboot to see it. Do not restart display managers from inside your session."
	@echo "If anything goes wrong: Ctrl+Alt+F2, log in, then 'sudo make revert' in this folder."

revert: ## Undo 'enable': greetd off, previous display manager back (or a text login) (sudo)
	$(need_root)
	@if [ -f $(BACKUP) ]; then mv $(BACKUP) $(GREETD_CONF); echo "restored $(GREETD_CONF)"; fi
	@sh system/display-manager.sh revert

remove-sddm: ## Uninstall SDDM once greetd is the login screen (sudo)
	$(need_root)
	@if [ "$$(basename "$$(readlink /etc/systemd/system/display-manager.service 2>/dev/null)")" != greetd.service ]; then \
		echo "error: greetd is not the active login screen yet; run 'sudo make enable' first"; exit 1; fi
	@if pacman -Q sddm >/dev/null 2>&1; then pacman -Rns sddm; else echo "sddm is not installed"; fi
	@rm -f /etc/archminimal-greeter/previous-display-manager

status: ## Show the active display manager and greeter state
	@sh system/display-manager.sh status
	@grep -s "^command" $(GREETD_CONF) | sed 's/^/  greetd:          /' || true
	@if [ ! -x $(BIN_DIR)/$(NAME) ]; then echo "  launcher:        not installed (sudo make install)"; \
	elif grep -q start-hyprland $(BIN_DIR)/$(NAME); then echo "  launcher:        up to date (start-hyprland)"; \
	else echo "  launcher:        OUTDATED, run: git pull && sudo make install"; fi
	@if [ -s $(STATE_DIR)/state.json ]; then echo "  last login:      $$(cat $(STATE_DIR)/state.json)"; fi

diagnose: ## After a login that did not reach the desktop: collect logs (run as your user, from Ctrl+Alt+F2)
	@sh system/diagnose.sh

logs: ## Show greetd logs from the current boot
	journalctl -b -u greetd --no-pager | tail -n 50
