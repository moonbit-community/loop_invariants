// ============================================================================
// SQRT DECOMPOSITION - Balancing Update and Query Complexity
// ============================================================================
//
// Sqrt Decomposition is a technique that divides an array into blocks of size
// √n, enabling O(√n) range queries and updates for many problems.
//
// KEY INSIGHT: By maintaining aggregate information for √n blocks, we can
// answer range queries by:
//   1. Processing O(1) partial blocks at boundaries
//   2. Processing O(√n) complete blocks in the middle
// This balances the work between preprocessing and query answering.
//
// STRUCTURE:
// Array:  [a0, a1, a2 | a3, a4, a5 | a6, a7, a8 | ...]
//          Block 0       Block 1       Block 2
//
// BLOCK INVARIANTS:
// 1. block_size ≈ √n (typically ceil(√n))
// 2. Block i contains elements [i * block_size, min((i+1) * block_size, n))
// 3. Each block maintains precomputed aggregate (sum, min, max, etc.)
//
// TIME COMPLEXITY:
// - Preprocess: O(n)
// - Query: O(√n)
// - Point update: O(1) to O(√n) depending on aggregate
// - Range update: O(√n) with lazy propagation
//
// SPACE: O(n + √n) = O(n)

///|
/// Compute integer square root (ceiling)
fn isqrt_ceil(n : Int) -> Int {
  if n <= 0 {
    return 1
  }
  // Newton's method for integer square root
  // INVARIANT: x is an upper bound on sqrt(n), decreasing toward the answer
  for x = n {
    let next = (x + n / x) / 2
    if next >= x {
      // x is the floor of sqrt(n), return ceiling
      break if x * x >= n { x } else { x + 1 }
    }
    continue next
  } where {
    invariant: x > 0,
    reasoning: (
      #|INVARIANT (Newton convergence):
      #|x remains positive and is an upper bound on sqrt(n). The update
      #|next = (x + n/x)/2 satisfies next <= x when x^2 >= n, so the sequence
      #|is non-increasing and converges to floor(sqrt(n)).
      #|
      #|We return the ceiling by checking whether x^2 already reaches n.
      #|MAINTENANCE:
      #|When next < x, we replace x with a tighter upper bound, preserving
      #|x >= sqrt(n) and moving toward the fixed point.
      #|TERMINATION:
      #|When next >= x, x is stable (floor sqrt), so we adjust to the ceiling.
    ),
  }
}

// ============================================================================
// SQRT DECOMPOSITION FOR RANGE SUM WITH POINT UPDATES
// ============================================================================

///|
/// Sqrt decomposition for range sum queries with O(√n) query and O(1) update
priv struct SqrtSum {
  arr : Array[Int] // Original array
  blocks : Array[Int] // Block sums
  block_size : Int
}

///|
/// Build sqrt decomposition for sum queries
fn SqrtSum::build(arr : Array[Int]) -> SqrtSum {
  let n = arr.length()
  if n == 0 {
    return { arr: [], blocks: [], block_size: 1 }
  }
  let block_size = isqrt_ceil(n)
  let num_blocks = (n + block_size - 1) / block_size
  let blocks = Array::make(num_blocks, 0)

  // INVARIANT: After processing element i, blocks[i/block_size] contains
  // sum of elements from (i/block_size)*block_size to i (inclusive)
  for i = 0; i < n; i = i + 1 {
    let block_idx = i / block_size
    blocks[block_idx] = blocks[block_idx] + arr[i]
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (Block sums):
      #|After processing elements [0..i), each block sum equals the sum of
      #|arr entries assigned to that block within that prefix. Since every
      #|index maps to exactly one block, the invariant accumulates correctly.
      #|MAINTENANCE:
      #|Add arr[i] to its block, extending the prefix sums.
      #|TERMINATION:
      #|At i = n, all blocks contain the total sums for the full array.
    ),
  }
  { arr: arr.copy(), blocks, block_size }
}

