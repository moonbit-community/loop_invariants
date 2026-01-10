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
  let aug = Array::makei(n, (i) => {
    Array::makei(m + 1, (j) => if j < m { a[i][j] } else { b[i] })
  })

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
    } where {
      invariant: i >= row + 1 && i <= n,
      reasoning: (
        #|Scan rows below the current pivot row to find the largest absolute entry.
        #|i advances through candidate rows in the same column.
      ),
      invariant: best_row >= row && best_row < n,
      reasoning: (
        #|best_row always points to a valid candidate row in the search range.
      ),
      invariant: best_val == abs(aug[best_row][col]),
      reasoning: (
        #|best_val tracks the maximum absolute value seen so far in column col.
      ),
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
    } where {
      invariant: j >= col && j <= m + 1,
      reasoning: (
        #|Normalize the pivot row by dividing each entry by the pivot.
        #|Entries in columns < j have already been scaled.
      ),
      invariant: abs(pivot) >= GAUSS_EPS,
      reasoning: (
        #|We only scale when the pivot is numerically non-zero.
      ),
    }

    // Eliminate column
    for i = 0; i < n; i = i + 1 {
      if i != row && abs(aug[i][col]) > GAUSS_EPS {
        let factor = aug[i][col]
        for j = col; j <= m; j = j + 1 {
          aug[i][j] = aug[i][j] - factor * aug[row][j]
        } where {
          invariant: j >= col && j <= m + 1,
          reasoning: (
            #|Subtract factor * pivot_row from row i to zero out column col.
            #|Columns col..j-1 have already been updated.
          ),
        }
      }
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|Eliminate the pivot column from every other row.
        #|Rows processed so far have column col reduced to zero.
      ),
      invariant: abs(aug[row][col] - 1.0) < GAUSS_EPS,
      reasoning: (
        #|Pivot row is normalized, so the pivot entry stays 1 throughout elimination.
      ),
    }

    rank = rank + 1
    row = row + 1
  } where {
    invariant: 0 <= row && row <= n && 0 <= col && col <= m,
    reasoning: (
      #|row counts how many pivot rows have been fixed; col is the next column to process.
      #|Bounds guarantee all matrix accesses remain valid.
    ),
    invariant: rank == row,
    reasoning: (
      #|Each successful pivot increases both rank and row by one.
      #|Thus rank equals the number of pivot rows already placed in echelon form.
    ),
  }

  // Check for inconsistency (0 = non-zero)
  let mut has_solution = true
  for i = rank; i < n; i = i + 1 {
    if abs(aug[i][m]) > GAUSS_EPS {
      has_solution = false
      break
    }
  } where {
    invariant: i >= rank && i <= n,
    reasoning: (
      #|Rows below rank should be all zeros on the left; any non-zero RHS is inconsistent.
    ),
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
      } where {
        invariant: j >= 0 && j <= m,
        reasoning: (
          #|Scan row i to locate its pivot column (entry ~ 1.0).
        ),
      }
    } where {
      invariant: i >= 0 && i <= rank && i <= m,
      reasoning: (
        #|Each pivot row contributes exactly one variable to the solution.
        #|We only scan rows that correspond to pivots.
      ),
    }
  }

  { solution, rank, has_solution, has_unique_solution: has_solution && rank == m }
}

