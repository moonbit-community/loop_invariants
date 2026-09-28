// Property-based tests for the challenge 2D Fenwick tree (0-indexed cells,
// half-open rectangles `[r1, r2) x [c1, c2)` with in-grid bounds), replayed
// against a 2D `Array[Array[Int]]` model with wrapping sums.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Mostly small Ints, sometimes full-range values (including the extrema);
/// arithmetic wraps identically in the implementation and the model.
fn gen_int(rs : @quickcheck.RandomState) -> Int {
  match rint(rs, 0, 7) {
    0 => @quickcheck.Arbitrary::arbitrary(0, rs)
    1 => [2147483647, -2147483648][rint(rs, 0, 1)]
    _ => rint(rs, -20, 20)
  }
}

///|
priv enum Op {
  Add(Int, Int, Int)
  Rect(Int, Int, Int, Int)
} derive(Debug)

///|
impl @quickcheck.Shrink for Op

///|
priv struct Case {
  rows : Int
  cols : Int
  ops : Array[Op]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Case with fn arbitrary(size, rs) {
  let rows = rint(rs, 1, 9)
  let cols = rint(rs, 1, 9)
  let ops = Array::makei(rint(rs, 0, size), _ => {
    if rint(rs, 0, 1) == 0 {
      Add(rint(rs, 0, rows - 1), rint(rs, 0, cols - 1), gen_int(rs))
    } else {
      let (a, b) = (rint(rs, 0, rows), rint(rs, 0, rows))
      let (c, d) = (rint(rs, 0, cols), rint(rs, 0, cols))
      Rect(
        if a < b {
          a
        } else {
          b
        },
        if c < d {
          c
        } else {
          d
        },
        if a < b {
          b
        } else {
          a
        },
        if c < d {
          d
        } else {
          c
        },
      )
    }
  })
  { rows, cols, ops, }
}

///|
impl @quickcheck.Shrink for Case with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.ops).map(ops => { ..self, ops, })
}

///|
fn run_case(c : Case) -> Bool {
  let fw = @challenge_fenwick_2d.Fenwick2D(c.rows, c.cols)
  let model = Array::makei(c.rows, _ => Array::make(c.cols, 0))
  let rect = (r1 : Int, c1 : Int, r2 : Int, c2 : Int) => {
    let mut s = 0
    for r in r1..<r2 {
      for col in c1..<c2 {
        s = s + model[r][col]
      }
    }
    s
  }
  for op in c.ops {
    match op {
      Add(r, col, d) => {
        fw.add(r, col, d)
        model[r][col] = model[r][col] + d
      }
      Rect(r1, c1, r2, c2) =>
        if fw.range_sum(r1, c1, r2, c2) != rect(r1, c1, r2, c2) {
          return false
        }
    }
  }
  (0)
  .until(c.rows + 1)
  .all(r => {
    (0)
    .until(c.cols + 1)
    .all(col => fw.prefix_sum(r, col) == rect(0, 0, r, col))
  })
}

///|
test "qc: challenge fenwick 2d agrees with grid model" {
  @quickcheck.check(run_case, seed=0xCF2_0001, count=200, observe=c => {
    [
      @quickcheck.classify(c.rows == 1 || c.cols == 1, "single row or column"),
      @quickcheck.classify(c.rows * c.cols >= 49, ">= 49 cells"),
    ]
  })
}
