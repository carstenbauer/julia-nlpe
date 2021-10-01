using STREAMBenchmark

println("+write_allocate"); flush(stdout);
benchmark(write_allocate=true)

println("-write_allocate"); flush(stdout);
benchmark(write_allocate=false)

println("vector_length_dependence"); flush(stdout);
STREAMBenchmark.vector_length_dependence()