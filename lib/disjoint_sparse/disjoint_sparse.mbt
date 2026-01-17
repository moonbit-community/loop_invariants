// ============================================================================
// DISJOINT SPARSE TABLE - O(1) Range Queries for Associative Operations
// ============================================================================
//
// Disjoint Sparse Table is a data structure for O(1) range queries on ANY
// associative operation, not just idempotent ones like min/max.
// This includes sum, product, XOR, and custom monoid operations.
//
// KEY INSIGHT: At each level of recursion, we precompute prefix and suffix
// aggregates from each "mid" point. Any query [l, r] crosses exactly one
// "mid" at some level, allowing O(1) query by combining suffix and prefix.
//
// STRUCTURE:
// Level 0: blocks of size 2, mids at 1, 3, 5, ...
// Level 1: blocks of size 4, mids at 2, 6, 10, ...
// Level 2: blocks of size 8, mids at 4, 12, 20, ...
// ...
//
// For each mid m at level k:
// - prefix[k][i] = combine(arr[m+1], ..., arr[i]) for i > m
// - suffix[k][i] = combine(arr[i], ..., arr[m]) for i <= m
//
// EXAMPLE for arr = [1, 2, 3, 4, 5, 6, 7, 8] with sum:
// Level 1 (block size 4):
//   Mid at 2: suffix = [_, 3, 5, 6], prefix = [_, _, 3, 7, 15]
//   Mid at 6: suffix = [_, _, _, _, 15, 26, 38, 51], prefix = [_, _, _, _, _, _, 7, 15]
// Wait, let me reconsider...
//
// Actually, the structure precomputes for each level k:
// - The array is divided into blocks of size 2^(k+1)
// - Each block has a "mid" at position 2^k - 1 within the block
// - suffix[i] = arr[i] ⊕ arr[i+1] ⊕ ... ⊕ arr[mid]
// - prefix[i] = arr[mid+1] ⊕ ... ⊕ arr[i]
//
// QUERY:
// 1. If l == r, return arr[l]
// 2. Find level k where l and r are in the same block but different halves
// 3. Return suffix[l] ⊕ prefix[r]
//
// Finding the right level: k = highest_bit(l XOR r)
//
// INVARIANTS:
// 1. table[k][i] contains result from i to/from the block mid at level k
// 2. For any range [l, r], exactly one level has l and r in different halves
// 3. Query uses suffix from l and prefix from r at that level
//
// TIME COMPLEXITY:
// - Build: O(n log n)
// - Query: O(1)
//
// SPACE COMPLEXITY: O(n log n)

///|
/// Disjoint Sparse Table for range sum queries
pub struct DisjointSparseSum {
  table : Array[Array[Int64]] // table[level][i]
  arr : Array[Int64]
  n : Int
}

///|
/// Find highest set bit position (floor(log2(x)))
fn highest_bit(x : Int) -> Int {
  if x <= 0 {
    return 0
  }

  // INVARIANT: result = floor(log2(x))
  for result = 0, val = x; val > 1; {
    continue result + 1, val / 2
  } else {
    result
  } where {
    invariant: result >= 0 && val >= 1,
    reasoning: (
      #|INVARIANT (highest_bit loop):
      #|val == floor(x / 2^result) and val >= 1 while looping.
      #|MAINTENANCE:
      #|Divide val by 2 and increment result, preserving the relation.
      #|TERMINATION:
      #|When val <= 1, result is floor(log2(x)).
    ),
  }
}

