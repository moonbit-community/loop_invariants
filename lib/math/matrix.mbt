// ============================================================================
// MATRIX EXPONENTIATION EXAMPLES WITH LOOP INVARIANTS
// ============================================================================
//
// Matrix exponentiation is a powerful technique for computing linear recurrences
// in O(log n) time. The key insight is that many recurrence relations can be
// expressed as matrix multiplication, and matrix powers can be computed efficiently
// using the same binary exponentiation technique used for scalar powers.
//
// The invariant reasoning here is particularly beautiful because it connects:
// 1. The algebraic properties of matrix multiplication (associativity)
// 2. Binary representation of exponents
// 3. The correspondence between matrix powers and recurrence solutions

// ============================================================================
// 2x2 MATRIX OPERATIONS
// ============================================================================
//
// A 2x2 matrix is represented as [a, b, c, d] meaning:
//   | a  b |
//   | c  d |
//
// This is sufficient for Fibonacci and many other two-term recurrences.

///|
/// Matrix multiplication for 2x2 matrices.
///
/// MATHEMATICAL FOUNDATION:
/// Matrix multiplication is defined as:
///   (AB)[i,j] = Σ_k A[i,k] * B[k,j]
///
/// For 2x2 matrices:
///   | a  b |   | e  f |   | ae+bg  af+bh |
///   | c  d | × | g  h | = | ce+dg  cf+dh |
///
/// KEY PROPERTIES:
/// 1. Associativity: (AB)C = A(BC) - enables binary exponentiation
/// 2. Identity: I·A = A·I = A where I = [[1,0],[0,1]]
/// 3. NOT commutative: AB ≠ BA in general
fn matrix_mult_2x2(
  a : (Int64, Int64, Int64, Int64),
  b : (Int64, Int64, Int64, Int64),
  modulo : Int64,
) -> (Int64, Int64, Int64, Int64) {
  let (a11, a12, a21, a22) = a
  let (b11, b12, b21, b22) = b
  (
    (a11 * b11 + a12 * b21) % modulo,
    (a11 * b12 + a12 * b22) % modulo,
    (a21 * b11 + a22 * b21) % modulo,
    (a21 * b12 + a22 * b22) % modulo,
  )
}

///|
/// Matrix exponentiation using binary exponentiation.
///
/// ALGORITHM INSIGHT:
/// We compute M^n using the binary representation of n.
/// If n = Σ b_i · 2^i, then M^n = Π M^(2^i) for all i where b_i = 1.
///
/// INVARIANT (m, r, p):
///   m^original_p = r · m^p
///
/// REASONING:
/// - Initially: m^p = I · m^p ✓
/// - When p is odd: m^p = m · m^(p-1), so r := r·m maintains m^orig_p = (r·m) · m^(p-1) = r · m^p
/// - When p is even: m^p = (m²)^(p/2), so m := m², p := p/2 maintains r · (m²)^(p/2) = r · m^p
/// - At termination (p=0): m^orig_p = r · m^0 = r · I = r
///
/// COMPLEXITY: O(log n) matrix multiplications = O(8 log n) = O(log n) scalar operations
#warnings("+missing_invariant+missing_reasoning")
fn matrix_pow_2x2(
  m : (Int64, Int64, Int64, Int64),
  p : Int64,
  modulo : Int64,
) -> (Int64, Int64, Int64, Int64) {
  let identity : (Int64, Int64, Int64, Int64) = (1L, 0L, 0L, 1L)
  for matrix = m, result = identity, power = p {
    if power <= 0L {
      break result
    } else if power % 2L == 1L {
      continue matrix_mult_2x2(matrix, matrix, modulo),
        matrix_mult_2x2(result, matrix, modulo),
        power / 2L
    } else {
      continue matrix_mult_2x2(matrix, matrix, modulo), result, power / 2L
    }
  } where {
    invariant: power >= 0L,
    reasoning: (
      #|LOOP INVARIANT: M^original_p ≡ result · matrix^power (mod modulo)
      #|
      #|This is the standard binary exponentiation invariant applied to matrices.
      #|
      #|INITIALIZATION (power = p):
      #|  M^p = I · M^p = result · matrix^power ✓
      #|
      #|MAINTENANCE:
      #|  Case 1 (power is odd):
      #|    Before: M^orig_p = result · matrix^power
      #|    After: M^orig_p = (result·matrix) · matrix^(power-1)
      #|                    = result · matrix · matrix^(power-1)
      #|                    = result · matrix^power ✓
      #|
      #|  Case 2 (power is even):
      #|    Before: M^orig_p = result · matrix^power
      #|    After: M^orig_p = result · (matrix²)^(power/2)
      #|                    = result · matrix^power ✓
      #|
      #|TERMINATION (power = 0):
      #|  M^orig_p = result · matrix^0 = result · I = result
      #|
      #|The beauty of matrix exponentiation is that associativity of matrix
      #|multiplication makes this work exactly like scalar exponentiation!
    ),
  }
}

