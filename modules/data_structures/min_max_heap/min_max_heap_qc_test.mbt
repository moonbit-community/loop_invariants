// Property-based tests for `MinMaxHeap`: interleaved push / pop_min / pop_max /
// peeks are replayed against a sorted `Array[Int64]` model.

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
priv enum Op {
  Push(Int64)
  PopMin
  PopMax
  Peek
} derive(Debug)

///|
impl @quickcheck.Shrink for Op

///|
priv struct Ops(Array[Op]) derive(Debug)

///|
impl @quickcheck.Arbitrary for Ops with fn arbitrary(size, rs) {
  let small = rint(rs, 0, 1) == 0
  // Push-heavy phases so the heap gets several levels deep.
  let push_weight = rint(rs, 1, 6)
  Ops(
    Array::makei(rint(rs, 0, size * 2), _ => {
      let r = rint(rs, 0, push_weight + 2)
      if r < push_weight {
        Push(if small { rint(rs, -3, 3).to_int64() } else { gen_val(rs) })
      } else if r == push_weight {
        PopMin
      } else if r == push_weight + 1 {
        PopMax
      } else {
        Peek
      }
    }),
  )
}

///|
impl @quickcheck.Shrink for Ops with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).map(x => Ops(x))
}

///|
fn run_ops(ops : Ops) -> Bool {
  let h = @min_max_heap.MinMaxHeap::new()
  let model : Array[Int64] = []
  for op in ops.0 {
    match op {
      Push(x) => {
        h.push(x)
        model.push(x)
        model.sort()
      }
      PopMin => {
        let expected = if model.length() == 0 {
          None
        } else {
          Some(model.remove(0))
        }
        if h.pop_min() != expected {
          return false
        }
      }
      PopMax => if h.pop_max() != model.pop() { return false }
      Peek => {
        let n = model.length()
        if h.peek_min() != (if n == 0 { None } else { Some(model[0]) }) ||
          h.peek_max() != (if n == 0 { None } else { Some(model[n - 1]) }) {
          return false
        }
      }
    }
    if h.length() != model.length() || h.is_empty() != (model.length() == 0) {
      return false
    }
  }
  // Drain alternately from both ends.
  let mut from_min = true
  while model.length() > 0 {
    let ok = if from_min {
      h.pop_min() == Some(model.remove(0))
    } else {
      h.pop_max() == model.pop()
    }
    if !ok {
      return false
    }
    from_min = !from_min
  }
  h.pop_min() is None && h.pop_max() is None
}

///|
test "qc: min-max heap agrees with sorted model" {
  @quickcheck.check(run_ops, seed=0x313_4EA9, count=400, observe=ops => {
    let mut size = 0
    let mut peak = 0
    for op in ops.0 {
      match op {
        Push(_) => size = size + 1
        PopMin | PopMax => if size > 0 { size = size - 1 }
        Peek => ()
      }
      if size > peak {
        peak = size
      }
    }
    [
      @quickcheck.classify(peak >= 7, "peak size >= 7 (3+ levels)"),
      @quickcheck.classify(peak >= 31, "peak size >= 31 (5+ levels)"),
    ]
  })
}
