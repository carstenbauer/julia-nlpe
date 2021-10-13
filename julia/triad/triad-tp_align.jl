# using LoopVectorization
using Base.Threads: @threads, nthreads
# using SIMD
# using VectorizationBase: assume

# posix_memalign taken from
# https://discourse.julialang.org/t/julia-alignas-is-there-a-way-to-specify-the-alignment-of-julia-objects-in-memory/57501/2
function alignedvec(::Type{T}, n::Integer, alignment::Integer=sizeof(Int)) where {T}
    @static if Sys.iswindows()
        return Array{T}(undef, n)
    else
        ispow2(alignment) || throw(ArgumentError("$alignment is not a power of 2"))
        alignment ≥ sizeof(Int) || throw(ArgumentError("$alignment is not a multiple of $(sizeof(Int))"))
        isbitstype(T) || throw(ArgumentError("$T is not a bitstype"))
        p = Ref{Ptr{T}}()
        err = ccall(:posix_memalign, Cint, (Ref{Ptr{T}}, Csize_t, Csize_t), p, alignment, n*sizeof(T))
        iszero(err) || throw(OutOfMemoryError())
        return unsafe_wrap(Array, p[], n, own=true)
    end
end

function do_triad(A,B,C,D,N,R)
    # assume 8MB outer level cache
    # CACHE_LIMIT = 2_000_000_000
    N2 = floor(Int, N/2)
    WT = @elapsed begin
        for j in 1:R
            # for i in 1:N
            #     A[i] = B[i] + C[i] * D[i]
            # end
            # assume((reinterpret(UInt, pointer(x)) % (64 % UInt)) == zero(UInt))
            # assume((reinterpret(UInt, pointer(y)) % (64 % UInt)) == zero(UInt))
            # @avx for i in 1:N
            @inbounds @simd for i in 1:N
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
            A = alignedvec(Float64, 2*N+offset, 64)
            B = alignedvec(Float64, 2*N+offset, 64)
            C = alignedvec(Float64, 2*N+offset, 64)
            D = alignedvec(Float64, 2*N+offset, 64)
            A .= 0.0
            B .= 1.0
            C .= 2.0
            D .= 3.0
            # A = fill(0.0, 2*N+offset)
            # B = fill(1.0, 2*N+offset)
            # C = fill(2.0, 2*N+offset)
            # D = fill(3.0, 2*N+offset)
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