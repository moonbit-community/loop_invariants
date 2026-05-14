// ============================================================================
// MYERS DIFF  -  Myers 1986
// ============================================================================
//
// PROBLEM
//
// Given two sequences `a` of length `n` and `b` of length `m`, find
// a **shortest edit script** (SES) -- the minimum number of single
// element insertions and deletions to transform `a` into `b`. The
// length of an SES equals `n + m - 2 * LCS(a, b)`, where LCS is the
// longest common subsequence.
//
// This is the algorithm behind `git diff`, GNU `diff`, and most
// modern line-diff tooling.
//
// THE EDIT GRAPH
//
// Think of an (n+1) x (m+1) grid where each cell is a state
// `(i, j) = (chars of a consumed, chars of b consumed)`. There are
// three kinds of moves:
//
//   - "down" -- consume one char of b (an insertion); j += 1
//   - "right" -- consume one char of a (a deletion); i += 1
//   - "diagonal" -- a[i] == b[j], free move; i += 1, j += 1
//
// We start at (0, 0), and we want to reach (n, m) along the shortest
// path counting only non-diagonal moves. Each "down" or "right" costs
// 1; diagonals are free. The shortest such path has D = SES length.
//
// MYERS' INSIGHT
//
// Instead of running BFS over the O(nm) cells, parametrise paths by
// their "k-line": the diagonal `k = i - j`. Run BFS over (D, k):
//
//   "What is the furthest x = i reachable in D non-diagonal moves
//    along k-line k?"
//
// Furthest x at (D, k) is derived from x at (D-1, k-1) -- a "down"
// brought us to k from k-1 -- or from x at (D-1, k+1) -- a "right"
// brought us from k+1. Either way, advance along the diagonal
// (free moves) as far as a[x] == b[x - k] allows.
//
// COMPLEXITY
//
//   Time  : O((n + m) * D) where D = length of the shortest edit script.
//   Space : O(n + m) for the V array, indexed by k.
//
// For nearly-identical inputs (D small), this is essentially linear,
// which is why it works so well on real-world diffs.
//
// THE INVARIANT
//
//   "After completing the BFS step for distance d, V[k] is the
//    maximum i reachable at edit-distance exactly d on diagonal k."
//
//   The first d at which V[n - m] >= n is the SES length D.

///|
/// An edit step.
pub enum Edit {
  /// Equal element: a[i] == b[j], advance both.
  Equal(Int)
  /// Insert b[j] (advance b, leave a behind).
  Insert(Int)
  /// Delete a[i] (advance a, leave b behind).
  Delete(Int)
} derive(Eq)

///|
/// Length of the shortest edit script transforming `a` into `b`.
/// Equals `n + m - 2 * LCS(a, b)`.
pub fn shortest_edit_distance(a : Array[Int], b : Array[Int]) -> Int {
  let n = a.length()
  let m = b.length()
  let max_d = n + m
  if max_d == 0 {
    return 0
  }
  // V[k + max_d]: max x reachable on k-line.
  let v = Array::make(2 * max_d + 1, -1)
  let offset = max_d
  v[1 + offset] = 0
  for d in 0..<=max_d {
    let mut k = -d
    while k <= d {
      let mut x = if k == -d ||
        (k != d && v[k - 1 + offset] < v[k + 1 + offset]) {
        // Down step: came from (d-1, k+1).
        v[k + 1 + offset]
      } else {
        // Right step: came from (d-1, k-1), and we advanced one column.
        v[k - 1 + offset] + 1
      }
      let mut y = x - k
      // Take free diagonal moves.
      while x < n && y < m && a[x] == b[y] {
        x = x + 1
        y = y + 1
      }
      v[k + offset] = x
      if x >= n && y >= m {
        return d
      }
      k = k + 2
    }
  }
  // Unreachable for valid inputs.
  max_d
}