///|
/// Build a disjoint sparse table for range sum queries.
pub fn DisjointSparseSum::new(arr : Array[Int64]) -> DisjointSparseSum {
  let n = arr.length()
  if n == 0 {
    return { table: [], arr: [], n: 0 }
  }

  // Compute ceil(log2(n))
  let log_n = highest_bit(n - 1) + 1
  let table : Array[Array[Int64]] = []

  // Build each level
  // INVARIANT: At level k, blocks have size 2^(k+1) and mids are at positions 2^k - 1 within each block
  for k = 0; k < log_n; k = k + 1 {
    let row = Array::make(n, 0L)
    let block_size = 2 << k // 2^(k+1)
    let half = 1 << k // 2^k

    // Process each block
    // INVARIANT: block_start is start of current block
    for block_start = 0; block_start < n; block_start = block_start + block_size {
      let mid = block_start + half - 1 // Last position in left half

      // Compute suffix from mid going left
      // suffix[i] = arr[i] + arr[i+1] + ... + arr[mid]
      if mid < n {
        row[mid] = arr[mid]
        for i in mid >.. block_start {
          row[i] = arr[i] + row[i + 1]
        }
      }

      // Compute prefix from mid+1 going right
      // prefix[i] = arr[mid+1] + arr[mid+2] + ... + arr[i]
      if mid + 1 < n {
        let right_end = if block_start + block_size < n {
          block_start + block_size - 1
        } else {
          n - 1
        }
        row[mid + 1] = arr[mid + 1]
        for i = mid + 2; i <= right_end; i = i + 1 {
          row[i] = row[i - 1] + arr[i]
        } where {
          invariant: i >= mid + 2 && i <= right_end + 1,
          reasoning: (
            #|INVARIANT (sum prefix):
            #|row[mid+1..i-1] stores sums arr[mid+1..j] for j in [mid+1..i-1].
            #|MAINTENANCE:
            #|Set row[i] = row[i-1] + arr[i], extending one step right.
            #|TERMINATION:
            #|At i = right_end + 1, prefixes for [mid+1..right_end] exist.
          ),
        }
      }
    } where {
      invariant: block_start >= 0 && block_start <= n,
      reasoning: (
        #|INVARIANT (sum blocks):
        #|Blocks in [0..block_start) already have correct suffix/prefix sums.
        #|MAINTENANCE:
        #|Compute suffixes and prefixes for the block starting at block_start.
        #|TERMINATION:
        #|At block_start = n, all blocks at this level are processed.
      ),
    }
    table.push(row)
  } where {
    invariant: k >= 0 && k <= log_n,
    reasoning: (
      #|INVARIANT (sum levels):
      #|Levels [0..k) are built with block size 2^(lvl+1) for level lvl.
      #|MAINTENANCE:
      #|Build level k by computing block-wise suffix/prefix sums around mids.
      #|TERMINATION:
      #|At k = log_n, all levels are constructed.
    ),
  }
  { table, arr, n }
}

///|
/// Query sum in range [l, r] (inclusive)
/// REASONING: Find level where l and r are in different halves of same block,
/// then combine suffix[l] and prefix[r]
pub fn DisjointSparseSum::query(
  self : DisjointSparseSum,
  l : Int,
  r : Int,
) -> Int64? {
  if l < 0 || r >= self.n || l > r || self.n == 0 {
    return None
  }
  if l == r {
    return Some(self.arr[l])
  }

  // Find level k where l and r are in different halves
  // This is the highest bit position where l and r differ
  let k = highest_bit(l ^ r)
  Some(self.table[k][l] + self.table[k][r])
}

///|
fn DisjointSparseSum::length(self : DisjointSparseSum) -> Int {
  self.n
}

// ============================================================================
// DISJOINT SPARSE TABLE FOR XOR
// ============================================================================

///|
/// Disjoint Sparse Table for range XOR queries
priv struct DisjointSparseXor {
  table : Array[Array[Int64]]
  arr : Array[Int64]
  n : Int
}

///|
fn DisjointSparseXor::new(arr : Array[Int64]) -> DisjointSparseXor {
  let n = arr.length()
  if n == 0 {
    return { table: [], arr: [], n: 0 }
  }
  let log_n = highest_bit(n - 1) + 1
  let table : Array[Array[Int64]] = []
  for k = 0; k < log_n; k = k + 1 {
    let row = Array::make(n, 0L)
    let block_size = 2 << k
    let half = 1 << k
    for block_start = 0; block_start < n; block_start = block_start + block_size {
      let mid = block_start + half - 1

      // Suffix XOR
      if mid < n {
        row[mid] = arr[mid]
        for i in mid >.. block_start {
          row[i] = arr[i] ^ row[i + 1]
        }
      }

      // Prefix XOR
      if mid + 1 < n {
        let right_end = if block_start + block_size < n {
          block_start + block_size - 1
        } else {
          n - 1
        }
        row[mid + 1] = arr[mid + 1]
        for i = mid + 2; i <= right_end; i = i + 1 {
          row[i] = row[i - 1] ^ arr[i]
        } where {
          invariant: i >= mid + 2 && i <= right_end + 1,
          reasoning: (
            #|INVARIANT (xor prefix):
            #|row[mid+1..i-1] stores XORs arr[mid+1..j] for j in [mid+1..i-1].
            #|MAINTENANCE:
            #|Set row[i] = row[i-1] ^ arr[i], extending one step right.
            #|TERMINATION:
            #|At i = right_end + 1, prefixes for [mid+1..right_end] exist.
          ),
        }
      }
    } where {
      invariant: block_start >= 0 && block_start <= n,
      reasoning: (
        #|INVARIANT (xor blocks):
        #|Blocks in [0..block_start) already have correct suffix/prefix XORs.
        #|MAINTENANCE:
        #|Compute suffixes and prefixes for the block starting at block_start.
        #|TERMINATION:
        #|At block_start = n, all blocks at this level are processed.
      ),
    }
    table.push(row)
  } where {
    invariant: k >= 0 && k <= log_n,
    reasoning: (
      #|INVARIANT (xor levels):
      #|Levels [0..k) are built with block size 2^(lvl+1) for level lvl.
      #|MAINTENANCE:
      #|Build level k by computing block-wise suffix/prefix XORs around mids.
      #|TERMINATION:
      #|At k = log_n, all levels are constructed.
    ),
  }
  { table, arr, n }
}