// ============================================================================
// MODULAR GAUSSIAN ELIMINATION
// ============================================================================

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
  let aug = Array::makei(n, (i) => {
    Array::makei(m + 1, (j) => {
      if j < m {
        ((a[i][j] % p) + p) % p
      } else {
        ((b[i] % p) + p) % p
      }
    })
  })

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
    } where {
      invariant: i >= row && i <= n,
      reasoning: (
        #|Search for a non-zero pivot in the current column.
        #|i advances through candidate rows starting at the current row.
      ),
      invariant: pivot_row == -1 || (pivot_row >= row && pivot_row < n),
      reasoning: (
        #|pivot_row is either unset (-1) or points to a valid candidate row.
      ),
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
    } where {
      invariant: j >= col && j <= m + 1,
      reasoning: (
        #|Normalize the pivot row so aug[row][col] becomes 1 in mod p arithmetic.
      ),
    }

    // Eliminate column
    for i = 0; i < n; i = i + 1 {
      if i != row && aug[i][col] != 0L {
        let factor = aug[i][col]
        for j = col; j <= m; j = j + 1 {
          aug[i][j] = ((aug[i][j] - factor * aug[row][j]) % p + p) % p
        } where {
          invariant: j >= col && j <= m + 1,
          reasoning: (
            #|Use the normalized pivot row to zero out column col in row i.
            #|All updates are reduced modulo p.
          ),
        }
      }
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|Eliminate the pivot column across all other rows.
      ),
      invariant: aug[row][col] == 1L,
      reasoning: (
        #|Pivot row is normalized, so the pivot entry remains 1 in GF(p).
      ),
    }

    row = row + 1
  } where {
    invariant: 0 <= row && row <= n && 0 <= col && col <= m,
    reasoning: (
      #|row counts the number of pivot rows found so far; col is the next column.
      #|Bounds guarantee safe access during elimination.
    ),
  }

  // Check for inconsistency
  for i = row; i < n; i = i + 1 {
    if aug[i][m] != 0L {
      return ([], false)
    }
  } where {
    invariant: i >= row && i <= n,
    reasoning: (
      #|Rows below the last pivot must have zero RHS for consistency.
    ),
  }

  // Extract solution
  let solution = Array::make(m, 0L)
  for i = 0; i < row && i < m; i = i + 1 {
    for j = 0; j < m; j = j + 1 {
      if aug[i][j] == 1L {
        solution[j] = aug[i][m]
        break
      }
    } where {
      invariant: j >= 0 && j <= m,
      reasoning: (
        #|Scan row i to locate its pivot column in GF(p).
      ),
    }
  } where {
    invariant: i >= 0 && i <= row && i <= m,
    reasoning: (
      #|Each pivot row contributes one variable assignment in the solution.
    ),
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
  let aug = Array::makei(n, (i) => {
    Array::makei(m + 1, (j) => if j < m { a[i][j] % 2 } else { b[i] % 2 })
  })

  let mut row = 0

  for col = 0; col < m && row < n; col = col + 1 {
    // Find pivot
    let mut pivot_row = -1
    for i = row; i < n; i = i + 1 {
      if aug[i][col] == 1 {
        pivot_row = i
        break
      }
    } where {
      invariant: i >= row && i <= n,
      reasoning: (
        #|Search for a row with a 1 in the pivot column over GF(2).
      ),
      invariant: pivot_row == -1 || (pivot_row >= row && pivot_row < n),
      reasoning: (
        #|pivot_row is unset or points to a valid candidate row.
      ),
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
        } where {
          invariant: j >= col && j <= m + 1,
          reasoning: (
            #|Apply XOR row operation to clear column col in row i.
          ),
        }
      }
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|Eliminate the pivot column across all other rows in GF(2).
      ),
      invariant: aug[row][col] == 1,
      reasoning: (
        #|Pivot entry stays 1 since swaps preserve it and XOR does not change it.
      ),
    }

    row = row + 1
  } where {
    invariant: 0 <= row && row <= n && 0 <= col && col <= m,
    reasoning: (
      #|row counts pivot rows found so far; col is the next column to process.
    ),
  }

  // Check for inconsistency
  for i = row; i < n; i = i + 1 {
    if aug[i][m] == 1 {
      return ([], false)
    }
  } where {
    invariant: i >= row && i <= n,
    reasoning: (
      #|Rows below the last pivot must have zero RHS for consistency in GF(2).
    ),
  }

  // Extract solution
  let solution = Array::make(m, 0)
  for i = 0; i < row && i < m; i = i + 1 {
    for j = 0; j < m; j = j + 1 {
      if aug[i][j] == 1 {
        solution[j] = aug[i][m]
        break
      }
    } where {
      invariant: j >= 0 && j <= m,
      reasoning: (
        #|Scan row i to locate its pivot column in GF(2).
      ),
    }
  } where {
    invariant: i >= 0 && i <= row && i <= m,
    reasoning: (
      #|Each pivot row yields one variable value in the solution.
    ),
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
