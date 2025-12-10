# config/ss_cache.sh
# SimpleScalar cache and experiment configuration

########################################
# Base cache geometry
########################################

# L1 instruction cache
export SS_IL1_CONFIG="il1:32768:64:1:l"

# L1 data cache
# export SS_DL1_CONFIG="dl1:32768:64:1:l"
export SS_DL1_CONFIG="dl1:16:32:1:l" #tiny DL1 cache


# Unified L2 cache
# export SS_UL2_CONFIG="ul2:262144:64:4:l"
export SS_UL2_CONFIG="ul2:8192:64:4:l" #small L2 cache

########################################
# Experiment mode
########################################
# Valid values (for your own bookkeeping / stats):
#   baseline
#   victim
#   miss
#   stream
#   stream_multi
#   victim_stream

# export SS_MODE="baseline"
export SS_MODE="victim"

########################################
# Victim cache parameters
########################################

# Enable/disable victim cache on DL1
export SS_VC_ENABLE=1       # 0 = off, 1 = on

# Number of victim entries (fully-associative)
export SS_VC_ENTRIES=4      # e.g., 4 or 8

########################################
# Miss cache parameters (optional variant)
########################################

export SS_MC_ENABLE=0       # 0 = off, 1 = on
export SS_MC_ENTRIES=4

########################################
# Stream buffer parameters
########################################

export SS_SB_ENABLE=0       # 0 = off, 1 = on

# Number of independent stream buffers
export SS_SB_COUNT=1        # for multi-way stream buffers, set to 2, 4, etc.

# How many lines deep each buffer is
export SS_SB_DEPTH=4        # typical small value (4–8)

# How many lines ahead to prefetch per trigger (degree)
export SS_SB_DEGREE=1
