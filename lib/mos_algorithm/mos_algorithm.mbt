// ============================================================================
// MO'S ALGORITHM - Square Root Decomposition for Offline Range Queries
// ============================================================================
//
// Mo's Algorithm answers multiple range queries on an array in
// O((N + Q) * sqrt(N)) time by cleverly ordering query processing.
//
// KEY INSIGHT: If we process queries in the right order, moving from one
// query's range to the next requires amortized O(sqrt(N)) operations.
//
// HOW IT WORKS:
// 1. Divide the array into blocks of size sqrt(N)
// 2. Sort queries by: (block of left endpoint, right endpoint)
// 3. Maintain current range [curL, curR] and add/remove elements one at a time
// 4. Answer queries in sorted order, then reorder answers by original query index
//
// COMPLEXITY ANALYSIS:
// - Block size B = sqrt(N)
// - There are N/B = sqrt(N) blocks
// - For queries with same left block:
//   - Right endpoint is sorted, moves at most N positions total
// - Left endpoint moves within block, at most B positions per query
// - Total left movement: Q * B = Q * sqrt(N)
// - Total right movement: (N/B) * N = N * sqrt(N)
// - Overall: O((N + Q) * sqrt(N))
//
// EXAMPLE:
// Array: [1, 2, 3, 4, 5, 6, 7, 8, 9]
// Queries: [(0,2), (3,5), (1,4), (6,8)]
// Block size: sqrt(9) = 3
//
// Sorted queries (by block of left, then by right):
// [(0,2), (1,4), (3,5), (6,8)]
//
// Processing:
// 1. Start with empty range
// 2. For (0,2): add elements 0,1,2
// 3. For (1,4): remove 0, add 3,4 (efficient!)
// 4. For (3,5): remove 1,2, add 5
// 5. For (6,8): remove 3,4,5, add 6,7,8
//
// REQUIREMENTS:
// - Queries must be answerable from a "state" that can be updated by
//   adding or removing a single element in O(1) or O(log N)
// - All queries known upfront (offline algorithm)
//
// COMMON APPLICATIONS:
// - Count distinct elements in range
// - Sum/count of elements with specific property
// - Mode (most frequent element) in range
// - Any decomposable function where add/remove is efficient
//
// INVARIANTS:
// 1. Queries are sorted by (left_block, right)
// 2. Current state correctly represents range [curL, curR]
// 3. After processing, all answers are in original query order

///|
/// Query structure for Mo's algorithm
priv struct MoQuery {
  left : Int
  right : Int // inclusive
  index : Int // original query index
}

///|
/// Integer square root
fn isqrt(n : Int) -> Int {
  if n <= 0 {
    return 0
  }
  // INVARIANT: result^2 <= n < (result+1)^2
  for result = 1; result * result <= n; result = result + 1 {

  } else {
    result - 1
  } where {
    invariant: result >= 1 && (result - 1) * (result - 1) <= n,
    reasoning: (
      #|result increases until result^2 > n.
      #|The last valid candidate is result - 1, the floor of sqrt(n).
    ),
  }
}

// ============================================================================
// COUNT DISTINCT ELEMENTS IN RANGE
// ============================================================================

///|
/// Mo's algorithm for counting distinct elements in ranges
priv struct MoDistinct {
  arr : Array[Int]
  n : Int
  block_size : Int
}

///|
fn MoDistinct::new(arr : Array[Int]) -> MoDistinct {
  let n = arr.length()
  let block_size = if n > 0 { isqrt(n) + 1 } else { 1 }
  { arr, n, block_size }
}

