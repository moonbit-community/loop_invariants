// ============================================================================
// SQRT DECOMPOSITION - O(√n) Query and Update
// ============================================================================
//
// Sqrt Decomposition divides an array into √n blocks, enabling O(√n) queries
// and updates. Simpler than segment trees, useful when operations are complex.
//
// KEY INSIGHT: Divide array into blocks of size √n. For range queries:
// - Process partial blocks (at most 2) element by element: O(√n)
// - Process complete blocks using precomputed values: O(√n)
// Total: O(√n)
//
// STRUCTURE:
// - blocks[i] = precomputed value for block i
// - block_size = √n
// - block_id(i) = i / block_size
//
// APPLICATIONS:
// 1. Range sum/min/max queries
// 2. Range updates (lazy propagation)
// 3. Mo's algorithm preprocessing
// 4. Problems with complex update operations
//
// INVARIANTS:
// 1. blocks[i] correctly represents aggregate of elements in block i
// 2. block_size ≈ √n balances partial and complete block processing
// 3. After point update, only one block needs rebuilding
//
// TIME COMPLEXITY: O(√n) per query/update
// SPACE COMPLEXITY: O(n)

///|
/// Compute the integer square root of `n` (i.e. `⌊√n⌋`).
///
/// Uses Newton's method, converging in O(log n) iterations.
/// Returns 0 for non-positive inputs.
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

// ============================================================================
// SQRT DECOMPOSITION FOR RANGE SUM
// ============================================================================

///|
/// Sqrt decomposition structure for **range sum queries** with **point updates**.
///
/// The array is divided into contiguous blocks of size `block_size ≈ √n`.
/// Each block stores the sum of its elements so that any range sum `[l, r]`
/// can be answered in O(√n) by combining:
///
/// - a left partial scan (up to `block_size` elements),
/// - O(√n) precomputed block sums in the middle, and
/// - a right partial scan (up to `block_size` elements).
///
/// Fields:
/// - `arr` — copy of the original array, mutated in place by `update`.
/// - `blocks` — `blocks[b]` holds the sum of all elements in block `b`.
/// - `block_size` — number of elements per block, set to `⌊√n⌋` (min 1).
/// - `n` — total number of elements.
pub struct SqrtSum {
  arr : Array[Int64]
  blocks : Array[Int64]
  block_size : Int
  n : Int
}

///|
/// Build a `SqrtSum` from an existing array.
///
/// Copies `arr`, computes `block_size = ⌊√n⌋` (clamped to 1), and initialises
/// each block aggregate in a single O(n) pass.
///
/// Parameters:
/// - `arr` — the source array of `Int64` values.
///
/// Returns a new `SqrtSum` ready for queries and updates.
///
/// Time: O(n).  Space: O(n).
pub fn SqrtSum::new(arr : Array[Int64]) -> SqrtSum {
  let n = arr.length()
  if n == 0 {
    return { arr: [], blocks: [], block_size: 1, n: 0 }
  }
  let block_size = if isqrt(n) > 0 { isqrt(n) } else { 1 }
  let num_blocks = (n + block_size - 1) / block_size
  let blocks = Array::make(num_blocks, 0L)

  // Build block sums
  for i in 0..<n {
    blocks[i / block_size] = blocks[i / block_size] + arr[i]
  }
  { arr: arr.copy(), blocks, block_size, n }
}

///|
/// Set `arr[idx] = val` and update the corresponding block sum in O(1).
///
/// Only the single block that contains `idx` is updated. Indices outside
/// `[0, n)` are silently ignored.
///
/// Parameters:
/// - `idx` — 0-based index of the element to change.
/// - `val` — new value to assign.
pub fn SqrtSum::update(self : SqrtSum, idx : Int, val : Int64) -> Unit {
  if idx < 0 || idx >= self.n {
    return
  }
  let block = idx / self.block_size
  self.blocks[block] = self.blocks[block] - self.arr[idx] + val
  self.arr[idx] = val
}