// ============================================================================
// FIBONACCI VIA MATRIX EXPONENTIATION
// ============================================================================
//
// THE FIBONACCI MATRIX IDENTITY:
//
//   | F(n+1) |   | 1  1 |^n   | 1 |
//   | F(n)   | = | 1  0 |   · | 0 |
//
// More directly:
//   | 1  1 |^n   | F(n+1)  F(n)   |
//   | 1  0 |   = | F(n)    F(n-1) |
//
// PROOF BY INDUCTION:
// Base case (n=1): [[1,1],[1,0]]^1 = [[F(2),F(1)],[F(1),F(0)]] = [[1,1],[1,0]] ✓
//
// Inductive step: Assume [[1,1],[1,0]]^n = [[F(n+1),F(n)],[F(n),F(n-1)]]
//   [[1,1],[1,0]]^(n+1) = [[1,1],[1,0]]^n · [[1,1],[1,0]]
//                       = [[F(n+1),F(n)],[F(n),F(n-1)]] · [[1,1],[1,0]]
//                       = [[F(n+1)+F(n), F(n+1)],[F(n)+F(n-1), F(n)]]
//                       = [[F(n+2), F(n+1)],[F(n+1), F(n)]] ✓

///|
/// Compute F(n) mod m using matrix exponentiation.
/// Time complexity: O(log n)
/// Space complexity: O(1)
///
/// CORRECTNESS:
/// By the Fibonacci matrix identity, [[1,1],[1,0]]^n[0,1] = F(n).
/// Matrix exponentiation preserves this relationship at each step.
fn fibonacci_matrix(n : Int64, modulo : Int64) -> Int64 {
  if n <= 0L {
    return 0L
  }
  if n == 1L {
    return 1L % modulo
  }
  let fib_matrix : (Int64, Int64, Int64, Int64) = (1L, 1L, 1L, 0L)
  let result = matrix_pow_2x2(fib_matrix, n, modulo)
  let (_, f_n, _, _) = result
  f_n
}

///|
test "fibonacci_matrix" {
  let modulo = 1000000007L
  // F(0)=0, F(1)=1, F(2)=1, F(3)=2, F(4)=3, F(5)=5, F(6)=8, F(7)=13, F(8)=21
  assert_eq(fibonacci_matrix(0L, modulo), 0L)
  assert_eq(fibonacci_matrix(1L, modulo), 1L)
  assert_eq(fibonacci_matrix(2L, modulo), 1L)
  assert_eq(fibonacci_matrix(5L, modulo), 5L)
  assert_eq(fibonacci_matrix(10L, modulo), 55L)
  assert_eq(fibonacci_matrix(20L, modulo), 6765L)
  // F(50) = 12586269025
  assert_eq(fibonacci_matrix(50L, modulo), 12586269025L % modulo)
}

// ============================================================================
// TRIBONACCI VIA 3x3 MATRIX EXPONENTIATION
// ============================================================================
//
// T(n) = T(n-1) + T(n-2) + T(n-3), with T(0)=0, T(1)=1, T(2)=1
//
// THE TRIBONACCI MATRIX:
//   | T(n+2) |   | 1  1  1 |^n   | 1 |
//   | T(n+1) | = | 1  0  0 |   · | 1 |
//   | T(n)   |   | 0  1  0 |     | 0 |
//
// This extends naturally from the Fibonacci case to any k-term recurrence.

