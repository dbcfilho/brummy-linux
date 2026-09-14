-- Brummy — desktop dbrum: Xeon E5-2670 v3 (sem iGPU) + RX 6600 XT, 2x 1080p60
-- M24CAB 24" (principal, esquerda) + 2270W 22" (direita).
-- Conectores variam (DP-1/HDMI-A-1/DP-2) — ajuste com `hyprctl monitors` se precisar.
hl.monitor({ output = "DP-1",     mode = "1920x1080@60", position = "0x0",    scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "1920x0", scale = 1 })
-- Fallback: qualquer monitor não listado sobe em preferred/auto.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Workspaces: ímpares no principal, pares no secundário (comente se não curtir)
hl.workspace_rule({ workspace = "1", monitor = "DP-1" })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1" })
