// ============================================================================
// MATRIX EXPONENTIATION - O(k^3 log n) Matrix Power
// ============================================================================
//
// Computes M^n in O(k^3 log n) time using binary exponentiation.
// Essential for solving linear recurrences in O(log n) time.
//
// KEY INSIGHT: Any linear recurrence can be represented as matrix multiplication:
// For Fibonacci: [F(n+1), F(n)] = [[1,1],[1,0]] * [F(n), F(n-1)]
// So F(n) = ([[1,1],[1,0]]^n)[0][1]
//
// APPLICATIONS:
// - Fibonacci in O(log n)
// - Linear recurrence relations
// - Graph path counting
// - Dynamic programming acceleration
//
// INVARIANTS (for binary exponentiation):
// 1. result * base^exp = original M^n (throughout loop)
// 2. exp halves each iteration
// 3. When exp is odd, multiply result by current base
//
// TIME COMPLEXITY: O(k^3 log n)
// SPACE COMPLEXITY: O(k^2)

/// The modulus used for all modular matrix arithmetic.
///
/// Using 10^9 + 7 (a prime) prevents Int64 overflow during multiplication
/// and keeps values in range for large exponents.

///|
const MATRIX_MOD : Int64 = 1000000007L

/// A dense k x k matrix of Int64 values, stored in row-major order.
///
/// All arithmetic operations either apply `MATRIX_MOD` (via `multiply`) or
/// operate on exact integers (via `multiply_no_mod`).  Use the modular path
/// whenever `n` is large; use the exact path only when you know intermediate
/// values stay within Int64 bounds.

///|
priv struct Matrix {
  data : Array[Array[Int64]]
  rows : Int
  cols : Int
}

/// Creates a zero-filled `rows x cols` matrix.

///|
fn Matrix::new(rows : Int, cols : Int) -> Matrix {
  let data = [| for _ in 0..<rows => Array::make(cols, 0L) |]
  { data, rows, cols }
}

/// Returns the `n x n` identity matrix.
///
/// The identity matrix satisfies `I * A = A * I = A` for any compatible
/// matrix `A`.  It is used to initialise `result` in `Matrix::power` so
/// that the loop invariant `result * base^e = M^n` holds before the first
/// iteration.
///
/// # Example
///
/// ```
/// let i2 = Matrix::identity(2)
/// // i2 = [ [1, 0],
/// //         [0, 1] ]
/// ```

///|
fn Matrix::identity(n : Int) -> Matrix {
  let m = Matrix::new(n, n)
  for i in 0..<n {
    m.data[i][i] = 1L
  }
  m
}

/// Constructs a matrix from a 2-D array literal.
///
/// Each inner array becomes one row.  An empty outer array produces a 0x0
/// matrix.  Rows are copied so later mutations to `arr` do not affect the
/// returned matrix.
///
/// # Example
///
/// ```
/// let m = Matrix::from_array([[1L, 2L], [3L, 4L]])
/// // m[0][0] = 1, m[0][1] = 2, m[1][0] = 3, m[1][1] = 4
/// ```

///|
fn Matrix::from_array(arr : Array[Array[Int64]]) -> Matrix {
  let rows = arr.length()
  if rows == 0 {
    return Matrix::new(0, 0)
  }
  let cols = arr[0].length()
  let data = [| for i in 0..<rows => arr[i].copy() |]
  { data, rows, cols }
}

/// Returns the element at row `i`, column `j`.

///|
fn Matrix::get(self : Matrix, i : Int, j : Int) -> Int64 {
  self.data[i][j]
}

/// Sets the element at row `i`, column `j` to `v`.

///|
fn Matrix::set(self : Matrix, i : Int, j : Int, v : Int64) -> Unit {
  self.data[i][j] = v
}

