///|
/// Non-empty arrays whose subarray sums fit in Int (|x| <= 10^6, len <= 60).
priv struct NonEmpty(Array[Int]) derive(Debug)

///|
impl @quickcheck.Arbitrary for NonEmpty with fn arbitrary(size, rs) {
  let elem = @quickcheck.frequency([
    (3, @quickcheck.int_range(-5, 6)),
    (1, @quickcheck.int_range(-1000000, 1000001)),
  ])
  let n = @quickcheck.int_range(1, (if size < 60 { size } else { 60 }) + 2).run(
    size, rs,
  )
  NonEmpty(elem.array_with_size(n).run(size, rs))
}

///|
impl @quickcheck.Shrink for NonEmpty with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0)
  .filter(xs => xs.length() > 0)
  .map(xs => NonEmpty(xs))
}

///|
test "qc: max_subarray_sum agrees with brute force over all (l, r)" {
  @quickcheck.check(
    (xs : NonEmpty) => {
      let xs = xs.0
      let mut best = xs[0]
      for l in 0..<xs.length() {
        let mut s = 0
        for r in l..<xs.length() {
          s = s + xs[r]
          if s > best {
            best = s
          }
        }
      }
      @verified_kadane.max_subarray_sum(xs[:]) == best
    },
    observe=xs => {
      [@quickcheck.classify(xs.0.iter().all(x => x < 0), "all negative")]
    },
    count=500,
    seed=0x4AD_0001,
  )
}
