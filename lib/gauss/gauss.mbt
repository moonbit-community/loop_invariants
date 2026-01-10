// ============================================================================
// GAUSSIAN ELIMINATION - Linear System Solver
// ============================================================================
//
// Gaussian elimination solves systems of linear equations Ax = b.
// Uses row reduction to transform matrix to row echelon form.
//
// ALGORITHM:
// 1. Forward elimination: Transform to upper triangular form
// 2. Back substitution: Solve from bottom up
//
// KEY OPERATIONS:
// - Swap rows (for pivot selection)
// - Scale row (divide by pivot)
// - Add multiple of one row to another
//
// PARTIAL PIVOTING: Select largest absolute value in column as pivot.
// This improves numerical stability.
//
// INVARIANTS:
// 1. Rows above current row are in row echelon form
// 2. Pivot element is non-zero (or row is skipped)
// 3. After forward elimination: upper triangular matrix
// 4. Each row operation preserves solution set
//
// TIME COMPLEXITY: O(n³)
// SPACE COMPLEXITY: O(n²)

///|
const GAUSS_EPS : Double = 0.000000001

///|
priv struct GaussResult {
  solution : Array[Double]
  rank : Int
  has_solution : Bool
  has_unique_solution : Bool
}

///|
/// Solve system Ax = b using Gaussian elimination
fn gauss_eliminate(a : Array[Array[Double]], b : Array[Double]) -> GaussResult {
  let n = a.length()
  if n == 0 {
    return {
      solution: [],
      rank: 0,
      has_solution: true,
      has_unique_solution: true,
    }
  }

  let m = a[0].length()

  // Create augmented matrix [A|b]
  let aug = Array::make(n, [])
  for i = 0; i < n; i = i + 1 {
    aug[i] = Array::make(m + 1, 0.0)
    for j = 0; j < m; j = j + 1 {
      aug[i][j] = a[i][j]
    }
    aug[i][m] = b[i]
  }

  let mut rank = 0
  let mut row = 0

  // Forward elimination
  for col = 0; col < m && row < n; col = col + 1 {
    // Find pivot (partial pivoting)
    let mut best_row = row
    let mut best_val = abs(aug[row][col])
    for i = row + 1; i < n; i = i + 1 {
      let val = abs(aug[i][col])
      if val > best_val {
        best_val = val
        best_row = i
      }
    }

    // Skip if column is zero
    if best_val < GAUSS_EPS {
      continue
    }

    // Swap rows
    if best_row != row {
      let tmp = aug[row]
      aug[row] = aug[best_row]
      aug[best_row] = tmp
    }

    // Scale pivot row
    let pivot = aug[row][col]
    for j = col; j <= m; j = j + 1 {
      aug[row][j] = aug[row][j] / pivot
    }

    // Eliminate column
    for i = 0; i < n; i = i + 1 {
      if i != row && abs(aug[i][col]) > GAUSS_EPS {
        let factor = aug[i][col]
        for j = col; j <= m; j = j + 1 {
          aug[i][j] = aug[i][j] - factor * aug[row][j]
        }
      }
    }

    rank = rank + 1
    row = row + 1
  }

  // Check for inconsistency (0 = non-zero)
  let mut has_solution = true
  for i = rank; i < n; i = i + 1 {
    if abs(aug[i][m]) > GAUSS_EPS {
      has_solution = false
      break
    }
  }

  // Extract solution
  let solution = Array::make(m, 0.0)
  if has_solution {
    // Back substitute (already in RREF from Gauss-Jordan)
    for i = 0; i < rank && i < m; i = i + 1 {
      // Find pivot column for this row
      for j = 0; j < m; j = j + 1 {
        if abs(aug[i][j] - 1.0) < GAUSS_EPS {
          solution[j] = aug[i][m]
          break
        }
      }
    }
  }

  { solution, rank, has_solution, has_unique_solution: has_solution && rank == m }
}

// ============================================================================
// MODULAR GAUSSIAN ELIMINATION
// ============================================================================

///|
const GAUSS_MOD : Int64 = 1000000007L