///|
/// Answer multiple range queries for distinct element count
/// queries: Array of (left, right) pairs, 0-indexed, inclusive
fn MoDistinct::answer_queries(
  self : MoDistinct,
  queries : Array[(Int, Int)]
) -> Array[Int] {
  let q = queries.length()
  if q == 0 || self.n == 0 {
    return []
  }

  // Create query objects with original indices
  let mo_queries = Array::makei(q, (i) => {
    let (l, r) = queries[i]
    { left: l, right: r, index: i }
  })

  // Sort queries by (left_block, right)
  // INVARIANT: After sort, queries in same block have increasing right
  mo_queries.sort_by(fn(a, b) {
    let block_a = a.left / self.block_size
    let block_b = b.left / self.block_size
    if block_a != block_b {
      block_a - block_b
    } else {
      a.right - b.right
    }
  })

  // Initialize frequency count map
  let freq : Array[Int] = Array::make(100001, 0) // Assuming values 0-100000
  let mut distinct = 0
  let mut cur_l = 0
  let mut cur_r = -1 // Empty range initially

  let answers = Array::make(q, 0)

  // Process queries in sorted order
  for i = 0; i < q; i = i + 1 {
    let query = mo_queries[i]
    let target_l = query.left
    let target_r = query.right

    // Expand right
    // INVARIANT: Each expansion adds one element to the range
    while cur_r < target_r {
      cur_r = cur_r + 1
      let val = self.arr[cur_r]
      if freq[val] == 0 {
        distinct = distinct + 1
      }
      freq[val] = freq[val] + 1
    }

    // Shrink right
    while cur_r > target_r {
      let val = self.arr[cur_r]
      freq[val] = freq[val] - 1
      if freq[val] == 0 {
        distinct = distinct - 1
      }
      cur_r = cur_r - 1
    }

    // Expand left
    while cur_l > target_l {
      cur_l = cur_l - 1
      let val = self.arr[cur_l]
      if freq[val] == 0 {
        distinct = distinct + 1
      }
      freq[val] = freq[val] + 1
    }

    // Shrink left
    while cur_l < target_l {
      let val = self.arr[cur_l]
      freq[val] = freq[val] - 1
      if freq[val] == 0 {
        distinct = distinct - 1
      }
      cur_l = cur_l + 1
    }

    // Store answer at original query index
    answers[query.index] = distinct
  } where {
    invariant: i >= 0 && i <= q && cur_l >= 0 && cur_l <= cur_r + 1 &&
      cur_r < self.n,
    reasoning: (
      #|STATE: freq matches counts in the current range [cur_l, cur_r],
      #|distinct is the number of values with freq > 0.
      #|answers for mo_queries[0..i) are already finalized.
      #|Each while loop updates the range by one element, preserving counts.
    ),
  }

  answers
}

///|
fn MoDistinct::length(self : MoDistinct) -> Int {
  self.n
}

// ============================================================================
// RANGE SUM WITH UPDATES (OFFLINE)
// ============================================================================

///|
/// Mo's algorithm for range sum queries
priv struct MoSum {
  arr : Array[Int64]
  n : Int
  block_size : Int
}

///|
fn MoSum::new(arr : Array[Int64]) -> MoSum {
  let n = arr.length()
  let block_size = if n > 0 { isqrt(n) + 1 } else { 1 }
  { arr, n, block_size }
}

///|
fn MoSum::answer_queries(
  self : MoSum,
  queries : Array[(Int, Int)]
) -> Array[Int64] {
  let q = queries.length()
  if q == 0 || self.n == 0 {
    return []
  }

  let mo_queries = Array::makei(q, (i) => {
    let (l, r) = queries[i]
    { left: l, right: r, index: i }
  })

  mo_queries.sort_by(fn(a, b) {
    let block_a = a.left / self.block_size
    let block_b = b.left / self.block_size
    if block_a != block_b {
      block_a - block_b
    } else {
      a.right - b.right
    }
  })

  let mut current_sum = 0L
  let mut cur_l = 0
  let mut cur_r = -1

  let answers = Array::make(q, 0L)

  for i = 0; i < q; i = i + 1 {
    let query = mo_queries[i]
    let target_l = query.left
    let target_r = query.right

    while cur_r < target_r {
      cur_r = cur_r + 1
      current_sum = current_sum + self.arr[cur_r]
    }

    while cur_r > target_r {
      current_sum = current_sum - self.arr[cur_r]
      cur_r = cur_r - 1
    }

    while cur_l > target_l {
      cur_l = cur_l - 1
      current_sum = current_sum + self.arr[cur_l]
    }

    while cur_l < target_l {
      current_sum = current_sum - self.arr[cur_l]
      cur_l = cur_l + 1
    }

    answers[query.index] = current_sum
  } where {
    invariant: i >= 0 && i <= q && cur_l >= 0 && cur_l <= cur_r + 1 &&
      cur_r < self.n,
    reasoning: (
      #|STATE: current_sum equals sum(arr[cur_l..cur_r]) for the current range.
      #|answers for mo_queries[0..i) are stored at original indices.
      #|Moving cur_l/cur_r adjusts current_sum by a single element each step.
    ),
  }

  answers
}

///|
fn MoSum::length(self : MoSum) -> Int {
  self.n
}

// ============================================================================
// COUNT ELEMENTS IN RANGE [lo, hi]
// ============================================================================

