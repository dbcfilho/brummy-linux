-- Brummy — vídeo Intel (T430 HD 4000 e PCs gerais com iGPU)
-- HD 4000 não tem Vulkan nativo: mesa provê lavapipe; VA-API via i965.
hl.env("LIBVA_DRIVER_NAME", "i965")