///|
/// Query sum in range [l, r]
/// REASONING: We decompose the range into:
///   1. Partial left block: elements from l to end of l's block
///   2. Complete middle blocks: full blocks between l and r's blocks
///   3. Partial right block: elements from start of r's block to r
fn SqrtSum::query(self : SqrtSum, l : Int, r : Int) -> Int {
  if l > r || l < 0 || r >= self.arr.length() {
    return 0
  }
  let left_block = l / self.block_size
  let right_block = r / self.block_size

  // If same block, just sum directly
  if left_block == right_block {
    // LOOP INVARIANT: sum contains sum of arr[l..i)
    let result = for i = l, sum = 0; i <= r; i = i + 1 {
      continue i + 1, sum + self.arr[i]
    } else {
      sum
    } where {
      invariant: i >= l && i <= r + 1,
      reasoning: (
        #|INVARIANT (single block scan):
        #|sum equals the sum of arr[l..i) within the block.
        #|MAINTENANCE:
        #|Add arr[i] and advance i by one.
        #|TERMINATION:
        #|At i = r + 1, sum is the full range sum.
      ),
    }
    return result
  }

  // Sum left partial block
  let left_block_end = (left_block + 1) * self.block_size - 1
  let left_sum = for i = l, sum = 0; i <= left_block_end; i = i + 1 {
    continue i + 1, sum + self.arr[i]
  } else {
    sum
  } where {
    invariant: i >= l && i <= left_block_end + 1,
    reasoning: (
      #|INVARIANT (Left partial):
      #|sum is the sum of arr[l..i) within the left boundary block. This
      #|handles the partial block exactly so no element is missed or double
      #|counted in the final range sum.
      #|MAINTENANCE:
      #|Add arr[i] and advance i, extending the left partial sum.
      #|TERMINATION:
      #|At i = left_block_end + 1, the left boundary is fully summed.
    ),
  }

  // Sum complete middle blocks
  // INVARIANT: sum contains sum of all complete blocks from left_block+1 to b-1
  let middle_sum = for b = left_block + 1, sum = 0; b < right_block; b = b + 1 {
    continue b + 1, sum + self.blocks[b]
  } else {
    sum
  } where {
    invariant: b >= left_block + 1 && b <= right_block,
    reasoning: (
      #|INVARIANT (middle blocks):
      #|sum equals the total of full blocks in [left_block+1, b).
      #|MAINTENANCE:
      #|Add blocks[b] to include the next full block.
      #|TERMINATION:
      #|At b = right_block, all middle blocks are summed.
    ),
  }

  // Sum right partial block
  let right_block_start = right_block * self.block_size
  let right_sum = for i = right_block_start, sum = 0; i <= r; i = i + 1 {
    continue i + 1, sum + self.arr[i]
  } else {
    sum
  } where {
    invariant: i >= right_block_start && i <= r + 1,
    reasoning: (
      #|INVARIANT (Right partial):
      #|sum equals the sum of arr[right_block_start..i) for the right boundary
      #|block, completing the final partial segment of the query.
      #|MAINTENANCE:
      #|Add arr[i] and advance i, extending the right partial sum.
      #|TERMINATION:
      #|At i = r + 1, the right boundary is fully summed.
    ),
  }
  left_sum + middle_sum + right_sum
}

///|
/// Point update: set arr[i] = val
fn SqrtSum::update(self : SqrtSum, i : Int, val : Int) -> Unit {
  if i < 0 || i >= self.arr.length() {
    return
  }
  let block_idx = i / self.block_size
  let diff = val - self.arr[i]
  self.arr[i] = val
  self.blocks[block_idx] = self.blocks[block_idx] + diff
}

///|
fn SqrtSum::get(self : SqrtSum, i : Int) -> Int {
  self.arr[i]
}

///|
fn SqrtSum::length(self : SqrtSum) -> Int {
  self.arr.length()
}

// ============================================================================
// SQRT DECOMPOSITION FOR RANGE MINIMUM WITH LAZY RANGE UPDATE
// ============================================================================

///|
/// Sqrt decomposition for range minimum queries with lazy range updates
priv struct SqrtMin {
  arr : Array[Int] // Original array
  blocks : Array[Int] // Block minimums
  pending : Array[Int] // Lazy add for each block (0 = no pending update)
  block_size : Int
}

///|
fn SqrtMin::build(arr : Array[Int]) -> SqrtMin {
  let n = arr.length()
  if n == 0 {
    return { arr: [], blocks: [], pending: [], block_size: 1 }
  }
  let block_size = isqrt_ceil(n)
  let num_blocks = (n + block_size - 1) / block_size
  let blocks = Array::make(num_blocks, 2147483647) // Max int as initial min
  let pending = Array::make(num_blocks, 0)

  // INVARIANT: blocks[b] contains minimum of block b's elements
  for i = 0; i < n; i = i + 1 {
    let block_idx = i / block_size
    if arr[i] < blocks[block_idx] {
      blocks[block_idx] = arr[i]
    }
  } where {
    invariant: i >= 0,
    reasoning: (
      #|INVARIANT (Block minima):
      #|After processing elements [0..i), blocks[b] is the minimum of all
      #|arr indices in that block that lie within the processed prefix.
      #|By scanning all indices, each block minimum becomes correct.
      #|MAINTENANCE:
      #|Update the current block minimum with arr[i] if needed.
      #|TERMINATION:
      #|At i = n, all blocks have the correct minimums.
    ),
  }
  { arr: arr.copy(), blocks, pending, block_size }
}

///|
/// Get actual value at index i (applying lazy propagation)
fn SqrtMin::get_value(self : SqrtMin, i : Int) -> Int {
  self.arr[i] + self.pending[i / self.block_size]
}