///|
#warnings("+missing_invariant+missing_reasoning")
fn matrix_mult_3x3(
  a : Array[Int64],
  b : Array[Int64],
  modulo : Int64,
) -> Array[Int64] {
  let result : Array[Int64] = Array::make(9, 0L)
  for i = 0 {
    if i >= 3 {
      break
    } else {
      for j = 0 {
        if j >= 3 {
          break
        } else {
          let sum = for k = 0, acc = 0L {
            if k >= 3 {
              break acc
            } else {
              let new_acc = (acc + a[i * 3 + k] * b[k * 3 + j]) % modulo
              continue k + 1, new_acc
            }
          } where {
            invariant: k >= 0 && k <= 3,
            reasoning: (
              #|INVARIANT (Dot product):
              #|acc = Σ_{t < k} a[i,t] * b[t,j] (mod modulo).
              #|After k reaches 3, acc is the full inner product for cell (i,j).
              #|MAINTENANCE:
              #|Add the term a[i,k] * b[k,j] to acc, extending the partial sum.
              #|TERMINATION:
              #|At k = 3, all three terms are included, so acc is complete.
            ),
          }
          result[i * 3 + j] = sum
          continue j + 1
        }
      } where {
        invariant: j >= 0 && j <= 3,
        reasoning: (
          #|INVARIANT (Row fill):
          #|After processing columns [0..j), result[i,*] is correct for those
          #|columns. Each column j computes the dot product of row i and
          #|column j of the right matrix.
          #|MAINTENANCE:
          #|Compute column j and store it in result, extending the row prefix.
          #|TERMINATION:
          #|At j = 3, the entire row i is filled.
        ),
      }
      continue i + 1
    }
  } where {
    invariant: i >= 0 && i <= 3,
    reasoning: (
      #|INVARIANT (Matrix fill):
      #|After processing rows [0..i), all entries in those rows are computed.
      #|This is the standard triple-loop matrix multiplication.
      #|MAINTENANCE:
      #|Finish row i, then advance to i+1 with all prior rows fixed.
      #|TERMINATION:
      #|At i = 3, all rows are complete.
    ),
  }
  result
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn matrix_pow_3x3(m : Array[Int64], p : Int64, modulo : Int64) -> Array[Int64] {
  let identity : Array[Int64] = [1L, 0L, 0L, 0L, 1L, 0L, 0L, 0L, 1L]
  for matrix = m, result = identity, power = p {
    if power <= 0L {
      break result
    } else if power % 2L == 1L {
      continue matrix_mult_3x3(matrix, matrix, modulo),
        matrix_mult_3x3(result, matrix, modulo),
        power / 2L
    } else {
      continue matrix_mult_3x3(matrix, matrix, modulo), result, power / 2L
    }
  } where {
    invariant: power >= 0L,
    reasoning: (
      #|INVARIANT: M^original_p ≡ result · matrix^power (mod modulo).
      #|
      #|This is the same binary exponentiation invariant as the 2x2 case.
      #|Associativity of 3x3 multiplication ensures regrouping is valid,
      #|so halving power and squaring matrix preserves the equation.
      #|MAINTENANCE:
      #|If power is odd, move one factor of matrix into result and square
      #|matrix; if even, only square matrix. The invariant is preserved.
      #|TERMINATION:
      #|At power = 0, result equals M^original_p.
    ),
  }
}

///|
/// Compute T(n) mod m using 3x3 matrix exponentiation.
///
/// MATRIX IDENTITY:
/// [T(n+2), T(n+1), T(n)]^T = M^n · [T(2), T(1), T(0)]^T = M^n · [1, 1, 0]^T
///
/// So T(n) = M^n[2,0] · T(2) + M^n[2,1] · T(1) + M^n[2,2] · T(0)
///         = M^n[2,0] + M^n[2,1]  (since T(2)=1, T(1)=1, T(0)=0)
fn tribonacci_matrix(n : Int64, modulo : Int64) -> Int64 {
  if n == 0L {
    return 0L
  }
  if n <= 2L {
    return 1L % modulo
  }
  let trib_matrix : Array[Int64] = [1L, 1L, 1L, 1L, 0L, 0L, 0L, 1L, 0L]
  let result = matrix_pow_3x3(trib_matrix, n, modulo)
  // T(n) = M^n[2,0] + M^n[2,1] = result[6] + result[7]
  (result[6] + result[7]) % modulo
}

///|
test "tribonacci_matrix" {
  let modulo = 1000000007L
  // T(0)=0, T(1)=1, T(2)=1, T(3)=2, T(4)=4, T(5)=7, T(6)=13, T(7)=24
  assert_eq(tribonacci_matrix(0L, modulo), 0L)
  assert_eq(tribonacci_matrix(1L, modulo), 1L)
  assert_eq(tribonacci_matrix(2L, modulo), 1L)
  assert_eq(tribonacci_matrix(3L, modulo), 2L)
  assert_eq(tribonacci_matrix(4L, modulo), 4L)
  assert_eq(tribonacci_matrix(5L, modulo), 7L)
  assert_eq(tribonacci_matrix(6L, modulo), 13L)
  assert_eq(tribonacci_matrix(7L, modulo), 24L)
}

// ============================================================================
// NUMBER OF PATHS IN A GRAPH VIA MATRIX EXPONENTIATION
// ============================================================================
//
// BEAUTIFUL THEOREM:
// If A is the adjacency matrix of a graph, then A^k[i,j] equals the number
// of paths of length exactly k from vertex i to vertex j.
//
// PROOF BY INDUCTION:
// Base case (k=1): A^1[i,j] = A[i,j] = 1 iff edge (i,j) exists = # paths of length 1 ✓
//
// Inductive step: Assume A^k[i,j] = # paths of length k from i to j.
//   A^(k+1)[i,j] = Σ_m A^k[i,m] · A[m,j]
//                = Σ_m (# paths of length k from i to m) · (1 if edge (m,j) exists, else 0)
//                = Σ_{m: edge(m,j)} (# paths of length k from i to m)
//                = # paths of length k+1 from i to j ✓
//
// This is one of the most elegant applications of matrix exponentiation!

///|
/// Counts paths of exactly length k between vertices in a graph.
/// adj_matrix is stored in row-major order, size n×n.
#warnings("+missing_invariant+missing_reasoning")
fn count_paths(
  adj_matrix : Array[Int64],
  n : Int,
  k : Int64,
  modulo : Int64,
) -> Array[Int64] {
  fn matrix_mult_nxn(a : Array[Int64], b : Array[Int64]) -> Array[Int64] {
    let result : Array[Int64] = Array::make(n * n, 0L)
    for i = 0 {
      if i >= n {
        break
      } else {
        for j = 0 {
          if j >= n {
            break
          } else {
            let sum = for kk = 0, acc = 0L {
              if kk >= n {
                break acc
              } else {
                let new_acc = (acc + a[i * n + kk] * b[kk * n + j]) % modulo
                continue kk + 1, new_acc
              }
            } where {
              invariant: kk >= 0 && kk <= n,
              reasoning: (
                #|INVARIANT (Dot product):
                #|acc = Σ_{t < kk} a[i,t] * b[t,j] (mod modulo).
                #|After kk reaches n, acc is the full inner product for (i,j).
                #|MAINTENANCE:
                #|Add the next term a[i,kk] * b[kk,j] to acc, extending the sum.
                #|TERMINATION:
                #|At kk = n, the full dot product is accumulated.
              ),
            }
            result[i * n + j] = sum
            continue j + 1
          }
        } where {
          invariant: j >= 0 && j <= n,
          reasoning: (
            #|INVARIANT (Row fill):
            #|After processing columns [0..j), result[i,*] is correct for those
            #|columns. Each column j computes a full dot product.
            #|MAINTENANCE:
            #|Compute column j and store it, extending the computed prefix.
            #|TERMINATION:
            #|At j = n, the entire row i is complete.
          ),
        }
        continue i + 1
      }
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (Matrix fill):
        #|After processing rows [0..i), every entry result[r,c] for r < i
        #|matches the matrix product of a and b. The inner loops compute each
        #|row by full dot products, so the outer loop accumulates completed rows.
        #|MAINTENANCE:
        #|Finish row i, then move to the next row with previous rows fixed.
        #|TERMINATION:
        #|At i = n, the full n×n product is computed.
      ),
    }
    result
  }
  // Build identity matrix
  let identity : Array[Int64] = Array::make(n * n, 0L)
  for i = 0 {
    if i >= n {
      break
    } else {
      identity[i * n + i] = 1L
      continue i + 1
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (Identity build):
      #|After processing rows [0..i), identity has 1s on the diagonal entries
      #|(t,t) for t < i and 0s elsewhere.
      #|MAINTENANCE:
      #|Set identity[i,i] = 1, extending the diagonal prefix.
      #|TERMINATION:
      #|At i = n, identity is the full n×n identity matrix.
    ),
  }
  // Matrix exponentiation
  for matrix = adj_matrix, result = identity, power = k {
    if power <= 0L {
      break result
    } else if power % 2L == 1L {
      continue matrix_mult_nxn(matrix, matrix),
        matrix_mult_nxn(result, matrix),
        power / 2L
    } else {
      continue matrix_mult_nxn(matrix, matrix), result, power / 2L
    }
  } where {
    invariant: power >= 0L,
    reasoning: (
      #|INVARIANT: A^original_k = result · matrix^power.
      #|
      #|By the path-counting theorem, A^t[i,j] equals the number of paths
      #|of length t from i to j. Binary exponentiation preserves this
      #|because matrix multiplication composes path lengths:
      #|A^a · A^b = A^(a+b).
      #|MAINTENANCE:
      #|If power is odd, multiply result by matrix, then square matrix and
      #|halve power; if even, only square matrix and halve power.
      #|TERMINATION:
      #|At power = 0, result equals A^original_k and encodes path counts.
    ),
  }
}