///|
/// Return the sum of `arr[l..r]` (both endpoints inclusive) in O(√n).
///
/// The range is decomposed into:
/// 1. A left partial block scanned element by element.
/// 2. Whole blocks in the middle accumulated via precomputed block sums.
/// 3. A right partial block scanned element by element.
///
/// Returns 0 if the range is empty or out of bounds.
///
/// Parameters:
/// - `l` — inclusive left index (0-based).
/// - `r` — inclusive right index (0-based).
pub fn SqrtSum::query(self : SqrtSum, l : Int, r : Int) -> Int64 {
  if l > r || l < 0 || r >= self.n {
    return 0L
  }
  let block_l = l / self.block_size
  let block_r = r / self.block_size
  let sum = if block_l == block_r {
    // Same block: iterate directly
    for i = l, sum = 0L; i <= r; {
      continue i + 1, sum + self.arr[i]
    } nobreak {
      sum
    } where {
      proof_invariant: i >= l && i <= r + 1,
      proof_reasoning: (
        #|INVARIANT (Single block sum):
        #|sum equals the sum of arr[l..i). Each step adds arr[i], so after
        #|i reaches r+1 we have the full sum for [l, r].
        #|MAINTENANCE:
        #|Add arr[i] and advance i, extending the prefix sum.
        #|TERMINATION:
        #|At i = r + 1, sum is the full range sum.
      ),
    }
  } else {
    // Left partial block
    let left_sum = for i = l, sum = 0L; i < (block_l + 1) * self.block_size; {
      continue i + 1, sum + self.arr[i]
    } nobreak {
      sum
    } where {
      proof_invariant: i >= l && i <= (block_l + 1) * self.block_size,
      proof_reasoning: (
        #|INVARIANT (Left partial sum):
        #|sum equals the sum of arr[l..i) within the left boundary block.
        #|After reaching the block boundary, the left partial block is fully
        #|accounted for.
        #|MAINTENANCE:
        #|Add arr[i] and advance i to extend the left partial sum.
        #|TERMINATION:
        #|At i = (block_l + 1) * block_size, the left boundary is done.
      ),
    }
    // Complete blocks
    let block_sum = for b = block_l + 1, sum = 0L; b < block_r; {
      continue b + 1, sum + self.blocks[b]
    } nobreak {
      sum
    } where {
      proof_invariant: b >= block_l + 1 && b <= block_r,
      proof_reasoning: (
        #|INVARIANT (Complete blocks):
        #|sum already includes the left partial block and complete blocks
        #|up to b-1. Each iteration adds the precomputed sum of block b.
        #|MAINTENANCE:
        #|Add blocks[b] and advance b to include the next full block.
        #|TERMINATION:
        #|At b = block_r, all middle blocks are included.
      ),
    }
    // Right partial block
    let right_sum = for i = block_r * self.block_size, sum = 0L; i <= r; {
      continue i + 1, sum + self.arr[i]
    } nobreak {
      sum
    } where {
      proof_invariant: i >= block_r * self.block_size && i <= r + 1,
      proof_reasoning: (
        #|INVARIANT (Right partial sum):
        #|sum includes left partial and complete blocks, plus arr from the
        #|right boundary block prefix. After i reaches r+1, the full range
        #|sum is complete.
        #|MAINTENANCE:
        #|Add arr[i] and advance i, extending the right partial sum.
        #|TERMINATION:
        #|At i = r + 1, the full range sum is complete.
      ),
    }
    left_sum + block_sum + right_sum
  }
  sum
}

// ============================================================================
// SQRT DECOMPOSITION FOR RANGE MINIMUM
// ============================================================================

///|
/// Sentinel value used as the initial minimum in `SqrtMin`: `Int64::max_value`.
///
/// Any real element compares less than this value, so it acts as a safe
/// identity element for the minimum operation.
const SQRT_INF : Int64 = 9223372036854775807L

///|
/// Sqrt decomposition structure for **range minimum queries** with **point
/// updates**.
///
/// Mirrors `SqrtSum` but stores block minimums instead of block sums.
/// Because a point update may raise the minimum of a block, the entire block
/// must be rescanned on each update (`rebuild_block`), giving O(√n) per update.
///
/// Fields:
/// - `arr` — copy of the source array, mutated by `update`.
/// - `blocks` — `blocks[b]` holds `min(arr[b*B .. (b+1)*B))`.
/// - `block_size` — elements per block (`⌊√n⌋`, min 1).
/// - `n` — total number of elements.
priv struct SqrtMin {
  arr : Array[Int64]
  blocks : Array[Int64]
  block_size : Int
  n : Int
}

