// Property-based tests for `max_overlap` on half-open intervals `[l, r)` with
// `l < r`: the count is compared with a brute-force maximum over all left
// endpoints, and the witness point must attain it.

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
/// Forces `l < r` (the documented precondition) without leaving `Int64`.
fn normalize(iv : (Int64, Int64)) -> (Int64, Int64) {
  let (l, r) = iv
  let (l, r) = if l <= r { (l, r) } else { (r, l) }
  if l < r {
    (l, r)
  } else if r == LMAX {
    (l - 1L, r)
  } else {
    (l, r + 1L)
  }
}

///|
priv struct Ivs {
  ivs : Array[(Int64, Int64)]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Ivs with fn arbitrary(size, rs) {
  let wide = rint(rs, 0, 3) == 0
  let pt = () => {
    if wide && rint(rs, 0, 3) == 0 {
      [LMIN, LMAX, 0L][rint(rs, 0, 2)]
    } else {
      rint(rs, -2, 8).to_int64()
    }
  }
  let ivs = Array::makei(rint(rs, 0, size), _ => normalize((pt(), pt())))
  { ivs, }
}

///|
impl @quickcheck.Shrink for Ivs with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.ivs).map(ivs => { ivs: ivs.map(normalize), })
}

///|
fn depth_at(ivs : Array[(Int64, Int64)], p : Int64) -> Int {
  ivs.iter().filter(iv => iv.0 <= p && p < iv.1).count()
}

///|
fn ref_max(ivs : Array[(Int64, Int64)]) -> Int {
  let mut best = 0
  for iv in ivs {
    let d = depth_at(ivs, iv.0)
    if d > best {
      best = d
    }
  }
  best
}

///|
test "qc: max_overlap count is the brute-force maximum depth" {
  @quickcheck.check(
    (c : Ivs) => @sweep_line_max_overlap.max_overlap(c.ivs).0 == ref_max(c.ivs),
    count=400,
    max_size=30,
    max_shrinks=2000,
    seed=151,
    observe=c => {
      let m = ref_max(c.ivs)
      [
        @quickcheck.classify(c.ivs.length() == 0, "no intervals"),
        @quickcheck.classify(m >= 3, "depth >= 3"),
        @quickcheck.classify(
          c.ivs.iter().any(a => c.ivs.iter().any(b => a.1 == b.0)),
          "touching intervals",
        ),
      ]
    },
  )
}

///|
test "qc: max_overlap witness point attains the maximum" {
  @quickcheck.check(
    (c : Ivs) => {
      let (best, w) = @sweep_line_max_overlap.max_overlap(c.ivs)
      if c.ivs.length() == 0 {
        best == 0 && w == 0L
      } else {
        depth_at(c.ivs, w) == best
      }
    },
    count=300,
    max_size=30,
    max_shrinks=2000,
    seed=152,
  )
}
