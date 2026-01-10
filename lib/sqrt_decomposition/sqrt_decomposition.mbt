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

// ============================================================================
// SQRT DECOMPOSITION FOR RANGE SUM
// ============================================================================

///|
priv struct SqrtSum {
  arr : Array[Int64]
  blocks : Array[Int64]
  block_size : Int
  n : Int
}

///|
fn SqrtSum::new(arr : Array[Int64]) -> SqrtSum {
  let n = arr.length()
  if n == 0 {
    return { arr: [], blocks: [], block_size: 1, n: 0 }
  }

  let block_size = if isqrt(n) > 0 { isqrt(n) } else { 1 }
  let num_blocks = (n + block_size - 1) / block_size
  let blocks = Array::make(num_blocks, 0L)

  // Build block sums
  for i = 0; i < n; i = i + 1 {
    blocks[i / block_size] = blocks[i / block_size] + arr[i]
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: "I: All block sums = 0. M: Add arr[i] to its block sum. T: blocks[b] = sum of elements in block b.",
  }

  { arr: arr.copy(), blocks, block_size, n }
}

///|
/// Point update: arr[idx] = val
fn SqrtSum::update(self : SqrtSum, idx : Int, val : Int64) -> Unit {
  if idx < 0 || idx >= self.n {
    return
  }
  let block = idx / self.block_size
  self.blocks[block] = self.blocks[block] - self.arr[idx] + val
  self.arr[idx] = val
}

///|
/// Range sum query [l, r] inclusive
fn SqrtSum::query(self : SqrtSum, l : Int, r : Int) -> Int64 {
  if l > r || l < 0 || r >= self.n {
    return 0L
  }

  let block_l = l / self.block_size
  let block_r = r / self.block_size
  let mut sum = 0L

  if block_l == block_r {
    // Same block: iterate directly
    for i = l; i <= r; i = i + 1 {
      sum = sum + self.arr[i]
    }
  } else {
    // Left partial block
    for i = l; i < (block_l + 1) * self.block_size; i = i + 1 {
      sum = sum + self.arr[i]
    }
    // Complete blocks
    for b = block_l + 1; b < block_r; b = b + 1 {
      sum = sum + self.blocks[b]
    } where {
      invariant: b >= block_l + 1 && b <= block_r,
      reasoning: "I: sum has left partial block. M: Add complete block sums. T: All complete blocks added.",
    }
    // Right partial block
    for i = block_r * self.block_size; i <= r; i = i + 1 {
      sum = sum + self.arr[i]
    }
  }

  sum
}

// ============================================================================
// SQRT DECOMPOSITION FOR RANGE MINIMUM
// ============================================================================

///|
const SQRT_INF : Int64 = 9223372036854775807L

///|
priv struct SqrtMin {
  arr : Array[Int64]
  blocks : Array[Int64]
  block_size : Int
  n : Int
}

///|
fn SqrtMin::new(arr : Array[Int64]) -> SqrtMin {
  let n = arr.length()
  if n == 0 {
    return { arr: [], blocks: [], block_size: 1, n: 0 }
  }

  let block_size = if isqrt(n) > 0 { isqrt(n) } else { 1 }
  let num_blocks = (n + block_size - 1) / block_size
  let blocks = Array::make(num_blocks, SQRT_INF)

  for i = 0; i < n; i = i + 1 {
    let b = i / block_size
    if arr[i] < blocks[b] {
      blocks[b] = arr[i]
    }
  }

  { arr: arr.copy(), blocks, block_size, n }
}

///|
fn SqrtMin::rebuild_block(self : SqrtMin, block : Int) -> Unit {
  let start = block * self.block_size
  let end = if (block + 1) * self.block_size < self.n {
    (block + 1) * self.block_size
  } else {
    self.n
  }
  self.blocks[block] = SQRT_INF
  for i = start; i < end; i = i + 1 {
    if self.arr[i] < self.blocks[block] {
      self.blocks[block] = self.arr[i]
    }
  }
}

///|
fn SqrtMin::update(self : SqrtMin, idx : Int, val : Int64) -> Unit {
  if idx < 0 || idx >= self.n {
    return
  }
  self.arr[idx] = val
  self.rebuild_block(idx / self.block_size)
}

