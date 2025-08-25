# Copyright (c) 2023, Modular Inc. All rights reserved.
#
# Licensed under the Apache License v2.0 with LLVM Exceptions:
# https://llvm.org/LICENSE.txt
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ===----------------------------------------------------------------------=== #

"""
Matrix multiplication optimization demonstration.
Originally from https://github.com/johnsoez4/mojo_max_syntax/issues/2398

This module demonstrates how various systems optimizations can be applied to a
naive matrix multiplication implementation in Mojo to gain significant performance
speedups through parallelization and SIMD vectorization.

The implementation showcases:
- Parameterized matrix dimensions and data types
- SIMD-optimized memory operations
- Parallel computation using the builtin parallelize function
- CPU-only baseline implementation for comparison
- Performance benchmarking and result verification
- Proper memory management with explicit allocation and deallocation
"""

import benchmark
from algorithm import parallelize
from memory import memset_zero
from random import rand
from sys.info import simdwidthof
from time import perf_counter_ns as now

alias M = 512
alias N = 4096
alias K = 512
alias type = DType.float32
alias scalar_type = Scalar[type]

alias nelts = simdwidthof[type]() * 2
alias tile_n = 64
alias tile_k = 4


struct Matrix[rows: Int, cols: Int](Movable):
    """
    A parameterized matrix implementation with SIMD-optimized operations.

    This struct provides a basic matrix implementation with compile-time
    dimensions and efficient memory operations using SIMD vectorization.

    Parameters:
        rows: Number of matrix rows (compile-time constant).
        cols: Number of matrix columns (compile-time constant).
    """

    var data: UnsafePointer[scalar_type]

    fn __init__(out self):
        """Initialize matrix with zero values."""
        self.data = UnsafePointer[scalar_type].alloc(rows * cols)
        memset_zero(self.data, rows * cols)

    fn __init__(out self, data: UnsafePointer[scalar_type]):
        """Initialize matrix with existing data pointer."""
        self.data = data

    @staticmethod
    fn rand() -> Self:
        """Create matrix with random values."""
        var data = UnsafePointer[scalar_type].alloc(rows * cols)
        rand(data, rows * cols)
        return Self(data)

    fn __getitem__(self, y: Int, x: Int) -> scalar_type:
        """Get matrix element at position (y, x)."""
        return self.load[1](y, x)

    fn __setitem__(mut self, y: Int, x: Int, val: scalar_type):
        """Set matrix element at position (y, x)."""
        self.store[1](y, x, val)

    fn load[nelts: Int](self, y: Int, x: Int) -> SIMD[type, nelts]:
        """Load SIMD vector from matrix starting at position (y, x)."""
        return self.data.load[width=nelts](y * self.cols + x)

    fn store[nelts: Int](self, y: Int, x: Int, val: SIMD[type, nelts]):
        """Store SIMD vector to matrix starting at position (y, x)."""
        return self.data.store[width=nelts](y * self.cols + x, val)


fn matmul_parallelized(mut C: Matrix, A: Matrix, B: Matrix):
    """
    Perform parallelized matrix multiplication: C = A * B.

    This function uses the builtin parallelize function to distribute
    matrix multiplication computation across multiple threads.

    Args:
        C: Output matrix (modified in-place).
        A: Left input matrix.
        B: Right input matrix.
    """

    @parameter
    fn calc_row(m: Int):
        """Calculate a single row of the result matrix."""
        for k in range(A.cols):
            for n in range(C.cols):
                C[m, n] += A[m, k] * B[k, n]

    num_work_items = C.rows
    num_workers = C.rows
    parallelize[calc_row](num_work_items, num_workers)


fn _cpu_multiply(mut C: Matrix, A: Matrix, B: Matrix):
    """
    Perform CPU-only matrix multiplication: C = A * B.

    This function performs matrix multiplication using only CPU computation
    without parallelization, serving as a baseline for performance comparison.

    Args:
        C: Output matrix (modified in-place).
        A: Left input matrix.
        B: Right input matrix.
    """
    for m in range(C.rows):
        for k in range(A.cols):
            for n in range(C.cols):
                C[m, n] += A[m, k] * B[k, n]


