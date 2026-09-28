// Property-based tests for `FenwickTree`: every operation sequence is replayed
// against a plain `Array[Int64]` model. Sums use wrapping `Int64` arithmetic in
// both the tree and the model, so extreme values are allowed.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Mostly small values (so sums are readable), sometimes full-range values and
/// the Int64 extrema.
fn gen_val(rs : @quickcheck.RandomState) -> Int64 {
  match rint(rs, 0, 9) {
    0 => @quickcheck.Arbitrary::arbitrary(0, rs)
    1 => [9223372036854775807L, -9223372036854775808L, 0L][rint(rs, 0, 2)]
    _ => rint(rs, -20, 20).to_int64()
  }
}

///|
/// Mostly valid indices, sometimes just outside `[0, n)`.
fn gen_index(rs : @quickcheck.RandomState, n : Int) -> Int {
  if n == 0 || rint(rs, 0, 7) == 0 {
    rint(rs, -2, n + 2)
  } else {
    rint(rs, 0, n - 1)
  }
}

///|
priv enum Op {
  Add(Int, Int64)
  Set(Int, Int64)
  Get(Int)
  Prefix(Int)
  Range(Int, Int)
} derive(Debug)

///|
impl @quickcheck.Shrink for Op

///|
priv struct Case {
  from_array : Bool
  init : Array[Int64]
  ops : Array[Op]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Case with fn arbitrary(size, rs) {
  let n = rint(rs, 0, if size < 24 { size } else { 24 })
  let from_array = rint(rs, 0, 3) != 0
  let init = if from_array {
    Array::makei(n, _ => gen_val(rs))
  } else {
    Array::make(n, 0L)
  }
  let ops = Array::makei(rint(rs, 0, size), _ => {
    match rint(rs, 0, 4) {
      0 => Add(gen_index(rs, n), gen_val(rs))
      1 => Set(gen_index(rs, n), gen_val(rs))
      2 => Get(gen_index(rs, n))
      3 => Prefix(gen_index(rs, n))
      _ => Range(gen_index(rs, n), gen_index(rs, n))
    }
  })
  { from_array, init, ops, }
}

///|
impl @quickcheck.Shrink for Case with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.ops).map(ops => { ..self, ops, })
}

///|
fn model_sum(arr : Array[Int64], l : Int, r : Int) -> Int64 {
  let mut s = 0L
  for i in l..<=r {
    s = s + arr[i]
  }
  s
}

///|
fn run_case(c : Case) -> Bool {
  let n = c.init.length()
  let model = c.init.copy()
  let ft = if c.from_array {
    @fenwick.FenwickTree::from_array(c.init.copy())
  } else {
    FenwickTree(n)
  }
  if ft.length() != n {
    return false
  }
  for op in c.ops {
    match op {
      Add(i, d) => {
        ft.add(i, d)
        if i >= 0 && i < n {
          model[i] = model[i] + d
        }
      }
      Set(i, v) => {
        ft.set(i, v)
        if i >= 0 && i < n {
          model[i] = v
        }
      }
      Get(i) => {
        let expected = if i >= 0 && i < n { model[i] } else { 0L }
        if ft.get(i) != expected {
          return false
        }
      }
      Prefix(i) => {
        // Documented: prefix_sum(-1) == 0 and indices past the end clamp.
        let expected = if i < 0 {
          0L
        } else {
          model_sum(model, 0, if i >= n { n - 1 } else { i })
        }
        if ft.prefix_sum(i) != expected {
          return false
        }
      }
      Range(l, r) => {
        let expected = if l > r || l < 0 || r >= n {
          0L
        } else {
          model_sum(model, l, r)
        }
        if ft.range_sum(l, r) != expected {
          return false
        }
      }
    }
  }
  // Final full comparison of every element.
  for i in 0..<n {
    if ft.get(i) != model[i] {
      return false
    }
  }
  true
}

///|
test "qc: fenwick agrees with array model" {
  @quickcheck.check(run_case, seed=0x5EED_F3A1, count=300, observe=c => {
    [
      @quickcheck.classify(c.init.length() == 0, "empty"),
      @quickcheck.classify(c.init.length() == 1, "size 1"),
      @quickcheck.classify(c.init.length() >= 16, "size >= 16"),
      @quickcheck.classify(c.from_array, "from_array"),
      @quickcheck.classify(
        c.ops
        .iter()
        .any(op => op is Add(_, 9223372036854775807L | -9223372036854775808L)),
        "extreme add",
      ),
      @quickcheck.classify(
        c.ops
        .iter()
        .any(op => op is Range(l, r) && l >= 0 && l <= r && r < c.init.length()),
        "valid range query",
      ),
    ]
  })
}
