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
  let mut x = n
  let mut y = (x + 1) / 2
  while y < x {
    x = y
    y = (x + n / x) / 2
  }
  x
}

///|
fn max_element(arr : Array[Int]) -> Int {
  let mut mx = 0
  for i = 0; i < arr.length(); i = i + 1 {
    if arr[i] > mx {
      mx = arr[i]
    }
  }
  mx
}

///|
/// Create Mo's algorithm solver for distinct element queries
fn MoDistinct::new(arr : Array[Int]) -> MoDistinct {
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
fn MoDistinct::process_queries(self : MoDistinct, queries : Array[(Int, Int)]) -> Array[Int] {
  let q = queries.length()
  if q == 0 {
    return []
  }

  // Create query objects with indices
  let mo_queries : Array[MoQuery] = []
  for i = 0; i < q; i = i + 1 {
    let (l, r) = queries[i]
    mo_queries.push({ l, r, idx: i })
  }

  // Sort by Mo's order: block of left endpoint, then right endpoint
  let block_size = self.block_size
  mo_queries.sort_by(fn(a, b) {
    let block_a = a.l / block_size
    let block_b = b.l / block_size
    if block_a != block_b {
      block_a - block_b
    } else {
      // Alternate direction for better cache performance
      if block_a % 2 == 0 { a.r - b.r } else { b.r - a.r }
    }
  })

  let results = Array::make(q, 0)

  for i = 0; i < q; i = i + 1 {
    let query = mo_queries[i]

    // Expand right
    while self.curr_r < query.r {
      self.curr_r = self.curr_r + 1
      self.add(self.curr_r)
    }

    // Shrink right
    while self.curr_r > query.r {
      self.remove(self.curr_r)
      self.curr_r = self.curr_r - 1
    }

    // Expand left
    while self.curr_l > query.l {
      self.curr_l = self.curr_l - 1
      self.add(self.curr_l)
    }

    // Shrink left
    while self.curr_l < query.l {
      self.remove(self.curr_l)
      self.curr_l = self.curr_l + 1
    }

    results[query.idx] = self.distinct
  } where {
    invariant: i >= 0 && i <= q,
    reasoning: "I: i=0, curr range is empty [0, -1]. M: For each query in Mo order, adjust curr_l and curr_r to match query's [l, r] by adding/removing elements. The Mo ordering ensures total pointer movements are O((n+q)√n): within each of √n blocks, right pointer moves monotonically O(n); left pointer moves at most √n per query. T: After i = q, all queries answered with results stored at original indices.",
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
fn MoSum::new(arr : Array[Int64]) -> MoSum {
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
fn MoSum::process_queries(self : MoSum, queries : Array[(Int, Int)]) -> Array[Int64] {
  let q = queries.length()
  if q == 0 {
    return []
  }

  let mo_queries : Array[MoQuery] = []
  for i = 0; i < q; i = i + 1 {
    let (l, r) = queries[i]
    mo_queries.push({ l, r, idx: i })
  }

  let block_size = self.block_size
  mo_queries.sort_by(fn(a, b) {
    let block_a = a.l / block_size
    let block_b = b.l / block_size
    if block_a != block_b {
      block_a - block_b
    } else {
      if block_a % 2 == 0 { a.r - b.r } else { b.r - a.r }
    }
  })

  let results = Array::make(q, 0L)

  for i = 0; i < q; i = i + 1 {
    let query = mo_queries[i]

    while self.curr_r < query.r {
      self.curr_r = self.curr_r + 1
      self.add(self.curr_r)
    }
    while self.curr_r > query.r {
      self.remove(self.curr_r)
      self.curr_r = self.curr_r - 1
    }
    while self.curr_l > query.l {
      self.curr_l = self.curr_l - 1
      self.add(self.curr_l)
    }
    while self.curr_l < query.l {
      self.remove(self.curr_l)
      self.curr_l = self.curr_l + 1
    }

    results[query.idx] = self.sum
  }

  results
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "mo distinct basic" {
  let arr = [1, 2, 1, 3, 1, 2, 4]
  let mo = MoDistinct::new(arr)

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
  let mo = MoDistinct::new(arr)

  let queries = [(0, 0)]
  let results = mo.process_queries(queries)

  inspect(results[0], content="1")
}

///|
test "mo distinct all same" {
  let arr = [1, 1, 1, 1, 1]
  let mo = MoDistinct::new(arr)

  let queries = [(0, 4), (1, 3), (2, 2)]
  let results = mo.process_queries(queries)

  inspect(results[0], content="1")
  inspect(results[1], content="1")
  inspect(results[2], content="1")
}

///|
test "mo distinct all different" {
  let arr = [1, 2, 3, 4, 5]
  let mo = MoDistinct::new(arr)

  let queries = [(0, 4), (0, 2), (3, 4)]
  let results = mo.process_queries(queries)

  inspect(results[0], content="5")
  inspect(results[1], content="3")
  inspect(results[2], content="2")
}

///|
test "mo sum basic" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let mo = MoSum::new(arr)

  let queries = [(0, 4), (1, 3), (2, 2)]
  let results = mo.process_queries(queries)

  inspect(results[0], content="15") // 1+2+3+4+5
  inspect(results[1], content="9") // 2+3+4
  inspect(results[2], content="3") // 3
}

///|
test "mo empty queries" {
  let arr = [1, 2, 3]
  let mo = MoDistinct::new(arr)
  let results = mo.process_queries([])
  inspect(results.length(), content="0")
}

///|
test "mo large block" {
  // Test with more elements to verify sqrt blocking
  let arr : Array[Int] = []
  for i = 0; i < 100; i = i + 1 {
    arr.push(i % 10)
  }

  let mo = MoDistinct::new(arr)
  let queries = [(0, 99), (0, 9), (50, 59), (25, 75)]
  let results = mo.process_queries(queries)

  inspect(results[0], content="10") // All 0-9
  inspect(results[1], content="10") // 0-9
  inspect(results[2], content="10") // 0-9
  inspect(results[3], content="10") // 0-9
}
