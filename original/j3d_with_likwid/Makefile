#
#	Makefile for Intel compiler
#
BHOME	=$(PWD)
#
F90	= ifort
CC	= icc
#
#
COMP	= -qopenmp
FOMP	= -qopenmp
COPTS	=  -Ofast -xHost  -fno-inline -fno-alias
HIOPT	=  -Ofast -xHost  -fno-inline -fno-alias
FLONG	= -132
#
#
NOLINK= -c
#

J3D.exe: j3d.o timing.o dummy.o
	$(CC) $(COMP) -o J3D.exe j3d.o timing.o dummy.o $(LIKWID_LIB) -llikwid

.c.o:
	$(CC) $(COPTS) $(LIKWID_INCLUDE) -DLIKWID_PERFMON  $(COMP) $(NOLINK) $<

.F.o:
	$(F90) $(HIOPT) $(FOMP) $(NOLINK) $<

clean:
	rm -f *.o *.exe