///|
/// Push lazy updates to a block's elements and recompute minimum
fn SqrtMin::push_block(self : SqrtMin, block_idx : Int) -> Unit {
  if self.pending[block_idx] == 0 {
    return
  }
  let start = block_idx * self.block_size
  let end_val = (block_idx + 1) * self.block_size
  let end = if end_val > self.arr.length() {
    self.arr.length()
  } else {
    end_val
  }

  // Apply lazy update to all elements
  for i = start; i < end; i = i + 1 {
    self.arr[i] = self.arr[i] + self.pending[block_idx]
  } where {
    invariant: i >= start && i <= end,
    reasoning: (
      #|INVARIANT (push block):
      #|Elements in [start..i) have had the pending delta applied.
      #|MAINTENANCE:
      #|Add pending[block_idx] to arr[i] and advance.
      #|TERMINATION:
      #|At i = end, the entire block is updated.
    ),
  }
  self.pending[block_idx] = 0
}

///|
/// Recompute minimum for a block after direct element modifications
fn SqrtMin::recompute_block(self : SqrtMin, block_idx : Int) -> Unit {
  let start = block_idx * self.block_size
  let end_val = (block_idx + 1) * self.block_size
  let end = if end_val > self.arr.length() {
    self.arr.length()
  } else {
    end_val
  }
  let min = for i = start, m = 2147483647; i < end; i = i + 1 {
    if self.arr[i] < m {
      continue i + 1, self.arr[i]
    } else {
      continue i + 1, m
    }
  } else {
    m
  } where {
    invariant: i >= start && i <= end,
    reasoning: (
      #|INVARIANT (recompute min):
      #|m is the minimum of self.arr[start..i).
      #|MAINTENANCE:
      #|Compare self.arr[i] against m and update if smaller.
      #|TERMINATION:
      #|At i = end, m is the minimum for the entire block.
    ),
  }
  self.blocks[block_idx] = min
}

///|
/// Query minimum in range [l, r]
fn SqrtMin::query(self : SqrtMin, l : Int, r : Int) -> Int {
  if l > r || l < 0 || r >= self.arr.length() {
    return 2147483647
  }
  let left_block = l / self.block_size
  let right_block = r / self.block_size

  // If same block, scan directly
  if left_block == right_block {
    let pending_add = self.pending[left_block]
    return for i = l, m = 2147483647; i <= r; i = i + 1 {
      let val = self.arr[i] + pending_add
      if val < m {
        continue i + 1, val
      } else {
        continue i + 1, m
      }
    } else {
      m
    } where {
      invariant: i >= l && i <= r + 1,
      reasoning: (
        #|INVARIANT (Single block scan):
        #|m is the minimum of values in arr[l..i), with the block's pending
        #|lazy add applied. This yields the exact minimum for the query range.
        #|MAINTENANCE:
        #|Compare val against m and advance i, extending the scanned prefix.
        #|TERMINATION:
        #|At i = r + 1, m is the minimum on [l, r].
      ),
    }
  }

  // Minimum from left partial block
  let left_add = self.pending[left_block]
  let left_block_end = (left_block + 1) * self.block_size - 1
  let left_min = for i = l, m = 2147483647; i <= left_block_end; i = i + 1 {
    let val = self.arr[i] + left_add
    if val < m {
      continue i + 1, val
    } else {
      continue i + 1, m
    }
  } else {
    m
  } where {
    invariant: i >= l && i <= left_block_end + 1,
    reasoning: (
      #|INVARIANT (Left boundary min):
      #|m tracks the minimum over arr[l..i) within the left partial block,
      #|including the block's pending add.
      #|MAINTENANCE:
      #|Update m with the next value and advance i.
      #|TERMINATION:
      #|At i = left_block_end + 1, the left boundary minimum is complete.
    ),
  }

  // Minimum from complete middle blocks
  let middle_min = for b = left_block + 1, m = 2147483647
                       b < right_block
                       b = b + 1 {
    let block_min = self.blocks[b] + self.pending[b]
    if block_min < m {
      continue b + 1, block_min
    } else {
      continue b + 1, m
    }
  } else {
    m
  } where {
    invariant: b >= left_block + 1 && b <= right_block,
    reasoning: (
      #|INVARIANT (Middle blocks min):
      #|m is the minimum across all complete blocks processed so far, each
      #|using blocks[b] plus its pending lazy value.
      #|MAINTENANCE:
      #|Compare the next block_min against m and advance b.
      #|TERMINATION:
      #|At b = right_block, all full blocks are folded into m.
    ),
  }

  // Minimum from right partial block
  let right_add = self.pending[right_block]
  let right_block_start = right_block * self.block_size
  let right_min = for i = right_block_start, m = 2147483647; i <= r; i = i + 1 {
    let val = self.arr[i] + right_add
    if val < m {
      continue i + 1, val
    } else {
      continue i + 1, m
    }
  } else {
    m
  } where {
    invariant: i >= right_block_start && i <= r + 1,
    reasoning: (
      #|INVARIANT (Right boundary min):
      #|m is the minimum over arr[right_block_start..i) with the pending add
      #|applied, completing the boundary scan.
      #|MAINTENANCE:
      #|Update m with the next value and advance i.
      #|TERMINATION:
      #|At i = r + 1, the right boundary minimum is complete.
    ),
  }

  // Return overall minimum
  let min1 = if left_min < middle_min { left_min } else { middle_min }
  if min1 < right_min {
    min1
  } else {
    right_min
  }
}

