// ============================================================================
// MO'S ALGORITHM - Offline Range Queries
// ============================================================================
//
// Answers offline range queries in O((n + q) * sqrt(n)) time by
// cleverly ordering queries to minimize element additions/removals.
//
// KEY INSIGHT: Sort queries by (l / sqrt(n), r). This ensures that
// as we process queries, left pointer moves O(n * sqrt(n)) total
// and right pointer moves O(n * sqrt(n)) total.
//
// INVARIANTS:
// 1. Current window [cur_l, cur_r] maintained by add/remove ops
// 2. Queries in same block have l within sqrt(n) of each other
// 3. Right pointer moves monotonically within each block
//
// TIME COMPLEXITY: O((n + q) * sqrt(n) * f) where f is add/remove cost
// SPACE COMPLEXITY: O(n + q)

///|
priv struct Query {
  id : Int
  left : Int
  right : Int
  block : Int
}

///|
fn Query::new(id : Int, left : Int, right : Int, block_size : Int) -> Query {
  { id, left, right, block: left / block_size }
}

///|
/// Sort queries for Mo's algorithm
fn sort_queries(queries : Array[Query]) -> Array[Query] {
  let sorted = queries.copy()
  sorted.sort_by_key(fn(q) {
    // Sort by block, then by right (alternating for optimization)
    (q.block, if q.block % 2 == 0 { q.right } else { -q.right })
  })
  sorted
}

///|
/// Generic Mo's algorithm structure
priv struct MoState {
  n : Int
  arr : Array[Int]
  count : Array[Int]     // Count of each value
  distinct : Int         // Number of distinct values in current window
}

///|
fn MoState::new(arr : Array[Int]) -> MoState {
  let n = arr.length()
  let max_val = for i = 0, m = 0; i < n; {
    continue i + 1, if arr[i] > m { arr[i] } else { m }
  } else {
    m
  }
  { n, arr, count: Array::make(max_val + 1, 0), distinct: 0 }
}

///|
fn MoState::add(self : MoState, idx : Int) -> Unit {
  let val = self.arr[idx]
  if self.count[val] == 0 {
    self.count[val] = 1
    // Can't modify distinct directly, need wrapper
  } else {
    self.count[val] = self.count[val] + 1
  }
}

///|
fn MoState::remove(self : MoState, idx : Int) -> Unit {
  let val = self.arr[idx]
  self.count[val] = self.count[val] - 1
}

///|
/// Count distinct elements in range queries using Mo's algorithm
fn mo_distinct_count(arr : Array[Int], queries : Array[(Int, Int)]) -> Array[Int] {
  let n = arr.length()
  if n == 0 || queries.length() == 0 {
    return Array::make(queries.length(), 0)
  }

  let block_size = isqrt(n)
  let max_val = for i = 0, m = 0; i < n; {
    continue i + 1, if arr[i] > m { arr[i] } else { m }
  } else {
    m
  }

  // Create and sort query objects
  let q_objs = Array::makei(queries.length(), fn(i) {
    let (l, r) = queries[i]
    Query::new(i, l, r, block_size)
  })
  let sorted = sort_queries(q_objs)

  // Process queries
  let count = Array::make(max_val + 1, 0)
  let results = Array::make(queries.length(), 0)

  let (_, _, _) = for i = 0, cur_l = 0, cur_r = -1, distinct = 0; i < sorted.length(); {
    let q = sorted[i]

    // Expand right
    let (new_r, d1) = for r = cur_r + 1, d = distinct; r <= q.right; {
      let val = arr[r]
      let new_d = if count[val] == 0 { d + 1 } else { d }
      count[val] = count[val] + 1
      continue r + 1, new_d
    } else {
      (q.right, d)
    }

    // Shrink right
    let (newer_r, d2) = for r = cur_r, d = d1; r > q.right; {
      let val = arr[r]
      count[val] = count[val] - 1
      let new_d = if count[val] == 0 { d - 1 } else { d }
      continue r - 1, new_d
    } else {
      (q.right, d)
    }

    // Expand left
    let (new_l, d3) = for l = cur_l - 1, d = d2; l >= q.left; {
      let val = arr[l]
      let new_d = if count[val] == 0 { d + 1 } else { d }
      count[val] = count[val] + 1
      continue l - 1, new_d
    } else {
      (q.left, d)
    }

    // Shrink left
    let (newer_l, d4) = for l = cur_l, d = d3; l < q.left; {
      let val = arr[l]
      count[val] = count[val] - 1
      let new_d = if count[val] == 0 { d - 1 } else { d }
      continue l + 1, new_d
    } else {
      (q.left, d)
    }

    results[q.id] = d4
    continue i + 1, newer_l, newer_r, d4
  } else {
    (cur_l, cur_r, distinct)
  }

  results
}

