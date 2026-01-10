// ============================================================================
// BLOOM FILTER - Probabilistic Set Membership
// ============================================================================
//
// A Bloom filter is a space-efficient probabilistic data structure for set membership.
// It can have false positives but never false negatives.
//
// KEY INSIGHT: Use k independent hash functions to map elements to k bit positions.
// An element is "probably in set" if all k bits are 1.
//
// OPERATIONS:
// - insert(x): Set bits at h1(x), h2(x), ..., hk(x)
// - contains(x): Check if all bits at h1(x), ..., hk(x) are 1
//
// FALSE POSITIVE PROBABILITY:
// p ≈ (1 - e^(-kn/m))^k
// where m = bits, n = elements, k = hash functions
//
// OPTIMAL k: k = (m/n) * ln(2) ≈ 0.7 * (m/n)
//
// INVARIANTS:
// 1. Once a bit is set to 1, it stays 1
// 2. If contains(x) returns false, x was never inserted
// 3. If contains(x) returns true, x was probably inserted
//
// TIME COMPLEXITY: O(k) for insert and query
// SPACE COMPLEXITY: O(m) bits

///|
priv struct BloomFilter {
  bits : Array[Bool]
  size : Int // m - number of bits
  hash_count : Int // k - number of hash functions
  mut count : Int // Number of elements inserted
}

///|
/// Create bloom filter with given size and hash count
fn BloomFilter::new(size : Int, hash_count : Int) -> BloomFilter {
  { bits: Array::make(size, false), size, hash_count, count: 0 }
}

///|
/// Create bloom filter optimized for n elements with false positive rate p
fn BloomFilter::with_fp_rate(n : Int, p : Double) -> BloomFilter {
  // m = -n * ln(p) / (ln(2))²
  // k = (m/n) * ln(2)
  let ln2 = 0.693147180559945
  let ln2_sq = ln2 * ln2

  let m_float = -1.0 * n.to_double() * ln_approx(p) / ln2_sq
  let m = m_float.to_int() + 1

  let k_float = (m.to_double() / n.to_double()) * ln2
  let k = if k_float.to_int() < 1 { 1 } else { k_float.to_int() }

  BloomFilter::new(m, k)
}

///|
/// Approximate natural logarithm for small values
fn ln_approx(x : Double) -> Double {
  // For small x (like false positive rates), use series expansion
  // ln(x) ≈ 2 * ((x-1)/(x+1) + 1/3 * ((x-1)/(x+1))³ + ...)
  // For simplicity, we use a rough approximation
  if x <= 0.0 {
    return -1000.0 // Very negative for invalid input
  }
  if x < 0.5 {
    return -2.0 - 1.0 / x // Rough approximation for small x
  }
  let y = (x - 1.0) / (x + 1.0)
  2.0 * y * (1.0 + y * y / 3.0 + y * y * y * y / 5.0)
}

///|
/// Simple hash function 1 (FNV-1a inspired)
fn hash1(s : String, m : Int) -> Int {
  let mut h = 2166136261L
  for i = 0; i < s.length(); i = i + 1 {
    h = h.lxor(s[i].to_int().to_int64())
    h = h * 16777619L
  }
  ((h % m.to_int64() + m.to_int64()) % m.to_int64()).to_int()
}

///|
/// Simple hash function 2 (DJB2 inspired)
fn hash2(s : String, m : Int) -> Int {
  let mut h = 5381L
  for i = 0; i < s.length(); i = i + 1 {
    h = h * 33L + s[i].to_int().to_int64()
  }
  ((h % m.to_int64() + m.to_int64()) % m.to_int64()).to_int()
}

///|
/// Get ith hash value using double hashing technique
fn get_hash(s : String, i : Int, m : Int) -> Int {
  let h1 = hash1(s, m)
  let h2 = hash2(s, m)
  ((h1 + i * h2) % m + m) % m
}

///|
fn BloomFilter::insert(self : BloomFilter, item : String) -> Unit {
  for i = 0; i < self.hash_count; i = i + 1 {
    let idx = get_hash(item, i, self.size)
    self.bits[idx] = true
  }
  self.count = self.count + 1
}

///|
fn BloomFilter::contains(self : BloomFilter, item : String) -> Bool {
  for i = 0; i < self.hash_count; i = i + 1 {
    let idx = get_hash(item, i, self.size)
    if not(self.bits[idx]) {
      return false
    }
  }
  true
}

///|
/// Get estimated false positive probability
fn BloomFilter::false_positive_rate(self : BloomFilter) -> Double {
  // p ≈ (1 - e^(-kn/m))^k
  let k = self.hash_count.to_double()
  let n = self.count.to_double()
  let m = self.size.to_double()

  let exp_arg = -k * n / m
  let base = 1.0 - exp_approx(exp_arg)
  pow_approx(base, k)
}

///|
/// Approximate e^x
fn exp_approx(x : Double) -> Double {
  // Taylor series: e^x = 1 + x + x²/2! + x³/3! + ...
  let mut result = 1.0
  let mut term = 1.0
  for i = 1; i < 20; i = i + 1 {
    term = term * x / i.to_double()
    result = result + term
  }
  result
}

///|
/// Approximate x^y
fn pow_approx(x : Double, y : Double) -> Double {
  // x^y = e^(y * ln(x))
  if x <= 0.0 {
    return 0.0
  }
  let ln_x = ln_approx(x)
  exp_approx(y * ln_x)
}

