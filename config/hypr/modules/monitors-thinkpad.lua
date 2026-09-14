-- Brummy — ThinkPad T430: LVDS 1366x768 (comum) ou 1600x900 (HD+)
-- Se o seu T430 for HD+, troque a mode para "1600x900@60".
-- HDMI/VGA externo sobe automático pelo fallback.
hl.monitor({ output = "eDP-1", mode = "1366x768@60", position = "0x0", scale = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
