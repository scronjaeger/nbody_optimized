all: build/0_planets_naive build/0_planets_naive_visualize build/1_planets_naive build/1_planets_naive_visualize build/2_planets_soa build/2_planets_soa_visualize build/3_planets_float build/3_planets_float_visualize build/4_planets_parallel build/4_planets_parallel_visualize build/5_planets_cuda build/5_planets_cuda_visualize

COMP = gcc
NV = nvcc -ccbin clang++ -arch=sm_89
VISFLAGS = -lGL -lGLEW -lglut
OPTFLAGS = -O3 -ffast-math -march=native -ftree-vectorize -funroll-loops -fopt-info-vec
PFLAGS = -fopenmp

build:
	mkdir -p build

build/0_planets_naive: 0_planets_naive.c planets.h | build
	$(COMP) $< -lm -o $@
build/0_planets_naive_visualize: 0_planets_naive.c planets.h | build
	$(COMP) $< -DVISUALIZE $(VISFLAGS) -lm -o $@

build/1_planets_naive: 0_planets_naive.c planets.h | build
	$(COMP) $< $(OPTFLAGS) -lm -o $@
build/1_planets_naive_visualize: 0_planets_naive.c planets.h | build
	$(COMP) $< -DVISUALIZE $(OPTFLAGS) $(VISFLAGS) -lm -o $@

build/2_planets_soa: 2_planets_soa.c planets.h | build
	$(COMP) $< $(OPTFLAGS) -lm -o $@
build/2_planets_soa_visualize: 2_planets_soa.c planets.h | build
	$(COMP) $< -DVISUALIZE $(OPTFLAGS) $(VISFLAGS) -lm -o $@

build/3_planets_float: 3_planets_float.c planets.h | build
	$(COMP) $< $(OPTFLAGS) -lm -o $@
build/3_planets_float_visualize: 3_planets_float.c planets.h | build
	$(COMP) $< -DVISUALIZE $(OPTFLAGS) $(VISFLAGS) -lm -o $@

build/4_planets_parallel: 4_planets_parallel.c planets.h | build
	$(COMP) $< $(OPTFLAGS) $(PFLAGS) -lm -o $@
build/4_planets_parallel_visualize: 4_planets_parallel.c planets.h | build
	$(COMP) $< -DVISUALIZE $(OPTFLAGS) $(PFLAGS) $(VISFLAGS) -lm -o $@

build/5_planets_cuda: 5_planets_cuda.cu planets.h | build
	$(NV) $< -o $@
build/5_planets_cuda_visualize: 5_planets_cuda.cu planets.h | build
	$(NV) $< -DVISUALIZE $(VISFLAGS) -o $@

clean:
	rm -f build/*

.PHONY: all clean
