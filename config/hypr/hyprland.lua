-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║  Brummy Linux v1.1 — Hyprland híbrido estilo macOS (config Lua)      ║
-- ║  Teclado-driven (tiling) + mouse tradicional (arrastar, dock, topbar) ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Formato Lua (Hyprland 0.55+). O hyprlang (.conf) foi descontinuado e some
-- na 0.57 — a config antiga está preservada em legacy/ só para consulta.
-- Docs: https://wiki.hypr.land/Configuring/Start/

local mainMod = "SUPER"

-- Programas padrão (troque aqui, os binds seguem sozinhos)
local terminal     = "kitty"
local fileManager  = "nautilus || thunar"
local browser      = "helium-browser || helium || firefox"
local editor       = "codium || code"
local launcher     = "wofi --show drun --allow-images"

-------------------------------------------------------------------------
-- PERFIL DE MÁQUINA ----------------------------------------------------
-------------------------------------------------------------------------
-- install.sh cria os links modules/profile-monitors.lua e profile-gpu.lua
-- apontando para o perfil detectado (desktop / thinkpad / general).
local function brummy_module(name)
  -- Tenta o require normal; se o package.path não incluir ~/.config/hypr,
  -- carrega pelo caminho absoluto. Ausência de módulo nunca derruba a sessão.
  local ok = pcall(require, "modules." .. name)
  if ok then return end
  local home = os.getenv("HOME") or ""
  local chunk = loadfile(home .. "/.config/hypr/modules/" .. name .. ".lua")
  if chunk then
    local ran, err = pcall(chunk)
    if not ran then hl.print("[brummy] módulo " .. name .. " falhou: " .. tostring(err)) end
  else
    hl.print("[brummy] módulo " .. name .. " não encontrado (rode ./install.sh)")
  end
end

brummy_module("profile-monitors")
brummy_module("profile-gpu")
brummy_module("trackpoint")

-------------------------------------------------------------------------
-- AUTOSTART macOS-like: topbar, dock, wallpaper, polkit -----------------
-------------------------------------------------------------------------
-- ~/.local/bin nem sempre está no PATH da sessão gráfica: chama pelo caminho.
local localBin = (os.getenv("HOME") or "") .. "/.local/bin/"

hl.on("hyprland.start", function()
  hl.exec_cmd("waybar")
  hl.exec_cmd("hyprpaper")
  -- Aplica o wallpaper do Brummy via IPC (resolve o link ~/Pictures/Brummy/current)
  hl.exec_cmd(localBin .. "brummy-wallpaper-apply")
  hl.exec_cmd("nwg-dock-hyprland -d -mb 12 -i 48 -w 6 -hotspot_delay 150 -cursor_insert")
  hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
  hl.exec_cmd("wl-paste --watch cliphist store")
  hl.exec_cmd("udiskie --tray")
  -- Cursor do Brummy também para apps XWayland/GTK
  hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 28")
end)

-------------------------------------------------------------------------
-- VARIÁVEIS DE AMBIENTE ------------------------------------------------
-------------------------------------------------------------------------
-- Cursor maior e visível (tradicional), tema Bibata do bundle AUR
hl.env("XCURSOR_SIZE",    "28")
hl.env("HYPRCURSOR_SIZE", "28")
hl.env("XCURSOR_THEME",   "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_THEME","Bibata-Modern-Ice")
-- Apps GTK/Qt escuros por padrão (combina com WhiteSur-Dark)
hl.env("GTK_THEME",       "WhiteSur-Dark")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")

-------------------------------------------------------------------------
-- LOOK AND FEEL --------------------------------------------------------
-------------------------------------------------------------------------
hl.config({
  general = {
    gaps_in     = 8,
    gaps_out    = 14,
    border_size = 1,
    col = {
      active_border   = "rgba(ffffff55)",
      inactive_border = "rgba(00000033)",
    },
    layout = "dwindle",
    -- Híbrido mouse: redimensionar pela borda sem tecla + snap nas bordas
    resize_on_border     = true,
    hover_icon_on_border = true,
    snap = {
      enabled    = true,
      window_gap = 10,
    },
  },

  -- Estética macOS: cantos arredondados, sombra suave, blur frosted glass
  decoration = {
    rounding         = 16,
    rounding_power   = 2,
    active_opacity   = 1.0,
    inactive_opacity = 0.97,
    dim_inactive     = true,
    dim_strength     = 0.08,

    shadow = {
      enabled      = true,
      range        = 30,
      render_power = 3,
      color        = "rgba(00000055)",
    },

    blur = {
      enabled           = true,
      size              = 12,
      passes            = 3,
      new_optimizations = true,
      ignore_opacity    = true,
      xray              = false,
      vibrancy          = 0.1696,
    },
  },

  animations = { enabled = true },

  dwindle = { preserve_split = true },

  input = {
    kb_layout  = "br,us",
    kb_variant = ",intl",
    -- Mouse tradicional: foco segue mouse, aceleração adaptativa
    follow_mouse               = 1,
    float_switch_override_focus = 1,
    mouse_refocus              = true,
    accel_profile              = "adaptive",
    touchpad = {
      natural_scroll      = true,
      clickfinger_behavior = true,
      tap_to_click        = true,
      drag_lock           = false,
    },
  },

  misc = {
    focus_on_activate          = true,
    mouse_move_enables_dpms    = true,
    key_press_enables_dpms     = true,
    animate_mouse_windowdragging = true,
    initial_workspace_tracking = 1,
    -- Sem o wallpaper/logo padrão do Hyprland: quem manda é o hyprpaper
    force_default_wallpaper    = 0,
    disable_hyprland_logo      = true,
  },
})

