# Analysis of 2x2 matrix products in Fortran


## Matmul

### Gfortran

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


### Ifort

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


### Putting explicitely the bounds in the matrix product

```diff
$ diff main_matmul.f90 main_matmul_bounds.f90 
42c42
<     C(:,:,k) = matmul(A(:,:,k),B(:,:,k))
---
>     C(1:2,1:2,k) = matmul(A(1:2,1:2,k),B(1:2,1:2,k))
```

```
$ gfortran -O2 -mavx -g main_matmul_bounds.f90

$ ./a.out < input 
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.2766000926494598       -5.1532002091407776       -5.4000002145767212       -9.4766003787517548     
   33.010190216968532        60.566595127298228        63.467285067529787        117.63323697367491     
  0.73450700000000002      seconds
```

Doesn't help with `O2`.

```
$ gfortran -O3 -mavx -g main_matmul_bounds.f90
$ ./a.out < input 
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.2766000926494598       -5.1532002091407776       -5.4000002145767212       -9.4766003787517548     
   33.010190216968532        60.566595127298228        63.467285067529787        117.63323697367491     
  0.73902100000000004      seconds
```

Doesn't help either with `O3`


### Ifort

```
$ ifort -O2 -xAVX -g main_matmul_bounds.f90

$ ./a.out < input 
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.27660009264946       -5.15320020914078       -5.40000021457672     
  -9.47660037875175     
   33.0101902169685        60.5665951272982        63.4672850675298     
   117.633236973675     
  0.161891000000000      seconds
```

Helps a lot!  Running maqao tells us the compiler chose not to
vectorize the loop (`main_matmul_bounds.ifort.O2.maqao`).

```
$ ifort -O3 -xAVX -g main_matmul_bounds.f90

$ ./a.out < input 
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.27660009264946       -5.15320020914078       -5.40000021457672     
  -9.47660037875175     
   33.0101902169685        60.5665951272982        63.4672850675298     
   117.633236973675     
  0.161269000000000      seconds
```

Same result as `O2`.



## Using naively loops instead of matmul

### Gfortran

```
$ gfortran -O2 -mavx -g main_loop.f90

$ ./a.out < input 
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.2766000926494598       -5.1532002091407776       -5.4000002145767212       -9.4766003787517548     
   33.010190216968532        60.566595127298228        63.467285067529787        117.63323697367491     
  0.28943400000000002      seconds
```

Significantly faster than `matmul`. Maqao tells us that the loop was not
vectorized.

```
$ gfortran -O3 -mavx -g main_loop.f90

$ ./a.out < input 
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.2766000926494598       -5.1532002091407776       -5.4000002145767212       -9.4766003787517548     
   33.010190216968532        60.566595127298228        63.467285067529787        117.63323697367491     
  0.68889100000000003      seconds
```

Maqao tells us the loop was vectorized with `O2`.

### Ifort

```
$ ifort -g -O2 -xAVX main_loop.f90 

$ ./a.out < input 
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.27660009264946       -5.15320020914078       -5.40000021457672     
  -9.47660037875175     
   33.0101902169685        60.5665951272982        63.4672850675298     
   117.633236973675     
  0.642834000000000      seconds
```

Maqao tells us the loop was vectorized.

```
$ ifort -g -O3 main_loop.f90 

$ ./a.out < input 
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.27660009264946       -5.15320020914078       -5.40000021457672     
  -9.47660037875175     
   33.0101902169685        60.5665951272982        63.4672850675298     
   117.633236973675     
  0.899007000000000      seconds
```

`O3` is still worse than O2. What about `O1`?

```
$ ifort -g -O1 -xAVX main_loop.f90

$ ./a.out < input 
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.27660009264946       -5.15320020914078       -5.40000021457672     
  -9.47660037875175     
   33.0101902169685        60.5665951272982        63.4672850675298     
   117.633236973675     
  0.347958000000000      seconds
```

`O1` is almost as fast as gfortran.


