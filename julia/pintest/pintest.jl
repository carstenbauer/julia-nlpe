using LIKWID
using Base.Threads
# using DataFrames

threadids = zeros(Int, nthreads())
procids = zeros(Int, nthreads())
procids_glibc = zeros(Int, nthreads())
@threads for i in 1:nthreads()
    threadids[i] = threadid()-1
    procids[i] = LIKWID.get_processor_id()
    procids_glibc[i] = LIKWID.get_processor_id_glibc()
end

# df = DataFrame(thread=threadids, proc=procids, glibc=procids_glibc)
# sort!(df, :thread)
# display(df)
println(); flush(stdout)
@show sort!(procids)
println(); flush(stdout)