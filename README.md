# N-Body Simulation in C

This repository contains several versions of an N-body simulation implemented in C. The simulation models the interaction of celestial bodies under the influence of gravitational forces. Each version introduces different optimizations or parallelization methods to improve performance.

## Repository Structure

```
.
├── 0_planets_naive.c           # Naive implementation of the N-body simulation
├── 2_planets_soa.c             # Implementation using Structure of Arrays (SoA) for better memory layout and vectorization potential
├── 3_planets_float.c           # Implementation using float instead of double for data types
├── 4_planets_parallel.c        # Parallelized implementation using OpenMP
├── 5_planets_cuda.cu           # CUDA implementation for GPU acceleration
├── Makefile                    # Makefile to build different versions of the simulation
├── planets.h                   # Header file common to all implementations
```

## Building the Simulation

You can build all versions of the simulation using the provided `Makefile`. The `Makefile` supports building both the standard and the visualization-enabled versions of each implementation.

### Requirements

- GCC (for C implementations)
- Clang and CUDA (for CUDA implementation)
- OpenGL, GLEW, and GLUT (for visualization)

### Compilation Commands

To compile the programs, you can simply run:

```sh
make
```

This will create executables in the `build` directory for each version of the implementation.

## Running the Simulation

There are two main modes for running each simulation:

1. **Standard mode (without visualization):**
   
   To run the standard version of the naive implementation:

   ```sh
   ./build/0_planets_naive
   ```

2. **Visualization mode:**
   
   To run the visualization version of the naive implementation:

   ```sh
   ./build/0_planets_naive_visualize
   ```

### Example

To run the standard and visualization versions of the SoA implementation:

```sh
./build/2_planets_soa
./build/2_planets_soa_visualize
```

## Implementation Details

### 0_planets_naive.c

A straightforward implementation with a naive N-body simulation algorithm.

### 2_planets_soa.c

Uses Structure of Arrays (SoA) instead of Array of Structures (AoS) to improve memory layout, enhancing cache utilization and enabling better vectorization.

### 3_planets_float.c

Uses `float` data type instead of `double` for position and velocity coordinates, potentially improving performance with lower precision.

### 4_planets_parallel.c

Parallelized with OpenMP to take advantage of multi-core processors, thereby speeding up the computation.

### 5_planets_cuda.cu

Implemented using CUDA to leverage GPU acceleration, significantly improving computational speed for large numbers of bodies.

## Cleaning Up

To remove all the built executables, you can run:

```sh
make clean
```

## Contributions

Contributions are welcome! If you wish to contribute, feel free to open a pull request or issue.

## License

This project is licensed under the GPL License. See the `LICENSE` file for details.