///|
/// Build a `SqrtMin` from an existing array in O(n).
///
/// Each block minimum is computed in a single forward pass.
fn SqrtMin::new(arr : Array[Int64]) -> SqrtMin {
  let n = arr.length()
  if n == 0 {
    return { arr: [], blocks: [], block_size: 1, n: 0 }
  }
  let block_size = if isqrt(n) > 0 { isqrt(n) } else { 1 }
  let num_blocks = (n + block_size - 1) / block_size
  let blocks = Array::make(num_blocks, SQRT_INF)
  for i in 0..<n {
    let b = i / block_size
    if arr[i] < blocks[b] {
      blocks[b] = arr[i]
    }
  }
  { arr: arr.copy(), blocks, block_size, n }
}

///|
/// Recompute `blocks[block]` by scanning all elements in that block.
///
/// Called after a point update because raising an element's value may
/// invalidate the stored block minimum; a full rescan is required.
///
/// Time: O(√n) (at most `block_size` elements scanned).
fn SqrtMin::rebuild_block(self : SqrtMin, block : Int) -> Unit {
  let start = block * self.block_size
  let end = if (block + 1) * self.block_size < self.n {
    (block + 1) * self.block_size
  } else {
    self.n
  }
  self.blocks[block] = SQRT_INF
  for i in start..<end {
    if self.arr[i] < self.blocks[block] {
      self.blocks[block] = self.arr[i]
    }
  }
}

///|
/// Set `arr[idx] = val` and rebuild the block minimum in O(√n).
///
/// Indices outside `[0, n)` are silently ignored.
fn SqrtMin::update(self : SqrtMin, idx : Int, val : Int64) -> Unit {
  if idx < 0 || idx >= self.n {
    return
  }
  self.arr[idx] = val
  self.rebuild_block(idx / self.block_size)
}

///|
/// Return the minimum of `arr[l..r]` (both endpoints inclusive) in O(√n).
///
/// Uses the same three-phase decomposition as `SqrtSum::query`:
/// left partial scan, whole-block minimums, right partial scan.
///
/// Returns `SQRT_INF` (Int64 max) when the range is empty or out of bounds.
fn SqrtMin::query(self : SqrtMin, l : Int, r : Int) -> Int64 {
  if l > r || l < 0 || r >= self.n {
    return SQRT_INF
  }
  let block_l = l / self.block_size
  let block_r = r / self.block_size
  let result = if block_l == block_r {
    for i = l, result = SQRT_INF; i <= r; {
      let result = if self.arr[i] < result { self.arr[i] } else { result }
      continue i + 1, result
    } nobreak {
      result
    } where {
      proof_invariant: i >= l && i <= r + 1,
      proof_reasoning: (
        #|INVARIANT (Single block min):
        #|result is the minimum of arr[l..i). Each step compares arr[i]
        #|and updates result, yielding the min over [l, r] at termination.
        #|MAINTENANCE:
        #|Update result with arr[i] if smaller, then advance i.
        #|TERMINATION:
        #|At i = r + 1, result is the minimum over [l, r].
      ),
    }
  } else {
    let left_result = for i = l, result = SQRT_INF; i <
                         (block_l + 1) * self.block_size; {
      let result = if self.arr[i] < result { self.arr[i] } else { result }
      continue i + 1, result
    } nobreak {
      result
    } where {
      proof_invariant: i >= l && i <= (block_l + 1) * self.block_size,
      proof_reasoning: (
        #|INVARIANT (Left partial min):
        #|result is the minimum of arr[l..i) in the left boundary block.
        #|After reaching the boundary, the left partial block is fully scanned.
        #|MAINTENANCE:
        #|Update result with arr[i] if smaller, then advance i.
        #|TERMINATION:
        #|At i = (block_l + 1) * block_size, the left partial min is complete.
      ),
    }
    let block_result = for b = block_l + 1, result = left_result; b < block_r; {
      let result = if self.blocks[b] < result { self.blocks[b] } else { result }
      continue b + 1, result
    } nobreak {
      result
    } where {
      proof_invariant: b >= block_l + 1 && b <= block_r,
      proof_reasoning: (
        #|INVARIANT (Complete blocks min):
        #|result is the minimum over the left partial block and complete
        #|blocks up to b-1. Each iteration considers block b's minimum.
        #|MAINTENANCE:
        #|Compare blocks[b] against result and advance b.
        #|TERMINATION:
        #|At b = block_r, all middle blocks are considered.
      ),
    }
    for i = block_r * self.block_size, result = block_result; i <= r; {
      let result = if self.arr[i] < result { self.arr[i] } else { result }
      continue i + 1, result
    } nobreak {
      result
    } where {
      proof_invariant: i >= block_r * self.block_size && i <= r + 1,
      proof_reasoning: (
        #|INVARIANT (Right partial min):
        #|result includes the left partial block, all complete blocks, and the
        #|right block prefix arr[block_r*bs..i). After i reaches r+1, result
        #|is the minimum over the full range.
        #|MAINTENANCE:
        #|Update result with arr[i] if smaller, then advance i.
        #|TERMINATION:
        #|At i = r + 1, result is the minimum over [l, r].
      ),
    }
  }
  result
}

