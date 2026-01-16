// Convex Hull Trick and DP Optimization Techniques
// with rigorous loop invariants and mathematical reasoning

///|
/// Convex Hull Trick for Linear Functions
///
/// MATHEMATICAL FOUNDATION:
/// Maintain a set of lines y = mx + b such that we can query
/// the minimum (or maximum) y-value at any x efficiently.
///
/// KEY INSIGHT:
/// Lines form a "lower envelope" - at any x, only one line is optimal.
/// If lines are added with decreasing slope, we can use a deque.
///
/// TIME: O(1) amortized per insert, O(log n) or O(1) per query
priv struct ConvexHullTrick {
  lines : Array[(Int64, Int64)] // (slope, intercept)
}

///|
fn ConvexHullTrick::new() -> ConvexHullTrick {
  { lines: [] }
}

///|
/// Check if line c makes line b irrelevant
/// Returns true if b is never the minimum when c is added
fn is_bad(a : (Int64, Int64), b : (Int64, Int64), c : (Int64, Int64)) -> Bool {
  // Line b is bad if intersection of a,c is to the left of intersection of a,b
  // (c.b - a.b) * (a.m - b.m) <= (b.b - a.b) * (a.m - c.m)
  let (am, ab) = a
  let (bm, bb) = b
  let (cm, cb) = c

  // Avoid division by comparing cross products
  (cb - ab) * (am - bm) <= (bb - ab) * (am - cm)
}

///|
/// Add a line y = mx + b
/// REQUIREMENT: Lines must be added in order of decreasing slope
fn ConvexHullTrick::add_line(
  self : ConvexHullTrick,
  m : Int64,
  b : Int64,
) -> Unit {
  // Remove lines that are no longer useful
  while self.lines.length() >= 2 {
    let n = self.lines.length()
    let a = self.lines[n - 2]
    let b_line = self.lines[n - 1]
    if is_bad(a, b_line, (m, b)) {
      let _ = self.lines.pop()

    } else {
      break
    }
  }
  self.lines.push((m, b))
}

///|
/// Evaluate line at x
fn eval_line(line : (Int64, Int64), x : Int64) -> Int64 {
  let (m, b) = line
  m * x + b
}

///|
/// Query minimum y-value at x
/// Uses binary search for O(log n) query
fn ConvexHullTrick::query_min(self : ConvexHullTrick, x : Int64) -> Int64 {
  if self.lines.length() == 0 {
    return 9223372036854775807L // Int64 max
  }
  let n = self.lines.length()

  // Binary search for the optimal line
  for lo = 0, hi = n - 1; lo < hi; {
    let mid = (lo + hi) / 2
    if eval_line(self.lines[mid], x) > eval_line(self.lines[mid + 1], x) {
      continue mid + 1, hi
    } else {
      continue lo, mid
    }
  } else {
    eval_line(self.lines[lo], x)
  } where {
    invariant: lo >= 0 && hi < n && lo <= hi,
    reasoning: (
      #|LOOP INVARIANT: Optimal line is in range [lo, hi]
      #|
      #|CONVEX HULL PROPERTY: The lower envelope is convex.
      #|Moving right increases the slope of the optimal line.
      #|Binary search finds the transition point.
      #|MAINTENANCE:
      #|Compare mid and mid+1; move the bound toward the smaller line.
      #|TERMINATION:
      #|At lo == hi, the remaining line is optimal for x.
    ),
  }
}

///|
test "convex hull trick basic" {
  let cht = ConvexHullTrick::new()

  // Add lines with decreasing slopes
  cht.add_line(3L, 0L) // y = 3x
  cht.add_line(2L, 1L) // y = 2x + 1
  cht.add_line(1L, 3L) // y = x + 3

  // At x=0: min(0, 1, 3) = 0
  assert_eq(cht.query_min(0L), 0L)

  // At x=2: min(6, 5, 5) = 5
  assert_eq(cht.query_min(2L), 5L)

  // At x=5: min(15, 11, 8) = 8
  assert_eq(cht.query_min(5L), 8L)
}

///|
/// Monotonic Convex Hull Trick
///
/// When queries are also monotonic, we can answer in O(1) amortized.
priv struct MonotonicCHT {
  lines : Array[(Int64, Int64)]
  ptr : Array[Int] // Current pointer for monotonic queries
}

