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
pub struct GaussResult {
  solution : Array[Double]
  rank : Int
  has_solution : Bool
  has_unique_solution : Bool
}

///|
/// Solve Ax = b using Gaussian elimination.
pub fn gauss_solve(a : Array[Array[Double]], b : Array[Double]) -> GaussResult {
  let n = a.length()
  if b.length() != n {
    return {
      solution: [],
      rank: 0,
      has_solution: false,
      has_unique_solution: false,
    }
  }
  let m = if n == 0 { 0 } else { a[0].length() }
  for row in a {
    if row.length() != m {
      return {
        solution: [],
        rank: 0,
        has_solution: false,
        has_unique_solution: false,
      }
    }
  }
  gauss_eliminate(a, b)
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
  let aug = Array::makei(n, i => {
    Array::makei(m + 1, j => if j < m { a[i][j] } else { b[i] })
  })

  // Forward elimination
  let rank = for col = 0, rank = 0, row = 0; col < m && row < n; {
    // Find pivot (partial pivoting)
    let (best_row, best_val) = for i = row + 1, best_row = row, best_val = abs(
                                       aug[row][col],
                                     ); i < n; {
      let val = abs(aug[i][col])
      if val > best_val {
        continue i + 1, i, val
      }
      continue i + 1, best_row, best_val
    } nobreak {
      (best_row, best_val)
    } where {
      invariant: i >= row + 1 && i <= n,
      reasoning: (
        #|INVARIANT (Pivot scan range):
        #|Rows [row+1..i) have been inspected for the current column.
        #|The loop only considers candidates below the active pivot row,
        #|which preserves the upper-triangular structure of prior pivots.
        #|MAINTENANCE:
        #|Inspect row i and update the best candidate if its absolute value is larger.
        #|TERMINATION:
        #|At i == n, all remaining rows have been considered for the pivot.
      ),
      invariant: best_row >= row && best_row < n,
      reasoning: (
        #|INVARIANT (Best row validity):
        #|best_row stays within [row, i), so it always names a row already
        #|examined for this pivot choice.
        #|MAINTENANCE:
        #|best_row is updated only to i, which is within the scanned prefix.
        #|TERMINATION:
        #|At loop end, best_row is a valid pivot candidate row.
      ),
      invariant: best_val == abs(aug[best_row][col]),
      reasoning: (
        #|INVARIANT (Best value):
        #|best_val is the maximum absolute entry seen so far in column col
        #|among rows [row..i). This implements partial pivoting for stability.
        #|MAINTENANCE:
        #|Update best_val when a larger absolute entry is found at row i.
        #|TERMINATION:
        #|At i == n, best_val is the column maximum among candidate rows.
      ),
    }

    // Skip if column is zero
    if best_val < GAUSS_EPS {
      continue col + 1, rank, row
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
        #|INVARIANT (Row normalization):
        #|After processing columns [col..j), aug[row][t] has been divided by
        #|pivot for every t in that range. When the loop ends, the pivot entry
        #|becomes 1 and the entire augmented row is scaled consistently.
        #|MAINTENANCE:
        #|Divide aug[row][j] by pivot and advance j.
        #|TERMINATION:
        #|At j == m + 1, the entire row is normalized.
      ),
      invariant: abs(pivot) >= GAUSS_EPS,
      reasoning: (
        #|INVARIANT (Non-zero pivot):
        #|We only normalize when the chosen pivot is safely away from zero,
        #|so dividing preserves numerical stability and avoids blow-ups.
        #|MAINTENANCE:
        #|Pivot stays fixed during normalization, so the bound remains valid.
        #|TERMINATION:
        #|Invariant holds until the normalized row is complete.
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
            #|INVARIANT (Row elimination):
            #|After processing columns [col..j), row i has been updated by
            #|subtracting factor * pivot_row, so all entries in that range
            #|match the new row with column col targeted for zeroing.
            #|MAINTENANCE:
            #|Update aug[i][j] by subtracting factor * aug[row][j], then advance j.
            #|TERMINATION:
            #|At j == m + 1, row i has been fully eliminated in column col.
          ),
        }
      }
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (Column elimination):
        #|After processing rows [0..i), every row other than the pivot row
        #|has column col reduced to 0 (within epsilon). This produces the
        #|Gauss-Jordan form for the current pivot column.
        #|MAINTENANCE:
        #|Eliminate column col in row i (when needed), preserving previous rows.
        #|TERMINATION:
        #|At i == n, all rows are cleared in column col except the pivot row.
      ),
      invariant: abs(aug[row][col] - 1.0) < GAUSS_EPS,
      reasoning: (
        #|INVARIANT (Pivot stability):
        #|The pivot entry remains 1 because we never modify the pivot row
        #|during elimination of other rows.
        #|MAINTENANCE:
        #|Elimination updates only non-pivot rows, so the pivot stays 1.
        #|TERMINATION:
        #|Invariant holds throughout elimination for this column.
      ),
    }
    continue col + 1, rank + 1, row + 1
  } nobreak {
    rank
  } where {
    invariant: 0 <= row && row <= n && 0 <= col && col <= m,
    reasoning: (
      #|INVARIANT (Forward elimination progress):
      #|row counts completed pivot rows, and col is the current column under
      #|consideration. All rows above row are already in reduced row-echelon
      #|form for columns < col, so each new pivot maintains the invariant.
      #|MAINTENANCE:
      #|Advance col each iteration; when a pivot is found, increment row.
      #|TERMINATION:
      #|At col == m or row == n, forward elimination is complete.
    ),
    invariant: rank == row,
    reasoning: (
      #|INVARIANT (Rank tracking):
      #|Every time we accept a pivot we increment row and rank together.
      #|Therefore rank equals the number of independent pivot rows built so far.
      #|MAINTENANCE:
      #|Increment rank alongside row when a pivot is fixed.
      #|TERMINATION:
      #|At loop end, rank is the matrix rank (number of pivots).
    ),
  }

  // Check for inconsistency (0 = non-zero)
  let has_solution = for i = rank; i < n; {
    if abs(aug[i][m]) > GAUSS_EPS {
      break false
    }
    continue i + 1
  } nobreak {
    true
  } where {
    invariant: i >= rank && i <= n,
    reasoning: (
      #|INVARIANT (Consistency check):
      #|Rows i >= rank have all-zero coefficients on the left side. If any
      #|such row has a non-zero right-hand side, the system is inconsistent
      #|because it encodes 0 = c with c != 0.
      #|MAINTENANCE:
      #|Check row i for a non-zero RHS and break if inconsistent.
      #|TERMINATION:
      #|At i == n, no inconsistent row was found.
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
          #|INVARIANT (Pivot column scan):
          #|After scanning columns [0..j), no pivot (value near 1) has been
          #|found yet. When we find it, the corresponding variable is fixed
          #|to the row's augmented value.
          #|MAINTENANCE:
          #|Inspect column j and advance until a pivot is found.
          #|TERMINATION:
          #|At j == m, all columns were scanned for this row.
        ),
      }
    } where {
      invariant: i >= 0 && i <= rank && i <= m,
      reasoning: (
        #|INVARIANT (Solution extraction):
        #|Each pivot row determines one basic variable. By scanning only the
        #|first rank rows, we assign values to all pivot variables while leaving
        #|free variables (if any) at their default value.
        #|MAINTENANCE:
        #|Find the pivot in row i and set the corresponding solution entry.
        #|TERMINATION:
        #|At i == rank, all basic variables have been assigned.
      ),
    }
  }
  {
    solution,
    rank,
    has_solution,
    has_unique_solution: has_solution && rank == m,
  }
}