// ============================================================================
// SQRT DECOMPOSITION WITH LAZY RANGE UPDATE
// ============================================================================

///|
/// Sqrt decomposition with **lazy range-add** and **range sum queries**.
///
/// Extends the basic sum structure to support `range_add(l, r, val)` —
/// adding `val` to every element in `[l, r]` — in O(√n) by deferring
/// element-level writes for complete blocks:
///
/// - **Partial blocks** (at most two): lazy is flushed first, then each
///   element is updated individually.
/// - **Complete blocks**: `lazy_add[b] += val` and `blocks[b]` is adjusted
///   by `val * block_length`; no element is touched.
///
/// Queries read `arr[i] + lazy_add[block(i)]` for individual elements and
/// the already-adjusted `blocks[b]` for whole blocks.
///
/// Fields:
/// - `arr` — element array; partial elements are kept up-to-date after push.
/// - `blocks` — precomputed block sums, including lazy contributions.
/// - `lazy_add` — pending addend for each block, applied on demand.
/// - `block_size` — elements per block (`⌊√n⌋`, min 1).
/// - `n` — total number of elements.
priv struct SqrtLazy {
  arr : Array[Int64]
  blocks : Array[Int64] // Block sums
  lazy_add : Array[Int64] // Lazy additive value for entire block
  block_size : Int
  n : Int
}

///|
/// Build a `SqrtLazy` from an existing array in O(n).
///
/// Block sums are initialised from the source array; all lazy addends start
/// at zero.
fn SqrtLazy::new(arr : Array[Int64]) -> SqrtLazy {
  let n = arr.length()
  if n == 0 {
    return { arr: [], blocks: [], lazy_add: [], block_size: 1, n: 0 }
  }
  let block_size = if isqrt(n) > 0 { isqrt(n) } else { 1 }
  let num_blocks = (n + block_size - 1) / block_size
  let blocks = Array::make(num_blocks, 0L)
  let lazy_add = Array::make(num_blocks, 0L)
  for i in 0..<n {
    blocks[i / block_size] = blocks[i / block_size] + arr[i]
  }
  { arr: arr.copy(), blocks, lazy_add, block_size, n }
}

///|
/// Flush the pending lazy addend for `block` down to individual elements.
///
/// After this call `lazy_add[block] == 0` and `arr[i]` reflects all
/// previously deferred additions for every `i` in the block.
///
/// This is called before element-level writes in partial-block updates so
/// that the invariant `arr[i] + lazy_add[block(i)]` always equals the
/// logical value of element `i`.
///
/// Time: O(√n) (scans at most `block_size` elements).
fn SqrtLazy::push(self : SqrtLazy, block : Int) -> Unit {
  if self.lazy_add[block] == 0L {
    return
  }
  let start = block * self.block_size
  let end = if (block + 1) * self.block_size < self.n {
    (block + 1) * self.block_size
  } else {
    self.n
  }
  for i in start..<end {
    self.arr[i] = self.arr[i] + self.lazy_add[block]
  }
  self.lazy_add[block] = 0L
}

