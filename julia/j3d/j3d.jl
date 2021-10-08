using LIKWID
using Base.Threads
using Printf

const oos = 1.0/6.0

function jacobi_line(d, s, top, bottom, front, back, n)
    #pragma vector nontemporal
    for i in 2:n-1
        d[i] = oos*(s[i-1]+s[i+1]+top[i]+bottom[i]+front[i]+back[i])
    end
end

@noinline function dummy(a, b)
    return nothing
end

function main()
    Marker.init()

    length(ARGS) < 1 && error("Expected <size> as input argument!")

    size = parse(Int, ARGS[1])
    phi = [
        rand(size*size*size),
        rand(size*size*size)
    ]

    t1=1
    t2=2

    iter=1
    runtime=0.0
    while runtime<0.5
        # time measurement
        wct_start = time()
        for n in 1:iter
            @threads for i in 1:nthreads()
                Marker.startregion("Sweep")
            end
            @threads for i in 2:size-1
                for j in 2:size-1
                    ofs = (i-1)*size*size + (j-1)*size
                    @views jacobi_line(
                        phi[t2][ofs:end],
                        phi[t1][ofs:end],
                        phi[t1][ofs+size:end],
                        phi[t1][ofs-size:end],
			            phi[t1][ofs+size*size:end],
                        phi[t1][ofs-size*size:end],
                        size
                    )
                end
            end
            @threads for i in 1:nthreads()
                Marker.stopregion("Sweep")
            end
            dummy(phi[1], phi[2])
            t1, t2 = t2, t1
        end
        wct_end = time()
        runtime = wct_end - wct_start
        iter *= 2
    end

    iter /= 2

    @printf("size: %d  time: %lf  iter: %d  MLUP/s: %lf\n",size,runtime,iter,iter*(size-2)*(size-2)*(size-2)/runtime/1000000.0)

    Marker.close()
end

main()