// ============================================================================
// ZOBRIST HASHING  -  Zobrist 1970
// ============================================================================
//
// PROBLEM
//
// Assign a unique 64-bit "fingerprint" to a board position (a function
// of `cells * piece-types`) so that
//
//   1. The hash of every reachable position is computed once, then
//      updated in `O(1)` per move via XORs.
//   2. Hash equality strongly suggests position equality (with
//      vanishing collision probability for random 64-bit keys).
//   3. The same machinery works for arrays/multisets, strings (treat
//      position = character), or any state expressible as a sum over
//      (cell, value) contributions.
//
// THE TRICK
//
// For each (cell, piece) pair, draw a random 64-bit key once. The hash
// of a position is the XOR of all keys for its occupied (cell, piece).
//
//   set_cell(c, new):
//     h ^= key[c, current[c]]    -- remove old
//     h ^= key[c, new]           -- add new
//
// XOR is self-inverse, so toggling the *same* key returns to the
// original hash. This makes incremental updates O(1).
//
// We provide a deterministic LCG to generate keys so tests are
// reproducible; you can re-seed with `with_seed` for production use.
//
// COMPLEXITY
//
//   precompute(cells, types) : O(cells * types)
//   set_cell                  : O(1)
//   full_hash                 : O(cells)
//
// THE INVARIANT
//
//   "After any sequence of set_cell operations, hash equals
//    XOR over all c of key[c, current[c]]."

///|
/// A Zobrist hasher for a board of `cells` slots and `types` possible
/// values per slot. Value 0 conventionally represents "empty" and
/// contributes nothing to the hash (since key[c, 0] is set to 0).
pub struct Zobrist {
  cells : Int
  types : Int
  // key[c * types + v] = random 64-bit key for (cell c, value v).
  key : Array[Int64]
  // current[c] = current value at cell c.
  current : Array[Int]
  mut hash : Int64
}

///|
fn next_random(state : Int64) -> Int64 {
  // SplitMix64-style finaliser; fast, decent for tests.
  let mut z = state + 0x9e3779b97f4a7c15L
  z = (z ^ shr_u(z, 30)) * 0xbf58476d1ce4e5b9L
  z = (z ^ shr_u(z, 27)) * 0x94d049bb133111ebL
  z ^ shr_u(z, 31)
}

///|
fn shr_u(x : Int64, n : Int) -> Int64 {
  (x.reinterpret_as_uint64() >> n).reinterpret_as_int64()
}

///|
/// Construct a hasher with `cells * (types - 1)` random keys (value 0
/// is always zero). `seed` is the LCG seed.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let z = @zobrist_hash.with_seed(8, 4, 12345L)
///   z.set_cell(0, 1)
///   z.set_cell(1, 2)
///   @debug.assert_eq(z.hash() != 0L, true)
/// }
/// ```
pub fn with_seed(cells : Int, types : Int, seed : Int64) -> Zobrist {
  let key = Array::make(cells * types, 0L)
  let mut s = seed
  for c in 0..<cells {
    // key[c * types + 0] stays 0 (empty contributes nothing).
    for v in 1..<types {
      s = next_random(s)
      key[c * types + v] = s
    }
  }
  { cells, types, key, current: Array::make(cells, 0), hash: 0L, }
}

///|
/// Set the value at `cell` to `value` and incrementally update the
/// hash. Returns the new hash.
pub fn Zobrist::set_cell(self : Zobrist, cell : Int, value : Int) -> Int64 {
  if cell < 0 || cell >= self.cells || value < 0 || value >= self.types {
    return self.hash
  }
  let old = self.current[cell]
  self.hash = self.hash ^ self.key[cell * self.types + old]
  self.hash = self.hash ^ self.key[cell * self.types + value]
  self.current[cell] = value
  self.hash
}

///|
/// Current hash.
pub fn Zobrist::hash(self : Zobrist) -> Int64 {
  self.hash
}

///|
/// Compute the full hash from `current` directly (debugging /
/// regression check).
pub fn Zobrist::full_hash(self : Zobrist) -> Int64 {
  let mut h = 0L
  for c in 0..<self.cells {
    h = h ^ self.key[c * self.types + self.current[c]]
  }
  h
}

///|
/// Read the current value at a cell.
pub fn Zobrist::get_cell(self : Zobrist, cell : Int) -> Int {
  if cell < 0 || cell >= self.cells {
    -1
  } else {
    self.current[cell]
  }
}

///|
test "zobrist same state same hash" {
  let a = with_seed(16, 4, 42L)
  let b = with_seed(16, 4, 42L)
  a.set_cell(0, 1) |> ignore
  a.set_cell(3, 2) |> ignore
  a.set_cell(7, 3) |> ignore
  b.set_cell(7, 3) |> ignore
  b.set_cell(0, 1) |> ignore
  b.set_cell(3, 2) |> ignore
  @debug.assert_eq(a.hash(), b.hash())
}

///|
test "zobrist diff state diff hash" {
  let a = with_seed(8, 3, 99L)
  let b = with_seed(8, 3, 99L)
  a.set_cell(0, 1) |> ignore
  b.set_cell(0, 2) |> ignore
  @debug.assert_eq(a.hash() != b.hash(), true)
}

///|
test "zobrist toggle returns to zero" {
  let z = with_seed(8, 4, 7L)
  z.set_cell(0, 1) |> ignore
  @debug.assert_eq(z.hash() != 0L, true)
  z.set_cell(0, 0) |> ignore
  @debug.assert_eq(z.hash(), 0L)
}

///|
test "zobrist incremental matches full" {
  let z = with_seed(20, 5, 12345L)
  z.set_cell(0, 1) |> ignore
  z.set_cell(5, 3) |> ignore
  z.set_cell(7, 4) |> ignore
  z.set_cell(0, 2) |> ignore // update
  @debug.assert_eq(z.hash(), z.full_hash())
}

///|
test "zobrist out-of-range ignored" {
  let z = with_seed(4, 3, 1L)
  let before = z.hash()
  z.set_cell(-1, 1) |> ignore
  @debug.assert_eq(z.hash(), before)
  z.set_cell(10, 1) |> ignore
  @debug.assert_eq(z.hash(), before)
  z.set_cell(0, -1) |> ignore
  @debug.assert_eq(z.hash(), before)
  z.set_cell(0, 3) |> ignore
  @debug.assert_eq(z.hash(), before)
}

///|
test "zobrist reproducible with seed" {
  let a = with_seed(10, 5, 314159L)
  let b = with_seed(10, 5, 314159L)
  for c in 0..<10 {
    a.set_cell(c, c % 4 + 1) |> ignore
    b.set_cell(c, c % 4 + 1) |> ignore
  }
  @debug.assert_eq(a.hash(), b.hash())
}

///|
test "zobrist no spurious collisions on small state" {
  // Hash 10 different single-cell single-value states; all distinct.
  let z = with_seed(10, 4, 999L)
  let hashes : Array[Int64] = []
  for c in 0..<10 {
    z.set_cell(c, 1) |> ignore
    hashes.push(z.hash())
    z.set_cell(c, 0) |> ignore // reset for the next pure single-cell test
  }
  for i in 0..<10 {
    for j in (i + 1)..<10 {
      @debug.assert_eq(hashes[i] != hashes[j], true)
    }
  }
}
