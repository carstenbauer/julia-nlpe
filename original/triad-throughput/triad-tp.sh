export OMP_NUM_THREADS=10
echo 10 | likwid-pin -c 0-9 ./triad
echo 100 | likwid-pin -c 0-9 ./triad
echo 1000 | likwid-pin -c 0-9 ./triad
echo 10000 | likwid-pin -c 0-9 ./triad
echo 100000 | likwid-pin -c 0-9 ./triad