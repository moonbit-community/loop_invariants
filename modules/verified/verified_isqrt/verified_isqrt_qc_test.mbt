///|
/// Non-negative Int inputs: small values, perfect squares and their
/// neighbours, overflow-prone boundaries, and uniform non-negative values.
priv struct NonNeg(Int) derive(Debug)

///|
impl @quickcheck.Arbitrary for NonNeg with fn arbitrary(size, rs) {
  let g = @quickcheck.frequency([
    (3, @quickcheck.int_range(0, 50)),
    (2, @quickcheck.int_range(0, 1000000)),
    (
      2,
      @quickcheck.int_range(1, 46341).flat_map(r => {
        @quickcheck.int_range(-1, 2).map(d => r * r + d)
      }),
    ),
    (
      1,
      @quickcheck.elements([
        @int.MAX_VALUE,
        @int.MAX_VALUE - 1,
        2147395599,
        2147395600,
        92681,
        1 << 30,
      ]),
    ),
    (2, @quickcheck.int_range(0, @int.MAX_VALUE)),
  ])
  NonNeg(g.run(size, rs))
}

///|
impl @quickcheck.Shrink for NonNeg with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).filter(x => x >= 0).map(x => NonNeg(x))
}

///|
test "qc: isqrt satisfies r*r <= n < (r+1)*(r+1) for every non-negative Int" {
  @quickcheck.check(
    (x : NonNeg) => {
      let n = x.0.to_int64()
      let r = @verified_isqrt.isqrt(x.0).to_int64()
      r >= 0L && r * r <= n && (r + 1L) * (r + 1L) > n
    },
    observe=x => [@quickcheck.classify(x.0 > 92681, "mid*mid exceeds Int")],
    count=2000,
    seed=0x15_0001,
  )
}

///|
test "regression: isqrt for n where mid * mid or n + 1 overflows Int" {
  @debug.assert_eq(@verified_isqrt.isqrt(92681), 304)
  @debug.assert_eq(@verified_isqrt.isqrt(100000), 316)
  @debug.assert_eq(@verified_isqrt.isqrt(2147395600), 46340)
  @debug.assert_eq(@verified_isqrt.isqrt(@int.MAX_VALUE), 46340)
}