## Putting explicitely the bounds in the loops

### Gfortran

```diff
$ diff main_loop.f90 main_loop_bounds.f90
40,41c40,41
<     do j=1,n2
<       do i=1,n1
---
>     do j=1,2
>       do i=1,2
44,45c44,45
<       do l=1,n2
<         do i=1,n1
---
>       do l=1,2
>         do i=1,2
```

```
$ gfortran -mavx -g -O2 main_loop_bounds.f90

$ ./a.out < input
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.2766000926494598       -5.1532002091407776       -5.4000002145767212       -9.4766003787517548     
   33.010190216968532        60.566595127298228        63.467285067529787        117.63323697367491     
  0.22000300000000000      seconds
```

```
$ gfortran -mavx -g -O3 main_loop_bounds.f90 

$ ./a.out < input 
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.2766000926494598       -5.1532002091407776       -5.4000002145767212       -9.4766003787517548     
   33.010190216968532        60.566595127298228        63.467285067529787        117.63323697367491     
  0.13356399999999999      seconds
```

Better than `O2`.

### Ifort

```
$ ifort -xAVX -g -O2 main_loop_bounds.f90 

$ ./a.out < input
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.27660009264946       -5.15320020914078       -5.40000021457672     
  -9.47660037875175     
   33.0101902169685        60.5665951272982        63.4672850675298     
   117.633236973675     
  0.172757000000000      seconds
```


```
$ ifort -xAVX -g -O3 main_loop_bounds.f90 

$ ./a.out < input 
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.27660009264946       -5.15320020914078       -5.40000021457672     
  -9.47660037875175     
   33.0101902169685        60.5665951272982        63.4672850675298     
   117.633236973675     
  0.161400000000000      seconds
```

Maqao tells us the loops were not vectorized.

## Removing the loops

### Gfortran

```
$ ./a.out < input
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.2766000926494598       -5.1532002091407776       -5.4000002145767212       -9.4766003787517548     
   33.010190216968532        60.566595127298228        63.467285067529787        117.63323697367491     
  0.12959399999999999      seconds
```

```
$ gfortran -mavx -g -O3 main_no_loops.f90

$ ./a.out < input
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.2766000926494598       -5.1532002091407776       -5.4000002145767212       -9.4766003787517548     
   33.010190216968532        60.566595127298228        63.467285067529787        117.63323697367491     
  0.12968900000000000      seconds
```

### Ifort

```
$ ifort -xAVX -g -O2 main_no_loops.f90

$ ./a.out < input
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.27660009264946       -5.15320020914078       -5.40000021457672     
  -9.47660037875175     
   33.0101902169685        60.5665951272982        63.4672850675298     
   117.633236973675     
  0.146645000000000      seconds
```

```
$ ./a.out < input
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.27660009264946       -5.15320020914078       -5.40000021457672     
  -9.47660037875175     
   33.0101902169685        60.5665951272982        63.4672850675298     
   117.633236973675     
  0.146779000000000      seconds
```

#### Asking the compiler not the vectorize the loop

```
$ diff main_no_loops.f90 main_no_loops_novector.f90 
38a39
>   !DIR$ NOVECTOR
```

```
$ ifort -xAVX -g -O2 main_no_loops_novector.f90

$ ./a.out < input
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.27660009264946       -5.15320020914078       -5.40000021457672     
  -9.47660037875175     
   33.0101902169685        60.5665951272982        63.4672850675298     
   117.633236973675     
  0.128921000000000      seconds
```

```
$ ifort -xAVX -g -O3 main_no_loops_novector.f90

$ ./a.out < input
 Enter n1, n2, n3
 n1=           2
 n2=           2
 n3=    10000000
  -2.27660009264946       -5.15320020914078       -5.40000021457672     
  -9.47660037875175     
   33.0101902169685        60.5665951272982        63.4672850675298     
   117.633236973675     
  0.128947000000000      seconds
```

