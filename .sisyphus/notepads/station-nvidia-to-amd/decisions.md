# Decisions

## [2026-04-11] Planning Phase

- AMD card: RX 6700 XT (RDNA 2) → amdgpu driver, no PRIME needed
- ROCm: NOT needed — Ollama moving to another machine
- Kernel params: trim to ONLY `amd_pstate=active` + `amdgpu.dc=1`
- Ollama: disable entirely (`ollama.enable = false`)
- LM Studio: disable entirely (`lmstudio.enable = false`)
- Open WebUI: disable entirely (`hosted-services.open-webui.enable = false`)
- Hyprland NVIDIA workarounds: remove from shared, add to vnpc-21 host overrides
- Zen-browser NVIDIA vars: remove MOZ_DISABLE_RDD_SANDBOX + MOZ_X11_EGL from shared, add to vnpc-21
- Keep in shared zen-browser: MOZ_ENABLE_WAYLAND, MOZ_WAYLAND_USE_VAAPI, MOZ_USE_XINPUT2
- Do NOT touch station's misc.vrr=0, render.direct_scanout=0, decoration.blur.enabled=false