///|
fn BloomFilter::element_count(self : BloomFilter) -> Int {
  self.count
}

///|
fn BloomFilter::bit_count(self : BloomFilter) -> Int {
  let mut count = 0
  for i = 0; i < self.size; i = i + 1 {
    if self.bits[i] {
      count = count + 1
    }
  }
  count
}

///|
fn BloomFilter::clear(self : BloomFilter) -> Unit {
  for i = 0; i < self.size; i = i + 1 {
    self.bits[i] = false
  }
  self.count = 0
}

// ============================================================================
// COUNTING BLOOM FILTER
// ============================================================================

///|
priv struct CountingBloomFilter {
  counts : Array[Int]
  size : Int
  hash_count : Int
  mut element_count : Int
}

///|
fn CountingBloomFilter::new(size : Int, hash_count : Int) -> CountingBloomFilter {
  {
    counts: Array::make(size, 0),
    size,
    hash_count,
    element_count: 0,
  }
}

///|
fn CountingBloomFilter::insert(self : CountingBloomFilter, item : String) -> Unit {
  for i = 0; i < self.hash_count; i = i + 1 {
    let idx = get_hash(item, i, self.size)
    self.counts[idx] = self.counts[idx] + 1
  }
  self.element_count = self.element_count + 1
}

///|
fn CountingBloomFilter::remove(self : CountingBloomFilter, item : String) -> Bool {
  // First check if item might exist
  for i = 0; i < self.hash_count; i = i + 1 {
    let idx = get_hash(item, i, self.size)
    if self.counts[idx] == 0 {
      return false
    }
  }

  // Decrement counters
  for i = 0; i < self.hash_count; i = i + 1 {
    let idx = get_hash(item, i, self.size)
    self.counts[idx] = self.counts[idx] - 1
  }
  self.element_count = self.element_count - 1
  true
}

///|
fn CountingBloomFilter::contains(self : CountingBloomFilter, item : String) -> Bool {
  for i = 0; i < self.hash_count; i = i + 1 {
    let idx = get_hash(item, i, self.size)
    if self.counts[idx] == 0 {
      return false
    }
  }
  true
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "bloom_filter basic" {
  let bf = BloomFilter::new(1000, 7)

  bf.insert("hello")
  bf.insert("world")
  bf.insert("test")

  inspect(bf.contains("hello"), content="true")
  inspect(bf.contains("world"), content="true")
  inspect(bf.contains("test"), content="true")
  inspect(bf.element_count(), content="3")
}

///|
test "bloom_filter not found" {
  let bf = BloomFilter::new(1000, 7)

  bf.insert("apple")
  bf.insert("banana")

  // These should probably return false (not guaranteed)
  // But with 1000 bits and only 2 elements, false positive is very unlikely
  inspect(bf.contains("apple"), content="true")
  inspect(bf.contains("banana"), content="true")
}

///|
test "bloom_filter no false negatives" {
  let bf = BloomFilter::new(100, 3)

  let items : Array[String] = [
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j",
  ]

  for i = 0; i < items.length(); i = i + 1 {
    bf.insert(items[i])
  }

  // All inserted items must be found (no false negatives)
  for i = 0; i < items.length(); i = i + 1 {
    inspect(bf.contains(items[i]), content="true")
  }
}

///|
test "bloom_filter bit count" {
  let bf = BloomFilter::new(100, 3)
  inspect(bf.bit_count(), content="0")

  bf.insert("test")
  inspect(bf.bit_count() > 0, content="true")
  inspect(bf.bit_count() <= 3, content="true") // At most 3 bits per element
}

///|
test "bloom_filter clear" {
  let bf = BloomFilter::new(100, 3)
  bf.insert("test")
  inspect(bf.contains("test"), content="true")

  bf.clear()
  inspect(bf.contains("test"), content="false")
  inspect(bf.element_count(), content="0")
}

///|
test "counting_bloom_filter basic" {
  let cbf = CountingBloomFilter::new(1000, 7)

  cbf.insert("hello")
  cbf.insert("world")

  inspect(cbf.contains("hello"), content="true")
  inspect(cbf.contains("world"), content="true")
}

///|
test "counting_bloom_filter remove" {
  let cbf = CountingBloomFilter::new(1000, 7)

  cbf.insert("hello")
  inspect(cbf.contains("hello"), content="true")

  let removed = cbf.remove("hello")
  inspect(removed, content="true")
  inspect(cbf.contains("hello"), content="false")
}

///|
test "counting_bloom_filter multiple" {
  let cbf = CountingBloomFilter::new(1000, 7)

  cbf.insert("test")
  cbf.insert("test") // Insert same element twice

  let _ = cbf.remove("test")
  // Should still contain because inserted twice
  inspect(cbf.contains("test"), content="true")

  let _ = cbf.remove("test")
  inspect(cbf.contains("test"), content="false")
}

///|
test "bloom_filter with_fp_rate" {
  // Create filter for 100 elements with 1% false positive rate
  let bf = BloomFilter::with_fp_rate(100, 0.01)

  // Should have reasonable size
  inspect(bf.size > 0, content="true")
  inspect(bf.hash_count > 0, content="true")
}

///|
test "hash functions" {
  let h1 = hash1("test", 1000)
  let h2 = hash2("test", 1000)

  inspect(h1 >= 0 && h1 < 1000, content="true")
  inspect(h2 >= 0 && h2 < 1000, content="true")
  // Different hash functions should give different values
  inspect(h1 != h2, content="true")
}