///|
fn DisjointSparseXor::query(
  self : DisjointSparseXor,
  l : Int,
  r : Int,
) -> Int64? {
  if l < 0 || r >= self.n || l > r || self.n == 0 {
    return None
  }
  if l == r {
    return Some(self.arr[l])
  }
  let k = highest_bit(l ^ r)
  Some(self.table[k][l] ^ self.table[k][r])
}

///|
fn DisjointSparseXor::length(self : DisjointSparseXor) -> Int {
  self.n
}

// ============================================================================
// DISJOINT SPARSE TABLE FOR PRODUCT (MODULAR)
// ============================================================================

///|
/// Disjoint Sparse Table for range product queries (modular arithmetic)
priv struct DisjointSparseProd {
  table : Array[Array[Int64]]
  arr : Array[Int64]
  n : Int
  modulo : Int64
}

///|
fn DisjointSparseProd::new(
  arr : Array[Int64],
  modulo : Int64,
) -> DisjointSparseProd {
  let n = arr.length()
  if n == 0 {
    return { table: [], arr: [], n: 0, modulo }
  }
  let log_n = highest_bit(n - 1) + 1
  let table : Array[Array[Int64]] = []
  for k = 0; k < log_n; k = k + 1 {
    let row = Array::make(n, 1L)
    let block_size = 2 << k
    let half = 1 << k
    for block_start = 0; block_start < n; block_start = block_start + block_size {
      let mid = block_start + half - 1

      // Suffix product
      if mid < n {
        row[mid] = arr[mid] % modulo
        for i in mid >.. block_start {
          row[i] = arr[i] * row[i + 1] % modulo
        }
      }

      // Prefix product
      if mid + 1 < n {
        let right_end = if block_start + block_size < n {
          block_start + block_size - 1
        } else {
          n - 1
        }
        row[mid + 1] = arr[mid + 1] % modulo
        for i = mid + 2; i <= right_end; i = i + 1 {
          row[i] = row[i - 1] * arr[i] % modulo
        } where {
          invariant: i >= mid + 2 && i <= right_end + 1,
          reasoning: (
            #|INVARIANT (prod prefix):
            #|row[mid+1..i-1] stores products arr[mid+1..j] mod modulo.
            #|MAINTENANCE:
            #|Set row[i] = row[i-1] * arr[i] mod modulo, extending right.
            #|TERMINATION:
            #|At i = right_end + 1, prefixes for [mid+1..right_end] exist.
          ),
        }
      }
    } where {
      invariant: block_start >= 0 && block_start <= n,
      reasoning: (
        #|INVARIANT (prod blocks):
        #|Blocks in [0..block_start) already have correct suffix/prefix products.
        #|MAINTENANCE:
        #|Compute suffixes and prefixes for the block starting at block_start.
        #|TERMINATION:
        #|At block_start = n, all blocks at this level are processed.
      ),
    }
    table.push(row)
  } where {
    invariant: k >= 0 && k <= log_n,
    reasoning: (
      #|INVARIANT (prod levels):
      #|Levels [0..k) are built with block size 2^(lvl+1) for level lvl.
      #|MAINTENANCE:
      #|Build level k by computing block-wise suffix/prefix products around mids.
      #|TERMINATION:
      #|At k = log_n, all levels are constructed.
    ),
  }
  { table, arr, n, modulo }
}

///|
fn DisjointSparseProd::query(
  self : DisjointSparseProd,
  l : Int,
  r : Int,
) -> Int64? {
  if l < 0 || r >= self.n || l > r || self.n == 0 {
    return None
  }
  if l == r {
    return Some(self.arr[l] % self.modulo)
  }
  let k = highest_bit(l ^ r)
  Some(self.table[k][l] * self.table[k][r] % self.modulo)
}

