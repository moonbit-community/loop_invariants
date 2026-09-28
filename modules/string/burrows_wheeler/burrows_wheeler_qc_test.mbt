// Property-based tests for the Burrows-Wheeler transform. The sentinel `-1`
// is appended by `transform` and callers must not include it in the text, so
// generated texts never contain -1 (other negative values are allowed: the
// sentinel only needs to be unique).

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
priv struct Text(Array[Int]) derive(Debug)

///|
impl @quickcheck.Arbitrary for Text with fn arbitrary(size, rs) {
  let len = rint(rs, 0, size)
  let k = rint(rs, 0, 3)
  Text(
    Array::makei(len, _ => {
      if k == 0 {
        let v : Int = @quickcheck.Arbitrary::arbitrary(size, rs)
        if v == -1 {
          -2
        } else {
          v
        }
      } else if k == 1 {
        // repetitive text: BWT is at its most interesting here
        [0, 1][rint(rs, 0, 1)]
      } else {
        rint(rs, 97, 99)
      }
    }),
  )
}

///|
impl @quickcheck.Shrink for Text with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0)
  .filter(a => !a.contains(-1))
  .map(a => Text(a))
}

///|
test "qc: inverse_transform(transform(x)) == x" {
  @quickcheck.check(
    (t : Text) => {
      @burrows_wheeler.inverse_transform(@burrows_wheeler.transform(t.0)) == t.0
    },
    observe=t => {
      [
        @quickcheck.classify(
          t.0.iter().any(v => v < -1),
          "values below the sentinel",
        ),
        @quickcheck.classify(t.0.length() > 10, "length > 10"),
      ]
    },
    count=500,
    max_size=30,
    seed=0xb3700001,
  )
}

///|
test "qc: transform is a permutation of text + sentinel, and the last column of sorted rotations" {
  @quickcheck.check(
    (t : Text) => {
      let x = t.0
      let bwt = @burrows_wheeler.transform(x)
      let ext = [..x, -1]
      let n = ext.length()
      // naive: sort the rotations explicitly, take the last column
      let rots = Array::makei(n, i => Array::makei(n, k => ext[(i + k) % n]))
      rots.sort()
      let last = rots.map(r => r[n - 1])
      let a = bwt.copy()
      a.sort()
      let b = ext.copy()
      b.sort()
      a == b && bwt == last
    },
    count=300,
    max_size=20,
    seed=0xb3700002,
  )
}