/// Multiplies two matrices with modular reduction.
///
/// Computes `self * other` where every intermediate accumulation is reduced
/// modulo `MATRIX_MOD`.  Both matrices must be conformable (`self.cols ==
/// other.rows`); the result has dimensions `self.rows x other.cols`.
///
/// Time: O(self.rows * self.cols * other.cols)
///
/// # Loop invariant
///
/// For each output cell `(i, j)` the inner accumulator `sum` satisfies:
///
///   `sum = (sum_{t < k} self[i,t] * other[t,j]) mod MATRIX_MOD`
///
/// When `k` reaches `self.cols`, `sum` is the complete dot product for
/// that cell.

///|
fn Matrix::multiply(self : Matrix, other : Matrix) -> Matrix {
  let result = Matrix::new(self.rows, other.cols)
  for i in 0..<self.rows {
    for j in 0..<other.cols {
      let sum = for k = 0, sum = 0L; k < self.cols; {
        continue k + 1, (sum + self.data[i][k] * other.data[k][j]) % MATRIX_MOD
      } nobreak {
        sum
      } where {
        proof_invariant: k >= 0 && k <= self.cols,
        proof_reasoning: (
          #|INVARIANT (Dot product):
          #|sum equals the partial dot product
          #|  sum_{t < k} self[i,t] * other[t,j] (mod MATRIX_MOD).
          #|When k reaches self.cols, sum is the full (i,j) entry.
          #|MAINTENANCE:
          #|Each step adds the next term self[i,k] * other[k,j] to sum.
          #|TERMINATION:
          #|At k == self.cols, the dot product is complete.
        ),
      }
      result.data[i][j] = sum
    }
  }
  result
}

/// Multiplies two matrices without modular reduction.
///
/// Computes `self * other` using exact integer arithmetic.  Use this only
/// when you are certain that no intermediate or final value exceeds the
/// Int64 range (approximately 9.2 * 10^18).  Suitable for small matrices
/// with small values, such as verifying identity-matrix properties.
///
/// Time: O(self.rows * self.cols * other.cols)
///
/// # Loop invariant
///
/// For each output cell `(i, j)` the inner accumulator `sum` satisfies:
///
///   `sum = sum_{t < k} self[i,t] * other[t,j]`
///
/// When `k` reaches `self.cols`, `sum` is the complete exact dot product.

///|
fn Matrix::multiply_no_mod(self : Matrix, other : Matrix) -> Matrix {
  let result = Matrix::new(self.rows, other.cols)
  for i in 0..<self.rows {
    for j in 0..<other.cols {
      let sum = for k = 0, sum = 0L; k < self.cols; {
        continue k + 1, sum + self.data[i][k] * other.data[k][j]
      } nobreak {
        sum
      } where {
        proof_invariant: k >= 0 && k <= self.cols,
        proof_reasoning: (
          #|INVARIANT (Dot product):
          #|sum equals the partial dot product sum_{t < k} self[i,t] * other[t,j].
          #|MAINTENANCE:
          #|Add self[i,k] * other[k,j] to extend the partial sum.
          #|TERMINATION:
          #|At k = self.cols, sum is the full entry for (i,j).
        ),
      }
      result.data[i][j] = sum
    }
  }
  result
}

/// Raises a square matrix to a non-negative integer power using binary
/// exponentiation.
///
/// Returns `self^exp` computed in O(k^3 log exp) time, where `k` is the
/// dimension of the matrix.  All multiplications use `Matrix::multiply`
/// (modular arithmetic).
///
/// If `self` is not square, it is returned unchanged (cannot exponentiate
/// a non-square matrix).  `self^0` returns the identity matrix of the
/// same dimension.
///
/// # Loop invariant
///
/// At the start of every iteration:
///
///   `result * base^e = M^exp`
///
/// where `M` is the original matrix.  The invariant is established with
/// `result = I` and `base = M` before the loop.  Each step either folds
/// one factor of `base` into `result` (when `e` is odd), squares `base`,
/// and halves `e`.  When `e` reaches 0, `result` equals `M^exp`.
///
/// # Example
///
/// ```
/// let m = Matrix::from_array([[1L, 1L], [1L, 0L]])
/// let m10 = m.power(10L)
/// // m10.get(0, 1) == F(10) == 55
/// ```

