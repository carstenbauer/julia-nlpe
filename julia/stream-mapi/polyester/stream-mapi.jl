using LIKWID
using Printf
using Base.Threads: threadid
using Polyester

@batch for i in 1:num_threads()
    @show threadid(), LIKWID.get_processor_id()
end

# INSTRUCTIONS:
#
#	1) Stream requires a good bit of memory to run.  Adjust the
#          value of 'N' (below) to give a 'timing calibration' of 
#          at least 20 clock-ticks.  This will provide rate estimates
#          that should be good to about 5% precision.
#

const NOLIKWID = false
const VERBOSE = false
const N = 40_000_000
const NTIMES = 50
const OFFSET = 0
const HLINE = "-------------------------------------------------------------"

const a = Vector{Float64}(undef, N+OFFSET)
const b = Vector{Float64}(undef, N+OFFSET)
const c = Vector{Float64}(undef, N+OFFSET)

const avgtime = zeros(4)
const maxtime = zeros(4)
const mintime = fill(typemax(Float32), 4)

const label = ["Copy:      ", "Scale:     ", "Add:       ", "Triad:     "]

const bytes = Float64[
    2 * sizeof(Float64) * N,
    2 * sizeof(Float64) * N,
    3 * sizeof(Float64) * N,
    3 * sizeof(Float64) * N,
]

const scalar = 3.0

function main()
    times = [zeros(NTIMES) for _ in 1:4]
    NOLIKWID || Marker.init()
    # --- SETUP --- determine precision and check timing ---
    println(HLINE)
    BytesPerWord = sizeof(Float64)
    @printf("This system uses %d bytes per DOUBLE PRECISION word.\n",
	BytesPerWord)
    
    println(HLINE)
    @printf("Array size = %d, Offset = %d\n" , N, OFFSET)
    @printf("Total memory required = %.1f MB.\n",
	(3.0 * BytesPerWord) * ( N / 1048576.0))
    @printf("Each test is run %d times, but only\n", NTIMES)
    @printf("the *best* time for each is used.\n")

    # init LIKWID marker API on all "threads"
    NOLIKWID || @batch for i in 1:num_threads()
        Marker.threadinit()
    end

    @batch for j in 1:N
        a[j] = 1.0
        b[j] = 2.0
        c[j] = 0.0
    end

    println(HLINE)
    if  (quantum = checktick()) >= 1
        @printf("Your clock granularity/precision appears to be %d microseconds.\n", quantum)
    else
        @printf("Your clock granularity appears to be less than one microsecond.\n")
    end

    t_start = time()
    @batch for j in 1:N
        a[j] = 2.0 * a[j]
    end
    t = 1.0e6 * (time() - t_start)

    @printf("Each test below will take on the order of %d microseconds.\n", round(Int, t) )
    @printf("   (= %d clock ticks)\n", round(Int, t/quantum) )
    @printf("Increase the size of the arrays if this shows that\n")
    @printf("you are not getting at least 20 clock ticks per test.\n")

    println(HLINE)

    @printf("WARNING -- The above is only a rough guideline.\n")
    @printf("For best results, please be sure you know the\n")
    @printf("precision of your system timer.\n")
    println(HLINE)

    #	--- MAIN LOOP --- repeat test cases NTIMES times ---

    for k in 1:NTIMES
        times[1][k] = time()
        kernel_copy()
        times[1][k] = time() - times[1][k]

        times[2][k] = time()
        kernel_scale()
        times[2][k] = time() - times[2][k]
        
        times[3][k] = time()
        kernel_add()
        times[3][k] = time() - times[3][k]
        
        times[4][k] = time()
        kernel_triad()
        times[4][k] = time() - times[4][k]
    end

    # --- SUMMARY ---

    for k in 2:NTIMES # note -- skip first iteration
        for j in 1:4
            avgtime[j] = avgtime[j] + times[j][k];
            mintime[j] = min(mintime[j], times[j][k])
            maxtime[j] = max(maxtime[j], times[j][k])
        end
    end

    @printf("Function      Rate (MB/s)   Avg time     Min time     Max time\n")
    for j in 1:4
        avgtime[j] = avgtime[j]/float(NTIMES-1)

        @printf("%s%11.4f  %11.4f  %11.4f  %11.4f\n", label[j],
            1.0e-6 * bytes[j]/mintime[j],
            avgtime[j],
            mintime[j],
            maxtime[j])
    end
    println(HLINE)

    # --- Check Results ---
    checkSTREAMresults()
    println(HLINE)

    NOLIKWID || Marker.close()
