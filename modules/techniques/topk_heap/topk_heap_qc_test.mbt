// Property-based tests for the bounded min-heap top-k: offline and streaming
// results are compared with "sort descending and take k".

///|
const LMAX : Int64 = 9223372036854775807L

///|
const LMIN : Int64 = -9223372036854775808L

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// `Int64` arrays whose elements come from one of three regimes: a tiny range
/// (many duplicates), full-range `Int64` (hits the extrema), or a per-element
/// mix of small values and `Int64` extrema.
priv struct I64s {
  xs : Array[Int64]
}

///|
impl @quickcheck.Arbitrary for I64s with fn arbitrary(size, rs) {
  let len = rint(rs, 0, size)
  let mode = rint(rs, 0, 3)
  let xs = Array::makei(len, _ => {
    match mode {
      0 | 1 => rint(rs, -3, 3).to_int64()
      2 => @quickcheck.Arbitrary::arbitrary(size, rs)
      _ =>
        if rint(rs, 0, 3) == 0 {
          [LMAX, LMIN, 0L, LMAX - 1L][rint(rs, 0, 3)]
        } else {
          rint(rs, -3, 3).to_int64()
        }
    }
  })
  { xs, }
}

///|
fn ref_top_k(xs : Array[Int64], k : Int) -> Array[Int64] {
  let s = xs.copy()
  s.sort_by((a, b) => b.compare(a))
  let m = if k < 0 { 0 } else if k > s.length() { s.length() } else { k }
  s[:m].to_owned()
}

///|
priv struct TopCase {
  xs : Array[Int64]
  k : Int
} derive(Debug)

///|
impl @quickcheck.Arbitrary for TopCase with fn arbitrary(size, rs) {
  let a : I64s = @quickcheck.Arbitrary::arbitrary(size, rs)
  let n = a.xs.length()
  let k = match rint(rs, 0, 7) {
    0 => rint(rs, -3, 0)
    1 => n + rint(rs, 0, 3)
    _ => rint(rs, 1, if n < 1 { 1 } else { n })
  }
  { xs: a.xs, k, }
}

///|
impl @quickcheck.Shrink for TopCase with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.xs, self.k)).map(p => { xs: p.0, k: p.1, })
}

///|
test "qc: top_k equals sort-descending-then-take-k" {
  @quickcheck.check(
    (c : TopCase) => @topk_heap.top_k(c.xs, c.k) == ref_top_k(c.xs, c.k),
    count=400,
    max_size=60,
    max_shrinks=1000,
    seed=91,
    observe=c => {
      [
        @quickcheck.classify(c.k <= 0, "k <= 0"),
        @quickcheck.classify(c.k >= c.xs.length() && c.k > 0, "k >= n"),
        @quickcheck.classify(c.k > 0 && c.k < c.xs.length(), "0 < k < n"),
      ]
    },
  )
}

///|
test "qc: streaming TopK tracks the top k of every prefix" {
  @quickcheck.check(
    (c : TopCase) => {
      let t = @topk_heap.new(c.k)
      if t.capacity() != (if c.k < 0 { 0 } else { c.k }) || t.length() != 0 {
        return false
      }
      for i, x in c.xs {
        t.add(x)
        let expected = ref_top_k(c.xs[:i + 1].to_owned(), c.k)
        if t.top_k_sorted() != expected || t.length() != expected.length() {
          return false
        }
      }
      true
    },
    count=300,
    max_size=40,
    max_shrinks=1000,
    seed=92,
  )
}