///|
fn MonotonicCHT::new() -> MonotonicCHT {
  { lines: [], ptr: [0] }
}

///|
fn MonotonicCHT::add_line_mono(
  self : MonotonicCHT,
  m : Int64,
  b : Int64,
) -> Unit {
  while self.lines.length() >= 2 {
    let n = self.lines.length()
    let a = self.lines[n - 2]
    let b_line = self.lines[n - 1]
    if is_bad(a, b_line, (m, b)) {
      let _ = self.lines.pop()
      // Adjust pointer if we removed the line it points to
      if self.ptr[0] >= self.lines.length() && self.ptr[0] > 0 {
        self.ptr[0] = self.ptr[0] - 1
      }
    } else {
      break
    }
  }
  self.lines.push((m, b))
}

///|
/// Query with monotonically increasing x
/// O(1) amortized
fn MonotonicCHT::query_mono_inc(self : MonotonicCHT, x : Int64) -> Int64 {
  if self.lines.length() == 0 {
    return 9223372036854775807L
  }

  // Advance pointer while next line is better
  while self.ptr[0] + 1 < self.lines.length() {
    if eval_line(self.lines[self.ptr[0]], x) >
      eval_line(self.lines[self.ptr[0] + 1], x) {
      self.ptr[0] = self.ptr[0] + 1
    } else {
      break
    }
  }
  eval_line(self.lines[self.ptr[0]], x)
}

///|
test "monotonic cht" {
  let cht = MonotonicCHT::new()
  cht.add_line_mono(3L, 0L)
  cht.add_line_mono(2L, 1L)
  cht.add_line_mono(1L, 3L)

  // Monotonic queries
  assert_eq(cht.query_mono_inc(0L), 0L)
  assert_eq(cht.query_mono_inc(2L), 5L)
  assert_eq(cht.query_mono_inc(5L), 8L)
}

///|
/// Li Chao Tree for General Line Queries
///
/// Supports arbitrary order of line insertion and queries.
/// O(log C) per operation where C is the coordinate range.
priv struct LiChaoNode {
  line : (Int64, Int64)?
  left : LiChaoNode?
  right : LiChaoNode?
}

///|
priv struct LiChaoTree {
  mut root : LiChaoNode?
  lo : Int64
  hi : Int64
}

///|
fn LiChaoTree::new(lo : Int64, hi : Int64) -> LiChaoTree {
  { root: None, lo, hi }
}

///|
fn add_line_li_chao_node(
  node : LiChaoNode?,
  lo : Int64,
  hi : Int64,
  line : (Int64, Int64),
) -> LiChaoNode {
  match node {
    None => { line: Some(line), left: None, right: None }
    Some(n) => {
      let mid = (lo + hi) / 2
      match n.line {
        None => { line: Some(line), left: n.left, right: n.right }
        Some(cur) => {
          let cur_at_mid = eval_line(cur, mid)
          let new_at_mid = eval_line(line, mid)
          if new_at_mid < cur_at_mid {
            // New line is better at midpoint
            let new_left = if eval_line(line, lo) < eval_line(cur, lo) {
              // New is better on left, push current to right
              n.left
            } else {
              // Current is better on left, recurse with current
              Some(add_line_li_chao_node(n.left, lo, mid, cur))
            }
            let new_right = if eval_line(line, hi) < eval_line(cur, hi) {
              n.right
            } else {
              Some(add_line_li_chao_node(n.right, mid + 1L, hi, cur))
            }
            { line: Some(line), left: new_left, right: new_right }
          } else {
            // Current line is better at midpoint
            let new_left = if eval_line(cur, lo) < eval_line(line, lo) {
              n.left
            } else {
              Some(add_line_li_chao_node(n.left, lo, mid, line))
            }
            let new_right = if eval_line(cur, hi) < eval_line(line, hi) {
              n.right
            } else {
              Some(add_line_li_chao_node(n.right, mid + 1L, hi, line))
            }
            { line: Some(cur), left: new_left, right: new_right }
          }
        }
      }
    }
  }
}

///|
fn LiChaoTree::add_line_li_chao(
  self : LiChaoTree,
  m : Int64,
  b : Int64,
) -> Unit {
  self.root = Some(add_line_li_chao_node(self.root, self.lo, self.hi, (m, b)))
}

