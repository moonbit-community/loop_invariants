// ============================================================================
// MO'S ALGORITHM - Offline Range Query Processing with Sqrt Decomposition
// ============================================================================
//
// Mo's algorithm answers multiple range queries on a static array by
// reordering queries to minimize the cost of transitioning between them.
//
// KEY INSIGHT: Group queries by blocks of size √n on the left endpoint.
// Within each block, sort by right endpoint. This ensures:
// - Left pointer moves O(√n) per query within a block
// - Right pointer moves O(n) per block (monotonic within block)
// - Total: O((n + q) * √n)
//
// ALGORITHM:
// 1. Divide queries into √n blocks based on left endpoint
// 2. Within each block, sort queries by right endpoint
// 3. Process queries in this order, maintaining current [l, r] answer
// 4. Transition between queries by adding/removing elements
//
// OPERATIONS:
// - add(x): Include element x in current range
// - remove(x): Exclude element x from current range
// These must be O(1) or O(log n) for the algorithm to be efficient.
//
// EXAMPLE: Distinct element count queries
// add(x): if count[x]++ == 0, distinct++
// remove(x): if --count[x] == 0, distinct--
//
// WHY SQRT WORKS:
// - Left pointer: within block moves ≤ √n, across blocks also ≤ √n per query
//   Total left moves: O(q * √n)
// - Right pointer: within block monotonic, so O(n) per block
//   Total right moves: O(√n * n) = O(n√n)
// - Combined: O((n + q) * √n)
//
// INVARIANTS:
// 1. Queries processed in Mo order minimize transitions
// 2. Current answer reflects elements in [curr_l, curr_r]
// 3. Block size √n balances left and right pointer movements
//
// TIME COMPLEXITY: O((n + q) * √n)
// SPACE COMPLEXITY: O(n + q)

///|
priv struct MoQuery {
  l : Int
  r : Int // Inclusive range [l, r]
  idx : Int // Original query index for result ordering
}

///|
/// Mo's algorithm state for distinct element counting
priv struct MoDistinct {
  arr : Array[Int]
  block_size : Int
  mut curr_l : Int
  mut curr_r : Int
  mut distinct : Int
  count : Array[Int] // count[x] = occurrences of x in current range
}

///|
fn isqrt(n : Int) -> Int {
  if n <= 0 {
    return 0
  }
  for x = n, y = (n + 1) / 2; y < x; {
    continue y, (y + n / y) / 2
  } nobreak {
    x
  }
}

///|
fn max_element(arr : Array[Int]) -> Int {
  let mx = for i in 0..<arr.length(); mx = 0 {
    let mx = if arr[i] > mx { arr[i] } else { mx }
    continue mx
  } nobreak {
    mx
  } where {
    proof_invariant: i >= 0 && i <= arr.length(),
    proof_reasoning: (
      #|INVARIANT (max scan):
      #|mx equals the maximum value in arr[0..i).
      #|MAINTENANCE:
      #|Compare arr[i] against mx and update if larger.
      #|TERMINATION:
      #|At i = arr.length(), mx is the maximum element of the array.
    ),
  }
  mx
}

///|
/// Create Mo's algorithm solver for distinct element queries
fn MoDistinct::MoDistinct(arr : Array[Int]) -> MoDistinct {
  let n = arr.length()
  let block_size = if n > 0 { isqrt(n) } else { 1 }
  let max_val = max_element(arr) + 1
  {
    arr,
    block_size,
    curr_l: 0,
    curr_r: -1,
    distinct: 0,
    count: Array::make(max_val + 1, 0),
  }
}

///|
fn MoDistinct::add(self : MoDistinct, idx : Int) -> Unit {
  let x = self.arr[idx]
  if self.count[x] == 0 {
    self.distinct = self.distinct + 1
  }
  self.count[x] = self.count[x] + 1
}

///|
fn MoDistinct::remove(self : MoDistinct, idx : Int) -> Unit {
  let x = self.arr[idx]
  self.count[x] = self.count[x] - 1
  if self.count[x] == 0 {
    self.distinct = self.distinct - 1
  }
}

