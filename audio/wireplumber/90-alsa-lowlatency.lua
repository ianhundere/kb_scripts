-- Low-latency ALSA configuration for WirePlumber
-- Optimized for T14s built-in audio (Family 17h/19h/1ah HD Audio Controller)

alsa_monitor.rules = {
  {
    matches = {
      {
        -- Apply to all ALSA devices
        { "device.name", "matches", "alsa_card.*" },
      },
    },
    apply_properties = {
      -- Lower period size for reduced latency
      ["api.alsa.period-size"]   = 128,  -- Reduced from default 1024
      ["api.alsa.period-num"]    = 2,    -- Number of periods

      -- Disable batch mode for lower latency
      ["api.alsa.disable-batch"] = true,

      -- Keep headroom for processing
      ["api.alsa.headroom"]      = 256,

      -- Suspend timeout (0 = never suspend, good for stability)
      ["session.suspend-timeout-seconds"] = 0,
    },
  },
  {
    matches = {
      {
        -- Specific settings for built-in audio controller
        { "node.name", "matches", "alsa_output.pci-0000_07_00.6.*" },
      },
    },
    apply_properties = {
      -- Ensure 48kHz for built-in audio
      ["audio.rate"] = 48000,

      -- Disable hardware volume (use software for better control)
      ["api.alsa.use-acp"] = true,
    },
  },
}