///|
test "count_paths" {
  // Triangle graph: 0-1-2-0
  //   0 -- 1
  //    \  /
  //     2
  let adj : Array[Int64] = [
    0L, 1L, 1L, // Row 0: edges to 1, 2
     1L, 0L, 1L, // Row 1: edges to 0, 2
     1L, 1L, 0L,
  ] // Row 2: edges to 0, 1
  let modulo = 1000000007L
  // Paths of length 1: just the adjacency matrix
  let paths1 = count_paths(adj, 3, 1L, modulo)
  assert_eq(paths1[0 * 3 + 1], 1L) // 0→1
  assert_eq(paths1[0 * 3 + 0], 0L) // 0→0 (no self-loop of length 1)
  // Paths of length 2 from 0 to 0: 0→1→0 and 0→2→0
  let paths2 = count_paths(adj, 3, 2L, modulo)
  assert_eq(paths2[0 * 3 + 0], 2L) // Two paths: 0→1→0 and 0→2→0
  // Paths of length 3 from 0 to 1: 0→1→0→1, 0→1→2→1, 0→2→0→1
  let paths3 = count_paths(adj, 3, 3L, modulo)
  assert_eq(paths3[0 * 3 + 1], 3L)
}

// ============================================================================
// MATRIX CHAIN MULTIPLICATION (OPTIMAL PARENTHESIZATION)
// ============================================================================
//
// Given matrices A_1, A_2, ..., A_n with dimensions d_0×d_1, d_1×d_2, ..., d_{n-1}×d_n,
// find the parenthesization that minimizes the number of scalar multiplications.
//
// RECURRENCE:
//   m[i,j] = min_{i≤k<j} { m[i,k] + m[k+1,j] + d_{i-1}·d_k·d_j }
//
// INVARIANT:
//   After filling diagonal d, m[i,i+d] contains the minimum cost to multiply A_i...A_{i+d}