///|
/// Range add: add val to all elements in [l, r]
/// REASONING: For partial blocks, we must push lazy and update individually.
/// For complete blocks, we just add to their lazy tag.
fn SqrtMin::range_add(self : SqrtMin, l : Int, r : Int, val : Int) -> Unit {
  if l > r || l < 0 || r >= self.arr.length() {
    return
  }
  let left_block = l / self.block_size
  let right_block = r / self.block_size
  if left_block == right_block {
    // Same block: push lazy and update individually
    self.push_block(left_block)
    for i = l; i <= r; i = i + 1 {
      self.arr[i] = self.arr[i] + val
    } where {
      invariant: i >= l && i <= r + 1,
      reasoning: (
        #|INVARIANT (Single-block update):
        #|All elements in arr[l..i) have been incremented by val. We update
        #|individually because lazy tags are pushed for this block.
        #|MAINTENANCE:
        #|Increment arr[i] and advance i to extend the updated prefix.
        #|TERMINATION:
        #|At i = r + 1, the entire block segment is updated.
      ),
    }
    self.recompute_block(left_block)
    return
  }

  // Left partial block
  self.push_block(left_block)
  let left_block_end = (left_block + 1) * self.block_size - 1
  for i = l; i <= left_block_end; i = i + 1 {
    self.arr[i] = self.arr[i] + val
  } where {
    invariant: i >= l && i <= left_block_end + 1,
    reasoning: (
      #|INVARIANT (Left boundary update):
      #|Elements in arr[l..i) within the left boundary block have been updated
      #|by val after pushing any pending lazy tag.
      #|MAINTENANCE:
      #|Increment arr[i] and advance i to extend the updated prefix.
      #|TERMINATION:
      #|At i = left_block_end + 1, the left boundary update is complete.
    ),
  }
  self.recompute_block(left_block)

  // Complete middle blocks: just update lazy
  for b = left_block + 1; b < right_block; b = b + 1 {
    self.pending[b] = self.pending[b] + val
  } where {
    invariant: b >= left_block + 1 && b <= right_block,
    reasoning: (
      #|INVARIANT (Middle blocks lazy):
      #|All fully covered blocks in [left_block+1..b) have had their lazy
      #|pending tag increased by val, so queries will reflect the update
      #|without touching individual elements.
      #|MAINTENANCE:
      #|Increment pending[b] for the next full block and advance b.
      #|TERMINATION:
      #|At b = right_block, all full blocks are updated lazily.
    ),
  }

  // Right partial block
  self.push_block(right_block)
  let right_block_start = right_block * self.block_size
  for i = right_block_start; i <= r; i = i + 1 {
    self.arr[i] = self.arr[i] + val
  } where {
    invariant: i >= right_block_start && i <= r + 1,
    reasoning: (
      #|INVARIANT (Right boundary update):
      #|Elements in arr[right_block_start..i) have been incremented by val
      #|after pushing the block's lazy tag.
      #|MAINTENANCE:
      #|Increment arr[i] and advance i to extend the updated prefix.
      #|TERMINATION:
      #|At i = r + 1, the right boundary update is complete.
    ),
  }
  self.recompute_block(right_block)
}

///|
fn SqrtMin::length(self : SqrtMin) -> Int {
  self.arr.length()
}

// ============================================================================
// MO'S ALGORITHM - SQRT DECOMPOSITION FOR OFFLINE QUERIES
// ============================================================================
//
// Mo's algorithm is a technique for answering multiple range queries efficiently
// by reordering queries to minimize total pointer movement.
//
// KEY INSIGHT: Sort queries by (l / √n, r) so that:
//   - Left pointer moves O(n√n) total (O(√n) per query within a block)
//   - Right pointer moves O(n) per block, O(n√n) total
//
// Total complexity: O((n + q)√n) for q queries

///|
/// A query with its original index
priv struct MoQuery {
  l : Int
  r : Int
  idx : Int // Original query index for output ordering
}

///|
/// Mo's algorithm solver for distinct count queries
/// Given an array, answer queries "how many distinct elements in [l, r]?"
priv struct MoSolver {
  arr : Array[Int]
  block_size : Int
}

///|
fn MoSolver::new(arr : Array[Int]) -> MoSolver {
  let n = arr.length()
  let block_size = if n > 0 { isqrt_ceil(n) } else { 1 }
  { arr, block_size }
}