///|
/// Add `val` to every element in `arr[l..r]` (inclusive) in O(√n).
///
/// Partial blocks at the boundaries are updated element by element (after
/// flushing their lazy addend). Complete blocks in the middle accumulate
/// `val` in `lazy_add` and adjust `blocks` without touching individual
/// elements.
///
/// Indices outside `[0, n)` or an empty range `l > r` are silently ignored.
fn SqrtLazy::range_add(self : SqrtLazy, l : Int, r : Int, val : Int64) -> Unit {
  if l > r || l < 0 || r >= self.n {
    return
  }
  let block_l = l / self.block_size
  let block_r = r / self.block_size
  if block_l == block_r {
    // Same block: update elements directly
    for i = l; i <= r; i = i + 1 {
      self.arr[i] = self.arr[i] + val
      self.blocks[block_l] = self.blocks[block_l] + val
    } where {
      proof_invariant: i >= l && i <= r + 1,
      proof_reasoning: (
        #|INVARIANT (Same block update):
        #|For indices [l..i), arr has been incremented by val and the block sum
        #|reflects those updates. After i reaches r+1, the entire range in this
        #|block is updated consistently.
        #|MAINTENANCE:
        #|Increment arr[i] and block sum, then advance i.
        #|TERMINATION:
        #|At i = r + 1, the block range is fully updated.
      ),
    }
  } else {
    // Left partial block
    self.push(block_l)
    for i = l; i < (block_l + 1) * self.block_size; i = i + 1 {
      self.arr[i] = self.arr[i] + val
      self.blocks[block_l] = self.blocks[block_l] + val
    } where {
      proof_invariant: i >= l && i <= (block_l + 1) * self.block_size,
      proof_reasoning: (
        #|INVARIANT (Left partial update):
        #|After pushing lazy, indices [l..i) are incremented by val and the
        #|block sum is adjusted. This completes the left partial block update.
        #|MAINTENANCE:
        #|Increment arr[i] and block sum, then advance i.
        #|TERMINATION:
        #|At i = (block_l + 1) * block_size, the left boundary is updated.
      ),
    }

    // Complete blocks: use lazy
    for b = block_l + 1; b < block_r; b = b + 1 {
      self.lazy_add[b] = self.lazy_add[b] + val
      let block_len = if (b + 1) * self.block_size < self.n {
        self.block_size
      } else {
        self.n - b * self.block_size
      }
      self.blocks[b] = self.blocks[b] + val * block_len.to_int64()
    } where {
      proof_invariant: b >= block_l + 1 && b <= block_r,
      proof_reasoning: (
        #|INVARIANT (Complete blocks lazy):
        #|All complete blocks in [block_l+1..b) have their lazy add and block
        #|sum updated. Each iteration updates one full block without touching
        #|individual elements.
        #|MAINTENANCE:
        #|Apply lazy add and sum adjustment to block b, then advance b.
        #|TERMINATION:
        #|At b = block_r, all middle blocks are updated.
      ),
    }

    // Right partial block
    self.push(block_r)
    for i = block_r * self.block_size; i <= r; i = i + 1 {
      self.arr[i] = self.arr[i] + val
      self.blocks[block_r] = self.blocks[block_r] + val
    } where {
      proof_invariant: i >= block_r * self.block_size && i <= r + 1,
      proof_reasoning: (
        #|INVARIANT (Right partial update):
        #|After pushing lazy for block_r, indices [block_r*bs..i) are updated
        #|and the block sum reflects those changes. After i reaches r+1, the
        #|right partial block is fully updated.
        #|MAINTENANCE:
        #|Increment arr[i] and block sum, then advance i.
        #|TERMINATION:
        #|At i = r + 1, the right boundary is updated.
      ),
    }
  }
}

