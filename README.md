# Matmul

## Gfortran

```
$ gfortran -g -mavx -O2 main_matmul.f90 

$ ./a.out < input 
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.2766000926494598       -5.1532002091407776       -5.4000002145767212       -9.4766003787517548     
   33.010190216968532        60.566595127298228        63.467285067529787        117.63323697367491     
  0.76974200000000004      seconds

$ objdump -d a.out | grep matmul
0000000000400a80 <_gfortran_matmul_r8@plt>:
  401613:       e8 68 f4 ff ff          callq  400a80 <_gfortran_matmul_r8@plt>

```

```
$ gfortran -mavx -O3 main_matmul.f90 
$ $ ./a.out < input
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.2766000926494598       -5.1532002091407776       -5.4000002145767212       -9.4766003787517548     
   33.010190216968532        60.566595127298228        63.467285067529787        117.63323697367491     
  0.73855300000000002      seconds

$ objdump -d a.out | grep matmul
0000000000400a80 <_gfortran_matmul_r8@plt>:
  401b36:401b36e8 45 ef ff ff       ffcallq  400a80 <_gfortran_matmul_r8@plt>

```

Gfortran generates calls to ``matmul``. There is an overhead due to function calls
which is not negligible for small matrices.


## Ifort

```
$ ifort -g -O2 -xAVX main_matmul.f90 
$ ./a.out < input
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.27660009264946       -5.15320020914078       -5.40000021457672     
  -9.47660037875175     
   33.0101902169685        60.5665951272982        63.4672850675298     
   117.633236973675     
  0.601217000000000      seconds

$ objdump -d a.out | grep matmul

```

No call to ``matmul`` is seen in the executable. The compiler inlines the
`matmul` call, and there is no calling overhead. This contributes to the
speedup versus gfortran.

```
$ ifort -g -O3 -xAVX main_matmul.f90 
$ ./a.out < input
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.27660009264946       -5.15320020914078       -5.40000021457672     
  -9.47660037875175     
   33.0101902169685        60.5665951272982        63.4672850675298     
   117.633236973675     
  0.843068000000000      seconds

$ objdump -d a.out | grep matmul

```

With th `-O3` option, the execution is slower than Gfortran. An analysis with
[MAQAO](http://www.maqao.org) of the two binaries gives the following (outputs
are `main_matmul.ifort.O2.maqao` and `main_matmul.ifort.O3.maqao`).

With `O2`, one vectorized version of the innermost loop of the matrix product
is produced, and it can run in 8 cycles.

With `O3`, multiples versions are produced.  The first strategy is the same as
`O2`, the second strategy runs in 8.50 cycles but with less pressure on the
load and store units, and a third strategy runs in 16 cycles (probably unrolled
two times).
For this particular example, this is less efficient than `O2`.