///|
/// Find minimum cost to multiply a chain of matrices.
/// dims[i] is the row dimension of matrix i (and column dimension of matrix i-1).
/// Returns the minimum number of scalar multiplications.
#warnings("+missing_invariant+missing_reasoning")
fn matrix_chain_order(dims : ArrayView[Int]) -> Int {
  let n = dims.length() - 1 // Number of matrices
  if n <= 1 {
    return 0
  }
  // m[i*n + j] = minimum cost to multiply matrices i..j (0-indexed)
  let m : Array[Int] = Array::make(n * n, 0)
  // Fill by increasing chain length
  for len = 2 {
    if len > n {
      break
    } else {
      // len is the chain length
      for i = 0 {
        if i + len > n {
          break
        } else {
          let j = i + len - 1
          m[i * n + j] = 2147483647 // Initialize to infinity
          // Try all split points
          for k = i {
            if k >= j {
              break
            } else {
              let cost = m[i * n + k] +
                m[(k + 1) * n + j] +
                dims[i] * dims[k + 1] * dims[j + 1]
              if cost < m[i * n + j] {
                m[i * n + j] = cost
              }
              continue k + 1
            }
          } where {
            invariant: k >= i && k <= j,
            reasoning: (
              #|INVARIANT: After iteration k, m[i,j] contains the minimum cost among
              #|all parenthesizations that split at position i, i+1, ..., k.
              #|
              #|The cost formula m[i,k] + m[k+1,j] + d_i·d_{k+1}·d_{j+1} represents:
              #|- m[i,k]: cost to compute A_i...A_k (dimensions d_i × d_{k+1})
              #|- m[k+1,j]: cost to compute A_{k+1}...A_j (dimensions d_{k+1} × d_{j+1})
              #|- d_i·d_{k+1}·d_{j+1}: cost to multiply the two results
              #|MAINTENANCE:
              #|Evaluate split at k and update m[i,j] if it improves the best
              #|cost seen so far, extending the min over [i..k].
              #|TERMINATION:
              #|At k = j, all split points have been considered, so m[i,j] is optimal.
            ),
          }
          continue i + 1
        }
      } where {
        invariant: i >= 0 && i <= n,
        reasoning: (
          #|Processing all chains of length len starting at position i.
          #|By the time we process m[i,j], all subproblems m[i,k] and m[k+1,j]
          #|for k in [i,j) have already been computed (shorter chains).
          #|MAINTENANCE:
          #|Compute m[i,j] using completed subproblems, then advance i to the
          #|next chain start of the same length.
          #|TERMINATION:
          #|At i + len > n, all chains of this length are processed.
        ),
      }
      continue len + 1
    }
  } where {
    invariant: len >= 2 && len <= n + 1,
    reasoning: (
      #|OUTER LOOP INVARIANT:
      #|After processing chain length len, all m[i,j] where j-i+1 < len are optimal.
      #|
      #|This follows from the principle of optimal substructure:
      #|An optimal parenthesization of A_i...A_j must consist of optimal
      #|parenthesizations of A_i...A_k and A_{k+1}...A_j for some k.
      #|
      #|COMPLEXITY: O(n³) time, O(n²) space
      #|MAINTENANCE:
      #|Using all chains of length len to compute length len+1 preserves the
      #|invariant for the next iteration.
      #|TERMINATION:
      #|At len = n + 1, all chain lengths up to n are processed.
    ),
  }
  m[0 * n + (n - 1)]
}