///|
/// Answer multiple range distinct count queries using Mo's algorithm
fn MoSolver::solve_distinct(
  self : MoSolver,
  queries : Array[(Int, Int)],
) -> Array[Int] {
  let q = queries.length()
  if q == 0 {
    return []
  }
  let n = self.arr.length()
  if n == 0 {
    return Array::make(q, 0)
  }

  // Find max element to size count array
  let max_val = for i = 0, m = 0; i < n; i = i + 1 {
    if self.arr[i] > m {
      continue i + 1, self.arr[i]
    } else {
      continue i + 1, m
    }
  } else {
    m
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (max scan):
      #|m is the maximum of self.arr[0..i).
      #|MAINTENANCE:
      #|Update m if self.arr[i] is larger, then advance.
      #|TERMINATION:
      #|At i = n, m is the maximum over the array.
    ),
  }

  // Create query objects with indices
  let mo_queries = Array::makei(q, i => {
    let (l, r) = queries[i]
    { l, r, idx: i }
  })

  // Sort queries by (l / block_size, r)
  // This is the key to Mo's algorithm efficiency
  let block_size = self.block_size
  mo_queries.sort_by((a, b) => if a.l / block_size != b.l / block_size {
    a.l / block_size - b.l / block_size
  } else {
    // Alternate direction for better cache behavior (optional optimization)
    a.r - b.r
  })
  let results = Array::make(q, 0)
  let count = Array::make(max_val + 1, 0) // count[v] = occurrences of value v
  let mut distinct = 0
  let mut cur_l = 0
  let mut cur_r = -1 // Start with empty range

  // Process queries in sorted order
  // INVARIANT: distinct = number of distinct values in arr[cur_l..cur_r]
  //            count[v] = occurrences of v in arr[cur_l..cur_r]
  for i = 0; i < q; i = i + 1 {
    let query = mo_queries[i]
    let l = query.l
    let r = query.r

    // Extend right
    // INVARIANT: Each step adds one element, updating count and distinct
    while cur_r < r {
      cur_r = cur_r + 1
      let v = self.arr[cur_r]
      if count[v] == 0 {
        distinct = distinct + 1
      }
      count[v] = count[v] + 1
    }

    // Shrink right
    while cur_r > r {
      let v = self.arr[cur_r]
      count[v] = count[v] - 1
      if count[v] == 0 {
        distinct = distinct - 1
      }
      cur_r = cur_r - 1
    }

    // Shrink left
    while cur_l < l {
      let v = self.arr[cur_l]
      count[v] = count[v] - 1
      if count[v] == 0 {
        distinct = distinct - 1
      }
      cur_l = cur_l + 1
    }

    // Extend left
    while cur_l > l {
      cur_l = cur_l - 1
      let v = self.arr[cur_l]
      if count[v] == 0 {
        distinct = distinct + 1
      }
      count[v] = count[v] + 1
    }
    results[query.idx] = distinct
  } where {
    invariant: cur_l >= 0 && cur_l <= n,
    reasoning: (
      #|INVARIANT (Left pointer bounds):
      #|cur_l stays within [0, n] as we move it toward each query's left bound.
      #|MAINTENANCE:
      #|cur_l only moves by +/-1 within [0, n].
      #|TERMINATION:
      #|At loop end, cur_l matches the current query's left bound.
    ),
    invariant: cur_r >= -1 && cur_r < n,
    reasoning: (
      #|INVARIANT (Right pointer bounds):
      #|cur_r stays within [-1, n-1], with -1 representing the empty range.
      #|MAINTENANCE:
      #|cur_r only moves by +/-1 within [-1, n-1].
      #|TERMINATION:
      #|At loop end, cur_r matches the current query's right bound.
    ),
    invariant: distinct >= 0,
    reasoning: (
      #|INVARIANT (Distinct count):
      #|distinct equals the number of values with count[v] > 0 in the current
      #|window. Every increment/decrement updates count and distinct in sync,
      #|so distinct never becomes negative.
      #|MAINTENANCE:
      #|Each pointer move updates count[v] and adjusts distinct exactly when
      #|a value enters or leaves the window.
      #|TERMINATION:
      #|At loop end, distinct matches the current query's window.
    ),
  }
  results
}

// ============================================================================
// CHTHOLLY TREE (ODT) - SQRT-LIKE INTERVAL MANAGEMENT
// ============================================================================
//
// The Chtholly Tree (named after a character) or Interval Container is a
// technique for handling range assignment operations efficiently.
//
// KEY INSIGHT: Range assignment creates uniformly-valued intervals.
// We maintain these intervals explicitly and merge/split as needed.
// Under random data, the expected number of intervals is O(n/q) where q is
// number of assign operations, making queries O(√n) expected.

///|
/// An interval [l, r] with value v
priv struct Interval {
  l : Int
  mut r : Int
  mut v : Int
}

///|
/// Interval container for range assignment + range query problems
priv struct IntervalTree {
  intervals : Array[Interval]
}

