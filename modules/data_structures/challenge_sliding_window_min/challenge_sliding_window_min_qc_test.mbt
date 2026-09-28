// Property-based tests for `sliding_window_min`: for `0 < k <= n` the result
// has `n - k + 1` entries, entry `i` being the minimum of `arr[i:i+k]`; any
// other `k` yields `[]`.

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
priv struct Case {
  arr : Array[Int]
  k : Int
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Case with fn arbitrary(size, rs) {
  let n = rint(rs, 0, size)
  let narrow = rint(rs, 0, 1) == 0
  let arr = Array::makei(n, _ => {
    if narrow {
      rint(rs, 0, 3)
    } else {
      gen_int(rs)
    }
  })
  { arr, k: rint(rs, -1, n + 1), }
}

///|
impl @quickcheck.Shrink for Case with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.arr, self.k)).map(p => { arr: p.0, k: p.1, })
}

///|
test "qc: sliding_window_min agrees with naive window minima" {
  @quickcheck.check(
    (c : Case) => {
      let n = c.arr.length()
      let k = c.k
      let expected : Array[Int] = if k > 0 && k <= n {
        Array::makei(n - k + 1, i => {
          let mut m = c.arr[i]
          for j in i..<(i + k) {
            if c.arr[j] < m {
              m = c.arr[j]
            }
          }
          m
        })
      } else {
        []
      }
      @challenge_sliding_window_min.sliding_window_min(c.arr[:], k) == expected
    },
    seed=0x51D_0001,
    count=300,
    observe=c => {
      [
        @quickcheck.classify(c.k <= 0 || c.k > c.arr.length(), "degenerate k"),
        @quickcheck.classify(c.k == 1, "k = 1"),
        @quickcheck.classify(c.k > 1 && c.k == c.arr.length(), "k = n > 1"),
      ]
    },
  )
}
