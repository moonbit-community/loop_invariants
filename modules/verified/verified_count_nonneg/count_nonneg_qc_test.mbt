///|
test "qc: count_nonneg counts entries >= 0 within [0, length]" {
  @quickcheck.check(
    (xs : Array[Int]) => {
      let fa = FixedArray::from_array(xs)
      let c = @verified_count_nonneg.count_nonneg(fa)
      // count_bounded(xs, c) is 0 <= c <= xs.length()
      c == xs.filter(x => x >= 0).length() && 0 <= c && c <= xs.length()
    },
    count=500,
    seed=0xC0_0001,
  )
}
