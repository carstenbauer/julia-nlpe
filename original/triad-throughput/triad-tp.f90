!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! triad.f90 benchmark demo code
! designed for throughput mode (no work sharing)
! ifort options:
! -Ofast -xHost -fno-alias -fno-inline -openmp[_stubs]
! G. Hager, 2010
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
program triad
!$  use omp_lib

  implicit none

  double precision, dimension(:),allocatable :: A,B,C,D
! Intel-specific: 16-byte alignment of allocatables
!DEC$ ATTRIBUTES ALIGN: 64 :: A
!DEC$ ATTRIBUTES ALIGN: 64 :: B
!DEC$ ATTRIBUTES ALIGN: 64 :: C
!DEC$ ATTRIBUTES ALIGN: 64 :: D
  double precision :: MFLOPS,WT
  integer :: N,i,NT
  integer(kind=8) :: R
  logical :: finish
  integer, parameter :: offset = 0

  finish = .false.
  NT = 1
  WT = 0.d0
  read *,N

!$OMP PARALLEL PRIVATE(A,B,C,D,i) REDUCTION(+:WT)
  allocate(A(1:2*N+offset),B(1:2*N+offset),C(1:2*N+offset),D(1:2*N+offset))

  do i=1,2*N+offset
     A(i) = 0.d0; B(i) = 1.d0
     C(i) = 2.d0; D(i) = 3.d0
  enddo

!$OMP SINGLE
  R = 1
!$  NT = omp_get_num_threads()
!$OMP END SINGLE

  ! warm up
  call do_triad(A(1+offset),B(1+offset),C(1+offset),D(1+offset),N,R,WT)

  do
!$OMP BARRIER
     call do_triad(A(1+offset),B(1+offset),C(1+offset),D(1+offset),N,R,WT)
!$OMP BARRIER
     ! exit if duration was above some limit
!$OMP SINGLE
     if(WT.ge.0.2d0) then 
        finish=.true.
     else
        R = R*2
     endif
!$OMP END SINGLE
     if(finish.eqv..true.) then
        deallocate(A,B,C,D)
        exit
     endif
     ! else do it again with doubled repeat count
  enddo

!  deallocate(A,B,C,D)

!$OMP END PARALLEL


  MFLOPS = 2.d0*dble(R)*dble(N)*NT*NT*1.d0/(WT*1.d6) ! compute MFlop/sec rate
  print *, "Length: ",N,"    MFLOP/s: ",MFLOPS
end program triad

subroutine do_triad(A,B,C,D,N,R,WT)
  use omp_lib
  implicit none
  integer, intent(in) :: N
  integer(kind=8), intent(in) :: R
  double precision, dimension(N), intent(inout) :: A
  double precision, dimension(N), intent(in) :: B,C,D
  double precision, intent(out) :: WT
  double precision :: S,E
  integer :: N2
  ! assume 8MB outer level cache
  integer, parameter :: CACHE_LIMIT=2000000000
  integer :: i
  integer(kind=8) :: j
  double precision, parameter :: cc=1.0000000001d0

  N2 = N/2

!  call get_walltime(S)

  S = omp_get_wtime()

  if(N.le.CACHE_LIMIT) then
     do j=1,R
! Intel-specific: Assume aligned moves
!DEC$ vector aligned
!DEC$ vector temporal
!DEC$ unroll(8)
        do i=1,N
           A(i) = B(i) + C(i) * D(i)
        enddo
        if(A(N2).lt.0) call dummy(A,B,C,D)
     enddo
  else
     do j=1,R
! Intel-specific: Assume aligned moves
!DEC$ vector aligned
!DEC$ vector nontemporal
!DEC$ unroll(8)
        do i=1,N
           A(i) = B(i) + C(i) * D(i)
        enddo
        if(A(N2).lt.0) call dummy(A,B,C,D)
     enddo
  endif
  
!  call get_walltime(E)
 
  E = omp_get_wtime()
 
  WT = E-S

end subroutine do_triad

