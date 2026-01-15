// ============================================================================
// MATRIX EXPONENTIATION - O(n³ log k) Matrix Power
// ============================================================================
//
// Computes M^k in O(n³ log k) time using binary exponentiation.
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
// 1. result * base^exp = original M^k (throughout loop)
// 2. exp halves each iteration
// 3. When exp is odd, multiply result by current base
//
// TIME COMPLEXITY: O(n³ log k)
// SPACE COMPLEXITY: O(n²)

///|
const MATRIX_MOD : Int64 = 1000000007L

///|
priv struct Matrix {
  data : Array[Array[Int64]]
  rows : Int
  cols : Int
}

///|
fn Matrix::new(rows : Int, cols : Int) -> Matrix {
  let data = Array::makei(rows, _ => Array::make(cols, 0L))
  { data, rows, cols }
}

///|
fn Matrix::identity(n : Int) -> Matrix {
  let m = Matrix::new(n, n)
  for i in 0..<n {
    m.data[i][i] = 1L
  }
  m
}

///|
fn Matrix::from_array(arr : Array[Array[Int64]]) -> Matrix {
  let rows = arr.length()
  if rows == 0 {
    return Matrix::new(0, 0)
  }
  let cols = arr[0].length()
  let data = Array::makei(rows, i => arr[i].copy())
  { data, rows, cols }
}

///|
fn Matrix::get(self : Matrix, i : Int, j : Int) -> Int64 {
  self.data[i][j]
}

///|
fn Matrix::set(self : Matrix, i : Int, j : Int, v : Int64) -> Unit {
  self.data[i][j] = v
}

///|
/// Matrix multiplication with modulo
fn Matrix::multiply(self : Matrix, other : Matrix) -> Matrix {
  let result = Matrix::new(self.rows, other.cols)
  for i = 0; i < self.rows; i = i + 1 {
    for j = 0; j < other.cols; j = j + 1 {
      let mut sum = 0L
      for k = 0; k < self.cols; k = k + 1 {
        sum = (sum + self.data[i][k] * other.data[k][j]) % MATRIX_MOD
      } where {
        invariant: k >= 0 && k <= self.cols,
        reasoning: (
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
    } where {
      invariant: j >= 0 && j <= other.cols,
      reasoning: (
        #|INVARIANT (Row fill):
        #|After processing columns [0..j), result[i][c] is correct for all c < j.
        #|Each column is computed by a full dot product over the shared dimension.
        #|MAINTENANCE:
        #|Computing column j extends the verified prefix.
        #|TERMINATION:
        #|At j == other.cols, row i is complete.
      ),
    }
  } where {
    invariant: i >= 0 && i <= self.rows,
    reasoning: (
      #|INVARIANT (Matrix fill):
      #|After processing rows [0..i), every entry in those rows matches the
      #|matrix product. The loop constructs the result row by row.
      #|MAINTENANCE:
      #|Filling row i preserves correctness for the processed prefix.
      #|TERMINATION:
      #|At i == self.rows, the full product matrix is computed.
    ),
  }
  result
}

///|
/// Matrix multiplication without modulo
fn Matrix::multiply_no_mod(self : Matrix, other : Matrix) -> Matrix {
  let result = Matrix::new(self.rows, other.cols)
  for i = 0; i < self.rows; i = i + 1 {
    for j = 0; j < other.cols; j = j + 1 {
      let mut sum = 0L
      for k = 0; k < self.cols; k = k + 1 {
        sum = sum + self.data[i][k] * other.data[k][j]
      } where {
        invariant: k >= 0 && k <= self.cols,
        reasoning: (
          #|INVARIANT (Dot product):
          #|sum equals the partial dot product sum_{t < k} self[i,t] * other[t,j].
          #|MAINTENANCE:
          #|Add self[i,k] * other[k,j] to extend the partial sum.
          #|TERMINATION:
          #|At k = self.cols, sum is the full entry for (i,j).
        ),
      }
      result.data[i][j] = sum
    } where {
      invariant: j >= 0 && j <= other.cols,
      reasoning: (
        #|INVARIANT (Row fill):
        #|After processing columns [0..j), result[i][c] is correct for all c < j.
        #|MAINTENANCE:
        #|Compute the dot product for column j and store it in result[i][j].
        #|TERMINATION:
        #|At j = other.cols, row i is fully computed.
      ),
    }
  } where {
    invariant: i >= 0 && i <= self.rows,
    reasoning: (
      #|INVARIANT (Matrix fill):
      #|Rows [0..i) are fully computed for the product without modulo.
      #|MAINTENANCE:
      #|Compute row i using dot products with all columns.
      #|TERMINATION:
      #|At i = self.rows, the full product matrix is computed.
    ),
  }
  result
}

///|
/// Matrix exponentiation using binary exponentiation
fn Matrix::power(self : Matrix, exp : Int64) -> Matrix {
  if self.rows != self.cols {
    return self // Cannot exponentiate non-square matrix
  }
  let n = self.rows

  // Binary exponentiation: result * base^e = M^exp (loop invariant)
  for e = exp, result = Matrix::identity(n), base = self.copy(); e > 0L; {
    let new_result = if e % 2L == 1L { result.multiply(base) } else { result }
    continue e / 2L, new_result, base.multiply(base)
  } else {
    result
  } where {
    invariant: e >= 0L,
    reasoning: (
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

///|
/// Copy matrix
fn Matrix::copy(self : Matrix) -> Matrix {
  let m = Matrix::new(self.rows, self.cols)
  for i in 0..<self.rows {
    for j in 0..<self.cols {
      m.data[i][j] = self.data[i][j]
    }
  }
  m
}

///|
/// Check if matrices are equal
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

///|
/// Compute nth Fibonacci number in O(log n)
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

///|
/// Solve linear recurrence: f(n) = c[0]*f(n-1) + c[1]*f(n-2) + ... + c[k-1]*f(n-k)
/// Given initial values f(0), f(1), ..., f(k-1)
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
  } else {
    ans
  } where {
    invariant: j >= 0 && j <= k,
    reasoning: (
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

///|
/// Count paths of exactly k steps from u to v in graph
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
