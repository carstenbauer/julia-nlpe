echo "##################### FLOPS_DP #####################"
JULIA_EXCLUSIVE=1 likwid-perfctr -c 0-7 -m -g FLOPS_DP julia --project=. -t 8 stream-mapi.jl
echo "##################### DATA #####################"
JULIA_EXCLUSIVE=1 likwid-perfctr -c 0-7 -m -g DATA julia --project=. -t 8 stream-mapi.jl