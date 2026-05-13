// ============================================================================
// Challenge: 2D Fenwick Tree (Range Sum)
// ============================================================================

///|
fn lowbit(x : Int) -> Int {
  x & -x
}

///|
/// A 2D Fenwick (binary indexed) tree supporting point updates and
/// rectangular prefix-sum queries.
///
/// Stores a `(rows+1) x (cols+1)` table of partial sums indexed via the
/// `lowbit` trick on both axes. Each update walks `O(log rows)` row indices,
/// each visiting `O(log cols)` column indices, for an overall
/// `O(log rows * log cols)` cost per operation. Build via the
/// `Fenwick2D::Fenwick2D` constructor, then use `add`, `prefix_sum`, and
/// `range_sum`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let g = Fenwick2D::Fenwick2D(3, 3)
///   g.add(0, 0, 1)
///   g.add(1, 1, 2)
///   g.add(2, 2, 4)
///   assert_eq(g.range_sum(0, 0, 3, 3), 7)
///   assert_eq(g.range_sum(1, 1, 3, 3), 6)
/// }
/// ```
pub struct Fenwick2D {
  rows : Int
  cols : Int
  tree : Array[Array[Int]]
}

///|
/// Create a 2D Fenwick tree with given rows and cols.
pub fn Fenwick2D::Fenwick2D(rows : Int, cols : Int) -> Fenwick2D {
  let tree = [ for _ in 0..<(rows + 1) => Array::make(cols + 1, 0) ]
  { rows, cols, tree }
}

///|
/// Add delta at position (r, c).
pub fn Fenwick2D::add(self : Fenwick2D, r : Int, c : Int, delta : Int) -> Unit {
  let x = r + 1
  let y = c + 1
  for i = x {
    if i > self.rows {
      break
    } else {
      let _ = for j = y {
        if j > self.cols {
          break ()
        } else {
          self.tree[i][j] = self.tree[i][j] + delta
          continue j + lowbit(j)
        }
      } where {
        proof_invariant: j > 0 && j <= self.cols + 1,
        proof_reasoning: (
          #|INVARIANT (col update):
          #|j visits all Fenwick column indices that cover the update position.
          #|MAINTENANCE:
          #|Advance by lowbit(j), which strictly increases j.
          #|TERMINATION:
          #|j eventually exceeds cols, finishing column updates for this row.
        ),
      }
      continue i + lowbit(i)
    }
  } where {
    proof_invariant: i > 0 && i <= self.rows + 1,
    proof_reasoning: (
      #|INVARIANT (row update):
      #|i visits all Fenwick row indices that cover the update position.
      #|MAINTENANCE:
      #|Advance by lowbit(i), which strictly increases i.
      #|TERMINATION:
      #|i eventually exceeds rows, finishing all affected rows.
    ),
  }
}

///|
/// Return prefix sum over rectangle [0, r) x [0, c).
pub fn Fenwick2D::prefix_sum(self : Fenwick2D, r : Int, c : Int) -> Int {
  for i = r, sum = 0 {
    if i <= 0 {
      break sum
    }
    let row_sum = for j = c, row_sum = 0 {
      if j <= 0 {
        break row_sum
      } else {
        continue j - lowbit(j), row_sum + self.tree[i][j]
      }
    } where {
      proof_invariant: j >= 0 && j <= c,
      proof_reasoning: (
        #|INVARIANT (col prefix):
        #|row_sum accumulates tree[i][j] contributions for columns in (j, c].
        #|MAINTENANCE:
        #|Subtract lowbit(j) to move to the next Fenwick parent.
        #|TERMINATION:
        #|At j = 0, all relevant columns are included.
      ),
    }
    continue i - lowbit(i), sum + row_sum
  } where {
    proof_invariant: i >= 0 && i <= r,
    proof_reasoning: (
      #|INVARIANT (row prefix):
      #|sum accumulates prefix contributions for rows in (i, r].
      #|MAINTENANCE:
      #|Subtract lowbit(i) to move to the next Fenwick parent row.
      #|TERMINATION:
      #|At i = 0, all relevant rows are included.
    ),
  }
}

///|
/// Query sum over rectangle [r1, r2) x [c1, c2).
pub fn Fenwick2D::range_sum(
  self : Fenwick2D,
  r1 : Int,
  c1 : Int,
  r2 : Int,
  c2 : Int,
) -> Int {
  self.prefix_sum(r2, c2) -
  self.prefix_sum(r1, c2) -
  self.prefix_sum(r2, c1) +
  self.prefix_sum(r1, c1)
}