// ============================================================================
// MODULAR GAUSSIAN ELIMINATION
// ============================================================================

///|
/// Modular multiplicative inverse using Fermat's little theorem
fn mod_inverse(a : Int64, m : Int64) -> Int64 {
  for result = 1L, base = a % m, exp = m - 2L; exp > 0L; {
    let next_result = if exp % 2L == 1L { result * base % m } else { result }
    continue next_result, base * base % m, exp / 2L
  } nobreak {
    result
  }
}

///|
/// Solve system Ax = b mod p
fn gauss_mod(
  a : Array[Array[Int64]],
  b : Array[Int64],
  p : Int64,
) -> (Array[Int64], Bool) {
  let n = a.length()
  if n == 0 {
    return ([], true)
  }
  let m = a[0].length()

  // Create augmented matrix
  let aug = Array::makei(n, i => {
    Array::makei(m + 1, j => {
      if j < m {
        (a[i][j] % p + p) % p
      } else {
        (b[i] % p + p) % p
      }
    })
  })
  // Forward elimination
  let row = for col = 0, row = 0; col < m && row < n; {
    // Find pivot
    let pivot_row = for i = row; i < n; {
      if aug[i][col] != 0L {
        break i
      }
      continue i + 1
    } nobreak {
      -1
    } where {
      invariant: i >= row && i <= n,
      reasoning: (
        #|INVARIANT (pivot search):
        #|Rows in [row..i) have been checked for a non-zero pivot in column col.
        #|MAINTENANCE:
        #|Advance i and test aug[i][col] for a non-zero entry.
        #|TERMINATION:
        #|At i = n, no pivot exists in this column.
      ),
    }
    if pivot_row < 0 {
      continue col + 1, row
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
        #|INVARIANT (normalize pivot row):
        #|Entries aug[row][col..j) are scaled so aug[row][col] = 1 in GF(p).
        #|MAINTENANCE:
        #|Multiply aug[row][j] by inv to normalize each entry.
        #|TERMINATION:
        #|At j = m + 1, the entire row is normalized.
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
            #|INVARIANT (row elimination):
            #|Entries aug[i][col..j) are updated to eliminate column col.
            #|MAINTENANCE:
            #|Subtract factor * pivot_row[j] modulo p for each column j.
            #|TERMINATION:
            #|At j = m + 1, row i has column col eliminated.
          ),
        }
      }
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (column elimination):
        #|Rows in [0..i) have column col eliminated (except pivot row).
        #|MAINTENANCE:
        #|Apply elimination to row i when needed.
        #|TERMINATION:
        #|At i = n, column col is eliminated in all non-pivot rows.
      ),
      invariant: aug[row][col] == 1L,
      reasoning: (
        #|INVARIANT (pivot stays 1):
        #|The pivot entry aug[row][col] remains 1 throughout elimination.
        #|MAINTENANCE:
        #|Row operations on other rows do not modify the pivot row.
        #|TERMINATION:
        #|Pivot entry is 1 when moving to the next column.
      ),
    }
    continue col + 1, row + 1
  } nobreak {
    row
  } where {
    invariant: 0 <= row && row <= n && 0 <= col && col <= m,
    reasoning: (
      #|INVARIANT (forward elimination):
      #|row is the number of pivots found; col is the current column being processed.
      #|MAINTENANCE:
      #|Each pivot increases row by 1 and moves to the next column.
      #|TERMINATION:
      #|At col = m or row = n, elimination is complete.
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
      #|INVARIANT (consistency check):
      #|All checked rows in [row..i) have zero RHS for a zero coefficient row.
      #|MAINTENANCE:
      #|Inspect aug[i][m] to ensure no contradiction appears.
      #|TERMINATION:
      #|At i = n, the system is consistent if no contradiction was found.
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
        #|INVARIANT (pivot scan):
        #|Columns in [0..j) have been checked for the pivot in row i.
        #|MAINTENANCE:
        #|Advance j until the leading 1 is found.
        #|TERMINATION:
        #|At j = m, the pivot is found or the row is all zeros.
      ),
    }
  } where {
    invariant: i >= 0 && i <= row && i <= m,
    reasoning: (
      #|INVARIANT (solution extraction):
      #|Each processed pivot row contributes one variable value to solution.
      #|MAINTENANCE:
      #|Assign the RHS to the pivot column for row i.
      #|TERMINATION:
      #|At i = row (or m), all leading variables are assigned.
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
  let aug = Array::makei(n, i => {
    Array::makei(m + 1, j => if j < m { a[i][j] % 2 } else { b[i] % 2 })
  })
  let row = for col = 0, row = 0; col < m && row < n; {
    // Find pivot
    let pivot_row = for i = row; i < n; {
      if aug[i][col] == 1 {
        break i
      }
      continue i + 1
    } nobreak {
      -1
    } where {
      invariant: i >= row && i <= n,
      reasoning: (
        #|INVARIANT (pivot search xor):
        #|Rows in [row..i) have been checked for a 1 in column col.
        #|MAINTENANCE:
        #|Advance i until a pivot row is found or the column is exhausted.
        #|TERMINATION:
        #|At i = n, no pivot exists in this column.
      ),
    }
    if pivot_row < 0 {
      continue col + 1, row
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
          aug[i][j] = aug[i][j] ^ aug[row][j]
        } where {
          invariant: j >= col && j <= m + 1,
          reasoning: (
            #|INVARIANT (xor elimination):
            #|Entries aug[i][col..j) are updated by XOR with pivot row.
            #|MAINTENANCE:
            #|XOR aug[row][j] into aug[i][j] to clear the pivot column.
            #|TERMINATION:
            #|At j = m + 1, column col is cleared in row i.
          ),
        }
      }
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (column elimination xor):
        #|Rows in [0..i) have column col eliminated (except the pivot row).
        #|MAINTENANCE:
        #|Apply XOR elimination to row i when it has a 1 in column col.
        #|TERMINATION:
        #|At i = n, the pivot column is cleared in all other rows.
      ),
      invariant: aug[row][col] == 1,
      reasoning: (
        #|INVARIANT (pivot stays 1 xor):
        #|The pivot entry aug[row][col] remains 1 in GF(2).
        #|MAINTENANCE:
        #|XOR operations on other rows do not affect the pivot row.
        #|TERMINATION:
        #|Pivot entry is 1 when moving to the next column.
      ),
    }
    continue col + 1, row + 1
  } nobreak {
    row
  } where {
    invariant: 0 <= row && row <= n && 0 <= col && col <= m,
    reasoning: (
      #|INVARIANT (forward elimination xor):
      #|row counts pivots found; col is the current column being processed.
      #|MAINTENANCE:
      #|Each pivot increases row by 1 and moves to the next column.
      #|TERMINATION:
      #|At col = m or row = n, elimination is complete.
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
      #|INVARIANT (consistency check xor):
      #|Checked rows in [row..i) have zero RHS for a zero coefficient row.
      #|MAINTENANCE:
      #|Inspect aug[i][m] to detect a contradiction.
      #|TERMINATION:
      #|At i = n, the system is consistent if no contradiction is found.
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
        #|INVARIANT (pivot scan xor):
        #|Columns in [0..j) have been checked for the pivot in row i.
        #|MAINTENANCE:
        #|Advance j until the leading 1 is found.
        #|TERMINATION:
        #|At j = m, the pivot is found or the row is all zeros.
      ),
    }
  } where {
    invariant: i >= 0 && i <= row && i <= m,
    reasoning: (
      #|INVARIANT (solution extraction xor):
      #|Each processed pivot row yields a variable assignment.
      #|MAINTENANCE:
      #|Assign the RHS to the pivot column for row i.
      #|TERMINATION:
      #|At i = row (or m), all leading variables are assigned.
    ),
  }
  (solution, true)
}

///|
fn abs(x : Double) -> Double {
  if x < 0.0 {
    -x
  } else {
    x
  }
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
  let a : Array[Array[Double]] = [
    [1.0, 1.0, 1.0],
    [2.0, -1.0, 1.0],
    [1.0, 2.0, -1.0],
  ]
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