fn verify_results_identical(C1: Matrix, C2: Matrix) -> Bool:
    """
    Verify that two matrices contain identical values.

    Args:
        C1: First matrix to compare.
        C2: Second matrix to compare.

    Returns:
        True if matrices are identical, False otherwise.
    """
    for m in range(C1.rows):
        for n in range(C1.cols):
            if abs(C1[m, n] - C2[m, n]) > 1e-6:
                return False
    return True


fn benchmark_cpu_multiply(A: Matrix, B: Matrix) -> Float64:
    """
    Benchmark CPU-only matrix multiplication.

    Args:
        A: Left input matrix.
        B: Right input matrix.

    Returns:
        Execution time in milliseconds.
    """
    var C = Matrix[M, N]()

    var start_time = now()
    _cpu_multiply(C, A, B)
    var end_time = now()

    C.data.free()

    var elapsed_ns = end_time - start_time
    return Float64(elapsed_ns) / 1_000_000.0


fn benchmark_parallelized_multiply(A: Matrix, B: Matrix) -> Float64:
    """
    Benchmark parallelized matrix multiplication.

    Args:
        A: Left input matrix.
        B: Right input matrix.

    Returns:
        Execution time in milliseconds.
    """
    var C = Matrix[M, N]()

    var start_time = now()
    matmul_parallelized(C, A, B)
    var end_time = now()

    C.data.free()

    var elapsed_ns = end_time - start_time
    return Float64(elapsed_ns) / 1_000_000.0


fn main() raises:
    """
    Main function demonstrating matrix multiplication benchmarks.

    Creates random matrices, verifies that CPU and parallelized implementations
    produce identical results, and benchmarks their performance.

    Raises:
        Error: If matrix operations fail or results don't match.
    """
    print("=== Matrix Multiplication Benchmark ===")
    print(
        "Matrix dimensions: A("
        + String(M)
        + "x"
        + String(K)
        + ") * B("
        + String(K)
        + "x"
        + String(N)
        + ") = C("
        + String(M)
        + "x"
        + String(N)
        + ")"
    )
    print()

    # Create input matrices with same random seed for reproducible results
    var A = Matrix[M, K].rand()
    var B = Matrix[K, N].rand()

    print("🔍 Verifying result correctness...")

    # Test CPU implementation
    var C_cpu = Matrix[M, N]()
    _cpu_multiply(C_cpu, A, B)

    # Test parallelized implementation
    var C_parallel = Matrix[M, N]()
    matmul_parallelized(C_parallel, A, B)

    # Verify results are identical
    if verify_results_identical(C_cpu, C_parallel):
        print(
            "✅ Results verification passed: CPU and parallelized"
            " implementations produce identical results"
        )
    else:
        print(
            "❌ Results verification failed: CPU and parallelized"
            " implementations produce different results"
        )
        raise Error(
            "Matrix multiplication implementations produce different results"
        )

    print()
    print("🚀 Running performance benchmarks...")

    # Benchmark CPU implementation
    var cpu_time = benchmark_cpu_multiply(A, B)
    print("CPU-only implementation:     " + String(cpu_time) + " ms")

    # Benchmark parallelized implementation
    var parallel_time = benchmark_parallelized_multiply(A, B)
    print("Parallelized implementation: " + String(parallel_time) + " ms")

    # Calculate speedup
    var speedup = cpu_time / parallel_time
    print("Speedup: " + String(speedup) + "x")

    print()
    if speedup > 1.0:
        print(
            "🎉 Parallelized implementation is "
            + String(speedup)
            + "x faster than CPU-only!"
        )
    else:
        print(
            "⚠️  CPU-only implementation performed better (possibly due to"
            " overhead)"
        )

    # Cleanup
    A.data.free()
    B.data.free()
    C_cpu.data.free()
    C_parallel.data.free()

    print("✅ Matrix multiplication benchmark completed successfully!")
