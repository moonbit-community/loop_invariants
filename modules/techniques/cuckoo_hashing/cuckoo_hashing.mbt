// ============================================================================
// CUCKOO HASHING - Two tables, two hashes, guaranteed O(1) lookups
// ============================================================================
//
// PROBLEM
//
// Build a hash set with **worst-case O(1) lookup**, not just expected.
// Chained or linear-probing hash tables have great average performance
// but their tail latency can be terrible. Cuckoo hashing (Pagh-Rodler
// 2001) achieves guaranteed O(1) lookup by storing each key in one of
// two possible slots.
//
// THE STRUCTURE
//
// Two tables T_1, T_2 of size `m` each and two hash functions h_1, h_2.
// Each key `x` lives in exactly one of T_1[h_1(x)] or T_2[h_2(x)].
//
// LOOKUP  -- check both slots, return whichever holds the key (or None
//            if neither does). At most two memory accesses.
//
// INSERT  -- place x in T_1[h_1(x)]. If that slot was occupied by some
//            other key y, "kick" y to T_2[h_2(y)]; if THAT slot was
//            occupied by z, kick z to T_1[h_1(z)]; etc. Bounded by
//            ~6 * log m kicks before declaring failure (and rebuilding
//            with new hash functions).
//
// THE INVARIANT
//
//     For every key in the set, EITHER  T_1[h_1(key)] == key
//                                  OR   T_2[h_2(key)] == key
//
// THE LOAD-FACTOR BOUND
//
// With load factor `n / (2m) < 0.5`, the probability of an unbounded
// kick chain is `O(1/m)`. In practice, with load factor 0.49 and `~12
// log m` kicks, insertion succeeds with probability `1 - 1/m`. For
// load factor approaching `0.5`, expected insertion time grows
// quickly; the standard fix is to rebuild with new seeds when the
// kick chain exceeds the threshold.

///|
/// A Cuckoo hash set storing `Int64` keys. Two tables of size `m` plus
/// two salts; together they hold up to about `m` keys efficiently
/// (load factor <= 0.5).
pub struct CuckooHash {
  m : Int
  mut count : Int
  max_kicks : Int
  table_1 : Array[Int64?]
  table_2 : Array[Int64?]
  salt_1 : Int64
  salt_2 : Int64
}

///|
/// Logical right shift on Int64 (built-in `>>` is arithmetic).
fn shr_logical(x : Int64, n : Int) -> Int64 {
  (x.reinterpret_as_uint64() >> n).reinterpret_as_int64()
}

///|
/// MurmurHash3-style 64-bit mixer with one round of salt mixing.
fn cuckoo_mix(x : Int64, salt : Int64) -> Int64 {
  let mut h = x ^ salt
  h = (h ^ shr_logical(h, 33)) * 0xff51afd7ed558ccdL
  h = (h ^ shr_logical(h, 33)) * 0xc4ceb9fe1a85ec53L
  h = h ^ shr_logical(h, 33)
  h
}

///|
/// Map a 64-bit hash into a slot index `[0, m)`.
fn bucket_of(h : Int64, m : Int) -> Int {
  let abs_h = if h < 0L { -h } else { h }
  (abs_h % m.to_int64()).to_int()
}

///|
/// Create an empty Cuckoo set with two tables of size `m`.
///
/// ## Parameters
///
/// - `m`    : per-table size. Total slots are `2 * m`. The hash set
///            comfortably holds up to about `m` keys (load factor 0.5);
///            beyond that, expect insertions to start failing.
/// - `seed` : deterministic seed for the two hash functions.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let s = @cuckoo_hashing.new(m=128, seed=1L)
///   for x in 0L..<60L {
///     s.insert(x) |> ignore
///   }
///   assert_eq(s.contains(42L), true)
///   assert_eq(s.contains(999L), false)
/// }
/// ```
pub fn new(m~ : Int, seed~ : Int64) -> CuckooHash {
  let size = if m < 4 { 4 } else { m }
  let t1 : Array[Int64?] = Array::make(size, None)
  let t2 : Array[Int64?] = Array::make(size, None)
  // Derive two distinct salts from the seed.
  let s1 = cuckoo_mix(seed, 0x9e3779b97f4a7c15L)
  let s2 = cuckoo_mix(seed, 0x6a09e667f3bcc908L)
  // `max_kicks` is the cycle-detection bound. 6 * ceil(log2(m)) is a
  // textbook choice; for small m we use a generous constant minimum.
  let log_m = log2_ceil(size)
  let max_k = if 6 * log_m > 20 { 6 * log_m } else { 20 }
  {
    m: size,
    count: 0,
    max_kicks: max_k,
    table_1: t1,
    table_2: t2,
    salt_1: s1,
    salt_2: s2,
  }
}

///|
/// Ceiling of `log2(n)`, returning at least 1.
fn log2_ceil(n : Int) -> Int {
  for r = 0, v = 1; v < n; {
    continue r + 1, v * 2
  } nobreak {
    if r < 1 {
      1
    } else {
      r
    }
  } where {
    proof_invariant: r >= 0,
    proof_invariant: v >= 1,
    proof_reasoning: (
      #|INVARIANT (ceil log2):
      #|r is the smallest power-of-two exponent tried so far, v = 2^r.
      #|TERMINATION: v doubles each step, eventually exceeds n.
    ),
  }
}