///|
fn query_li_chao_node(
  node : LiChaoNode?,
  lo : Int64,
  hi : Int64,
  x : Int64,
) -> Int64 {
  match node {
    None => 9223372036854775807L
    Some(n) => {
      let cur_val = match n.line {
        None => 9223372036854775807L
        Some(line) => eval_line(line, x)
      }
      let mid = (lo + hi) / 2
      let child_val = if x <= mid {
        query_li_chao_node(n.left, lo, mid, x)
      } else {
        query_li_chao_node(n.right, mid + 1L, hi, x)
      }
      if cur_val < child_val {
        cur_val
      } else {
        child_val
      }
    }
  }
}

///|
fn LiChaoTree::query_li_chao(self : LiChaoTree, x : Int64) -> Int64 {
  query_li_chao_node(self.root, self.lo, self.hi, x)
}

///|
test "li chao tree" {
  let lct = LiChaoTree::new(0L, 100L)
  lct.add_line_li_chao(3L, 0L)
  lct.add_line_li_chao(2L, 1L)
  lct.add_line_li_chao(1L, 3L)
  assert_eq(lct.query_li_chao(0L), 0L)
  assert_eq(lct.query_li_chao(2L), 5L)
  assert_eq(lct.query_li_chao(5L), 8L)
}

///|
/// Divide and Conquer DP Optimization
///
/// MATHEMATICAL FOUNDATION:
/// When opt(i) <= opt(i+1) for the optimal decision point,
/// we can use divide and conquer to reduce O(n²) to O(n log n).
///
/// dp[i] = min over j<i of (cost(j, i) + dp[j])
///
/// This is useful when the cost function satisfies the quadrangle inequality.
fn divide_conquer_dp(
  n : Int,
  cost : (Int, Int) -> Int64,
  initial : Array[Int64],
) -> Array[Int64] {
  let dp = Array::makei(n, i => initial[i])

  // Divide and conquer helper
  // Computes dp[lo..hi] given that opt is in [opt_lo, opt_hi]
  fn solve(
    dp : Array[Int64],
    lo : Int,
    hi : Int,
    opt_lo : Int,
    opt_hi : Int,
    cost : (Int, Int) -> Int64,
  ) -> Unit {
    if lo > hi {
      return
    }
    let mid = (lo + hi) / 2
    let mut best_val = 9223372036854775807L
    let mut best_opt = opt_lo

    // Find optimal decision for mid in range [opt_lo, min(opt_hi, mid-1)]
    for j = opt_lo; j <= opt_hi && j < mid; j = j + 1 {
      let val = dp[j] + cost(j, mid)
      if val < best_val {
        best_val = val
        best_opt = j
      }
    } where {
      invariant: j >= opt_lo && j <= opt_hi + 1,
      reasoning: (
        #|INVARIANT (mid candidate scan):
        #|best_val is the minimum value seen in [opt_lo..j) with best_opt as argmin.
        #|MAINTENANCE:
        #|Compare candidate j, updating best_val and best_opt when it improves.
        #|TERMINATION:
        #|At j = opt_hi + 1 (or mid), best_opt is the optimal decision for mid.
      ),
    }
    if best_val < dp[mid] {
      dp[mid] = best_val
    }

    // Recurse on left and right halves
    solve(dp, lo, mid - 1, opt_lo, best_opt, cost)
    solve(dp, mid + 1, hi, best_opt, opt_hi, cost)
  }

  solve(dp, 1, n - 1, 0, n - 1, cost)
  dp
}

///|
test "divide conquer dp" {
  // Simple quadratic cost: cost(j, i) = (i - j)^2
  let n = 5
  let cost = fn(j : Int, i : Int) -> Int64 {
    let diff = (i - j).to_int64()
    diff * diff
  }
  let initial : Array[Int64] = [0L, 100L, 100L, 100L, 100L]
  let dp = divide_conquer_dp(n, cost, initial)

  // dp[0] = 0 (initial)
  // dp[1] = dp[0] + cost(0,1) = 0 + 1 = 1
  // dp[2] = dp[0] + cost(0,2) = 0 + 4 = 4 (algorithm finds global min via divide-conquer)
  assert_eq(dp[0], 0L)
  assert_eq(dp[1], 1L)
  assert_eq(dp[2], 4L)
}