///|
/// Process queries and return results in original order
fn MoDistinct::process_queries(
  self : MoDistinct,
  queries : Array[(Int, Int)],
) -> Array[Int] {
  let q = queries.length()
  if q == 0 {
    return []
  }

  // Create query objects with indices
  let mo_queries : Array[MoQuery] = []
  for i in 0..<q {
    let (l, r) = queries[i]
    mo_queries.push({ l, r, idx: i })
  } where {
    proof_invariant: i >= 0 && i <= q,
    proof_reasoning: (
      #|INVARIANT (query prep):
      #|mo_queries contains converted queries for indices [0, i), preserving
      #|their original positions in idx.
      #|MAINTENANCE:
      #|Convert queries[i] to MoQuery and append.
      #|TERMINATION:
      #|At i = q, all queries are ready for Mo ordering.
    ),
  }

  // Sort by Mo's order: block of left endpoint, then right endpoint
  let block_size = self.block_size
  mo_queries.sort_by((a, b) => {
    if a.l / block_size != b.l / block_size {
      a.l / block_size - b.l / block_size
      // Alternate direction for better cache performance
    } else if a.l / block_size % 2 == 0 {
      a.r - b.r
    } else {
      b.r - a.r
    }
  })
  let results = Array::make(q, 0)
  for i in 0..<q {
    let query = mo_queries[i]

    // Expand right
    for expand_right = self.curr_r < query.r; expand_right; {
      self.curr_r = self.curr_r + 1
      self.add(self.curr_r)
      continue self.curr_r < query.r
    }

    // Shrink right
    for shrink_right = self.curr_r > query.r; shrink_right; {
      self.remove(self.curr_r)
      self.curr_r = self.curr_r - 1
      continue self.curr_r > query.r
    }

    // Expand left
    for expand_left = self.curr_l > query.l; expand_left; {
      self.curr_l = self.curr_l - 1
      self.add(self.curr_l)
      continue self.curr_l > query.l
    }

    // Shrink left
    for shrink_left = self.curr_l < query.l; shrink_left; {
      self.remove(self.curr_l)
      self.curr_l = self.curr_l + 1
      continue self.curr_l < query.l
    }
    results[query.idx] = self.distinct
  } where {
    proof_invariant: i >= 0 && i <= q,
    proof_reasoning: (
      #|INVARIANT (process queries):
      #|Before processing query i, curr_l..curr_r matches the previous query
      #|range and distinct reflects counts within that range.
      #|MAINTENANCE:
      #|Adjust curr_l/curr_r to the new [l, r] by add/remove operations, which
      #|updates counts and distinct in O(1) per move. Mo ordering bounds total
      #|pointer movement to O((n + q) * sqrt(n)).
      #|TERMINATION:
      #|At i = q, every query has been answered and stored at its original index.
    ),
  }
  results
}

// ============================================================================
// MO'S ALGORITHM FOR RANGE SUM
// ============================================================================

///|
priv struct MoSum {
  arr : Array[Int64]
  block_size : Int
  mut curr_l : Int
  mut curr_r : Int
  mut sum : Int64
}

///|
fn MoSum::MoSum(arr : Array[Int64]) -> MoSum {
  let n = arr.length()
  let block_size = if n > 0 { isqrt(n) } else { 1 }
  { arr, block_size, curr_l: 0, curr_r: -1, sum: 0L }
}

///|
fn MoSum::add(self : MoSum, idx : Int) -> Unit {
  self.sum = self.sum + self.arr[idx]
}

///|
fn MoSum::remove(self : MoSum, idx : Int) -> Unit {
  self.sum = self.sum - self.arr[idx]
}

