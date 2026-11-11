-- Hyprland configuration used ONLY for the login screen (archminimal-greeter).
-- Hyprland 0.57+ Lua format. Your own ~/.config/hypr is not involved.
--
-- Installed to /usr/share/archminimal-greeter/ and replaced on every
-- `make install`. Put your own settings (keyboard layout, monitors) in
-- /etc/archminimal-greeter/local.lua, which is loaded last and never touched.

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.config({
    input = {
        kb_layout          = "us",
        numlock_by_default = true,
        follow_mouse       = 0,
    },
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
        background_color         = "rgb(28292d)",
        -- The launcher starts Hyprland through start-hyprland; this keeps the
        -- login screen clean even if an older launcher is still installed.
        disable_watchdog_warning = true,
    },
    animations = { enabled = false },
    decoration = {
        blur   = { enabled = false },
        shadow = { enabled = false },
    },
    cursor = { inactive_timeout = 5 },
    -- No update news or donation prompts on the login screen.
    ecosystem = {
        no_update_news  = true,
        no_donation_nag = true,
    },
})

-- The greeter. Once it exits (successful login), close Hyprland so greetd can
-- start the session.
-- Security: Quickshell's greetd module logs every request at debug level,
-- including the password reply, so that category is switched off; umask 077
-- keeps the log readable by the greeter user only.
hl.on("hyprland.start", function()
    hl.exec_cmd("umask 077; qs --log-rules 'quickshell.service.greetd.debug=false' -p /usr/share/archminimal-greeter >/var/cache/archminimal-greeter/greeter.log 2>&1; hyprctl dispatch 'hl.dsp.exit()'")
end)

-- Local overrides, e.g.
--   hl.config({ input = { kb_layout = "us,ru", kb_options = "grp:alt_shift_toggle" } })
--   hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0", scale = 1 })
local ok, err = pcall(dofile, "/etc/archminimal-greeter/local.lua")
if not ok and not tostring(err):find("No such file") then
    error("/etc/archminimal-greeter/local.lua: " .. tostring(err))
end