///|
fn Matrix::power(self : Matrix, exp : Int64) -> Matrix {
  if self.rows != self.cols {
    return self // Cannot exponentiate non-square matrix
  }
  let n = self.rows

  // Binary exponentiation: result * base^e = M^exp (loop invariant)
  for e = exp, result = Matrix::identity(n), base = self.copy(); e > 0L; {
    let new_result = if e % 2L == 1L { result.multiply(base) } else { result }
    continue e / 2L, new_result, base.multiply(base)
  } nobreak {
    result
  } where {
    proof_invariant: e >= 0L,
    proof_reasoning: (
      #|INVARIANT (Binary exponentiation):
      #|result * base^e = M^exp holds at each step. When e is odd we fold one
      #|factor of base into result, then square base and halve e. This preserves
      #|the invariant while strictly decreasing e toward 0.
      #|MAINTENANCE:
      #|If e is odd, multiply result by base; square base; halve e.
      #|TERMINATION:
      #|At e = 0, result equals M^exp (returned via else branch).
    ),
  }
}

/// Returns a deep copy of the matrix.
///
/// Mutations to the returned matrix do not affect the original.

///|
fn Matrix::copy(self : Matrix) -> Matrix {
  let m = Matrix::new(self.rows, self.cols)
  for i in 0..<self.rows {
    for j in 0..<self.cols {
      m.data[i][j] = self.data[i][j]
    }
  }
  m
}

/// Returns `true` if `self` and `other` have the same dimensions and all
/// corresponding elements are equal.

///|
fn Matrix::equals(self : Matrix, other : Matrix) -> Bool {
  if self.rows != other.rows || self.cols != other.cols {
    return false
  }
  for i in 0..<self.rows {
    for j in 0..<self.cols {
      if self.data[i][j] != other.data[i][j] {
        return false
      }
    }
  }
  true
}

// ============================================================================
// FIBONACCI using Matrix Exponentiation
// ============================================================================

/// Computes the nth Fibonacci number in O(log n) time using matrix
/// exponentiation.
///
/// Uses the identity:
///
/// ```
/// [ F(n+1)  F(n)   ]   [ 1  1 ]^n
/// [ F(n)    F(n-1) ] = [ 1  0 ]
/// ```
///
/// so `F(n)` is the (0,1) entry of the Fibonacci matrix raised to the nth
/// power.  The result is returned modulo `MATRIX_MOD` (10^9 + 7) for large
/// `n`.
///
/// Special cases: `fibonacci(0) = 0`, `fibonacci(1) = 1`.
///
/// # Example
///
/// ```
/// fibonacci(10L) // 55
/// fibonacci(20L) // 6765
/// fibonacci(50L) // 586268941  (= F(50) mod 10^9+7)
/// ```

///|
fn fibonacci(n : Int64) -> Int64 {
  if n <= 0L {
    return 0L
  }
  if n == 1L {
    return 1L
  }

  // [[1,1],[1,0]]^n gives [[F(n+1), F(n)], [F(n), F(n-1)]]
  let fib_matrix = Matrix::from_array([[1L, 1L], [1L, 0L]])
  let result = fib_matrix.power(n)
  result.data[0][1] // F(n)
}

// ============================================================================
// LINEAR RECURRENCE
// ============================================================================

