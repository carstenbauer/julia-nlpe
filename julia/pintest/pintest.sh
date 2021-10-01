echo "JULIA PLAIN:"
julia --project -t 8 pintest.jl
echo "JULIA EXCLUSIVE:"
JULIA_EXCLUSIVE=1 julia --project -t 8 pintest.jl
echo "LIKWID PIN PLAIN:"
likwid-pin -c 0-7 julia --project -t 8 pintest.jl
echo "LIKWID PIN MASKED:"
likwid-pin -s 0xfffffffffffffe01 -c 0-7 julia --project -t 8 pintest.jl
echo "LIKWID PERFCTR PLAIN:"
likwid-perfctr -C 0-7 -g FLOPS_DP -m julia --project -t 8 pintest.jl
echo "LIKWID PERFCTR MASKED:"
likwid-perfctr -s 0xfffffffffffffe01 -C 0-7 -g FLOPS_DP -m julia --project -t 8 pintest.jl
echo "LIKWID PERFCTR + PIN MASKED:"
likwid-perfctr -c 0-7 -g FLOPS_DP -m likwid-pin -s 0xfffffffffffffe01 -c 0-7 julia --project -t 8 pintest.jl
