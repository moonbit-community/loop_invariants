// ============================================================================
// Challenge: 2D Fenwick Tree (Range Sum)
// ============================================================================

///|
fn lowbit(x : Int) -> Int {
  x & -x
}

///|
pub struct Fenwick2D {
  rows : Int
  cols : Int
  tree : Array[Array[Int]]
}

///|
pub fn Fenwick2D::new(rows : Int, cols : Int) -> Fenwick2D {
  let tree = Array::makei(rows + 1, fn(_) { Array::make(cols + 1, 0) })
  { rows, cols, tree }
}

///|
#warnings("+missing_invariant+missing_reasoning")
pub fn Fenwick2D::add(self : Fenwick2D, r : Int, c : Int, delta : Int) -> Unit {
  let x = r + 1
  let y = c + 1
  for i = x; i <= self.rows; i = i + lowbit(i) {
    for j = y; j <= self.cols; j = j + lowbit(j) {
      self.tree[i][j] = self.tree[i][j] + delta
    } where {
      invariant: j > 0 && j <= self.cols + 1,
      reasoning: (
        #|INVARIANT (col update):
        #|j visits all Fenwick column indices that cover the update position.
        #|MAINTENANCE:
        #|Advance by lowbit(j), which strictly increases j.
        #|TERMINATION:
        #|j eventually exceeds cols, finishing column updates for this row.
      ),
    }
  } where {
    invariant: i > 0 && i <= self.rows + 1,
    reasoning: (
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
#warnings("+missing_invariant+missing_reasoning")
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
      invariant: j >= 0 && j <= c,
      reasoning: (
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
    invariant: i >= 0 && i <= r,
    reasoning: (
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

///|
test "fenwick_2d_basic" {
  let fw = Fenwick2D::new(3, 3)
  fw.add(0, 0, 5)
  fw.add(1, 2, 3)
  fw.add(2, 1, 4)
  assert_eq(fw.range_sum(0, 0, 3, 3), 12)
  assert_eq(fw.range_sum(1, 1, 3, 3), 7)
}