/// Solves a k-term linear recurrence in O(k^3 log n) time.
///
/// Given a recurrence of the form:
///
/// ```
/// f(n) = c[0]*f(n-1) + c[1]*f(n-2) + ... + c[k-1]*f(n-k)
/// ```
///
/// and initial values `f(0), f(1), ..., f(k-1)`, returns `f(n)` modulo
/// `MATRIX_MOD`.
///
/// Internally builds the k x k companion (transition) matrix:
///
/// ```
/// [ c[0]  c[1]  c[2]  ...  c[k-1] ]
/// [  1     0     0    ...    0     ]
/// [  0     1     0    ...    0     ]
/// [  ...                          ]
/// [  0     0     0    ...    0     ]
/// ```
///
/// raises it to the power `n - k + 1`, then computes the dot product with
/// the reversed initial vector.
///
/// # Parameters
///
/// - `coefficients` - recurrence coefficients `[c[0], c[1], ..., c[k-1]]`
/// - `initial` - base values `[f(0), f(1), ..., f(k-1)]`
/// - `n` - the index to evaluate
///
/// # Example
///
/// Fibonacci (`k = 2`, coefficients = `[1, 1]`, initial = `[0, 1]`):
///
/// ```
/// solve_recurrence([1L, 1L], [0L, 1L], 10L) // 55
/// ```
///
/// Tribonacci (`k = 3`, coefficients = `[1, 1, 1]`, initial = `[0, 0, 1]`):
///
/// ```
/// solve_recurrence([1L, 1L, 1L], [0L, 0L, 1L], 6L) // 7
/// ```
///
/// # Loop invariant
///
/// The final dot-product loop maintains:
///
///   `ans = sum_{t < j} result[0][t] * initial[k-1-t]  (mod MATRIX_MOD)`
///
/// When `j` reaches `k`, `ans` is the complete recurrence value `f(n)`.

///|
fn solve_recurrence(
  coefficients : Array[Int64],
  initial : Array[Int64],
  n : Int64,
) -> Int64 {
  let k = coefficients.length()
  if k == 0 {
    return 0L
  }
  if n < k.to_int64() {
    return initial[n.to_int()]
  }

  // Build transition matrix
  // [[c[0], c[1], ..., c[k-1]],
  //  [1,    0,    ..., 0     ],
  //  [0,    1,    ..., 0     ],
  //  ...
  //  [0,    0,    ..., 0     ]]
  let m = Matrix::new(k, k)
  for j in 0..<k {
    m.data[0][j] = coefficients[j]
  }
  for i in 1..<k {
    m.data[i][i - 1] = 1L
  }
  let result = m.power(n - k.to_int64() + 1L)
  // Compute answer using fold over coefficients and initial values
  for j = 0, ans = 0L; j < k; {
    continue j + 1, (ans + result.data[0][j] * initial[k - 1 - j]) % MATRIX_MOD
  } nobreak {
    ans
  } where {
    proof_invariant: j >= 0 && j <= k,
    proof_reasoning: (
      #|INVARIANT (recurrence sum):
      #|ans is the partial sum of result[0][t] * initial[k-1-t] for t in [0,j).
      #|MAINTENANCE:
      #|Add the next term result[0][j] * initial[k-1-j] to the sum.
      #|TERMINATION:
      #|At j = k, ans is the complete recurrence value f(n).
    ),
  }
}

// ============================================================================
// GRAPH PATH COUNTING
// ============================================================================

/// Counts the number of walks of exactly `k` steps between every pair of
/// vertices in a directed graph.
///
/// If `adj` is the adjacency matrix of a graph with `v` vertices, then
/// `(adj^k)[i][j]` equals the number of distinct walks of length `k` from
/// vertex `i` to vertex `j`.  This follows from the definition of matrix
/// multiplication applied inductively.
///
/// Returns the full `v x v` result matrix so callers can query any pair
/// `(i, j)` using `Matrix::get`.
///
/// Time: O(v^3 log k)
///
/// # Parameters
///
/// - `adj_matrix` - square adjacency matrix where `adj[i][j] = 1` if edge
///   `i -> j` exists (0 otherwise); arbitrary non-negative weights also work
/// - `k` - walk length (number of steps)
///
/// # Example
///
/// ```
/// // Cycle graph: 0 -> 1 -> 2 -> 0
/// let adj = [[0L, 1L, 0L], [0L, 0L, 1L], [1L, 0L, 0L]]
/// let paths3 = count_paths(adj, 3L)
/// // paths3.get(0, 0) == 1  (exactly one 3-step walk from 0 back to 0)
/// ```

