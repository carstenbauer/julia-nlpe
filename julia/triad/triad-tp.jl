using LoopVectorization
using Base.Threads: @threads, nthreads

function do_triad(A,B,C,D,N,R)
    # assume 8MB outer level cache
    # CACHE_LIMIT = 2_000_000_000
    N2 = floor(Int, N/2)
    WT = @elapsed begin
        for j in 1:R
            # for i in 1:N
            #     A[i] = B[i] + C[i] * D[i]
            # end
            @avx for i in 1:N
                A[i] = B[i] + C[i] * D[i]
            end
            A[N2] < 0 && dummy(A,B,C,D)
        end
    end
    return WT
end

@noinline dummy(A,B,C,D) = nothing

function main()
    finish = false
    NT = nthreads()
    WTs = zeros(NT)
    offset = 0
    length(ARGS) > 0 || error("First argument must be <size>!")
    N = parse(Int, ARGS[1])
    R = 1

    # warmup
    do_triad(rand(5),rand(5),rand(5),rand(5),5,5)

    while !finish
        # println("iterate")
        @threads for threadid in 1:NT
            A = fill(0.0, 2*N+offset)
            B = fill(1.0, 2*N+offset)
            C = fill(2.0, 2*N+offset)
            D = fill(3.0, 2*N+offset)
            # @views do_triad(
            #     A[1+offset:end],
            #     B[1+offset:end],
            #     C[1+offset:end],
            #     D[1+offset:end],
            #     N,
            #     R,
            #     WT,
            # )
            WTs[threadid] = do_triad(A,B,C,D,N,R)
            if threadid == 1
                if WTs[threadid] ≥ 0.2
                    finish = true
                else
                    R = 2*R
                end
            end
        end
    end

    WT = sum(WTs)
    MFLOPS = 2.0*R*N*NT*NT*1.0/(WT*1.e6) # compute MFlop/sec rate
    println("Length: ",N,"    MFLOP/s: ",MFLOPS)
    return nothing
end

main()