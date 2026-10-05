local terminal = "kitty"
local menu     = "wofi --show drun"

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.config({
    general = {
        gaps_in     = 6,
        gaps_out    = 12,
        border_size = 2,
        ["col.active_border"]   = { colors = { "rgba(37e6d8ee)", "rgba(1b8f88ee)" }, angle = 45 },
        ["col.inactive_border"] = "rgba(0a1416aa)",
        resize_on_border = true,
        layout = "dwindle",
    },
    decoration = {
        rounding = 0,
        active_opacity   = 1.0,
        inactive_opacity = 0.94,
        blur = { enabled = true, size = 6, passes = 2, vibrancy = 0.15 },
        shadow = { enabled = true, range = 12, render_power = 2, color = "rgba(00000055)" },
    },
    dwindle = { preserve_split = true, smart_split = false },
    misc = { disable_hyprland_logo = true, disable_splash_rendering = true },
    input = { kb_layout = "us", follow_mouse = 1, sensitivity = 0.0 },
})

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("swww-daemon")
    hl.exec_cmd("sh -c 'sleep 1; swww img /usr/share/wallpapers/Vendetta/contents/images/1920x1080.png --transition-type grow --transition-pos center --transition-fps 60'")
end)

local mod = "SUPER"
hl.bind(mod .. " + Return",   hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + D",        hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + Q",        hl.dsp.window.close())
hl.bind(mod .. " + M",        hl.dsp.exit())
hl.bind(mod .. " + V",        hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + F",        hl.dsp.window.fullscreen())
hl.bind(mod .. " + J",        hl.dsp.layout("togglesplit"))

hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))

for i = 1, 5 do
    local key = tostring(i)
    hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
