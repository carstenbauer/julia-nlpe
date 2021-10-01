# likwid-perfctr -s 0xfffffffffffffe01 -C 0-7 -m -g FLOPS_DP julia --project=. -t 8 stream-mapi.jl
# likwid-perfctr -c 0-7 -m -g FLOPS_DP likwid-pin -s 0xfffffffffffffe01 -c 0-7 julia --project=. -t 8 stream-mapi.jl
JULIA_EXCLUSIVE=1 likwid-perfctr -c 0-7 -m -g FLOPS_DP julia --project=. -t 8 stream-mapi.jl