///|
/// Modular multiplicative inverse using Fermat's little theorem
fn mod_inverse(a : Int64, m : Int64) -> Int64 {
  let mut result = 1L
  let mut base = a % m
  let mut exp = m - 2L

  while exp > 0L {
    if exp % 2L == 1L {
      result = result * base % m
    }
    base = base * base % m
    exp = exp / 2L
  }

  result
}

///|
/// Solve system Ax = b mod p
fn gauss_mod(
  a : Array[Array[Int64]],
  b : Array[Int64],
  p : Int64
) -> (Array[Int64], Bool) {
  let n = a.length()
  if n == 0 {
    return ([], true)
  }

  let m = a[0].length()

  // Create augmented matrix
  let aug = Array::make(n, [])
  for i = 0; i < n; i = i + 1 {
    aug[i] = Array::make(m + 1, 0L)
    for j = 0; j < m; j = j + 1 {
      aug[i][j] = ((a[i][j] % p) + p) % p
    }
    aug[i][m] = ((b[i] % p) + p) % p
  }

  let mut row = 0

  // Forward elimination
  for col = 0; col < m && row < n; col = col + 1 {
    // Find pivot
    let mut pivot_row = -1
    for i = row; i < n; i = i + 1 {
      if aug[i][col] != 0L {
        pivot_row = i
        break
      }
    }

    if pivot_row < 0 {
      continue
    }

    // Swap rows
    if pivot_row != row {
      let tmp = aug[row]
      aug[row] = aug[pivot_row]
      aug[pivot_row] = tmp
    }

    // Scale pivot row
    let inv = mod_inverse(aug[row][col], p)
    for j = col; j <= m; j = j + 1 {
      aug[row][j] = aug[row][j] * inv % p
    }

    // Eliminate column
    for i = 0; i < n; i = i + 1 {
      if i != row && aug[i][col] != 0L {
        let factor = aug[i][col]
        for j = col; j <= m; j = j + 1 {
          aug[i][j] = ((aug[i][j] - factor * aug[row][j]) % p + p) % p
        }
      }
    }

    row = row + 1
  }

  // Check for inconsistency
  for i = row; i < n; i = i + 1 {
    if aug[i][m] != 0L {
      return ([], false)
    }
  }

  // Extract solution
  let solution = Array::make(m, 0L)
  for i = 0; i < row && i < m; i = i + 1 {
    for j = 0; j < m; j = j + 1 {
      if aug[i][j] == 1L {
        solution[j] = aug[i][m]
        break
      }
    }
  }

  (solution, true)
}

// ============================================================================
// XOR GAUSSIAN ELIMINATION (for GF(2))
// ============================================================================

///|
/// Solve system over GF(2) (XOR equations)
fn gauss_xor(a : Array[Array[Int]], b : Array[Int]) -> (Array[Int], Bool) {
  let n = a.length()
  if n == 0 {
    return ([], true)
  }

  let m = a[0].length()

  // Create augmented matrix
  let aug = Array::make(n, [])
  for i = 0; i < n; i = i + 1 {
    aug[i] = Array::make(m + 1, 0)
    for j = 0; j < m; j = j + 1 {
      aug[i][j] = a[i][j] % 2
    }
    aug[i][m] = b[i] % 2
  }

  let mut row = 0

  for col = 0; col < m && row < n; col = col + 1 {
    // Find pivot
    let mut pivot_row = -1
    for i = row; i < n; i = i + 1 {
      if aug[i][col] == 1 {
        pivot_row = i
        break
      }
    }

    if pivot_row < 0 {
      continue
    }

    // Swap rows
    if pivot_row != row {
      let tmp = aug[row]
      aug[row] = aug[pivot_row]
      aug[pivot_row] = tmp
    }

    // XOR eliminate column
    for i = 0; i < n; i = i + 1 {
      if i != row && aug[i][col] == 1 {
        for j = col; j <= m; j = j + 1 {
          aug[i][j] = aug[i][j].lxor(aug[row][j])
        }
      }
    }

    row = row + 1
  }

  // Check for inconsistency
  for i = row; i < n; i = i + 1 {
    if aug[i][m] == 1 {
      return ([], false)
    }
  }

  // Extract solution
  let solution = Array::make(m, 0)
  for i = 0; i < row && i < m; i = i + 1 {
    for j = 0; j < m; j = j + 1 {
      if aug[i][j] == 1 {
        solution[j] = aug[i][m]
        break
      }
    }
  }

  (solution, true)
}