///|
/// Mo's algorithm for counting elements within value range
priv struct MoRangeCount {
  arr : Array[Int]
  n : Int
  block_size : Int
}

///|
fn MoRangeCount::new(arr : Array[Int]) -> MoRangeCount {
  let n = arr.length()
  let block_size = if n > 0 { isqrt(n) + 1 } else { 1 }
  { arr, n, block_size }
}

///|
/// Count elements with value in [lo, hi] for each query range
/// queries: Array of (left, right, lo, hi)
fn MoRangeCount::answer_queries(
  self : MoRangeCount,
  queries : Array[(Int, Int, Int, Int)]
) -> Array[Int] {
  let q = queries.length()
  if q == 0 || self.n == 0 {
    return []
  }

  // For this variant, we need to track frequency of each value
  let freq : Array[Int] = Array::make(100001, 0)

  // Create MoQuery with extended info
  let mo_queries = Array::makei(q, (i) => {
    let (l, r, lo, hi) = queries[i]
    ({ left: l, right: r, index: i }, lo, hi)
  })

  // Sort by Mo ordering
  mo_queries.sort_by(fn(a, b) {
    let (qa, _, _) = a
    let (qb, _, _) = b
    let block_a = qa.left / self.block_size
    let block_b = qb.left / self.block_size
    if block_a != block_b {
      block_a - block_b
    } else {
      qa.right - qb.right
    }
  })

  let mut cur_l = 0
  let mut cur_r = -1
  let answers = Array::make(q, 0)

  for i = 0; i < q; i = i + 1 {
    let (query, lo, hi) = mo_queries[i]
    let target_l = query.left
    let target_r = query.right

    while cur_r < target_r {
      cur_r = cur_r + 1
      let val = self.arr[cur_r]
      freq[val] = freq[val] + 1
    }

    while cur_r > target_r {
      let val = self.arr[cur_r]
      freq[val] = freq[val] - 1
      cur_r = cur_r - 1
    }

    while cur_l > target_l {
      cur_l = cur_l - 1
      let val = self.arr[cur_l]
      freq[val] = freq[val] + 1
    }

    while cur_l < target_l {
      let val = self.arr[cur_l]
      freq[val] = freq[val] - 1
      cur_l = cur_l + 1
    }

    // Count elements in [lo, hi]
    // INVARIANT: freq[v] = count of v in current range [cur_l, cur_r]
    let mut count = 0
    for v = lo; v <= hi && v < 100001; v = v + 1 {
      count = count + freq[v]
    } where {
      invariant: v >= lo && v <= hi && v < 100001,
      reasoning: (
        #|count is the sum of freq[lo..v) over the current range.
        #|The upper bound is clamped by the freq array size.
      ),
    }
    answers[query.index] = count
  } where {
    invariant: i >= 0 && i <= q && cur_l >= 0 && cur_l <= cur_r + 1 &&
      cur_r < self.n,
    reasoning: (
      #|STATE: freq[v] counts occurrences of v in [cur_l, cur_r].
      #|answers for mo_queries[0..i) are finalized in original order.
    ),
  }

  answers
}

///|
fn MoRangeCount::length(self : MoRangeCount) -> Int {
  self.n
}

// ============================================================================
// MODE (MOST FREQUENT ELEMENT) IN RANGE
// ============================================================================

///|
/// Mo's algorithm for finding mode in ranges
priv struct MoMode {
  arr : Array[Int]
  n : Int
  block_size : Int
}

///|
fn MoMode::new(arr : Array[Int]) -> MoMode {
  let n = arr.length()
  let block_size = if n > 0 { isqrt(n) + 1 } else { 1 }
  { arr, n, block_size }
}