-- Curvas e animações estilo macOS (mola suave na janela, slide no workspace)
hl.curve("mac",           { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.curve("almostLinear",  { type = "bezier", points = { {0.5, 0.5},  {0.75, 1}   } })

hl.animation({ leaf = "windows",    enabled = true, speed = 5, bezier = "mac",          style = "slide" })
hl.animation({ leaf = "fade",       enabled = true, speed = 5, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "mac",          style = "slide" })
hl.animation({ leaf = "layers",     enabled = true, speed = 4, bezier = "mac",          style = "fade" })

-- Frosted glass na bar, no dock e no Spotlight
hl.layer_rule({ name = "blur-waybar", match = { namespace = "^waybar$" },
                blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ name = "blur-dock",   match = { namespace = "^nwg-dock" }, blur = true })
hl.layer_rule({ name = "blur-wofi",   match = { namespace = "^wofi$" },    blur = true })

-------------------------------------------------------------------------
-- GESTOS (touchpad) ----------------------------------------------------
-------------------------------------------------------------------------
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-------------------------------------------------------------------------
-- REGRAS DE JANELA -----------------------------------------------------
-------------------------------------------------------------------------
local traditionalApps = "^(thunar|nautilus|org.gnome.Nautilus|pavucontrol|nm-connection-editor|file-roller|wlogout|nwg-look|gparted|GParted)$"

-- Híbrido: apps "de janelinha" flutuam e vêm centralizados; o resto tila
hl.window_rule({ name = "brummy-float-tradicionais",
                 match = { class = traditionalApps }, float = true })
hl.window_rule({ name = "brummy-center-tradicionais",
                 match = { class = "^(thunar|nautilus|org.gnome.Nautilus|pavucontrol|wlogout)$" },
                 center = true })
hl.window_rule({ name = "brummy-size-arquivos",
                 match = { class = "^(thunar|nautilus|org.gnome.Nautilus)$" },
                 size = "900 600" })
hl.window_rule({ name = "brummy-pip",
                 match = { title = "^(Picture-in-Picture)$" },
                 stay_focused = true, pin = true })

-- Gaming: Steam/jogos em fullscreen sem sombra/blur, tearing liberado p/ VRR
hl.window_rule({ name = "brummy-jogos",
                 match = { class = "^(steam_app.*|gamescope)$" },
                 fullscreen = true, no_blur = true, no_shadow = true, immediate = true })

-------------------------------------------------------------------------
-- ATALHOS (ver `brummy apps`) ------------------------------------------
-------------------------------------------------------------------------
hl.bind(mainMod .. " + Q",         hl.dsp.exec_cmd(terminal),    { description = "Terminal" })
hl.bind(mainMod .. " + E",         hl.dsp.exec_cmd(fileManager), { description = "Arquivos" })
hl.bind(mainMod .. " + B",         hl.dsp.exec_cmd(browser),     { description = "Navegador" })
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd(editor),      { description = "Editor" })
hl.bind(mainMod .. " + D",         hl.dsp.exec_cmd(launcher),    { description = "Launcher" })
hl.bind(mainMod .. " + SPACE",     hl.dsp.exec_cmd(launcher),    { description = "Spotlight" })
hl.bind(mainMod .. " + L",         hl.dsp.exec_cmd("hyprlock"),  { description = "Bloquear tela" })
-- Print estilo macOS (SHIFT+CMD+4): recorta e abre o editor de marcação
hl.bind(mainMod .. " + SHIFT + S",
        hl.dsp.exec_cmd("hyprshot -m region --raw | satty --filename - --copy-command wl-copy"),
        { description = "Captura de tela" })

hl.bind(mainMod .. " + C",         hl.dsp.window.close())
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + V",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + J",         hl.dsp.window.cycle_next({ next = true }))
hl.bind(mainMod .. " + K",         hl.dsp.window.cycle_next({ next = false }))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit())

-- Workspaces 1..9 (SHIFT move a janela junto)
for i = 1, 9 do
  hl.bind(mainMod .. " + " .. i,           hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. i,   hl.dsp.window.move({ workspace = i }))
end

-- Mouse tradicional: arrastar com SUPER ou ALT, scroll troca workspace
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("ALT + mouse:272",         hl.dsp.window.drag(),   { mouse = true })
hl.bind("ALT + mouse:273",         hl.dsp.window.resize(), { mouse = true })
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
-- Clique do meio fecha, SHIFT + botão direito flutua
hl.bind(mainMod .. " + mouse:274",         hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + mouse:273", hl.dsp.window.float({ action = "toggle" }))

-- Mídia e brilho (notebook tradicional)
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%"),   { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"),  { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s +10%"),                       { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"),                       { locked = true, repeating = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