///|
test "matrix_chain_order" {
  // Example: matrices with dimensions 10×30, 30×5, 5×60
  // dims = [10, 30, 5, 60]
  // Option 1: (A1·A2)·A3 = 10·30·5 + 10·5·60 = 1500 + 3000 = 4500
  // Option 2: A1·(A2·A3) = 30·5·60 + 10·30·60 = 9000 + 18000 = 27000
  // Optimal: Option 1 with cost 4500
  let dims : Array[Int] = [10, 30, 5, 60]
  assert_eq(matrix_chain_order(dims[:]), 4500)
  // Another example: [40, 20, 30, 10, 30]
  // Matrices: 40×20, 20×30, 30×10, 10×30
  let dims2 : Array[Int] = [40, 20, 30, 10, 30]
  assert_eq(matrix_chain_order(dims2[:]), 26000)
}

// ============================================================================
// STRASSEN'S MATRIX MULTIPLICATION INSIGHT
// ============================================================================
//
// While we don't implement full Strassen's algorithm here (it's complex),
// we document its profound insight:
//
// STANDARD 2×2 MULTIPLICATION: 8 multiplications, 4 additions
//   | a  b |   | e  f |   | ae+bg  af+bh |
//   | c  d | × | g  h | = | ce+dg  cf+dh |
//
// STRASSEN'S INSIGHT: Can be done with 7 multiplications, 18 additions!
//   M1 = (a+d)(e+h)      M5 = (a+b)h
//   M2 = (c+d)e          M6 = (c-a)(e+f)
//   M3 = a(f-h)          M7 = (b-d)(g+h)
//   M4 = d(g-e)
//
//   Result:
//   | M1+M4-M5+M7    M3+M5        |
//   | M2+M4          M1-M2+M3+M6  |
//
// WHY IT MATTERS:
// For n×n matrices (n = 2^k), standard algorithm: O(n³)
// Strassen's: T(n) = 7T(n/2) + O(n²) = O(n^log₂7) ≈ O(n^2.807)
//
// This was revolutionary: it showed that matrix multiplication might be
// faster than the "obvious" O(n³) bound. Current best known is O(n^2.373).