///|
/// Knuth's Optimization
///
/// MATHEMATICAL FOUNDATION:
/// For interval DP where opt(i, j-1) <= opt(i, j) <= opt(i+1, j),
/// we can reduce O(n³) to O(n²).
///
/// dp[i][j] = min over i<k<j of (dp[i][k] + dp[k][j] + cost(i, j))
fn knuth_optimization(
  n : Int,
  cost : (Int, Int) -> Int64,
) -> Array[Array[Int64]] {
  let dp = Array::makei(n, _ => Array::make(n, 0L))
  let opt = Array::makei(n, i => {
    let row = Array::make(n, 0)
    row[i] = i
    row
  })

  // Process by increasing length
  for len = 2; len <= n; len = len + 1 {
    for i = 0; i + len - 1 < n; i = i + 1 {
      let j = i + len - 1
      dp[i][j] = 9223372036854775807L

      // opt[i][j] is in range [opt[i][j-1], opt[i+1][j]]
      let lo_opt = if j > 0 { opt[i][j - 1] } else { i }
      let hi_opt = if i + 1 < n { opt[i + 1][j] } else { j }
      for k = lo_opt; k <= hi_opt && k < j; k = k + 1 {
        let val = dp[i][k] + dp[k + 1][j] + cost(i, j)
        if val < dp[i][j] {
          dp[i][j] = val
          opt[i][j] = k
        }
      } where {
        invariant: k >= lo_opt && k <= hi_opt + 1,
        reasoning: (
          #|KNUTH'S OPTIMIZATION: opt(i,j-1) <= opt(i,j) <= opt(i+1,j)
          #|
          #|By constraining the search range, we reduce total work
          #|from O(n³) to O(n²) because sum of ranges is O(n²).
          #|MAINTENANCE:
          #|Evaluate dp[i][k] within the restricted range and update opt[i][j].
          #|TERMINATION:
          #|At k == hi_opt + 1, the optimal split for (i,j) is chosen.
        ),
      }
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (interval start scan):
        #|Intervals of length len starting before i are fully processed.
        #|MAINTENANCE:
        #|Compute dp[i][j] and opt[i][j] for the current interval.
        #|TERMINATION:
        #|At i = n, all length-len intervals are processed.
      ),
    }
  } where {
    invariant: len >= 2 && len <= n + 1,
    reasoning: (
      #|INVARIANT (length layers):
      #|All interval lengths in [2..len) are complete before processing len.
      #|MAINTENANCE:
      #|Use smaller intervals to build dp for length len.
      #|TERMINATION:
      #|At len = n + 1, all interval lengths are processed.
    ),
  }
  dp
}

///|
test "knuth optimization" {
  // Matrix chain multiplication-like cost
  let n = 4
  let cost = fn(i : Int, j : Int) -> Int64 {
    if i >= j || i < 0 || j >= n {
      0L
    } else {
      // Simplified: just j - i (for testing)
      (j - i).to_int64()
    }
  }
  let dp = knuth_optimization(n, cost)
  // Just verify it runs without error
  assert_true(dp[0][n - 1] >= 0L)
}

///|
/// 1D/1D DP Optimization with Monotone Queue
///
/// For dp[i] = min over j in [i-k, i-1] of (dp[j] + a[i])
/// Use monotone deque for O(n) total.
fn sliding_window_dp(arr : ArrayView[Int64], k : Int) -> Array[Int64] {
  let n = arr.length()
  let dp : Array[Int64] = Array::make(n, 0L)
  let deque : Array[Int] = [] // Indices
  dp[0] = arr[0]
  deque.push(0)
  for i = 1; i < n; i = i + 1 {
    // Remove elements outside window
    while deque.length() > 0 && deque[0] < i - k {
      // Remove front
      for j = 0; j < deque.length() - 1; j = j + 1 {
        deque[j] = deque[j + 1]
      } where {
        invariant: j >= 0 && j <= deque.length() - 1,
        reasoning: (
          #|INVARIANT (shift left):
          #|deque[0..j) has been shifted one position left to remove the front.
          #|MAINTENANCE:
          #|Copy deque[j+1] into deque[j], extending the shifted prefix.
          #|TERMINATION:
          #|At j = deque.length() - 1, the front element is removed.
        ),
      }
      let _ = deque.pop()

    }

    // dp[i] = dp[front] + arr[i]
    dp[i] = if deque.length() > 0 { dp[deque[0]] + arr[i] } else { arr[i] }

    // Maintain monotonicity: remove worse candidates from back
    while deque.length() > 0 && dp[deque[deque.length() - 1]] >= dp[i] {
      let _ = deque.pop()

    }
    deque.push(i)
  } where {
    invariant: i >= 1 && i <= n,
    reasoning: (
      #|LOOP INVARIANT: deque contains indices in [i-k+1, i] in increasing order
      #|with dp values in increasing order.
      #|
      #|MONOTONE QUEUE INSIGHT: Each element enters/exits once -> O(n) total.
      #|MAINTENANCE:
      #|Drop out-of-window indices and dominated dp values, then push i.
      #|TERMINATION:
      #|At i == n, dp is computed for all positions.
    ),
  }
  dp
}