end


function kernel_copy()
    NOLIKWID || @batch for i in 1:num_threads()
        Marker.startregion("COPY")
    end
    @batch for j in 1:N
        @inbounds c[j] = a[j]
    end
    NOLIKWID || @batch for i in 1:num_threads()
        Marker.stopregion("COPY")
    end
    return nothing
end

function kernel_scale()
    NOLIKWID || @batch for i in 1:num_threads()
        Marker.startregion("SCALE")
    end
    @batch for j in 1:N
        @inbounds b[j] = scalar*c[j]
    end
    NOLIKWID || @batch for i in 1:num_threads()
        Marker.stopregion("SCALE")
    end
    return nothing
end

function kernel_add()
    NOLIKWID || @batch for i in 1:num_threads()
        # @show threadid(), LIKWID.get_processor_id_glibc()
        Marker.startregion("ADD")
    end
    @batch for j in 1:N
        @inbounds c[j] = a[j]+b[j]
    end
    NOLIKWID || @batch for i in 1:num_threads()
        # @show threadid(), LIKWID.get_processor_id_glibc()
        Marker.stopregion("ADD")
    end
    return nothing
end

function kernel_triad()
    NOLIKWID || @batch for i in 1:num_threads()
        Marker.startregion("TRIAD")
    end
    @batch for j in 1:N
        @inbounds a[j] = b[j]+scalar*c[j]
    end
    NOLIKWID || @batch for i in 1:num_threads()
        Marker.stopregion("TRIAD")
    end
    return nothing
end



const M = 20

function checktick()
    # Collect a sequence of M unique time values from the system.
    timesfound = Vector{Float64}(undef, M)
    for i in 1:M
        t1 = time()
        while ((t2=time()) - t1) < 1.0e-6
            nothing
        end
        timesfound[i] = t1 = t2
    end

    #
    # Determine the minimum difference between these M values.
    # This result will be our estimate (in microseconds) for the
    # clock granularity.
    #
    minDelta = minimum(d for d in diff(timesfound) if d >= 0) * 1.0e6

    return round(Int, minDelta)
end

function checkSTREAMresults()
    # reproduce initialization
	aj = 1.0
	bj = 2.0
	cj = 0.0
    # a[] is modified during timing check
	aj = 2.0 * aj
    # now execute timing loop
	for k in 1:NTIMES
        cj = aj
        bj = scalar*cj
        cj = aj+bj
        aj = bj+scalar*cj
    end
	aj = aj * float(N)
	bj = bj * float(N)
	cj = cj * float(N)

	asum = 0.0
	bsum = 0.0
	csum = 0.0
	for j in 1:N
		asum += a[j]
		bsum += b[j]
		csum += c[j]
    end

    if VERBOSE
        @printf("Results Comparison: \n")
        @printf("        Expected  : %f %f %f \n",aj,bj,cj)
        @printf("        Observed  : %f %f %f \n",asum,bsum,csum)
    end

	epsilon = 1.e-8

	if abs(aj-asum)/asum > epsilon
		@printf("Failed Validation on array a[]\n")
		@printf("        Expected  : %f \n",aj)
		@printf("        Observed  : %f \n",asum)
	elseif abs(bj-bsum)/bsum > epsilon
		@printf("Failed Validation on array b[]\n")
		@printf("        Expected  : %f \n",bj)
		@printf("        Observed  : %f \n",bsum)
	elseif abs(cj-csum)/csum > epsilon
		@printf("Failed Validation on array c[]\n")
		@printf("        Expected  : %f \n",cj)
		@printf("        Observed  : %f \n",csum)
	else 
		@printf("Solution Validates\n")
    end
end

main()