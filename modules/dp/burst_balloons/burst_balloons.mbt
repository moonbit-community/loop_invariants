// ============================================================================
// BURST BALLOONS  -  classic O(n^3) interval DP
// ============================================================================
//
// PROBLEM
//
// A row of `n` balloons with values `nums[0..n-1]`. When you burst the
// `i`-th balloon, you earn `left * nums[i] * right` coins where `left`
// and `right` are the values of the still-alive balloons immediately
// to the left and right of `i` (or `1` if there are none). Find the
// maximum total coins.
//
// THE INSIGHT
//
// Instead of choosing which to burst *first*, pick which to burst
// **last** in a given interval. If `k` is the last balloon left inside
// the open interval `(i, j)`, the coins for that final burst are
// `nums[i] * nums[k] * nums[j]` (because `i` and `j` are still alive
// at that moment).
//
// Let `dp[i][j]` be the max coins achievable from balloons strictly
// between `i` and `j` (where `nums[i]` and `nums[j]` are the boundary
// values). With sentinels `nums[-1] = nums[n] = 1`:
//
//   dp[i][j] = 0                                      if j - i <= 1
//            = max over k in (i, j) of (
//                dp[i][k] + dp[k][j]
//                + nums[i] * nums[k] * nums[j]
//              )
//
// COMPLEXITY
//
//   Time : O(n^3)
//   Space: O(n^2)
//
// THE INVARIANT
//
//   "After all intervals of length L have been processed, dp[i][j]
//    equals the maximum coins reachable from any complete bursting
//    sequence of balloons strictly between i and j."

///|
/// Maximum coins from optimal bursting order.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // [3, 1, 5, 8] -> 167.
///   @debug.assert_eq(@burst_balloons.max_coins([3L, 1L, 5L, 8L]), 167L)
/// }
/// ```
pub fn max_coins(nums : Array[Int64]) -> Int64 {
  let n = nums.length()
  if n == 0 {
    return 0L
  }
  // Pad with sentinel 1s at both ends.
  let v = Array::make(n + 2, 1L)
  for i in 0..<n {
    v[i + 1] = nums[i]
  }
  let m = n + 2
  let dp = Array::makei(m, _ => Array::make(m, 0L))
  for len in 2..<m {
    for i in 0..<(m - len) {
      let j = i + len
      let mut best = 0L
      for k in (i + 1)..<j {
        let cand = dp[i][k] + dp[k][j] + v[i] * v[k] * v[j]
        if cand > best {
          best = cand
        }
      }
      dp[i][j] = best
    }
  }
  dp[0][m - 1]
}

///|
test "classic 3 1 5 8" {
  @debug.assert_eq(max_coins([3L, 1L, 5L, 8L]), 167L)
}

///|
test "empty array" {
  @debug.assert_eq(max_coins([]), 0L)
}

///|
test "single balloon" {
  @debug.assert_eq(max_coins([5L]), 5L)
}

///|
test "two balloons" {
  // [a, b]: optimal is burst b first earning 1*b*1=b, then a earning 1*a*1=a.
  // Or burst a first earning 1*a*b, then b earning 1*b*1=b. Sums to (a*b + b)
  // vs (a + b). Pick max.
  let a = 3L
  let b = 4L
  let expected = if a * b + b > a + b { a * b + b } else { a + b }
  @debug.assert_eq(max_coins([a, b]), expected)
}

///|
test "uniform values" {
  // All 1s: each burst gives 1, n bursts -> n coins.
  @debug.assert_eq(max_coins([1L, 1L, 1L, 1L, 1L]), 5L)
}

///|
test "increasing values" {
  // [1, 2, 3]: burst 2 first (1*2*3 = 6), then 1 (1*1*3 = 3), then 3
  // (1*3*1 = 3) -> 12.
  @debug.assert_eq(max_coins([1L, 2L, 3L]), 12L)
}

///|
test "agrees with brute force for small n" {
  fn brute(nums : Array[Int64]) -> Int64 {
    let n = nums.length()
    if n == 0 {
      return 0L
    }
    let alive = Array::make(n, true)
    fn recurse(nums : Array[Int64], alive : Array[Bool]) -> Int64 {
      let n = nums.length()
      let mut best = 0L
      for i in 0..<n {
        if !alive[i] {
          continue
        }
        let mut left = 1L
        let mut j = i - 1
        while j >= 0 {
          if alive[j] {
            left = nums[j]
            break
          }
          j = j - 1
        }
        let mut right = 1L
        j = i + 1
        while j < n {
          if alive[j] {
            right = nums[j]
            break
          }
          j = j + 1
        }
        alive[i] = false
        let v = left * nums[i] * right + recurse(nums, alive)
        alive[i] = true
        if v > best {
          best = v
        }
      }
      best
    }

    recurse(nums, alive)
  }

  let cases : ReadOnlyArray[Array[Int64]] = [
    [3L, 1L, 5L, 8L],
    [9L, 76L, 64L, 21L],
    [2L, 3L, 2L],
    [1L],
  ]
  for c in cases {
    @debug.assert_eq(max_coins(c), brute(c))
  }
}
