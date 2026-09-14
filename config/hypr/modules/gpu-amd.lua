-- Brummy — GPU AMD RX 6600 XT (RDNA2, desktop): força RADV + radeonsi
hl.env("LIBVA_DRIVER_NAME", "radeonsi")
hl.env("VDPAU_DRIVER",      "radeonsi")
hl.env("AMD_VULKAN_ICD",    "RADV")
hl.env("RADV_PERFTEST",     "sam,nggc")