///|
/// Find mode (most frequent element) for each query range
/// Returns (mode_value, frequency) for each query
fn MoMode::answer_queries(
  self : MoMode,
  queries : Array[(Int, Int)]
) -> Array[(Int, Int)] {
  let q = queries.length()
  if q == 0 || self.n == 0 {
    return []
  }

  let freq : Array[Int] = Array::make(100001, 0)
  let mut max_freq = 0
  let mut mode = 0

  let mo_queries = Array::makei(q, (i) => {
    let (l, r) = queries[i]
    { left: l, right: r, index: i }
  })

  mo_queries.sort_by(fn(a, b) {
    let block_a = a.left / self.block_size
    let block_b = b.left / self.block_size
    if block_a != block_b {
      block_a - block_b
    } else {
      a.right - b.right
    }
  })

  let mut cur_l = 0
  let mut cur_r = -1
  let answers = Array::make(q, (0, 0))

  // Helper to recalculate mode (needed after removals)
  fn recalc_mode(freq : Array[Int], arr : Array[Int], cur_l : Int, cur_r : Int) -> (Int, Int) {
    let mut max_f = 0
    let mut m = 0
    for i = cur_l; i <= cur_r; i = i + 1 {
      let v = arr[i]
      if freq[v] > max_f || (freq[v] == max_f && v < m) {
        max_f = freq[v]
        m = v
      }
    } where {
      invariant: i >= cur_l && i <= cur_r + 1,
      reasoning: (
        #|max_f/m track the best (highest freq, smallest value tie-break)
        #|among values in arr[cur_l..i).
      ),
    }
    (m, max_f)
  }

  for i = 0; i < q; i = i + 1 {
    let query = mo_queries[i]
    let target_l = query.left
    let target_r = query.right

    while cur_r < target_r {
      cur_r = cur_r + 1
      let val = self.arr[cur_r]
      freq[val] = freq[val] + 1
      if freq[val] > max_freq || (freq[val] == max_freq && val < mode) {
        max_freq = freq[val]
        mode = val
      }
    }

    while cur_r > target_r {
      let val = self.arr[cur_r]
      freq[val] = freq[val] - 1
      cur_r = cur_r - 1
    }

    while cur_l > target_l {
      cur_l = cur_l - 1
      let val = self.arr[cur_l]
      freq[val] = freq[val] + 1
      if freq[val] > max_freq || (freq[val] == max_freq && val < mode) {
        max_freq = freq[val]
        mode = val
      }
    }

    while cur_l < target_l {
      let val = self.arr[cur_l]
      freq[val] = freq[val] - 1
      cur_l = cur_l + 1
    }

    // Recalculate mode after removals (can't efficiently track max decrease)
    let (m, f) = recalc_mode(freq, self.arr, cur_l, cur_r)
    max_freq = f
    mode = m

    answers[query.index] = (mode, max_freq)
  } where {
    invariant: i >= 0 && i <= q && cur_l >= 0 && cur_l <= cur_r + 1 &&
      cur_r < self.n,
    reasoning: (
      #|STATE: freq matches counts in [cur_l, cur_r]; mode/max_freq are
      #|recomputed for the current range before storing each answer.
      #|answers for mo_queries[0..i) are written in original order.
    ),
  }

  answers
}

///|
fn MoMode::length(self : MoMode) -> Int {
  self.n
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "mo distinct basic" {
  let arr : Array[Int] = [1, 2, 1, 3, 2, 1, 4]
  let mo = MoDistinct::new(arr)

  let queries : Array[(Int, Int)] = [(0, 2), (1, 4), (0, 6)]
  let answers = mo.answer_queries(queries)

  // [0,2]: {1,2,1} -> distinct = 2
  // [1,4]: {2,1,3,2} -> distinct = 3
  // [0,6]: {1,2,1,3,2,1,4} -> distinct = 4
  inspect(answers[0], content="2")
  inspect(answers[1], content="3")
  inspect(answers[2], content="4")
}

///|
test "mo distinct single element" {
  let arr : Array[Int] = [5, 5, 5, 5]
  let mo = MoDistinct::new(arr)

  let queries : Array[(Int, Int)] = [(0, 0), (0, 3), (1, 2)]
  let answers = mo.answer_queries(queries)

  inspect(answers[0], content="1")
  inspect(answers[1], content="1")
  inspect(answers[2], content="1")
}

///|
test "mo distinct all different" {
  let arr : Array[Int] = [1, 2, 3, 4, 5]
  let mo = MoDistinct::new(arr)

  let queries : Array[(Int, Int)] = [(0, 4), (1, 3), (2, 2)]
  let answers = mo.answer_queries(queries)

  inspect(answers[0], content="5")
  inspect(answers[1], content="3")
  inspect(answers[2], content="1")
}

///|
test "mo sum basic" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let mo = MoSum::new(arr)

  let queries : Array[(Int, Int)] = [(0, 2), (1, 3), (0, 4)]
  let answers = mo.answer_queries(queries)

  // [0,2]: 1+2+3 = 6
  // [1,3]: 2+3+4 = 9
  // [0,4]: 1+2+3+4+5 = 15
  inspect(answers[0], content="6")
  inspect(answers[1], content="9")
  inspect(answers[2], content="15")
}