///|
/// Compute a shortest edit script that transforms `a` into `b`.
///
/// Returns an array of `Edit` operations in order. The script's
/// length minus the count of `Equal` operations equals the result
/// of `shortest_edit_distance(a, b)`.
///
/// ## Example
///
/// ```moonbit nocheck
/// let ops = @myers_diff.diff([1, 2, 3, 4], [1, 3, 4, 5])
/// // [Equal(1), Delete(2), Equal(3), Equal(4), Insert(5)]
/// ```
pub fn diff(a : Array[Int], b : Array[Int]) -> Array[Edit] {
  let n = a.length()
  let m = b.length()
  if n == 0 {
    let result : Array[Edit] = []
    for j in 0..<m {
      result.push(Insert(b[j]))
    }
    return result
  }
  if m == 0 {
    let result : Array[Edit] = []
    for i in 0..<n {
      result.push(Delete(a[i]))
    }
    return result
  }
  // Forward Myers, storing V at each d so we can reconstruct the path.
  let max_d = n + m
  let offset = max_d
  // trace[d] is a snapshot of V (length 2*max_d + 1) at edit-distance d.
  let trace : Array[Array[Int]] = []
  let v = Array::make(2 * max_d + 1, -1)
  v[1 + offset] = 0
  let mut final_d = -1
  let mut d_iter = 0
  let mut found = false
  while d_iter <= max_d && !found {
    // Snapshot V before processing this d.
    let snap = v.copy()
    trace.push(snap)
    let mut k = -d_iter
    while k <= d_iter {
      let mut x = if k == -d_iter ||
        (k != d_iter && v[k - 1 + offset] < v[k + 1 + offset]) {
        v[k + 1 + offset]
      } else {
        v[k - 1 + offset] + 1
      }
      let mut y = x - k
      while x < n && y < m && a[x] == b[y] {
        x = x + 1
        y = y + 1
      }
      v[k + offset] = x
      if x >= n && y >= m {
        final_d = d_iter
        found = true
        break
      }
      k = k + 2
    }
    d_iter = d_iter + 1
  }
  // Walk back from (n, m) using the trace. Build path of all grid
  // points visited, in reverse (from (n, m) back to (0, 0)).
  let path : Array[(Int, Int)] = []
  path.push((n, m))
  let mut x = n
  let mut y = m
  let mut d = final_d
  while d > 0 {
    let vd = trace[d]
    let k = x - y
    let prev_k = if k == -d ||
      (k != d && vd[k - 1 + offset] < vd[k + 1 + offset]) {
      k + 1
    } else {
      k - 1
    }
    let prev_x = vd[prev_k + offset]
    let prev_y = prev_x - prev_k
    // Diagonal stretch back to (prev_x, prev_y) — these are free moves.
    while x > prev_x && y > prev_y {
      x = x - 1
      y = y - 1
      path.push((x, y))
    }
    // One non-diagonal move: from (prev_x, prev_y) to (x, y).
    if d > 0 {
      x = prev_x
      y = prev_y
      path.push((x, y))
    }
    d = d - 1
  }
  // For d=0 case, walk back final diagonal stretch all the way.
  while x > 0 && y > 0 {
    x = x - 1
    y = y - 1
    path.push((x, y))
  }
  // path is reverse: (n,m), ..., (0,0). Walk forward (reverse it).
  let result : Array[Edit] = []
  let mut i = path.length() - 1
  while i > 0 {
    let (px, py) = path[i]
    let (nx, ny) = path[i - 1]
    if nx == px + 1 && ny == py + 1 {
      result.push(Equal(a[px]))
    } else if nx == px + 1 {
      result.push(Delete(a[px]))
    } else {
      result.push(Insert(b[py]))
    }
    i = i - 1
  }
  result
}

///|
test "myers identical sequences" {
  let a = [1, 2, 3, 4]
  let b = [1, 2, 3, 4]
  @debug.assert_eq(shortest_edit_distance(a, b), 0)
  let ops = diff(a, b)
  @debug.assert_eq(ops.length(), 4)
  // All operations are Equal.
  for o in ops {
    match o {
      Equal(_) => ()
      _ => panic()
    }
  }
}

///|
test "myers empty vs nonempty" {
  @debug.assert_eq(shortest_edit_distance([], [1, 2, 3]), 3)
  @debug.assert_eq(shortest_edit_distance([1, 2, 3], []), 3)
  @debug.assert_eq(diff([], [7, 8]).length(), 2)
  @debug.assert_eq(diff([7, 8], []).length(), 2)
}

///|
test "myers insertion only" {
  let a = [1, 2, 3]
  let b = [1, 9, 2, 3]
  @debug.assert_eq(shortest_edit_distance(a, b), 1)
  let ops = diff(a, b)
  // Exactly one Insert(9).
  let mut insert_count = 0
  for o in ops {
    if o is Insert(_) {
      insert_count = insert_count + 1
    }
  }
  @debug.assert_eq(insert_count, 1)
}

///|
test "myers deletion only" {
  let a = [1, 2, 3, 4]
  let b = [1, 2, 4]
  @debug.assert_eq(shortest_edit_distance(a, b), 1)
}

///|
test "myers substitution as delete+insert" {
  // Diff has no atomic 'substitute'; replacing 3 with 9 = delete 3 + insert 9.
  let a = [1, 2, 3]
  let b = [1, 2, 9]
  @debug.assert_eq(shortest_edit_distance(a, b), 2)
}

///|
test "myers classic ABCABBA -> CBABAC" {
  // The classic LCS / SES example from Myers' paper.
  let a = [
    'A'.to_int(),
    'B'.to_int(),
    'C'.to_int(),
    'A'.to_int(),
    'B'.to_int(),
    'B'.to_int(),
    'A'.to_int(),
  ]
  let b = [
    'C'.to_int(),
    'B'.to_int(),
    'A'.to_int(),
    'B'.to_int(),
    'A'.to_int(),
    'C'.to_int(),
  ]
  // LCS = "CABA" (or "CBBA" etc.), length 4. SES = 7 + 6 - 2*4 = 5.
  @debug.assert_eq(shortest_edit_distance(a, b), 5)
}

///|
test "myers diff reconstructs target" {
  let a = [1, 2, 3, 4, 5]
  let b = [2, 4, 5, 6]
  let ops = diff(a, b)
  // Apply ops to a, expect b.
  let result : Array[Int] = []
  let mut i = 0
  for o in ops {
    match o {
      Equal(v) => {
        result.push(v)
        i = i + 1
      }
      Insert(v) => result.push(v)
      Delete(_) => i = i + 1
    }
  }
  let _ = i
  @debug.assert_eq(result, b)
}

///|
test "myers diff full delete then full insert" {
  let a = [1, 2, 3]
  let b = [9, 8, 7]
  // No common elements; SES = 3 + 3 = 6.
  @debug.assert_eq(shortest_edit_distance(a, b), 6)
}

///|
test "myers diff prefix shared" {
  let a = [1, 2, 3, 4, 5]
  let b = [1, 2, 3, 8, 9]
  // 3 common, 2 deletes, 2 inserts: SES = 4.
  @debug.assert_eq(shortest_edit_distance(a, b), 4)
}