///|
fn IntervalTree::new(arr : Array[Int]) -> IntervalTree {
  let intervals : Array[Interval] = []
  if arr.length() == 0 {
    return { intervals, }
  }

  // Initially, each element is its own interval
  // We can compress consecutive equal elements
  let mut start = 0
  for i = 1; i <= arr.length(); i = i + 1 {
    if i == arr.length() || arr[i] != arr[start] {
      intervals.push({ l: start, r: i - 1, v: arr[start] })
      start = i
    }
  } where {
    invariant: i >= 1 && i <= arr.length() + 1,
    reasoning: (
      #|INVARIANT (Run compression):
      #|i scans one past the array end as a sentinel. When the value changes
      #|or we hit the sentinel, we close the run [start, i-1] as one interval.
      #|MAINTENANCE:
      #|If the run continues, increment i; if it ends, emit the interval and
      #|reset start to the new run.
      #|TERMINATION:
      #|At i = arr.length() + 1, all runs are emitted.
    ),
    invariant: start >= 0 && start <= i,
    reasoning: (
      #|INVARIANT (Run start):
      #|start is the first index of the current equal-value run, so
      #|arr[start..i) all share the same value.
      #|MAINTENANCE:
      #|start changes only when a run ends, keeping start at the next run's
      #|first index.
      #|TERMINATION:
      #|At loop end, start is positioned at the sentinel boundary.
    ),
  }
  { intervals, }
}

///|
/// Find interval containing position pos
fn IntervalTree::find_interval(self : IntervalTree, pos : Int) -> Int? {
  // Binary search for interval containing pos
  for lo = 0, hi = self.intervals.length() - 1; lo <= hi; {
    let mid = (lo + hi) / 2
    let interval = self.intervals[mid]
    if pos < interval.l {
      continue lo, mid - 1
    } else if pos > interval.r {
      continue mid + 1, hi
    } else {
      break Some(mid)
    }
  } else {
    None
  } where {
    invariant: lo >= 0 && hi >= -1,
    reasoning: (
      #|INVARIANT (Binary search window):
      #|Intervals containing pos, if any, must lie in index range [lo, hi].
      #|When hi < lo, the range is empty and no interval contains pos.
      #|MAINTENANCE:
      #|Each comparison discards half the window while preserving all
      #|possible intervals that could contain pos.
      #|TERMINATION:
      #|When lo > hi, no interval contains pos.
    ),
    invariant: hi < self.intervals.length(),
    reasoning: (
      #|INVARIANT (Index bounds):
      #|hi remains within valid indices or becomes -1 when the search window
      #|is empty, so array accesses stay safe.
      #|MAINTENANCE:
      #|Updates keep hi within [-1, length-1].
      #|TERMINATION:
      #|At exit, hi has moved past lo or a match is found.
    ),
  }
}

///|
/// Split interval at position pos, ensuring pos is start of some interval
/// Returns index of interval starting at pos
fn IntervalTree::split_at(self : IntervalTree, pos : Int) -> Int {
  if pos < 0 {
    return 0
  }
  match self.find_interval(pos) {
    None => self.intervals.length()
    Some(idx) => {
      let interval = self.intervals[idx]
      if interval.l == pos {
        idx
      } else {
        // Split: [l, r] -> [l, pos-1], [pos, r]
        let new_interval : Interval = { l: pos, r: interval.r, v: interval.v }
        self.intervals[idx].r = pos - 1
        // Insert new interval after idx
        self.intervals.insert(idx + 1, new_interval)
        idx + 1
      }
    }
  }
}

///|
/// Assign value v to range [l, r]
fn IntervalTree::assign(self : IntervalTree, l : Int, r : Int, v : Int) -> Unit {
  if l > r || self.intervals.length() == 0 {
    return
  }

  // Split at r+1 first (to not invalidate l's index)
  let _ = self.split_at(r + 1)
  let left_idx = self.split_at(l)

  // Find rightmost interval in [l, r]
  let right_idx = for i = left_idx
                      i < self.intervals.length() && self.intervals[i].l <= r
                      i = i + 1 {
    continue i + 1
  } else {
    i - 1
  } where {
    invariant: i >= left_idx && i <= self.intervals.length() + 1,
    reasoning: (
      #|INVARIANT (Right boundary scan):
      #|i advances while interval starts are <= r, so i-1 is the last interval
      #|that intersects [l, r]. This identifies the range to replace.
      #|MAINTENANCE:
      #|Advance i while the interval start remains within the assignment range.
      #|TERMINATION:
      #|When the condition fails, i-1 is the last overlapping interval.
    ),
  }
  if right_idx >= left_idx {
    // Remove intervals from left_idx to right_idx
    // and replace with single interval [l, r] with value v
    // Using multiple removes (simple but O(n) per remove)
    let num_to_remove = right_idx - left_idx + 1
    for j = 0; j < num_to_remove; j = j + 1 {
      let _ = self.intervals.remove(left_idx)

    } where {
      invariant: j >= 0 && j <= num_to_remove,
      reasoning: (
        #|INVARIANT (Interval removal):
        #|After removing j intervals, all original intervals in [left_idx, left_idx+j)
        #|have been deleted. This clears the overlapping range so the new
        #|single interval can be inserted.
        #|MAINTENANCE:
        #|Remove one more interval at left_idx, increasing j by one.
        #|TERMINATION:
        #|At j = num_to_remove, the entire overlapping range is cleared.
      ),
    }
    self.intervals.insert(left_idx, { l, r, v })
  }
}