///|
fn DisjointSparseProd::length(self : DisjointSparseProd) -> Int {
  self.n
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "disjoint sparse sum basic" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L]
  let dst = DisjointSparseSum::new(arr)

  // Single elements
  inspect(dst.query(0, 0), content="Some(1)")
  inspect(dst.query(3, 3), content="Some(4)")

  // Ranges
  inspect(dst.query(0, 3), content="Some(10)") // 1+2+3+4
  inspect(dst.query(4, 7), content="Some(26)") // 5+6+7+8
  inspect(dst.query(0, 7), content="Some(36)") // 1+...+8
  inspect(dst.query(2, 5), content="Some(18)") // 3+4+5+6
}

///|
test "disjoint sparse sum edge cases" {
  let arr : Array[Int64] = [42L]
  let dst = DisjointSparseSum::new(arr)
  inspect(dst.query(0, 0), content="Some(42)")
  inspect(dst.length(), content="1")
}

///|
test "disjoint sparse sum empty" {
  let arr : Array[Int64] = []
  let dst = DisjointSparseSum::new(arr)
  inspect(dst.query(0, 0), content="None")
  inspect(dst.length(), content="0")
}

///|
test "disjoint sparse sum invalid range" {
  let arr : Array[Int64] = [1L, 2L, 3L]
  let dst = DisjointSparseSum::new(arr)
  inspect(dst.query(-1, 0), content="None")
  inspect(dst.query(0, 10), content="None")
  inspect(dst.query(2, 1), content="None")
}

///|
test "disjoint sparse xor basic" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L]
  let dst = DisjointSparseXor::new(arr)

  // Single elements
  inspect(dst.query(0, 0), content="Some(1)")

  // XOR of 1,2,3,4 = 4
  inspect(dst.query(0, 3), content="Some(4)")

  // XOR of 5,6,7,8 = 5^6^7^8 = 12
  inspect(dst.query(4, 7), content="Some(12)")
}

///|
test "disjoint sparse xor all same" {
  let arr : Array[Int64] = [5L, 5L, 5L, 5L]
  let dst = DisjointSparseXor::new(arr)

  // XOR of same values: even count = 0
  inspect(dst.query(0, 3), content="Some(0)")

  // Odd count = value
  inspect(dst.query(0, 2), content="Some(5)")
}

///|
test "disjoint sparse prod basic" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let dst = DisjointSparseProd::new(arr, 1000000007L)

  // Single elements
  inspect(dst.query(0, 0), content="Some(1)")

  // Product of 1,2,3,4 = 24
  inspect(dst.query(0, 3), content="Some(24)")

  // Product of 2,3,4,5 = 120
  inspect(dst.query(1, 4), content="Some(120)")
}

///|
test "disjoint sparse prod modular" {
  let arr : Array[Int64] = [1000000L, 1000000L, 1000000L]
  let modulo = 1000000007L
  let dst = DisjointSparseProd::new(arr, modulo)

  // Product modulo should be handled correctly
  let result = dst.query(0, 2)
  inspect(result is Some(_), content="true")
}

///|
test "disjoint sparse sum power of 2" {
  // Test with power of 2 size
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L]
  let dst = DisjointSparseSum::new(arr)
  inspect(dst.query(0, 7), content="Some(36)")
  inspect(dst.query(0, 1), content="Some(3)")
  inspect(dst.query(6, 7), content="Some(15)")
}

///|
test "disjoint sparse sum non power of 2" {
  // Test with non-power of 2 size
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L, 6L]
  let dst = DisjointSparseSum::new(arr)
  inspect(dst.query(0, 5), content="Some(21)")
  inspect(dst.query(1, 4), content="Some(14)")
}

///|
test "disjoint sparse xor length" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let dst = DisjointSparseXor::new(arr)
  inspect(dst.length(), content="5")
}

///|
test "disjoint sparse prod length" {
  let arr : Array[Int64] = [1L, 2L, 3L]
  let dst = DisjointSparseProd::new(arr, 1000000007L)
  inspect(dst.length(), content="3")
}

///|
test "highest bit" {
  inspect(highest_bit(1), content="0")
  inspect(highest_bit(2), content="1")
  inspect(highest_bit(3), content="1")
  inspect(highest_bit(4), content="2")
  inspect(highest_bit(7), content="2")
  inspect(highest_bit(8), content="3")
}