///|
/// Return the sum of `arr[l..r]` (inclusive) in O(√n), accounting for
/// any pending lazy addends.
///
/// For partial blocks, each element is read as `arr[i] + lazy_add[block(i)]`.
/// For complete blocks, `blocks[b]` already incorporates the lazy contribution
/// (it is updated eagerly in `range_add`), so it is used directly.
///
/// Returns 0 if the range is empty or out of bounds.
fn SqrtLazy::query(self : SqrtLazy, l : Int, r : Int) -> Int64 {
  if l > r || l < 0 || r >= self.n {
    return 0L
  }
  let block_l = l / self.block_size
  let block_r = r / self.block_size
  let sum = if block_l == block_r {
    for i = l, sum = 0L; i <= r; {
      continue i + 1, sum + self.arr[i] + self.lazy_add[block_l]
    } nobreak {
      sum
    } where {
      proof_invariant: i >= l && i <= r + 1,
      proof_reasoning: (
        #|INVARIANT (Single block query):
        #|sum equals the sum of arr[l..i) with the block's lazy add applied.
        #|When i reaches r+1, sum is the full range sum.
        #|MAINTENANCE:
        #|Add the next value with lazy applied and advance i.
        #|TERMINATION:
        #|At i = r + 1, sum is the full range sum.
      ),
    }
  } else {
    let left_sum = for i = l, sum = 0L; i < (block_l + 1) * self.block_size; {
      continue i + 1, sum + self.arr[i] + self.lazy_add[block_l]
    } nobreak {
      sum
    } where {
      proof_invariant: i >= l && i <= (block_l + 1) * self.block_size,
      proof_reasoning: (
        #|INVARIANT (Left partial query):
        #|sum equals the left partial block sum for indices [l..i) with the
        #|lazy add applied. After the boundary, the left partial block is done.
        #|MAINTENANCE:
        #|Add the next value with lazy applied and advance i.
        #|TERMINATION:
        #|At i = (block_l + 1) * block_size, the left boundary is done.
      ),
    }
    let block_sum = for b = block_l + 1, sum = left_sum; b < block_r; {
      continue b + 1, sum + self.blocks[b]
    } nobreak {
      sum
    } where {
      proof_invariant: b >= block_l + 1 && b <= block_r,
      proof_reasoning: (
        #|INVARIANT (Complete blocks query):
        #|sum includes the left partial block and complete blocks up to b-1.
        #|Each blocks[b] already includes lazy contributions, so adding it is
        #|correct for the full block.
        #|MAINTENANCE:
        #|Add blocks[b] and advance b to include the next full block.
        #|TERMINATION:
        #|At b = block_r, all middle blocks are included.
      ),
    }
    let right_sum = for i = block_r * self.block_size, sum = 0L; i <= r; {
      continue i + 1, sum + self.arr[i] + self.lazy_add[block_r]
    } nobreak {
      sum
    } where {
      proof_invariant: i >= block_r * self.block_size && i <= r + 1,
      proof_reasoning: (
        #|INVARIANT (Right partial query):
        #|sum includes left partial and complete blocks plus the right block
        #|prefix [block_r*bs..i). After i reaches r+1, the full range is covered.
        #|MAINTENANCE:
        #|Add the next value with lazy applied and advance i.
        #|TERMINATION:
        #|At i = r + 1, the full range is covered.
      ),
    }
    block_sum + right_sum
  }
  sum
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "sqrt sum basic" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 9L]
  let sqrt = SqrtSum::new(arr)
  inspect(sqrt.query(0, 8), content="45") // Sum 1..9
  inspect(sqrt.query(0, 2), content="6") // 1+2+3
  inspect(sqrt.query(3, 5), content="15") // 4+5+6
}

///|
test "sqrt sum update" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let sqrt = SqrtSum::new(arr)
  inspect(sqrt.query(0, 4), content="15")
  sqrt.update(2, 10L)
  inspect(sqrt.query(0, 4), content="22") // 1+2+10+4+5
}

///|
test "sqrt min basic" {
  let arr : Array[Int64] = [5L, 2L, 8L, 1L, 9L, 3L, 7L, 4L, 6L]
  let sqrt = SqrtMin::new(arr)
  inspect(sqrt.query(0, 8), content="1")
  inspect(sqrt.query(0, 2), content="2")
  inspect(sqrt.query(4, 8), content="3")
}

///|
test "sqrt min update" {
  let arr : Array[Int64] = [5L, 2L, 8L, 1L, 9L]
  let sqrt = SqrtMin::new(arr)
  inspect(sqrt.query(0, 4), content="1")
  sqrt.update(3, 10L)
  inspect(sqrt.query(0, 4), content="2")
}

///|
test "sqrt lazy range add" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 9L]
  let sqrt = SqrtLazy::new(arr)
  inspect(sqrt.query(0, 8), content="45")
  sqrt.range_add(2, 6, 10L) // Add 10 to indices 2-6
  inspect(sqrt.query(0, 8), content="95") // 45 + 5*10 = 95
  inspect(sqrt.query(2, 6), content="75") // (3+4+5+6+7) + 5*10
}

///|
test "sqrt single element" {
  let arr : Array[Int64] = [42L]
  let sqrt = SqrtSum::new(arr)
  inspect(sqrt.query(0, 0), content="42")
}

///|
test "sqrt empty" {
  let arr : Array[Int64] = []
  let sqrt = SqrtSum::new(arr)
  inspect(sqrt.query(0, 0), content="0")
}

///|
test "sqrt large" {
  let arr : Array[Int64] = [| for i in 0..<1000 => i.to_int64() |]
  let sqrt = SqrtSum::new(arr)
  // Sum 0..999 = 999*1000/2 = 499500
  inspect(sqrt.query(0, 999), content="499500")
}

///|
test "isqrt" {
  inspect(isqrt(0), content="0")
  inspect(isqrt(1), content="1")
  inspect(isqrt(4), content="2")
  inspect(isqrt(9), content="3")
  inspect(isqrt(10), content="3")
  inspect(isqrt(100), content="10")
}