///|
test "sliding window dp" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let dp = sliding_window_dp(arr[:], 2)

  // dp[0] = 1
  // dp[1] = dp[0] + 2 = 3
  // dp[2] = min(dp[0], dp[1]) + 3 = 1 + 3 = 4
  // dp[3] = min(dp[1], dp[2]) + 4 = 3 + 4 = 7
  // dp[4] = min(dp[2], dp[3]) + 5 = 4 + 5 = 9
  assert_eq(dp[0], 1L)
  assert_eq(dp[1], 3L)
  assert_eq(dp[2], 4L)
  assert_eq(dp[3], 7L)
  assert_eq(dp[4], 9L)
}

///|
/// Aliens Trick (WQS Binary Search)
///
/// MATHEMATICAL FOUNDATION:
/// For problems like "find minimum cost using exactly k items",
/// binary search on the penalty λ for using an item.
/// The optimal k becomes monotonic in λ.
fn aliens_trick(
  n : Int,
  target_k : Int,
  compute_dp : (Int64) -> (Int64, Int),
) -> Int64 {
  let _ = n
  let mut lo = -1000000000L
  let mut hi = 1000000000L

  // Binary search for the right penalty
  for iter = 0; iter < 100; iter = iter + 1 {
    let mid = (lo + hi) / 2L
    let (_, k) = compute_dp(mid)
    if k <= target_k {
      hi = mid
    } else {
      lo = mid
    }
  } where {
    invariant: iter >= 0 && iter <= 100,
    reasoning: (
      #|WQS BINARY SEARCH:
      #|- Adding penalty λ per item makes DP choose fewer items as λ increases
      #|- Binary search on λ to find where exactly target_k items are chosen
      #|- Final answer = dp_cost - k * λ
      #|MAINTENANCE:
      #|Evaluate compute_dp(mid) and tighten [lo, hi] toward target_k.
      #|TERMINATION:
      #|After 100 iterations, hi is a stable penalty for the target regime.
    ),
  }
  let (cost, k) = compute_dp(hi)
  cost - k.to_int64() * hi
}

///|
test "aliens trick structure" {
  // Simple test: just verify the structure works
  // Simplified: more penalty means fewer items
  let compute = lambda => if lambda < 0L {
    (100L, 5)
  } else if lambda < 10L {
    (50L, 3)
  } else {
    (20L, 1)
  }
  let result = aliens_trick(10, 3, compute)
  // Should find lambda around 0-10 where k=3
  assert_true(result >= 0L)
}

///|
/// Slope Trick
///
/// For piecewise linear convex functions, maintain the "slope changes"
/// efficiently using priority queues.
///
/// This implementation shows the concept with arrays.
priv struct SlopeTrick {
  left_slopes : Array[Int64] // Max-heap of x where slope increases
  right_slopes : Array[Int64] // Min-heap of x where slope decreases
  mut base_cost : Int64
}

///|
fn SlopeTrick::new() -> SlopeTrick {
  { left_slopes: [], right_slopes: [], base_cost: 0L }
}