///|
fn isqrt(n : Int) -> Int {
  for x = n, y = (n + 1) / 2; y < x; {
    continue y, (y + n / y) / 2
  } else {
    if x * x > n { x - 1 } else { x }
  }
}

///|
/// Sum in range queries using Mo's algorithm
fn mo_range_sum(arr : Array[Int], queries : Array[(Int, Int)]) -> Array[Int] {
  let n = arr.length()
  if n == 0 || queries.length() == 0 {
    return Array::make(queries.length(), 0)
  }

  let block_size = isqrt(n)

  let q_objs = Array::makei(queries.length(), fn(i) {
    let (l, r) = queries[i]
    Query::new(i, l, r, block_size)
  })
  let sorted = sort_queries(q_objs)

  let results = Array::make(queries.length(), 0)

  let (_, _, _) = for i = 0, cur_l = 0, cur_r = -1, sum = 0; i < sorted.length(); {
    let q = sorted[i]

    // Expand right
    let (new_r, s1) = for r = cur_r + 1, s = sum; r <= q.right; {
      continue r + 1, s + arr[r]
    } else {
      (q.right, s)
    }

    // Shrink right
    let (_, s2) = for r = cur_r, s = s1; r > q.right; {
      continue r - 1, s - arr[r]
    } else {
      (q.right, s)
    }

    // Expand left
    let (new_l, s3) = for l = cur_l - 1, s = s2; l >= q.left; {
      continue l - 1, s + arr[l]
    } else {
      (q.left, s)
    }

    // Shrink left
    let (_, s4) = for l = cur_l, s = s3; l < q.left; {
      continue l + 1, s - arr[l]
    } else {
      (q.left, s)
    }

    results[q.id] = s4
    continue i + 1, new_l, new_r, s4
  } else {
    (cur_l, cur_r, sum)
  }

  results
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "mo distinct count" {
  let arr : Array[Int] = [1, 2, 1, 3, 2, 1]
  let queries : Array[(Int, Int)] = [(0, 2), (1, 4), (0, 5)]
  let results = mo_distinct_count(arr, queries)

  inspect(results[0], content="2") // [1,2,1] -> 2 distinct
  inspect(results[1], content="3") // [2,1,3,2] -> 3 distinct
  inspect(results[2], content="3") // all -> 3 distinct
}

///|
test "mo range sum" {
  let arr : Array[Int] = [1, 2, 3, 4, 5]
  let queries : Array[(Int, Int)] = [(0, 2), (1, 3), (0, 4)]
  let results = mo_range_sum(arr, queries)

  inspect(results[0], content="6")  // 1+2+3
  inspect(results[1], content="9")  // 2+3+4
  inspect(results[2], content="15") // 1+2+3+4+5
}

///|
test "mo single element" {
  let arr : Array[Int] = [5]
  let queries : Array[(Int, Int)] = [(0, 0)]

  let distinct = mo_distinct_count(arr, queries)
  inspect(distinct[0], content="1")

  let sums = mo_range_sum(arr, queries)
  inspect(sums[0], content="5")
}

///|
test "mo empty queries" {
  let arr : Array[Int] = [1, 2, 3]
  let queries : Array[(Int, Int)] = []

  let results = mo_distinct_count(arr, queries)
  inspect(results.length(), content="0")
}

///|
test "mo all same elements" {
  let arr : Array[Int] = [5, 5, 5, 5]
  let queries : Array[(Int, Int)] = [(0, 3), (1, 2)]
  let results = mo_distinct_count(arr, queries)

  inspect(results[0], content="1")
  inspect(results[1], content="1")
}

///|
test "isqrt" {
  inspect(isqrt(1), content="1")
  inspect(isqrt(4), content="2")
  inspect(isqrt(10), content="3")
  inspect(isqrt(100), content="10")
}

///|
test "mo many queries" {
  let arr : Array[Int] = [1, 2, 3, 4, 5, 6, 7, 8]
  let queries : Array[(Int, Int)] = [
    (0, 3), (2, 5), (1, 6), (0, 7), (3, 4)
  ]
  let results = mo_range_sum(arr, queries)

  inspect(results[0], content="10")  // 1+2+3+4
  inspect(results[1], content="18")  // 3+4+5+6
  inspect(results[2], content="27")  // 2+3+4+5+6+7
  inspect(results[3], content="36")  // 1+...+8
  inspect(results[4], content="9")   // 4+5
}
