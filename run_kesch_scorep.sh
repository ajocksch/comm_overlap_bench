#!/usr/bin/env bash
module purge
module purge
module load CMake
module load craype-haswell
module load craype-network-infiniband
module use /apps/common/UES/RHAT6/easybuild/modules/all
module use /apps/escha/UES/RH6.7/sandbox-scorep/modules/all
module load Score-P/3.1-gmvapich2-15.11_cuda_7.0_gdr

echo Modules:
module list

# Add the boost library path manually
export BOOST_LIBRARY_PATH=/apps/escha/UES/RH6.7/easybuild/software/Boost/1.49.0-gmvolf-15.11-Python-2.7.10/lib
export LD_LIBRARY_PATH=$BOOST_LIBRARY_PATH:$LD_LIBRARY_PATH

[ -z "${jobs}" ] && jobs=2
echo "Running with ${jobs} jobs (set jobs environment variable to change)"

# Setup Node configuration
tasks_socket=$jobs
if [ "$jobs" -gt "8" ]; then
    tasks_socket=8
fi
partition=debug
tasks_node=$jobs
if [ "$jobs" -gt "16" ]; then
    tasks_node=16
    partition=dev
fi
nodes=1
if [ "$jobs" -gt "16" ]; then
    let nodes=($jobs+16-1)/16
fi

# Setup GPU
[ -z "${G2G}" ] && export G2G=2
if [ "${G2G}" == 2 ]; then
    echo "Setting special settings for G2G=2"
    export MV2_USE_GPUDIRECT=1
    export MV2_CUDA_IPC=1
    export MV2_ENABLE_AFFINITY=1
    export MV2_GPUDIRECT_GDRCOPY_LIB=/apps/escha/gdrcopy/20170131/libgdrapi.so
    export MV2_USE_CUDA=1
    echo
fi

export LD_PRELOAD="$SCOREP_ROOT/lib/libscorep_init.so $SCOREP_ROOT/lib/libscorep_adapter_compiler_event.so $SCOREP_ROOT/lib/libscorep_adapter_cuda_event.so $SCOREP_ROOT/lib/libscorep_adapter_mpi_event.so $SCOREP_ROOT/lib/libscorep_measurement.so $SCOREP_ROOT/lib/libscorep_adapter_utils.so $SCOREP_ROOT/lib/libscorep_adapter_compiler_mgmt.so $SCOREP_ROOT/lib/libscorep_adapter_cuda_mgmt.so $SCOREP_ROOT/lib/libscorep_adapter_mpi_mgmt.so $SCOREP_ROOT/lib/libscorep_mpp_mpi.so $SCOREP_ROOT/lib/libscorep_online_access_mpp_mpi.so $SCOREP_ROOT/lib/libscorep_thread_mockup.so $SCOREP_ROOT/lib/libscorep_mutex_mockup.so $SCOREP_ROOT/lib/libscorep_alloc_metric.so /opt/mvapich2/gdr/2.1/cuda7.0/gnu/lib64/libmpi.so /opt/mvapich2/gdr/2.1/cuda7.0/gnu/lib64/libmpichf90.so"
export SCOREP_MPI_MAX_COMMUNICATORS=2000
export SCOREP_TOTAL_MEMORY=1G
export SCOREP_ENABLE_PROFILING=false
export SCOREP_ENABLE_TRACING=true
export SCOREP_CUDA_ENABLE=1

echo "Nodes: ${nodes}"
echo "Tasks/Node: ${tasks_node}"
echo "Tasks/Socket: ${tasks_socket}"
echo "Partition: ${partition}"

args="-n 1"

echo =======================================================================
echo = Default Benchmark
echo =======================================================================
srun --nodes=$nodes --ntasks=$jobs --ntasks-per-node=$tasks_node --ntasks-per-socket=$tasks_socket --partition=$partition --gres=gpu:$tasks_node --distribution=block:block --cpu_bind=q  build/src/comm_overlap_benchmark $args
#echo =======================================================================
#echo = No Communication
#echo =======================================================================
#srun --nodes=$nodes --ntasks=$jobs --ntasks-per-node=$tasks_node --ntasks-per-socket=$tasks_socket --partition=$partition --gres=gpu:$tasks_node --distribution=block:block --cpu_bind=q  build/src/comm_overlap_benchmark --nocomm $args
#echo =======================================================================
#echo = No Computation
#echo =======================================================================
#srun --nodes=$nodes --ntasks=$jobs --ntasks-per-node=$tasks_node --ntasks-per-socket=$tasks_socket --partition=$partition --gres=gpu:$tasks_node --distribution=block:block --cpu_bind=q  build/src/comm_overlap_benchmark --nocomp $args
#