///|
/// Demonstrates Strassen's 7-multiplication formula for 2×2 matrices.
/// Returns the same result as standard multiplication but uses only 7 mults.
fn strassen_2x2(
  a : Int,
  b : Int,
  c : Int,
  d : Int,
  e : Int,
  f : Int,
  g : Int,
  h : Int,
) -> (Int, Int, Int, Int) {
  // 7 multiplications (the key insight!)
  let m1 = (a + d) * (e + h)
  let m2 = (c + d) * e
  let m3 = a * (f - h)
  let m4 = d * (g - e)
  let m5 = (a + b) * h
  let m6 = (c - a) * (e + f)
  let m7 = (b - d) * (g + h)
  // Combine with additions only
  let c11 = m1 + m4 - m5 + m7
  let c12 = m3 + m5
  let c21 = m2 + m4
  let c22 = m1 - m2 + m3 + m6
  (c11, c12, c21, c22)
}

///|
test "strassen_2x2" {
  // Verify Strassen gives same result as standard multiplication
  let (c11, c12, c21, c22) = strassen_2x2(1, 2, 3, 4, 5, 6, 7, 8)
  // Standard: [[1,2],[3,4]] × [[5,6],[7,8]] = [[1·5+2·7, 1·6+2·8], [3·5+4·7, 3·6+4·8]]
  //         = [[5+14, 6+16], [15+28, 18+32]] = [[19, 22], [43, 50]]
  assert_eq(c11, 19)
  assert_eq(c12, 22)
  assert_eq(c21, 43)
  assert_eq(c22, 50)
}

// ============================================================================
// FAST DOUBLING FOR FIBONACCI
// ============================================================================
//
// An even more elegant approach derived from matrix identities:
//
// From [[1,1],[1,0]]^n = [[F(n+1),F(n)],[F(n),F(n-1)]], we get:
//   [[1,1],[1,0]]^2n = ([[1,1],[1,0]]^n)²
//
// Which gives us the FAST DOUBLING FORMULAS:
//   F(2n)   = F(n) · (2·F(n+1) - F(n))
//   F(2n+1) = F(n)² + F(n+1)²
//
// PROOF:
// [[F(2n+1),F(2n)],[F(2n),F(2n-1)]] = [[F(n+1),F(n)],[F(n),F(n-1)]]²
//
// F(2n) = F(n+1)·F(n) + F(n)·F(n-1) = F(n)·(F(n+1) + F(n-1)) = F(n)·(2F(n+1) - F(n))
// F(2n+1) = F(n+1)² + F(n)²
//
// This is arguably the most elegant Fibonacci algorithm!

///|
/// Fast doubling algorithm for Fibonacci.
/// Returns (F(n), F(n+1)) in O(log n) time with only O(1) space.
#warnings("+missing_invariant+missing_reasoning")
fn fibonacci_fast_doubling(n : Int64, modulo : Int64) -> (Int64, Int64) {
  if n == 0L {
    return (0L, 1L)
  }
  // Recursively compute F(n/2) and F(n/2 + 1)
  // But we do it iteratively using the binary representation of n
  for bit = 63, f_k = 0L, f_k1 = 1L {
    if bit < 0 {
      break (f_k, f_k1)
    } else {
      // Double: compute F(2k) and F(2k+1) from F(k) and F(k+1)
      let f_2k = f_k * (2L * f_k1 - f_k) % modulo
      let f_2k = (f_2k + modulo) % modulo // Handle negative
      let f_2k1 = (f_k * f_k + f_k1 * f_k1) % modulo
      // If bit is set in n, we need F(2k+1) and F(2k+2)
      if ((n >> bit) & 1L) == 1L {
        // F(2k+2) = F(2k+1) + F(2k)
        let f_2k2 = (f_2k + f_2k1) % modulo
        continue bit - 1, f_2k1, f_2k2
      } else {
        continue bit - 1, f_2k, f_2k1
      }
    }
  } where {
    invariant: bit >= -1 && bit <= 63,
    reasoning: (
      #|INVARIANT: (f_k, f_k1) = (F(k), F(k+1)) where k is the number formed
      #|by the bits of n from position 63 down to bit+1.
      #|
      #|INITIALIZATION (bit = 63):
      #|  k = 0, so (f_k, f_k1) = (F(0), F(1)) = (0, 1) ✓
      #|
      #|MAINTENANCE:
      #|  The doubling formulas give us (F(2k), F(2k+1)).
      #|  If bit is set, we want k' = 2k+1, so we return (F(2k+1), F(2k+2)).
      #|  If bit is clear, we want k' = 2k, so we return (F(2k), F(2k+1)).
      #|
      #|TERMINATION (bit = -1):
      #|  k = n, so we have (F(n), F(n+1)) ✓
      #|
      #|The fast doubling formulas are derived from matrix squaring:
      #|  [[F(2k+1),F(2k)],[F(2k),F(2k-1)]] = [[F(k+1),F(k)],[F(k),F(k-1)]]²
      #|
      #|Computing the squares:
      #|  F(2k)   = F(k)·F(k+1) + F(k)·F(k-1)
      #|          = F(k)·(F(k+1) + F(k-1))
      #|          = F(k)·(F(k+1) + F(k+1) - F(k))  [since F(k-1) = F(k+1) - F(k)]
      #|          = F(k)·(2·F(k+1) - F(k))
      #|
      #|  F(2k+1) = F(k+1)² + F(k)²
    ),
  }
}

