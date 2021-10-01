#bash -l
module load system/CUDA
export JULIA_CUDA_USE_BINARYBUILDER=false
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
