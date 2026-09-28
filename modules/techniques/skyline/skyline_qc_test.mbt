// Property-based tests for the skyline sweep, compared with a brute-force
// evaluation of the height function `h(x) = max { h_i : l_i <= x < r_i }`
// at every building edge.

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
/// Buildings `(l, r, h)` with `l <= r` and `h >= 0`. Coordinates come from a
/// tiny range (shared edges, nested and touching buildings are common) or
/// include the `Int64` extrema; heights repeat often.
priv struct City {
  bs : Array[(Int64, Int64, Int64)]
} derive(Debug)

///|
fn coord(rs : @quickcheck.RandomState, wide : Bool) -> Int64 {
  if wide && rint(rs, 0, 3) == 0 {
    [LMIN, LMAX, LMIN + 1L, LMAX - 1L][rint(rs, 0, 3)]
  } else {
    rint(rs, -2, 10).to_int64()
  }
}

///|
fn normalize(b : (Int64, Int64, Int64)) -> (Int64, Int64, Int64) {
  let (l, r, h) = b
  let (l, r) = if l <= r { (l, r) } else { (r, l) }
  (l, r, if h < 0L { h.lnot() } else { h })
}

///|
impl @quickcheck.Arbitrary for City with fn arbitrary(size, rs) {
  let wide = rint(rs, 0, 3) == 0
  let bs = Array::makei(rint(rs, 0, size), _ => {
    let h = if rint(rs, 0, 7) == 0 {
      [LMAX, 0L][rint(rs, 0, 1)]
    } else {
      rint(rs, 1, 5).to_int64()
    }
    normalize((coord(rs, wide), coord(rs, wide), h))
  })
  { bs, }
}

///|
impl @quickcheck.Shrink for City with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.bs).map(bs => { bs: bs.map(normalize), })
}

///|
fn height_at(bs : Array[(Int64, Int64, Int64)], x : Int64) -> Int64 {
  let mut h = 0L
  for b in bs {
    if b.0 <= x && x < b.1 && b.2 > h {
      h = b.2
    }
  }
  h
}

///|
fn ref_skyline(bs : Array[(Int64, Int64, Int64)]) -> Array[(Int64, Int64)] {
  let xs : Array[Int64] = []
  for b in bs {
    xs.push(b.0)
    xs.push(b.1)
  }
  xs.sort()
  xs.dedup()
  let res : Array[(Int64, Int64)] = []
  let mut prev = 0L
  for x in xs {
    let h = height_at(bs, x)
    if h != prev {
      res.push((x, h))
      prev = h
    }
  }
  res
}

///|
test "qc: skyline matches brute-force heights at every edge" {
  @quickcheck.check(
    (c : City) => @skyline.compute(c.bs) == ref_skyline(c.bs),
    count=400,
    max_size=25,
    max_shrinks=2000,
    seed=141,
    observe=c => {
      let sky = ref_skyline(c.bs)
      [
        @quickcheck.classify(c.bs.length() == 0, "no buildings"),
        @quickcheck.classify(sky.length() >= 6, ">= 6 key points"),
        @quickcheck.classify(
          c.bs.iter().any(b => b.0 == b.1),
          "zero-width building",
        ),
        @quickcheck.classify(
          c.bs.iter().any(b => b.0 == LMIN || b.1 == LMAX),
          "Int64 extreme coordinate",
        ),
      ]
    },
  )
}

///|
test "qc: skyline key points are strictly increasing in x and end at height 0" {
  @quickcheck.check(
    (c : City) => {
      let sky = @skyline.compute(c.bs)
      for i in 1..<sky.length() {
        if sky[i - 1].0 >= sky[i].0 || sky[i - 1].1 == sky[i].1 {
          return false
        }
      }
      sky.length() == 0 || sky[sky.length() - 1].1 == 0L
    },
    seed=142,
  )
}