///|
fn SlopeTrick::push_left(self : SlopeTrick, x : Int64) -> Unit {
  self.left_slopes.push(x)
  // Bubble up (max-heap)
  let mut i = self.left_slopes.length() - 1
  while i > 0 {
    let parent = (i - 1) / 2
    if self.left_slopes[i] > self.left_slopes[parent] {
      let temp = self.left_slopes[i]
      self.left_slopes[i] = self.left_slopes[parent]
      self.left_slopes[parent] = temp
      i = parent
    } else {
      break
    }
  }
}

///|
fn SlopeTrick::push_right(self : SlopeTrick, x : Int64) -> Unit {
  self.right_slopes.push(x)
  // Bubble up (min-heap)
  let mut i = self.right_slopes.length() - 1
  while i > 0 {
    let parent = (i - 1) / 2
    if self.right_slopes[i] < self.right_slopes[parent] {
      let temp = self.right_slopes[i]
      self.right_slopes[i] = self.right_slopes[parent]
      self.right_slopes[parent] = temp
      i = parent
    } else {
      break
    }
  }
}

///|
fn SlopeTrick::pop_left(self : SlopeTrick) -> Int64 {
  if self.left_slopes.length() == 0 {
    return -9223372036854775807L
  }
  let result = self.left_slopes[0]
  let last = match self.left_slopes.pop() {
    Some(v) => v
    None => return result
  }
  if self.left_slopes.length() > 0 {
    self.left_slopes[0] = last
    // Bubble down
    let mut i = 0
    while true {
      let left = 2 * i + 1
      let right = 2 * i + 2
      let mut largest = i
      if left < self.left_slopes.length() &&
        self.left_slopes[left] > self.left_slopes[largest] {
        largest = left
      }
      if right < self.left_slopes.length() &&
        self.left_slopes[right] > self.left_slopes[largest] {
        largest = right
      }
      if largest != i {
        let temp = self.left_slopes[i]
        self.left_slopes[i] = self.left_slopes[largest]
        self.left_slopes[largest] = temp
        i = largest
      } else {
        break
      }
    }
  }
  result
}

///|
fn SlopeTrick::pop_right(self : SlopeTrick) -> Int64 {
  if self.right_slopes.length() == 0 {
    return 9223372036854775807L
  }
  let result = self.right_slopes[0]
  let last = match self.right_slopes.pop() {
    Some(v) => v
    None => return result
  }
  if self.right_slopes.length() > 0 {
    self.right_slopes[0] = last
    // Bubble down
    let mut i = 0
    while true {
      let left = 2 * i + 1
      let right = 2 * i + 2
      let mut smallest = i
      if left < self.right_slopes.length() &&
        self.right_slopes[left] < self.right_slopes[smallest] {
        smallest = left
      }
      if right < self.right_slopes.length() &&
        self.right_slopes[right] < self.right_slopes[smallest] {
        smallest = right
      }
      if smallest != i {
        let temp = self.right_slopes[i]
        self.right_slopes[i] = self.right_slopes[smallest]
        self.right_slopes[smallest] = temp
        i = smallest
      } else {
        break
      }
    }
  }
  result
}

///|
/// Add |x - a| to the function
fn SlopeTrick::add_abs(self : SlopeTrick, a : Int64) -> Unit {
  // Function f(x) += |x - a|
  // This adds slope +1 at x >= a and slope -1 at x < a

  let l = if self.left_slopes.length() > 0 {
    self.left_slopes[0]
  } else {
    -9223372036854775807L
  }
  let r = if self.right_slopes.length() > 0 {
    self.right_slopes[0]
  } else {
    9223372036854775807L
  }
  if a <= l {
    // a is to the left of the minimum range
    self.base_cost = self.base_cost + l - a
    let popped = self.pop_left()
    self.push_left(a)
    self.push_right(popped)
  } else if a >= r {
    // a is to the right of the minimum range
    self.base_cost = self.base_cost + a - r
    let popped = self.pop_right()
    self.push_right(a)
    self.push_left(popped)
  } else {
    // a is within the minimum range
    self.push_left(a)
    self.push_right(a)
  }
}

///|
test "slope trick abs sum" {
  let st = SlopeTrick::new()

  // Add |x - 1| + |x - 3| + |x - 5|
  // Minimum is at x = 3 with value |3-1| + |3-3| + |3-5| = 2 + 0 + 2 = 4
  st.add_abs(1L)
  st.add_abs(3L)
  st.add_abs(5L)
  assert_eq(st.base_cost, 4L)
}
