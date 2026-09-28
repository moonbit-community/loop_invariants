// Property-based tests for `coordinate_compress`: `unique` is the strictly
// increasing set of input values, `compressed[i]` indexes `values[i]` in it,
// and the mapping preserves order.

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
priv struct Values(Array[Int]) derive(Debug)

///|
impl @quickcheck.Arbitrary for Values with fn arbitrary(size, rs) {
  let narrow = rint(rs, 0, 1) == 0
  Values(
    Array::makei(rint(rs, 0, size), _ => {
      if narrow {
        rint(rs, -3, 3)
      } else {
        gen_int(rs)
      }
    }),
  )
}

///|
impl @quickcheck.Shrink for Values with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).map(xs => Values(xs))
}

///|
test "qc: coordinate_compress is an order-preserving rank map" {
  @quickcheck.check(
    (v : Values) => {
      let values = v.0
      let (compressed, unique) = @challenge_coordinate_compress.coordinate_compress(
        values[:],
      )
      let n = values.length()
      compressed.length() == n &&
      // unique is strictly increasing ...
      (1).until(unique.length()).all(i => unique[i - 1] < unique[i]) &&
      // ... and contains exactly the input values
      unique.iter().all(u => values.contains(u)) &&
      (0)
      .until(n)
      .all(i => {
        let c = compressed[i]
        c >= 0 && c < unique.length() && unique[c] == values[i]
      }) &&
      (0)
      .until(n)
      .all(i => {
        (0)
        .until(n)
        .all(j => (compressed[i] < compressed[j]) == (values[i] < values[j]))
      })
    },
    seed=0xC0_0C0,
    count=300,
    observe=v => {
      let (_, unique) = @challenge_coordinate_compress.coordinate_compress(
        v.0[:],
      )
      [
        @quickcheck.classify(v.0.length() == 0, "empty"),
        @quickcheck.classify(unique.length() < v.0.length(), "has duplicates"),
        @quickcheck.classify(
          v.0.iter().any(x => x == 2147483647 || x == -2147483648),
          "contains Int extremum",
        ),
      ]
    },
  )
}