///|
test "fibonacci_fast_doubling" {
  let modulo = 1000000007L
  assert_eq(fibonacci_fast_doubling(0L, modulo), (0L, 1L))
  assert_eq(fibonacci_fast_doubling(1L, modulo).0, 1L)
  assert_eq(fibonacci_fast_doubling(10L, modulo).0, 55L)
  assert_eq(fibonacci_fast_doubling(50L, modulo).0, 12586269025L % modulo)
  // Verify consistency with matrix method
  assert_eq(
    fibonacci_fast_doubling(100L, modulo).0,
    fibonacci_matrix(100L, modulo),
  )
}

// ============================================================================
// LUCAS NUMBERS VIA MATRIX EXPONENTIATION
// ============================================================================
//
// Lucas numbers follow the same recurrence as Fibonacci but with different seeds:
//   L(n) = L(n-1) + L(n-2), with L(0) = 2, L(1) = 1
//
// BEAUTIFUL IDENTITY connecting Lucas and Fibonacci:
//   L(n) = F(n-1) + F(n+1) = F(n) + 2·F(n-1)
//
// The Lucas-Fibonacci matrix relationship:
//   | L(n+1) |   | 1  1 |^n   | 1 |
//   | L(n)   | = | 1  0 |   · | 2 |
//
// Or equivalently, since L(n) = F(n-1) + F(n+1):
//   | L(n) |   | 1  2 |   | F(n)   |
//   |      | = |      | · |        |
//   |      |   |      |   | F(n-1) |

///|
fn lucas_matrix(n : Int64, modulo : Int64) -> Int64 {
  if n == 0L {
    return 2L % modulo
  }
  if n == 1L {
    return 1L % modulo
  }
  // We can use: L(n) = F(n-1) + F(n+1)
  // From matrix exponentiation of [[1,1],[1,0]]^n = [[F(n+1),F(n)],[F(n),F(n-1)]]
  let fib_matrix : (Int64, Int64, Int64, Int64) = (1L, 1L, 1L, 0L)
  let result = matrix_pow_2x2(fib_matrix, n, modulo)
  // result = (F(n+1), F(n), F(n), F(n-1))
  let (f_n1, _, _, f_n_minus_1) = result
  // L(n) = F(n-1) + F(n+1)
  (f_n1 + f_n_minus_1) % modulo
}

///|
test "lucas_matrix" {
  let modulo = 1000000007L
  // L(0)=2, L(1)=1, L(2)=3, L(3)=4, L(4)=7, L(5)=11, L(6)=18
  assert_eq(lucas_matrix(0L, modulo), 2L)
  assert_eq(lucas_matrix(1L, modulo), 1L)
  assert_eq(lucas_matrix(2L, modulo), 3L)
  assert_eq(lucas_matrix(3L, modulo), 4L)
  assert_eq(lucas_matrix(4L, modulo), 7L)
  assert_eq(lucas_matrix(5L, modulo), 11L)
  assert_eq(lucas_matrix(6L, modulo), 18L)
}