///|
fn abs(x : Double) -> Double {
  if x < 0.0 { -x } else { x }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "gauss basic 2x2" {
  // x + y = 3
  // 2x - y = 3
  // Solution: x = 2, y = 1
  let a : Array[Array[Double]] = [[1.0, 1.0], [2.0, -1.0]]
  let b : Array[Double] = [3.0, 3.0]
  let result = gauss_eliminate(a, b)

  inspect(result.has_unique_solution, content="true")
  inspect(abs(result.solution[0] - 2.0) < 0.001, content="true")
  inspect(abs(result.solution[1] - 1.0) < 0.001, content="true")
}

///|
test "gauss 3x3" {
  // x + y + z = 6
  // 2x - y + z = 3
  // x + 2y - z = 2
  // Solution: x = 1, y = 2, z = 3
  let a : Array[Array[Double]] = [[1.0, 1.0, 1.0], [2.0, -1.0, 1.0], [
      1.0, 2.0, -1.0,
    ]]
  let b : Array[Double] = [6.0, 3.0, 2.0]
  let result = gauss_eliminate(a, b)

  inspect(result.has_unique_solution, content="true")
  inspect(abs(result.solution[0] - 1.0) < 0.001, content="true")
  inspect(abs(result.solution[1] - 2.0) < 0.001, content="true")
  inspect(abs(result.solution[2] - 3.0) < 0.001, content="true")
}

///|
test "gauss no solution" {
  // x + y = 1
  // x + y = 2 (inconsistent)
  let a : Array[Array[Double]] = [[1.0, 1.0], [1.0, 1.0]]
  let b : Array[Double] = [1.0, 2.0]
  let result = gauss_eliminate(a, b)

  inspect(result.has_solution, content="false")
}

///|
test "gauss infinite solutions" {
  // x + y = 2
  // 2x + 2y = 4 (dependent)
  let a : Array[Array[Double]] = [[1.0, 1.0], [2.0, 2.0]]
  let b : Array[Double] = [2.0, 4.0]
  let result = gauss_eliminate(a, b)

  inspect(result.has_solution, content="true")
  inspect(result.has_unique_solution, content="false")
  inspect(result.rank, content="1")
}

///|
test "gauss_mod basic" {
  // x + y = 3 (mod 7)
  // 2x + y = 5 (mod 7)
  // Solution: x = 2, y = 1
  let a : Array[Array[Int64]] = [[1L, 1L], [2L, 1L]]
  let b : Array[Int64] = [3L, 5L]
  let (solution, success) = gauss_mod(a, b, 7L)

  inspect(success, content="true")
  inspect(solution[0], content="2")
  inspect(solution[1], content="1")
}

///|
test "gauss_xor basic" {
  // x XOR y = 1
  // y = 1
  // Solution: x = 0, y = 1
  let a : Array[Array[Int]] = [[1, 1], [0, 1]]
  let b : Array[Int] = [1, 1]
  let (solution, success) = gauss_xor(a, b)

  inspect(success, content="true")
  inspect(solution[0], content="0")
  inspect(solution[1], content="1")
}

///|
test "gauss_xor lights out" {
  // Simple lights-out puzzle: toggle pattern
  // x1 XOR x2 = 1
  // x2 XOR x3 = 0
  // x1 XOR x3 = 1
  let a : Array[Array[Int]] = [[1, 1, 0], [0, 1, 1], [1, 0, 1]]
  let b : Array[Int] = [1, 0, 1]
  let (_, success) = gauss_xor(a, b)

  inspect(success, content="true")
}

///|
test "gauss empty" {
  let a : Array[Array[Double]] = []
  let b : Array[Double] = []
  let result = gauss_eliminate(a, b)

  inspect(result.has_solution, content="true")
  inspect(result.rank, content="0")
}

///|
test "mod_inverse" {
  // 3 * 5 = 15 ≡ 1 (mod 7)
  inspect(mod_inverse(3L, 7L), content="5")
  // 2 * 4 = 8 ≡ 1 (mod 7)
  inspect(mod_inverse(2L, 7L), content="4")
}