///|
fn SqrtMin::query(self : SqrtMin, l : Int, r : Int) -> Int64 {
  if l > r || l < 0 || r >= self.n {
    return SQRT_INF
  }

  let block_l = l / self.block_size
  let block_r = r / self.block_size
  let mut result = SQRT_INF

  if block_l == block_r {
    for i = l; i <= r; i = i + 1 {
      if self.arr[i] < result {
        result = self.arr[i]
      }
    }
  } else {
    for i = l; i < (block_l + 1) * self.block_size; i = i + 1 {
      if self.arr[i] < result {
        result = self.arr[i]
      }
    }
    for b = block_l + 1; b < block_r; b = b + 1 {
      if self.blocks[b] < result {
        result = self.blocks[b]
      }
    }
    for i = block_r * self.block_size; i <= r; i = i + 1 {
      if self.arr[i] < result {
        result = self.arr[i]
      }
    }
  }

  result
}

// ============================================================================
// SQRT DECOMPOSITION WITH LAZY RANGE UPDATE
// ============================================================================

///|
priv struct SqrtLazy {
  arr : Array[Int64]
  blocks : Array[Int64] // Block sums
  lazy : Array[Int64] // Lazy additive value for entire block
  block_size : Int
  n : Int
}

///|
fn SqrtLazy::new(arr : Array[Int64]) -> SqrtLazy {
  let n = arr.length()
  if n == 0 {
    return { arr: [], blocks: [], lazy: [], block_size: 1, n: 0 }
  }

  let block_size = if isqrt(n) > 0 { isqrt(n) } else { 1 }
  let num_blocks = (n + block_size - 1) / block_size
  let blocks = Array::make(num_blocks, 0L)
  let lazy = Array::make(num_blocks, 0L)

  for i = 0; i < n; i = i + 1 {
    blocks[i / block_size] = blocks[i / block_size] + arr[i]
  }

  { arr: arr.copy(), blocks, lazy, block_size, n }
}

///|
/// Push lazy value to elements in a block
fn SqrtLazy::push(self : SqrtLazy, block : Int) -> Unit {
  if self.lazy[block] == 0L {
    return
  }
  let start = block * self.block_size
  let end = if (block + 1) * self.block_size < self.n {
    (block + 1) * self.block_size
  } else {
    self.n
  }
  for i = start; i < end; i = i + 1 {
    self.arr[i] = self.arr[i] + self.lazy[block]
  }
  self.lazy[block] = 0L
}

///|
/// Range add: arr[l..r] += val
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
    }
  } else {
    // Left partial block
    self.push(block_l)
    for i = l; i < (block_l + 1) * self.block_size; i = i + 1 {
      self.arr[i] = self.arr[i] + val
      self.blocks[block_l] = self.blocks[block_l] + val
    }

    // Complete blocks: use lazy
    for b = block_l + 1; b < block_r; b = b + 1 {
      self.lazy[b] = self.lazy[b] + val
      let block_len = if (b + 1) * self.block_size < self.n {
        self.block_size
      } else {
        self.n - b * self.block_size
      }
      self.blocks[b] = self.blocks[b] + val * block_len.to_int64()
    } where {
      invariant: b >= block_l + 1 && b <= block_r,
      reasoning: "I: Partial blocks updated. M: Apply lazy update to complete blocks. T: All complete blocks have lazy value set.",
    }

    // Right partial block
    self.push(block_r)
    for i = block_r * self.block_size; i <= r; i = i + 1 {
      self.arr[i] = self.arr[i] + val
      self.blocks[block_r] = self.blocks[block_r] + val
    }
  }
}

///|
fn SqrtLazy::query(self : SqrtLazy, l : Int, r : Int) -> Int64 {
  if l > r || l < 0 || r >= self.n {
    return 0L
  }

  let block_l = l / self.block_size
  let block_r = r / self.block_size
  let mut sum = 0L

  if block_l == block_r {
    for i = l; i <= r; i = i + 1 {
      sum = sum + self.arr[i] + self.lazy[block_l]
    }
  } else {
    for i = l; i < (block_l + 1) * self.block_size; i = i + 1 {
      sum = sum + self.arr[i] + self.lazy[block_l]
    }
    for b = block_l + 1; b < block_r; b = b + 1 {
      sum = sum + self.blocks[b]
    }
    for i = block_r * self.block_size; i <= r; i = i + 1 {
      sum = sum + self.arr[i] + self.lazy[block_r]
    }
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
  let arr : Array[Int64] = []
  for i = 0; i < 1000; i = i + 1 {
    arr.push(i.to_int64())
  }
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