///|
/// Lookup: return true iff `key` is in the set. Two array accesses,
/// worst case.
pub fn CuckooHash::contains(self : CuckooHash, key : Int64) -> Bool {
  let b1 = bucket_of(cuckoo_mix(key, self.salt_1), self.m)
  match self.table_1[b1] {
    Some(v) => if v == key { return true }
    None => ()
  }
  let b2 = bucket_of(cuckoo_mix(key, self.salt_2), self.m)
  match self.table_2[b2] {
    Some(v) => v == key
    None => false
  }
}

///|
/// Insert `key`. Returns `true` on success, `false` when the
/// `max_kicks` bound is exceeded (in which case a rebuild with new
/// seeds is required; this package does not auto-rebuild -- callers
/// can construct a new `CuckooHash` with a different seed).
///
/// Re-inserting a key already present is a no-op (returns `true`).
pub fn CuckooHash::insert(self : CuckooHash, key : Int64) -> Bool {
  if self.contains(key) {
    return true
  }
  // Eviction chain. Each iteration places the current `current` into
  // T_1 at its h_1 slot, displacing any incumbent, then if anyone was
  // displaced, moves the displaced one to T_2 at its h_2 slot, etc.
  let mut current = key
  let mut go_to_t1 = true
  let outcome = for k = 0 {
    if k >= self.max_kicks {
      // Reached the cycle bound; rebuild required.
      break false
    }
    if go_to_t1 {
      let b = bucket_of(cuckoo_mix(current, self.salt_1), self.m)
      match self.table_1[b] {
        None => {
          self.table_1[b] = Some(current)
          break true
        }
        Some(other) => {
          self.table_1[b] = Some(current)
          current = other
          go_to_t1 = false
          continue k + 1
        }
      }
    } else {
      let b = bucket_of(cuckoo_mix(current, self.salt_2), self.m)
      match self.table_2[b] {
        None => {
          self.table_2[b] = Some(current)
          break true
        }
        Some(other) => {
          self.table_2[b] = Some(current)
          current = other
          go_to_t1 = true
          continue k + 1
        }
      }
    }
  } where {
    proof_invariant: k >= 0 && k <= self.max_kicks,
    proof_reasoning: (
      #|INVARIANT (Eviction chain):
      #|Before iteration k, `current` is some key that has been
      #|displaced and is looking for a home. `go_to_t1` indicates
      #|which table it will try next.
      #|
      #|MAINTENANCE:
      #|If the target slot is empty, place `current` and exit success.
      #|If the slot is occupied, swap: store `current` there and let
      #|the previous occupant become the new `current`. Flip the
      #|target table.
      #|
      #|TERMINATION:
      #|Bounded by `max_kicks`. A cycle in the eviction chain (very
      #|rare for load factor < 0.5) causes an exit with `false`.
    ),
  }
  if outcome {
    self.count = self.count + 1
  }
  outcome
}

///|
/// Number of keys currently stored.
pub fn CuckooHash::count_of(self : CuckooHash) -> Int {
  self.count
}

///|
/// Per-table size `m` (total slots are `2 * m`).
pub fn CuckooHash::capacity(self : CuckooHash) -> Int {
  self.m
}

///|
/// Current load factor `n / (2 * m)`.
pub fn CuckooHash::load_factor(self : CuckooHash) -> Double {
  self.count.to_double() / (2 * self.m).to_double()
}

///|
test "cuckoo basic insert and contains" {
  let s = new(m=128, seed=1L)
  for x in 0L..<60L {
    let ok = s.insert(x)
    @debug.assert_eq(ok, true)
  }
  for x in 0L..<60L {
    @debug.assert_eq(s.contains(x), true)
  }
  @debug.assert_eq(s.contains(1000L), false)
  @debug.assert_eq(s.count_of(), 60)
}

///|
test "cuckoo duplicate insert is no-op" {
  let s = new(m=64, seed=42L)
  @debug.assert_eq(s.insert(42L), true)
  @debug.assert_eq(s.insert(42L), true)
  @debug.assert_eq(s.count_of(), 1)
}

///|
test "cuckoo capacity is per-table" {
  let s = new(m=256, seed=1L)
  @debug.assert_eq(s.capacity(), 256)
}

///|
test "cuckoo load factor monotonic" {
  let s = new(m=128, seed=7L)
  let mut prev = 0.0
  for x in 0L..<50L {
    s.insert(x) |> ignore
    let l = s.load_factor()
    @debug.assert_eq(l >= prev, true)
    prev = l
  }
}

///|
test "cuckoo handles negative keys" {
  let s = new(m=64, seed=1L)
  for x in -30L..<30L {
    s.insert(x) |> ignore
  }
  for x in -30L..<30L {
    @debug.assert_eq(s.contains(x), true)
  }
}

///|
test "cuckoo missing keys absent" {
  let s = new(m=128, seed=99L)
  for x in 0L..<50L {
    s.insert(x) |> ignore
  }
  for x in 100L..<200L {
    @debug.assert_eq(s.contains(x), false)
  }
}

///|
test "cuckoo all inserted keys present at moderate load" {
  let s = new(m=512, seed=12345L)
  let mut successes = 0
  for x in 0L..<200L {
    if s.insert(x) {
      successes = successes + 1
    }
  }
  // At load factor ~0.2 every insert succeeds.
  @debug.assert_eq(successes, 200)
  for x in 0L..<200L {
    @debug.assert_eq(s.contains(x), true)
  }
}

///|
test "cuckoo degenerate m coerced" {
  let s = new(m=0, seed=1L)
  // Coerced to 4.
  @debug.assert_eq(s.capacity(), 4)
}