///|
test "mo sum single" {
  let arr : Array[Int64] = [42L]
  let mo = MoSum::new(arr)

  let queries : Array[(Int, Int)] = [(0, 0)]
  let answers = mo.answer_queries(queries)

  inspect(answers[0], content="42")
}

///|
test "mo range count" {
  let arr : Array[Int] = [1, 5, 3, 2, 4, 3, 5]
  let mo = MoRangeCount::new(arr)

  // Count elements with value in [2, 4]
  let queries : Array[(Int, Int, Int, Int)] = [(0, 3, 2, 4), (0, 6, 3, 5)]
  let answers = mo.answer_queries(queries)

  // [0,3] with [2,4]: {1,5,3,2} -> {3,2} -> 2
  // [0,6] with [3,5]: {1,5,3,2,4,3,5} -> {5,3,4,3,5} -> 5
  inspect(answers[0], content="2")
  inspect(answers[1], content="5")
}

///|
test "mo mode basic" {
  let arr : Array[Int] = [1, 2, 2, 3, 2, 1, 1, 1]
  let mo = MoMode::new(arr)

  let queries : Array[(Int, Int)] = [(0, 4), (4, 7)]
  let answers = mo.answer_queries(queries)

  // [0,4]: {1,2,2,3,2} -> mode=2, freq=3
  // [4,7]: {2,1,1,1} -> mode=1, freq=3
  let (mode0, freq0) = answers[0]
  let (mode1, freq1) = answers[1]

  inspect(mode0, content="2")
  inspect(freq0, content="3")
  inspect(mode1, content="1")
  inspect(freq1, content="3")
}

///|
test "mo empty queries" {
  let arr : Array[Int] = [1, 2, 3]
  let mo = MoDistinct::new(arr)

  let queries : Array[(Int, Int)] = []
  let answers = mo.answer_queries(queries)

  inspect(answers.length(), content="0")
}

///|
test "mo empty array" {
  let arr : Array[Int] = []
  let mo = MoDistinct::new(arr)

  let queries : Array[(Int, Int)] = [(0, 0)]
  let answers = mo.answer_queries(queries)

  inspect(answers.length(), content="0")
}

///|
test "mo distinct many queries" {
  let arr : Array[Int] = [1, 2, 3, 4, 5, 1, 2, 3, 4, 5]
  let mo = MoDistinct::new(arr)

  let queries : Array[(Int, Int)] = [
    (0, 4),
    (5, 9),
    (0, 9),
    (2, 7),
    (3, 6),
  ]
  let answers = mo.answer_queries(queries)

  // [0,4]: {1,2,3,4,5} -> 5
  // [5,9]: {1,2,3,4,5} -> 5
  // [0,9]: {1,2,3,4,5,1,2,3,4,5} -> 5
  // [2,7]: {3,4,5,1,2,3} -> 5
  // [3,6]: {4,5,1,2} -> 4
  inspect(answers[0], content="5")
  inspect(answers[1], content="5")
  inspect(answers[2], content="5")
  inspect(answers[3], content="5")
  inspect(answers[4], content="4")
}

///|
test "isqrt" {
  inspect(isqrt(0), content="0")
  inspect(isqrt(1), content="1")
  inspect(isqrt(4), content="2")
  inspect(isqrt(9), content="3")
  inspect(isqrt(10), content="3")
  inspect(isqrt(15), content="3")
  inspect(isqrt(16), content="4")
  inspect(isqrt(100), content="10")
}

///|
test "mo sum negative" {
  let arr : Array[Int64] = [-1L, -2L, 3L, -4L, 5L]
  let mo = MoSum::new(arr)

  let queries : Array[(Int, Int)] = [(0, 4), (0, 1), (2, 4)]
  let answers = mo.answer_queries(queries)

  // [0,4]: -1-2+3-4+5 = 1
  // [0,1]: -1-2 = -3
  // [2,4]: 3-4+5 = 4
  inspect(answers[0], content="1")
  inspect(answers[1], content="-3")
  inspect(answers[2], content="4")
}

///|
test "mo length" {
  let arr : Array[Int] = [1, 2, 3, 4, 5]
  let mo = MoDistinct::new(arr)
  inspect(mo.length(), content="5")

  let mo_sum = MoSum::new([1L, 2L, 3L])
  inspect(mo_sum.length(), content="3")

  let mo_range = MoRangeCount::new([1, 2, 3])
  inspect(mo_range.length(), content="3")

  let mo_mode = MoMode::new([1, 2, 2])
  inspect(mo_mode.length(), content="3")
}
