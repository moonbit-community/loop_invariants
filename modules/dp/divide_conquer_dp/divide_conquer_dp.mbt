// ============================================================================
// DIVIDE-AND-CONQUER DP OPTIMIZATION
// ============================================================================
//
// PROBLEM
//
// Many DPs have the shape
//
//   dp_t[j] = min_{i < j}  ( dp_{t-1}[i] + C(i, j) )
//
// for `t = 1..T` layers and `j = 0..N`. The naive cost is `O(T * N^2)`.
//
// When the cost function `C` satisfies the **Knuth-Yao** (quadrangle)
// inequality
//
//   C(a, c) + C(b, d) <= C(a, d) + C(b, c)    for  a <= b <= c <= d
//
// then the optimal split point `opt[t][j] = argmin_i dp_{t-1}[i] + C(i, j)`
// is **monotone non-decreasing** in `j`:
//
//   opt[t][j] <= opt[t][j+1]
//
// Divide-and-conquer exploits this to reduce each layer from `O(N^2)`
// to `O(N log N)`, giving an overall `O(T N log N)` runtime.
//
// THE ALGORITHM
//
// For a fixed layer `t` and a range `[lo, hi]` of `j`-values with known
// search bounds `[a, b]` on `opt`:
//
//   1. Pick the middle `mid = (lo + hi) / 2`.
//   2. Scan `i in [a, min(mid, b)]` to find `opt[mid]` and `dp[t][mid]`.
//   3. Recurse on `[lo, mid - 1]` with search bound `[a, opt[mid]]`.
//   4. Recurse on `[mid + 1, hi]` with search bound `[opt[mid], b]`.
//
// Each level of recursion touches each `i` at most once across all
// recursive calls (the search bounds telescope), so a single layer
// runs in `O(N log N)`.
//
// THE INVARIANT
//
//   "Throughout the recursive calls within one DP layer, opt[j] is
//    constrained to lie in `[a, b]` where `a` is at most opt[j-1] and
//    `b` is at least opt[j+1]. The monotonicity of opt makes the
//    search bounds tighten as the recursion descends."

///|
const INF : Int64 = 4611686018427387903L

///|
/// Solve `T` layers of the DP
///
///   dp_t[j] = min_{i in [0, j]}  ( dp_{t-1}[i] + cost(i, j) )
///
/// where `cost` satisfies the quadrangle inequality. `base[j]` is the
/// initial layer `dp_0`. Returns the final layer `dp_T`.
///
/// Caller responsibilities:
///   - `cost(i, j)` is defined for `0 <= i <= j <= n`.
///   - `cost` is monotone (concretely the quadrangle inequality).
///
/// Time `O(T * n * log n)`; space `O(n)` per layer.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // dp_0 = [0, 0, 0, 0]; cost(i, j) = (j - i)^2.
///   let cost = fn(i : Int, j : Int) -> Int64 {
///     let d = (j - i).to_int64()
///     d * d
///   }
///   let base = [0L, 0L, 0L, 0L]
///   let dp = @divide_conquer_dp.solve(base, 2, cost)
///   @debug.assert_eq(dp.length(), 4)
/// }
/// ```
pub fn solve(
  base : Array[Int64],
  layers : Int,
  cost : (Int, Int) -> Int64,
) -> Array[Int64] {
  let n = base.length()
  let mut prev = Array::makei(n, i => base[i])
  let mut cur = Array::make(n, INF)
  for _t in 1..<=layers {
    // Reset current layer.
    for j in 0..<n {
      cur[j] = INF
    }
    solve_range(prev, cur, cost, 0, n - 1, 0, n - 1)
    let tmp = prev
    prev = cur
    cur = tmp
  }
  prev
}

///|
fn solve_range(
  prev : Array[Int64],
  cur : Array[Int64],
  cost : (Int, Int) -> Int64,
  lo : Int,
  hi : Int,
  a : Int,
  b : Int,
) -> Unit {
  if lo > hi {
    return
  }
  let mid = (lo + hi) / 2
  let upper = if mid < b { mid } else { b }
  let mut best : Int64 = INF
  let mut arg : Int = a
  let mut i = a
  while i <= upper {
    if prev[i] != INF {
      let v = prev[i] + cost(i, mid)
      if v < best {
        best = v
        arg = i
      }
    }
    i = i + 1
  }
  cur[mid] = best
  solve_range(prev, cur, cost, lo, mid - 1, a, arg)
  solve_range(prev, cur, cost, mid + 1, hi, arg, b)
}

