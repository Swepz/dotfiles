local home = assert(os.getenv("HOME"), "HOME is not set")
local scripts = home .. "/.config/hypr/scripts"

for name, value in pairs({
    SDL_VIDEODRIVER = "wayland",
    EGL_PLATFORM = "wayland",
    GDK_DISABLE = "vulkan",
    XDG_CURRENT_DESKTOP = "Hyprland",
    XDG_SESSION_TYPE = "wayland",
    XDG_SESSION_DESKTOP = "Hyprland",
    QT_QPA_PLATFORM = "wayland;xcb",
    QT_QPA_PLATFORMTHEME = "qt5ct",
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1",
    QT_AUTO_SCREEN_SCALE_FACTOR = "1",
    GDK_SCALE = "1",
    GDK_BACKEND = "wayland,x11,*",
    CLUTTER_BACKEND = "wayland",
    MOZ_ENABLE_WAYLAND = "1",
    XCURSOR_SIZE = "24",
    HYPRCURSOR_SIZE = "24",
    OZONE_PLATFORM = "wayland",
    ELECTRON_OZONE_PLATFORM_HINT = "wayland",
}) do
    hl.env(name, value)
end

hl.config({
    cursor = {
        no_hardware_cursors = true,
    },
    input = {
        kb_layout = "se, us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        numlock_by_default = true,
        follow_mouse = 1,
        mouse_refocus = false,
        touchpad = {
            natural_scroll = false,
            scroll_factor = 1.0,
            disable_while_typing = false,
        },
        sensitivity = 0,
    },
    general = {
        gaps_in = 0,
        gaps_out = 0,
        border_size = 1,
        col = {
            active_border = "rgba(36f9f6ff)",
            inactive_border = "rgba(6d77b3ff)",
        },
        layout = "master",
        resize_on_border = true,
    },
    decoration = {
        rounding = 10,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        fullscreen_opacity = 1.0,
        blur = {
            enabled = true,
            size = 6,
            passes = 3,
            new_optimizations = true,
            ignore_opacity = true,
            vibrancy = 0.55,
            xray = true,
        },
        shadow = {
            enabled = true,
            range = 15,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
    },
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "slave",
        mfact = 0.6,
    },
    binds = {
        workspace_back_and_forth = false,
        allow_workspace_cycles = true,
        pass_mouse_when_bound = false,
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        initial_workspace_tracking = 0,
    },
    animations = {
        enabled = false,
    },
    xwayland = {
        force_zero_scaling = true,
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

local autostart = {
    "hyprctl setcursor breeze_cursors 24",
    "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",
    "systemctl --user start gnome-keyring-daemon.service",
    scripts .. "/wallpaper-restore.sh",
    "swaync",
    home .. "/.config/ashell/launch.sh",
    "sh -c 'exec hyprdynamicmonitors run --enable-lid-events >>\"$HOME/.cache/hyprdynamicmonitors.log\" 2>&1'",
    scripts .. "/gtk.sh",
    "hypridle",
    "wl-paste --watch cliphist store",
    "mullvad-vpn",
    scripts .. "/cleanup.sh",
    "zen-browser",
    "zeditor",
    "rustdesk",
    "vesktop",
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
    "systemctl --user start hyprland-session.target",
}

hl.on("hyprland.start", function()
    for _, command in ipairs(autostart) do
        hl.exec_cmd(command)
    end
end)

local function exec(keys, command, options)
    hl.bind(keys, hl.dsp.exec_cmd(command), options)
end

exec("SUPER + RETURN", "alacritty")
exec("SUPER + W", "zen-browser")
exec("SUPER + E", "nautilus")
exec("SUPER + CTRL + E", "rofimoji")
exec("SUPER + CTRL + C", "qalculate-gtk")

local function set_zoom(offset)
    local current, err = hl.get_config("cursor.zoom_factor")
    if current == nil then
        error(err, 0)
    end
    hl.config({ cursor = { zoom_factor = math.max(1, current + offset) } })
end

hl.bind("SUPER + SHIFT + mouse_down", function() set_zoom(0.5) end)
hl.bind("SUPER + SHIFT + mouse_up", function() set_zoom(-0.5) end)
hl.bind("SUPER + SHIFT + Z", function()
    hl.config({ cursor = { zoom_factor = 1 } })
end)

hl.bind("SUPER + Q", hl.dsp.window.close())
exec("SUPER + SHIFT + Q", "hyprctl activewindow | grep pid | tr -d 'pid:' | xargs kill")
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind("SUPER + M", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind("SUPER + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + SHIFT + T", function()
    local workspace = assert(hl.get_active_workspace(), "no active workspace")
    for _, window in ipairs(hl.get_workspace_windows(workspace)) do
        hl.dispatch(hl.dsp.window.float({ window = window }))
    end
end)
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"))

for key, direction in pairs({ left = "left", right = "right", up = "up", down = "down" }) do
    hl.bind("SUPER + " .. key, hl.dsp.focus({ direction = direction }))
    hl.bind("SUPER + ALT + " .. key, hl.dsp.window.swap({ direction = direction }))
end

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("SUPER + SHIFT + right", hl.dsp.window.resize({ relative = true, x = 100, y = 0 }))
hl.bind("SUPER + SHIFT + left", hl.dsp.window.resize({ relative = true, x = -100, y = 0 }))
hl.bind("SUPER + SHIFT + down", hl.dsp.window.resize({ relative = true, x = 0, y = 100 }))
hl.bind("SUPER + SHIFT + up", hl.dsp.window.resize({ relative = true, x = 0, y = -100 }))
hl.bind("SUPER + G", hl.dsp.group.toggle())
hl.bind("SUPER + K", hl.dsp.layout("swapsplit"))
hl.bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end, { repeating = true })
exec("SUPER + SPACE", "hyprctl switchxkblayout all next")

exec("SUPER + CTRL + R", "hyprctl reload")
hl.bind("SUPER + SHIFT + A", function()
    local enabled, err = hl.get_config("animations.enabled")
    if enabled == nil then
        error(err, 0)
    end
    hl.config({ animations = { enabled = not enabled } })
end)
exec("SUPER + PRINT", scripts .. "/screenshot.sh")
exec("SUPER + ALT + F", scripts .. "/screenshot.sh --instant")
exec("SUPER + ALT + S", scripts .. "/screenshot.sh --instant-area")
exec("SUPER + ALT + R", scripts .. "/toggle-record.sh")
exec("SUPER + CTRL + X", scripts .. "/power-menu.sh")
exec("SUPER + SHIFT + W", scripts .. "/waypaper.sh --random")
exec("SUPER + CTRL + W", scripts .. "/waypaper.sh")
exec("SUPER + ALT + W", scripts .. "/wallpaper-automation.sh")
exec("SUPER + D", scripts .. "/launcher.sh")
exec("SUPER + CTRL + K", scripts .. "/keybindings.sh")
exec("SUPER + SHIFT + B", home .. "/.config/ashell/launch.sh")
exec("SUPER + CTRL + B", home .. "/.config/ashell/toggle.sh")
exec("SUPER + SHIFT + R", scripts .. "/loadconfig.sh")
exec("SUPER + V", "cliphist list | rofi -dmenu | cliphist decode | wl-copy")
exec("SUPER + ALT + G", scripts .. "/gamemode.sh")
exec("SUPER + CTRL + L", scripts .. "/power.sh lock")
exec("SUPER + SHIFT + H", scripts .. "/hyprshade.sh")

local function move_workspace_windows(target)
    return function()
        local source = assert(hl.get_active_workspace(), "no active workspace")
        for _, window in ipairs(hl.get_workspace_windows(source)) do
            hl.dispatch(hl.dsp.window.move({ workspace = target, window = window }))
        end
        hl.dispatch(hl.dsp.focus({ workspace = target }))
    end
end

for workspace = 1, 10 do
    local key = tostring(workspace % 10)
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = workspace }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
    hl.bind("SUPER + CTRL + " .. key, move_workspace_windows(workspace))
end

hl.bind("SUPER + Tab", hl.dsp.focus({ workspace = "m+1" }))
hl.bind("SUPER + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }))
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "r-1" }))
hl.bind("SUPER + CTRL + down", hl.dsp.focus({ workspace = "emptym" }))
hl.bind("SUPER + CTRL + SHIFT + left", hl.dsp.workspace.move({ monitor = "l" }))
hl.bind("SUPER + CTRL + SHIFT + right", hl.dsp.workspace.move({ monitor = "r" }))
hl.bind("SUPER + ALT + SHIFT + left", hl.dsp.window.move({ monitor = "l" }))
hl.bind("SUPER + ALT + SHIFT + right", hl.dsp.window.move({ monitor = "r" }))

