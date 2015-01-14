program test
  call run
end

subroutine run
  implicit none
  double precision, allocatable  :: A(:,:,:)
  double precision, allocatable  :: B(:,:,:)
  double precision, allocatable  :: C(:,:,:)
  
  integer                        :: n1,n2,n3
  integer                        :: i,j,k,l
  integer*8                      :: t0,t1, count_rate, count_max

  print *,  'Enter n1, n2, n3'
  read(*,*) n1,n2,n3

  print *,  'n1=', n1
  print *,  'n2=', n2
  print *,  'n3=', n3

  allocate (A(n1,n2,n3))
  allocate (B(n1,n2,n3))
  allocate (C(n1,n2,n3))

  do j=1,n2
    do i=1,n1
      A(i,j,1) = dble(i-j+1)*0.1234 - dble(i+j)**2 * 0.6
    enddo
  enddo
  print *,  A(:,:,1)

  do k=2,n3
    A(:,:,k) = A(:,:,1)
  enddo
  B = A

  call system_clock(t0, count_rate, count_max)
  !DIR$ NOVECTOR
  do k=1,n3
    C(1,1,k) = A(1,1,k)*B(1,1,k) + A(1,2,k)*B(2,1,k)
    C(2,1,k) = A(2,1,k)*B(1,1,k) + A(2,2,k)*B(2,1,k)
    C(1,2,k) = A(1,1,k)*B(1,2,k) + A(1,2,k)*B(2,2,k)
    C(2,2,k) = A(2,1,k)*B(1,2,k) + A(2,2,k)*B(2,2,k)
  enddo
  call system_clock(t1, count_rate, count_max)
  print *,  C(:,:,n3)
  print *,  dble(t1-t0)/dble(count_rate), 'seconds'
  deallocate(A,B,C)
end