///|
/// Query sum in range [l, r]
fn IntervalTree::query_sum(self : IntervalTree, l : Int, r : Int) -> Int {
  if l > r || self.intervals.length() == 0 {
    return 0
  }
  let sum = for i = 0, s = 0; i < self.intervals.length(); i = i + 1 {
    let interval = self.intervals[i]
    if interval.r < l || interval.l > r {
      continue i + 1, s
    }
    // Interval overlaps [l, r]
    let left_bound = if interval.l > l { interval.l } else { l }
    let right_bound = if interval.r < r { interval.r } else { r }
    let cnt = right_bound - left_bound + 1
    continue i + 1, s + cnt * interval.v
  } else {
    s
  } where {
    invariant: i >= 0 && i <= self.intervals.length(),
    reasoning: (
      #|INVARIANT (Sum accumulation):
      #|s equals the total contribution of all processed intervals that
      #|overlap [l, r]. Non-overlapping intervals contribute 0.
      #|MAINTENANCE:
      #|Add the contribution of interval i if it overlaps [l, r].
      #|TERMINATION:
      #|At i = intervals.length(), s is the full range sum.
    ),
  }
  sum
}

///|
/// Add val to all elements in range [l, r]
fn IntervalTree::range_add(
  self : IntervalTree,
  l : Int,
  r : Int,
  val : Int,
) -> Unit {
  if l > r || self.intervals.length() == 0 {
    return
  }
  let _ = self.split_at(r + 1)
  let left_idx = self.split_at(l)
  for i = left_idx
      i < self.intervals.length() && self.intervals[i].l <= r
      i = i + 1 {
    self.intervals[i].v = self.intervals[i].v + val
  } where {
    invariant: i >= left_idx && i <= self.intervals.length() + 1,
    reasoning: (
      #|INVARIANT (Range add):
      #|All intervals in [left_idx, i) intersect [l, r] and have been incremented
      #|by val. The split ensures interval boundaries align with l and r.
      #|MAINTENANCE:
      #|Increment the next overlapping interval and advance i.
      #|TERMINATION:
      #|At i where interval.l > r, all affected intervals are updated.
    ),
  }
}