///|
test "dq dp partition into 2" {
  // Partition [3, 1, 4, 1, 5] into 2 contiguous groups minimising the
  // sum of (max - min within each group). Equivalent recurrence:
  //   dp_0[0] = 0; dp_0[j>0] = INF                  (empty prefix has 0 cost
  //                                                  only for j = 0)
  //   dp_t[j] = min_{i<j} ( dp_{t-1}[i] + cost(i+1, j) )
  //
  // For testing, we just verify that the value at the final position
  // equals what a brute force computes.
  let arr = [3L, 1L, 4L, 1L, 5L]
  let n = arr.length()
  // Set up "j = number of elements consumed"; dp_0[0] = 0 else INF.
  let base = Array::make(n + 1, INF)
  base[0] = 0L
  fn cost(i : Int, j : Int) -> Int64 {
    if i >= j {
      return 0L
    }
    let mut mn = arr[i]
    let mut mx = arr[i]
    let mut k = i + 1
    while k < j {
      if arr[k] < mn {
        mn = arr[k]
      }
      if arr[k] > mx {
        mx = arr[k]
      }
      k = k + 1
    }
    mx - mn
  }

  let dp = solve(base, 2, cost)
  // Brute force: try every split.
  let mut brute : Int64 = INF
  for split in 1..<n {
    let v = cost(0, split) + cost(split, n)
    if v < brute {
      brute = v
    }
  }
  @debug.assert_eq(dp[n], brute)
}

///|
test "dq dp single layer matches brute" {
  // For a randomly chosen quadrangle-inequality cost (e.g. (j-i)^2),
  // confirm 1 layer of DC DP matches naive O(n^2).
  let n = 6
  let base = [0L, 0L, 0L, 0L, 0L, 0L]
  fn cost(i : Int, j : Int) -> Int64 {
    let d = (j - i).to_int64()
    d * d
  }

  let dq = solve(base, 1, cost)
  // Naive: dp1[j] = min_i base[i] + (j-i)^2.
  let naive = Array::make(n, INF)
  for j in 0..<n {
    for i in 0..<=j {
      let v = base[i] + cost(i, j)
      if v < naive[j] {
        naive[j] = v
      }
    }
  }
  for j in 0..<n {
    @debug.assert_eq(dq[j], naive[j])
  }
}

///|
test "dq dp larger brute force" {
  let n = 8
  let base = Array::makei(n, i => if i == 0 { 0L } else { INF })
  // cost(i, j) = (sum of squares of an arbitrary fixed array slice).
  let weights = [1L, 3L, 2L, 5L, 4L, 1L, 6L, 2L]
  fn cost(i : Int, j : Int) -> Int64 {
    let mut s = 0L
    let mut k = i
    while k < j {
      s = s + weights[k] * weights[k]
      k = k + 1
    }
    s
  }

  // T = 1 layer should match the cumulative sum cost(0, j).
  let dp1 = solve(base, 1, cost)
  for j in 0..<n {
    @debug.assert_eq(dp1[j], cost(0, j))
  }
  // T = 2 layers: cheapest way to split [0, j) into 2 contiguous parts.
  let dp2 = solve(base, 2, cost)
  for j in 1..<n {
    let mut best : Int64 = INF
    for split in 0..<=j {
      let v = cost(0, split) + cost(split, j)
      if v < best {
        best = v
      }
    }
    @debug.assert_eq(dp2[j], best)
  }
}

///|
test "dq dp degenerate input" {
  // Empty base.
  let r = solve([], 5, fn(_a, _b) { 0L })
  @debug.assert_eq(r, [])
  // Zero layers: returns base unchanged.
  let base = [3L, 5L, 7L]
  let r0 = solve(base, 0, fn(_a, _b) { 0L })
  @debug.assert_eq(r0, [3L, 5L, 7L])
}