///|
fn MoSum::process_queries(
  self : MoSum,
  queries : Array[(Int, Int)],
) -> Array[Int64] {
  let q = queries.length()
  if q == 0 {
    return []
  }
  let mo_queries : Array[MoQuery] = []
  for i in 0..<q {
    let (l, r) = queries[i]
    mo_queries.push({ l, r, idx: i })
  } where {
    proof_invariant: i >= 0 && i <= q,
    proof_reasoning: (
      #|INVARIANT (query prep):
      #|mo_queries contains converted queries for indices [0, i), preserving
      #|their original positions in idx.
      #|MAINTENANCE:
      #|Convert queries[i] to MoQuery and append.
      #|TERMINATION:
      #|At i = q, all queries are ready for Mo ordering.
    ),
  }
  let block_size = self.block_size
  mo_queries.sort_by((a, b) => {
    if a.l / block_size != b.l / block_size {
      a.l / block_size - b.l / block_size
    } else if a.l / block_size % 2 == 0 {
      a.r - b.r
    } else {
      b.r - a.r
    }
  })
  let results = Array::make(q, 0L)
  for i in 0..<q {
    let query = mo_queries[i]
    for expand_right = self.curr_r < query.r; expand_right; {
      self.curr_r = self.curr_r + 1
      self.add(self.curr_r)
      continue self.curr_r < query.r
    }
    for shrink_right = self.curr_r > query.r; shrink_right; {
      self.remove(self.curr_r)
      self.curr_r = self.curr_r - 1
      continue self.curr_r > query.r
    }
    for expand_left = self.curr_l > query.l; expand_left; {
      self.curr_l = self.curr_l - 1
      self.add(self.curr_l)
      continue self.curr_l > query.l
    }
    for shrink_left = self.curr_l < query.l; shrink_left; {
      self.remove(self.curr_l)
      self.curr_l = self.curr_l + 1
      continue self.curr_l < query.l
    }
    results[query.idx] = self.sum
  } where {
    proof_invariant: i >= 0 && i <= q,
    proof_reasoning: (
      #|INVARIANT (process sums):
      #|curr_l..curr_r matches the previous query range, and sum equals the
      #|sum of arr[curr_l..curr_r].
      #|MAINTENANCE:
      #|Move curr_l/curr_r to the new range by add/remove operations, keeping
      #|sum consistent with the current window.
      #|TERMINATION:
      #|At i = q, all query sums are stored at their original indices.
    ),
  }
  results
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "mo distinct basic" {
  let arr = [1, 2, 1, 3, 1, 2, 4]
  let mo = MoDistinct(arr)
  let queries = [(0, 2), (1, 4), (2, 6), (0, 6)]
  let results = mo.process_queries(queries)
  inspect(results[0], content="2") // [1,2,1] -> {1,2}
  inspect(results[1], content="3") // [2,1,3,1] -> {1,2,3}
  inspect(results[2], content="4") // [1,3,1,2,4] -> {1,2,3,4}
  inspect(results[3], content="4") // [1,2,1,3,1,2,4] -> {1,2,3,4}
}

///|
test "mo distinct single element" {
  let arr = [5]
  let mo = MoDistinct(arr)
  let queries = [(0, 0)]
  let results = mo.process_queries(queries)
  inspect(results[0], content="1")
}

///|
test "mo distinct all same" {
  let arr = [1, 1, 1, 1, 1]
  let mo = MoDistinct(arr)
  let queries = [(0, 4), (1, 3), (2, 2)]
  let results = mo.process_queries(queries)
  inspect(results[0], content="1")
  inspect(results[1], content="1")
  inspect(results[2], content="1")
}

///|
test "mo distinct all different" {
  let arr = [1, 2, 3, 4, 5]
  let mo = MoDistinct(arr)
  let queries = [(0, 4), (0, 2), (3, 4)]
  let results = mo.process_queries(queries)
  inspect(results[0], content="5")
  inspect(results[1], content="3")
  inspect(results[2], content="2")
}

///|
test "mo sum basic" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let mo = MoSum(arr)
  let queries = [(0, 4), (1, 3), (2, 2)]
  let results = mo.process_queries(queries)
  inspect(results[0], content="15") // 1+2+3+4+5
  inspect(results[1], content="9") // 2+3+4
  inspect(results[2], content="3") // 3
}

///|
test "mo empty queries" {
  let arr = [1, 2, 3]
  let mo = MoDistinct(arr)
  let results = mo.process_queries([])
  inspect(results.length(), content="0")
}

///|
test "mo large block" {
  // Test with more elements to verify sqrt blocking
  let arr : Array[Int] = [ for i in 0..<100 => i % 10 ]
  let mo = MoDistinct(arr)
  let queries = [(0, 99), (0, 9), (50, 59), (25, 75)]
  let results = mo.process_queries(queries)
  inspect(results[0], content="10") // All 0-9
  inspect(results[1], content="10") // 0-9
  inspect(results[2], content="10") // 0-9
  inspect(results[3], content="10") // 0-9
}
