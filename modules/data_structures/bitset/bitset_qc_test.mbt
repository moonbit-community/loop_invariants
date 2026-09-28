// Property-based tests for `BitSet`: operation sequences are replayed against
// an `Array[Bool]` model of length `capacity`. Bulk operations take a second
// bit set whose capacity may differ; bits of `other` past its capacity count
// as zero and bits of `self` past its own capacity must stay unset
// (the documented invariant).

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Capacities clustered around word boundaries.
fn gen_cap(rs : @quickcheck.RandomState) -> Int {
  match rint(rs, 0, 3) {
    0 => rint(rs, 0, 3)
    1 => 64 * rint(rs, 0, 3) + rint(rs, -2, 2)
    _ => rint(rs, 0, 200)
  }
}

///|
fn gen_bit(rs : @quickcheck.RandomState, cap : Int) -> Int {
  if cap == 0 || rint(rs, 0, 9) == 0 {
    rint(rs, -3, cap + 3)
  } else {
    rint(rs, 0, cap - 1)
  }
}

///|
priv enum Op {
  Set(Int)
  Unset(Int)
  Flip(Int)
  Contains(Int)
  NextSet(Int)
  /// Bulk op with another set: kind 0 = or, 1 = and, 2 = xor.
  Bulk(Int, Int, Array[Int])
} derive(Debug)

///|
impl @quickcheck.Shrink for Op

///|
priv struct Case {
  cap : Int
  ops : Array[Op]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Case with fn arbitrary(size, rs) {
  let cap = gen_cap(rs)
  let ops = Array::makei(rint(rs, 0, size), _ => {
    match rint(rs, 0, 9) {
      0 | 1 | 2 => Set(gen_bit(rs, cap))
      3 => Unset(gen_bit(rs, cap))
      4 => Flip(gen_bit(rs, cap))
      5 => Contains(gen_bit(rs, cap))
      6 | 7 => NextSet(gen_bit(rs, cap))
      _ => {
        let other_cap = if rint(rs, 0, 1) == 0 { cap } else { gen_cap(rs) }
        let bits = Array::makei(rint(rs, 0, 10), _ => gen_bit(rs, other_cap))
        Bulk(rint(rs, 0, 2), other_cap, bits)
      }
    }
  })
  { cap, ops, }
}

///|
impl @quickcheck.Shrink for Case with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.ops).map(ops => { ..self, ops, })
}

///|
fn model_next(model : Array[Bool], start : Int) -> Int {
  for i in (if start < 0 { 0 } else { start })..<model.length() {
    if model[i] {
      return i
    }
  }
  -1
}

///|
fn run_case(c : Case) -> Bool {
  // `new` clamps a negative capacity to 0.
  let cap = if c.cap < 0 { 0 } else { c.cap }
  let b = @bitset.new(c.cap)
  let model = Array::make(cap, false)
  let valid = (i : Int) => i >= 0 && i < cap
  if b.capacity() != cap {
    return false
  }
  for op in c.ops {
    match op {
      Set(i) => {
        b.set(i)
        if valid(i) {
          model[i] = true
        }
      }
      Unset(i) => {
        b.unset(i)
        if valid(i) {
          model[i] = false
        }
      }
      Flip(i) => {
        b.flip(i)
        if valid(i) {
          model[i] = !model[i]
        }
      }
      Contains(i) => if b.contains(i) != (valid(i) && model[i]) { return false }
      NextSet(i) => if b.next_set(i) != model_next(model, i) { return false }
      Bulk(kind, other_cap, bits) => {
        let other = @bitset.new(other_cap)
        let other_cap = if other_cap < 0 { 0 } else { other_cap }
        let other_model = Array::make(other_cap, false)
        for i in bits {
          other.set(i)
          if i >= 0 && i < other_cap {
            other_model[i] = true
          }
        }
        let o = (i : Int) => i < other_cap && other_model[i]
        match kind {
          0 => {
            b.or_in(other)
            for i in 0..<cap {
              model[i] = model[i] || o(i)
            }
          }
          1 => {
            b.and_in(other)
            for i in 0..<cap {
              model[i] = model[i] && o(i)
            }
          }
          _ => {
            b.xor_in(other)
            for i in 0..<cap {
              model[i] = model[i] != o(i)
            }
          }
        }
      }
    }
    if b.count_set() != model.iter().filter(x => x).count() ||
      b.first_set() != model_next(model, 0) {
      return false
    }
  }
  for i in -1..<(cap + 2) {
    if b.contains(i) != (valid(i) && model[i]) {
      return false
    }
  }
  true
}

///|
test "qc: bitset agrees with Array[Bool] model" {
  @quickcheck.check(run_case, seed=0xB175_E7, count=400, observe=c => {
    [
      @quickcheck.classify(
        c.cap > 0 && c.cap % 64 == 0,
        "capacity positive multiple of 64",
      ),
      @quickcheck.classify(c.cap > 64, "multi-word"),
      @quickcheck.classify(c.cap <= 0, "capacity <= 0"),
      @quickcheck.classify(
        c.ops.iter().any(op => op is Bulk(_, oc, _) && oc != c.cap),
        "bulk op with different capacity",
      ),
    ]
  })
}

///|
/// `or_in` / `xor_in` with a wider `other` (same word count) used to copy
/// `other`'s bits past `self.capacity()` into the padding of `self`'s last
/// word, breaking the "bits >= capacity are 0" invariant: `count_set`
/// counted them.
test "regression: bitset or_in/xor_in keep padding bits clear" {
  let a = @bitset.new(1)
  let wide = @bitset.new(3)
  wide.set(1)
  wide.set(2)
  a.xor_in(wide)
  debug_inspect(a.count_set(), content="0")
  debug_inspect(a.first_set(), content="-1")
  let b = @bitset.new(10)
  let wide2 = @bitset.new(64)
  wide2.set(3)
  wide2.set(40)
  wide2.set(63)
  b.or_in(wide2)
  debug_inspect(b.count_set(), content="1")
  debug_inspect(b.next_set(4), content="-1")
  // A later `and_in` / `xor_in` must not resurrect stale padding bits.
  let c = @bitset.new(70)
  c.set(69)
  b.xor_in(c)
  debug_inspect(b.count_set(), content="1")
}