///|
fn IntervalTree::get(self : IntervalTree, pos : Int) -> Int? {
  match self.find_interval(pos) {
    Some(idx) => Some(self.intervals[idx].v)
    None => None
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "sqrt sum basic" {
  let arr = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  let sq = SqrtSum::build(arr)

  // Full range sum
  inspect(sq.query(0, 8), content="45")

  // Partial ranges
  inspect(sq.query(0, 2), content="6") // 1+2+3
  inspect(sq.query(3, 5), content="15") // 4+5+6
  inspect(sq.query(6, 8), content="24") // 7+8+9

  // Single element
  inspect(sq.query(4, 4), content="5")

  // Cross-block query
  inspect(sq.query(2, 6), content="25") // 3+4+5+6+7

  // Test get and length
  inspect(sq.length(), content="9")
  inspect(sq.get(0), content="1")
  inspect(sq.get(4), content="5")
}

///|
test "sqrt sum update" {
  let arr = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  let sq = SqrtSum::build(arr)
  inspect(sq.query(0, 8), content="45")

  // Update element
  sq.update(4, 100) // Change 5 to 100
  inspect(sq.query(0, 8), content="140") // 45 - 5 + 100
  inspect(sq.query(4, 4), content="100")
  inspect(sq.query(3, 5), content="110") // 4 + 100 + 6

  // Another update
  sq.update(0, 10) // Change 1 to 10
  inspect(sq.query(0, 2), content="15") // 10+2+3
}

///|
test "sqrt min basic" {
  let arr = [5, 2, 8, 1, 9, 3, 7, 4, 6]
  let sq = SqrtMin::build(arr)

  // Full range minimum
  inspect(sq.query(0, 8), content="1")

  // Partial ranges
  inspect(sq.query(0, 2), content="2") // min(5,2,8)
  inspect(sq.query(3, 5), content="1") // min(1,9,3)
  inspect(sq.query(6, 8), content="4") // min(7,4,6)

  // Single element
  inspect(sq.query(4, 4), content="9")

  // Test get_value and length
  inspect(sq.length(), content="9")
  inspect(sq.get_value(0), content="5")
  inspect(sq.get_value(3), content="1")
}

///|
test "sqrt min range add" {
  let arr = [5, 2, 8, 1, 9, 3, 7, 4, 6]
  let sq = SqrtMin::build(arr)
  inspect(sq.query(0, 8), content="1")

  // Add 10 to range [3, 5]
  sq.range_add(3, 5, 10)
  // New values: [5, 2, 8, 11, 19, 13, 7, 4, 6]
  inspect(sq.query(3, 5), content="11") // min(11, 19, 13)
  inspect(sq.query(0, 8), content="2") // min is now 2

  // Add -5 to all
  sq.range_add(0, 8, -5)
  // New values: [0, -3, 3, 6, 14, 8, 2, -1, 1]
  inspect(sq.query(0, 8), content="-3")
}

///|
test "mo algorithm distinct" {
  let arr = [1, 2, 1, 3, 2, 1, 4, 1, 2]
  let solver = MoSolver::new(arr)
  let queries = [(0, 2), (0, 4), (0, 8), (3, 6), (5, 8)]
  let results = solver.solve_distinct(queries)

  // [0,2] = [1,2,1]: 2 distinct (1, 2)
  // [0,4] = [1,2,1,3,2]: 3 distinct (1, 2, 3)
  // [0,8] = all: 4 distinct (1, 2, 3, 4)
  // [3,6] = [3,2,1,4]: 4 distinct
  // [5,8] = [1,4,1,2]: 3 distinct (1, 2, 4)
  inspect(results, content="[2, 3, 4, 4, 3]")
}

///|
test "mo algorithm empty" {
  let arr : Array[Int] = []
  let solver = MoSolver::new(arr)
  let results = solver.solve_distinct([])
  inspect(results, content="[]")
  let arr2 = [1, 2, 3]
  let solver2 = MoSolver::new(arr2)
  let results2 = solver2.solve_distinct([])
  inspect(results2, content="[]")
}

///|
test "interval tree assign" {
  let arr = [1, 1, 1, 1, 1, 1, 1, 1]
  let tree = IntervalTree::new(arr)

  // Query initial sum
  inspect(tree.query_sum(0, 7), content="8")

  // Assign 5 to [2, 5]
  tree.assign(2, 5, 5)
  // Array: [1, 1, 5, 5, 5, 5, 1, 1]
  inspect(tree.query_sum(0, 7), content="24") // 2 + 20 + 2
  inspect(tree.query_sum(2, 5), content="20") // 4 * 5

  // Assign 10 to [4, 6]
  tree.assign(4, 6, 10)
  // Array: [1, 1, 5, 5, 10, 10, 10, 1]
  inspect(tree.query_sum(0, 7), content="43") // 2 + 10 + 30 + 1
}

///|
test "interval tree range add" {
  let arr = [1, 2, 3, 4, 5]
  let tree = IntervalTree::new(arr)
  inspect(tree.query_sum(0, 4), content="15")

  // Add 10 to [1, 3]
  tree.range_add(1, 3, 10)
  // Array: [1, 12, 13, 14, 5]
  inspect(tree.query_sum(0, 4), content="45")
  inspect(tree.query_sum(1, 3), content="39")
}

///|
test "interval tree get" {
  let arr = [1, 2, 3, 4, 5]
  let tree = IntervalTree::new(arr)
  inspect(tree.get(0), content="Some(1)")
  inspect(tree.get(2), content="Some(3)")
  inspect(tree.get(4), content="Some(5)")
  tree.assign(1, 3, 100)
  inspect(tree.get(0), content="Some(1)")
  inspect(tree.get(1), content="Some(100)")
  inspect(tree.get(2), content="Some(100)")
  inspect(tree.get(3), content="Some(100)")
  inspect(tree.get(4), content="Some(5)")
}

///|
test "isqrt ceil" {
  // Test integer square root ceiling
  fn test_isqrt(n : Int) -> Int {
    isqrt_ceil(n)
  }

  inspect(test_isqrt(1), content="1")
  inspect(test_isqrt(4), content="2")
  inspect(test_isqrt(5), content="3") // ceil(sqrt(5)) = 3
  inspect(test_isqrt(9), content="3")
  inspect(test_isqrt(10), content="4") // ceil(sqrt(10)) = 4
  inspect(test_isqrt(16), content="4")
  inspect(test_isqrt(100), content="10")
}

///|
test "sqrt decomposition stress" {
  // Test with larger array
  let arr = Array::makei(100, i => i + 1)
  let sq = SqrtSum::build(arr)

  // Sum 1 to 100 = 5050
  inspect(sq.query(0, 99), content="5050")

  // Sum 1 to 50 = 1275
  inspect(sq.query(0, 49), content="1275")

  // Sum 51 to 100 = 3775
  inspect(sq.query(50, 99), content="3775")

  // Update and verify
  sq.update(49, 1000) // Change 50 to 1000
  inspect(sq.query(0, 99), content="6000") // 5050 - 50 + 1000
}
