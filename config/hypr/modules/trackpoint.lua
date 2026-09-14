-- Brummy — TrackPoint ThinkPad (inofensivo no desktop: só aplica se o device existir)
-- Botão do meio = scroll (estilo clássico ThinkPad), sensibilidade moderada.
hl.device({
  name                    = "tpps/2-ibm-trackpoint",
  sensitivity             = 0.0,
  scroll_method           = "on_button_down",
  scroll_button           = 274,
  middle_button_emulation = true,
})