exec("XF86MonBrightnessUp", "brightnessctl -q s +10%")
exec("XF86MonBrightnessDown", "brightnessctl -q s 10%-")
exec("XF86AudioRaiseVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 2%+", { locked = true, repeating = true })
exec("XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-", { locked = true, repeating = true })
exec("XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
exec("XF86AudioPlay", "playerctl play-pause")
exec("XF86AudioPause", "playerctl pause")
exec("XF86AudioNext", "playerctl next")
exec("XF86AudioPrev", "playerctl previous")
exec("XF86AudioMicMute", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
exec("XF86Calculator", "qalculate-gtk")
exec("XF86ScreenSaver", "hyprlock")
exec("code:238", "brightnessctl -d smc::kbd_backlight s +10")
exec("code:237", "brightnessctl -d smc::kbd_backlight s 10-")

local window_rules = {
    { match = { title = "^(Microsoft-edge)$" }, tile = true },
    { match = { title = "^(Brave-browser)$" }, tile = true },
    { match = { title = "^(Chromium)$" }, tile = true },
    { match = { title = "^(pavucontrol)$" }, float = true },
    { match = { title = "^(blueman-manager)$" }, float = true },
    { match = { title = "^(nm-connection-editor)$" }, float = true },
    { match = { title = "^(qalculate-gtk)$" }, float = true },
    { match = { title = "^(Picture-in-Picture)$" }, float = true, pin = true, move = { "69.5%", "4%" } },
    { match = { class = ".*" }, idle_inhibit = "fullscreen" },
    { name = "resolve-xwayland", match = { class = "\\bresolve\\b", xwayland = true }, no_blur = true },
    { name = "old-school-runescape", match = { class = "osclient.exe" }, float = true, size = { 1400, 900 }, min_size = { 765, 502 }, center = true },
    { match = { class = "^(zen)$" }, workspace = "1 silent" },
    { match = { class = "^(dev\\.zed\\.Zed)$" }, workspace = "3 silent" },
    { match = { class = "^(rustdesk)$" }, workspace = "9 silent" },
    { match = { class = "^(vesktop)$" }, workspace = "10 silent" },
    { name = "pavucontrol", match = { class = ".*org.pulseaudio.pavucontrol.*" }, float = true, size = { 700, 600 }, center = true, pin = true },
    { match = { title = "ChatGPT.*" }, float = true },
    { name = "chatgpt-openai", match = { title = ".*chat.openai.com.*" }, float = true, size = { 500, "50%" }, move = { 20, 70 } },
    { name = "waypaper", match = { class = ".*waypaper.*" }, float = true, size = { 900, 700 }, center = true, pin = true },
    { name = "newelle", match = { class = "io.github.qwersyk.Newelle" }, float = true, size = { 1000, 700 }, center = true, pin = true },
    { name = "blueman", match = { class = "blueman-manager" }, float = true, size = { 800, 600 }, center = true },
    { name = "nwg-look", match = { class = "nwg-look" }, float = true, size = { 700, 600 }, move = { "10%", "20%" }, pin = true },
    { name = "nwg-displays", match = { class = "nwg-displays" }, float = true, size = { 900, 600 }, move = { "10%", "20%" }, pin = true },
    { name = "missioncenter", match = { class = "io.missioncenter.MissionCenter" }, float = true, pin = true, center = true, size = { 900, 600 } },
    { name = "missioncenter-prefs", match = { class = "missioncenter", title = "^(Preferences)$" }, float = true, pin = true, center = true },
    { name = "gnome-calc", match = { class = "org.gnome.Calculator" }, float = true, size = { 700, 600 }, center = true },
    { name = "share-picker", match = { class = "hyprland-share-picker" }, float = true, pin = true, center = true, size = { 600, 400 } },
    { name = "dotfiles-floating", match = { class = "dotfiles-floating" }, float = true, size = { 1000, 700 }, center = true },
    { name = "dotfiles-sidepad", match = { class = "dotfiles-sidepad" }, float = true, size = { 1000, 700 }, center = true, pin = true },
    { name = "file-picker", match = { class = "xdg-desktop-portal-gtk", title = "^(Open.*Files?|Save.*Files?|All Files|Save)" }, float = true, center = true },
}

for _, rule in ipairs(window_rules) do
    hl.window_rule(rule)
end

hl.layer_rule({ name = "swaync-control", match = { namespace = "swaync-control-center" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ name = "swaync-notification", match = { namespace = "swaync-notification-window" }, blur = true, ignore_alpha = 0.3 })

exec("SUPER + ALT + D", "/usr/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh record", { description = "Speech-to-text" })

require("monitors")