///|
fn count_paths(adj_matrix : Array[Array[Int64]], k : Int64) -> Matrix {
  let m = Matrix::from_array(adj_matrix)
  m.power(k)
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "matrix multiply" {
  let a = Matrix::from_array([[1L, 2L], [3L, 4L]])
  let b = Matrix::from_array([[5L, 6L], [7L, 8L]])
  let c = a.multiply_no_mod(b)

  // [[1*5+2*7, 1*6+2*8], [3*5+4*7, 3*6+4*8]] = [[19, 22], [43, 50]]
  inspect(c.get(0, 0), content="19")
  inspect(c.get(0, 1), content="22")
  inspect(c.get(1, 0), content="43")
  inspect(c.get(1, 1), content="50")
}

///|
test "matrix identity" {
  let a = Matrix::from_array([[1L, 2L], [3L, 4L]])
  let i = Matrix::identity(2)
  let b = a.multiply_no_mod(i)
  inspect(a.equals(b), content="true")
}

///|
test "matrix set" {
  let m = Matrix::new(1, 1)
  m.set(0, 0, 7L)
  inspect(m.get(0, 0), content="7")
}

///|
test "matrix power" {
  let a = Matrix::from_array([[1L, 1L], [1L, 0L]])
  let a2 = a.power(2L)
  // [[1,1],[1,0]]^2 = [[2,1],[1,1]]
  inspect(a2.get(0, 0), content="2")
  inspect(a2.get(0, 1), content="1")
  inspect(a2.get(1, 0), content="1")
  inspect(a2.get(1, 1), content="1")
}

///|
test "fibonacci" {
  inspect(fibonacci(0L), content="0")
  inspect(fibonacci(1L), content="1")
  inspect(fibonacci(2L), content="1")
  inspect(fibonacci(3L), content="2")
  inspect(fibonacci(4L), content="3")
  inspect(fibonacci(5L), content="5")
  inspect(fibonacci(10L), content="55")
  inspect(fibonacci(20L), content="6765")
}

///|
test "fibonacci large" {
  // F(50) = 12586269025, mod 10^9+7 = 586268941
  inspect(fibonacci(50L), content="586268941")
}

///|
test "solve_recurrence fibonacci" {
  // Fibonacci: f(n) = f(n-1) + f(n-2)
  let coeffs : Array[Int64] = [1L, 1L]
  let initial : Array[Int64] = [0L, 1L] // f(0)=0, f(1)=1
  inspect(solve_recurrence(coeffs, initial, 0L), content="0")
  inspect(solve_recurrence(coeffs, initial, 1L), content="1")
  inspect(solve_recurrence(coeffs, initial, 10L), content="55")
}

///|
test "solve_recurrence tribonacci" {
  // Tribonacci: f(n) = f(n-1) + f(n-2) + f(n-3)
  let coeffs : Array[Int64] = [1L, 1L, 1L]
  let initial : Array[Int64] = [0L, 0L, 1L] // f(0)=0, f(1)=0, f(2)=1

  // T(3) = 1, T(4) = 2, T(5) = 4, T(6) = 7
  inspect(solve_recurrence(coeffs, initial, 3L), content="1")
  inspect(solve_recurrence(coeffs, initial, 4L), content="2")
  inspect(solve_recurrence(coeffs, initial, 5L), content="4")
  inspect(solve_recurrence(coeffs, initial, 6L), content="7")
}

///|
test "count_paths" {
  // Graph: 0 -> 1 -> 2 -> 0
  let adj : Array[Array[Int64]] = [[0L, 1L, 0L], [0L, 0L, 1L], [1L, 0L, 0L]]
  let paths2 = count_paths(adj, 2L)
  // 2 steps from 0: 0->1->2
  inspect(paths2.get(0, 2), content="1")
  let paths3 = count_paths(adj, 3L)
  // 3 steps from 0 back to 0: 0->1->2->0
  inspect(paths3.get(0, 0), content="1")
}

///|
test "matrix power zero" {
  let a = Matrix::from_array([[2L, 3L], [4L, 5L]])
  let a0 = a.power(0L)
  let i = Matrix::identity(2)
  inspect(a0.equals(i), content="true")
}

///|
test "matrix power one" {
  let a = Matrix::from_array([[2L, 3L], [4L, 5L]])
  let a1 = a.power(1L)
  inspect(a.equals(a1), content="true")
}
