// Property-based tests for `Fenwick2D` (1-indexed): operation sequences are
// replayed against a 2D `Array[Array[Int64]]` model with wrapping Int64 sums.
// Out-of-grid updates are ignored, `prefix_sum` returns 0 for non-positive
// coordinates and clamps large ones, so `range_sum` (inclusion-exclusion of
// four prefix sums) is the sum over the rectangle's intersection with the grid.

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
  Update(Int, Int, Int64)
  SetTo(Int, Int, Int64)
  Get(Int, Int)
  Prefix(Int, Int)
  Range(Int, Int, Int, Int)
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
  // Mostly in-grid, sometimes one or two cells outside on either side.
  let x = () => {
    if rint(rs, 0, 5) == 0 {
      rint(rs, -1, rows + 2)
    } else {
      rint(rs, 1, rows)
    }
  }
  let y = () => {
    if rint(rs, 0, 5) == 0 {
      rint(rs, -1, cols + 2)
    } else {
      rint(rs, 1, cols)
    }
  }
  let ops = Array::makei(rint(rs, 0, size), _ => {
    match rint(rs, 0, 5) {
      0 | 1 => Update(x(), y(), gen_val(rs))
      2 => SetTo(rint(rs, 1, rows), rint(rs, 1, cols), gen_val(rs))
      3 => Get(x(), y())
      4 => Prefix(x(), y())
      _ => Range(x(), y(), x(), y())
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
  let fw = @fenwick2d.Fenwick2D(c.rows, c.cols)
  if fw.get_rows() != c.rows || fw.get_cols() != c.cols {
    return false
  }
  // model[x][y] for 1 <= x <= rows, 1 <= y <= cols (row/col 0 unused).
  let model = Array::makei(c.rows + 1, _ => Array::make(c.cols + 1, 0L))
  let inside = (x : Int, y : Int) => {
    x >= 1 && x <= c.rows && y >= 1 && y <= c.cols
  }
  let rect = (x1 : Int, y1 : Int, x2 : Int, y2 : Int) => {
    let mut s = 0L
    for x in 1..<=c.rows {
      for y in 1..<=c.cols {
        if x >= x1 && x <= x2 && y >= y1 && y <= y2 {
          s = s + model[x][y]
        }
      }
    }
    s
  }
  for op in c.ops {
    match op {
      Update(x, y, d) => {
        fw.update(x, y, d)
        if inside(x, y) {
          model[x][y] = model[x][y] + d
        }
      }
      SetTo(x, y, v) => {
        fw.set(x, y, model[x][y], v)
        model[x][y] = v
      }
      Get(x, y) => {
        let expected = if inside(x, y) { model[x][y] } else { 0L }
        if fw.get(x, y) != expected {
          return false
        }
      }
      Prefix(x, y) =>
        if fw.prefix_sum(x, y) != rect(1, 1, x, y) {
          return false
        }
      Range(x1, y1, x2, y2) =>
        if fw.range_sum(x1, y1, x2, y2) != rect(x1, y1, x2, y2) {
          return false
        }
    }
  }
  for x in 1..<=c.rows {
    for y in 1..<=c.cols {
      if fw.get(x, y) != model[x][y] {
        return false
      }
    }
  }
  true
}

///|
test "qc: fenwick2d agrees with grid model" {
  @quickcheck.check(run_case, seed=0xF2D_0001, count=300, observe=c => {
    [
      @quickcheck.classify(c.rows == 1 || c.cols == 1, "single row or column"),
      @quickcheck.classify(c.rows >= 8 && c.cols >= 8, "at least 8x8"),
      @quickcheck.classify(
        c.ops
        .iter()
        .any(op => op is Range(x1, y1, x2, y2) && (x1 > x2 || y1 > y2)),
        "empty rectangle query",
      ),
    ]
  })
}
