# SingleDispatchArrays.jl
Fast single dispatch for an array of non-homogeneous elements.

See discussions at [Union splitting vs C++](https://discourse.julialang.org/t/union-splitting-vs-c/61772/20). Because dynamic dispatch is a complicated search in Julia, where it is only a function pointer in C++, Julia has very bad performance with non-homogeneous array relative to C++. This performance drawback can be addressed by either manual or automatic union splitting or "switch-case", equivalently. SingleDispatchArrays.jl implements union splitting with generated function, with manual bookkeeping of possible subtypes.

Benchmark on x86 cloud server:

```
> cd benchmark
> g++ -o lines -O3 -march=native -W -Wall  lines.cpp && ./lines
n = 1000000 
dynamic dispatch : 0.012808 us per iteration (12.808000 ms total) [500006.610053]

> julia --project=.. lines.jl 
result = 500261.127245642
 with runtime dispatch:   153.494 ms (2000000 allocations: 30.52 MiB)
 with splitting:   8.007 ms (0 allocations: 0 bytes)
 with SingleDispatchArrays.jl:   9.075 ms (2 allocations: 32 bytes)
```

The result is common among my x86 machines, but on my Raspberry Pi 4B, the result is 10ms for splitting, 20ms for SingleDispatchArrays.jl and C++.
