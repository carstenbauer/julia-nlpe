using Polyester, LIKWID
using BenchmarkTools

# @batch per=core for i in 1:num_threads()
#     @show Threads.threadid(), LIKWID.get_processor_id()
# end

@batch per=core for i in 1:2*num_threads()
    @show i, Threads.threadid(), LIKWID.get_processor_id()
end

function f(x)
    @batch per=core for i in 1:length(x)
        # @show LIKWID.get_processor_id()
        x[i] = x[i] + x[i]
    end
    return nothing
end

function f_serial(x)
    for i in 1:length(x)
        # @show LIKWID.get_processor_id()
        x[i] = x[i] + x[i]
    end
    return nothing
end

# x = rand(100_000)
# @btime f(x)
# @btime f_serial(x)