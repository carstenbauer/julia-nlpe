icc -c timing.c
icc -c dummy.c
ifort -Ofast -xHost -qopenmp -fno-alias -fno-inline triad-tp.f90 dummy.o timing.o -o triad