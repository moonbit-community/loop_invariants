// Property-based tests for the persistent `SkewHeap`: a random history of
// push / pop_min / merge operations over *versions* is replayed against sorted
// `Array[Int64]` models. Every version (not just the latest) is re-checked
// after each step, so any mutation of an older heap is detected.

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
/// Operations refer to earlier versions by `index % versions.length()`.
priv enum Op {
  Push(Int, Int64)
  Pop(Int)
  Merge(Int, Int)
} derive(Debug)

///|
impl @quickcheck.Shrink for Op

///|
priv struct Ops(Array[Op]) derive(Debug)

///|
impl @quickcheck.Arbitrary for Ops with fn arbitrary(size, rs) {
  let small = rint(rs, 0, 1) == 0
  let v = () => if small { rint(rs, -3, 3).to_int64() } else { gen_val(rs) }
  Ops(
    Array::makei(rint(rs, 0, size), _ => {
      match rint(rs, 0, 5) {
        0 | 1 | 2 => Push(rint(rs, 0, 1000), v())
        3 | 4 => Pop(rint(rs, 0, 1000))
        _ => Merge(rint(rs, 0, 1000), rint(rs, 0, 1000))
      }
    }),
  )
}

///|
impl @quickcheck.Shrink for Ops with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).map(x => Ops(x))
}

///|
fn sorted(xs : Array[Int64]) -> Array[Int64] {
  let ys = xs.copy()
  ys.sort()
  ys
}

///|
fn agrees(h : @skew_heap.SkewHeap, model : Array[Int64]) -> Bool {
  h.length() == model.length() &&
  h.is_empty() == (model.length() == 0) &&
  h.peek_min() == (if model.length() == 0 { None } else { Some(model[0]) })
}

///|
fn drain(h : @skew_heap.SkewHeap) -> Array[Int64] {
  let out : Array[Int64] = []
  for cur = h {
    match cur.pop_min() {
      Some((x, rest)) => {
        out.push(x)
        continue rest
      }
      None => break
    }
  }
  out
}

///|
fn run_ops(ops : Ops) -> Bool {
  let heaps : Array[@skew_heap.SkewHeap] = [@skew_heap.SkewHeap::new()]
  let models : Array[Array[Int64]] = [[]]
  for op in ops.0 {
    let k = heaps.length()
    match op {
      Push(i, x) => {
        heaps.push(heaps[i % k].push(x))
        models.push(sorted([..models[i % k], x]))
      }
      Pop(i) =>
        match (heaps[i % k].pop_min(), models[i % k]) {
          (None, []) => ()
          (Some((x, rest)), [m, .. ms]) => {
            if x != m {
              return false
            }
            heaps.push(rest)
            models.push(ms.to_owned())
          }
          _ => return false
        }
      Merge(i, j) => {
        heaps.push(heaps[i % k].merge(heaps[j % k]))
        models.push(sorted([..models[i % k], ..models[j % k]]))
      }
    }
    for v in 0..<heaps.length() {
      if !agrees(heaps[v], models[v]) {
        return false
      }
    }
  }
  for v in 0..<heaps.length() {
    if drain(heaps[v]) != models[v] {
      return false
    }
  }
  true
}

///|
test "qc: SkewHeap versions agree with sorted models" {
  @quickcheck.check(run_ops, seed=0x4EA9_0041, count=200, observe=ops => {
    let merges = ops.0.iter().filter(op => op is Merge(_, _)).count()
    [
      @quickcheck.classify(merges > 0, "has merge"),
      @quickcheck.classify(ops.0.length() >= 50, ">= 50 ops"),
    ]
  })
}

///|
test "qc: SkewHeap merge then drain is sorted concatenation" {
  @quickcheck.check(
    (ab : (Array[Int64], Array[Int64])) => {
      let (a, b) = ab
      let build = (xs : Array[Int64]) => {
        xs.fold(init=@skew_heap.SkewHeap::new(), (h, x) => h.push(x))
      }
      let ha = build(a)
      let hb = build(b)
      drain(ha.merge(hb)) == sorted([..a, ..b]) &&
      drain(hb.merge(ha)) == sorted([..a, ..b]) &&
      // merging does not disturb the inputs
      drain(ha) == sorted(a) &&
      drain(hb) == sorted(b)
    },
    seed=0x4EA9_0042,
    count=200,
  )
}
