///|
/// Division arguments with `n >= 0`, `d > 0`, and a quotient small enough
/// (<= 10^5) for the repeated-subtraction loop to stay fast. Boundary values
/// such as `n = Int max` are included.
priv struct DivArgs((Int, Int)) derive(Debug)

///|
impl @quickcheck.Arbitrary for DivArgs with fn arbitrary(size, rs) {
  let n_gen = @quickcheck.frequency([
    (3, @quickcheck.int_range(0, 1000)),
    (1, @quickcheck.elements([0, 1, @int.MAX_VALUE, @int.MAX_VALUE - 1])),
    (2, @quickcheck.int_range(0, @int.MAX_VALUE)),
  ])
  let n = n_gen.run(size, rs)
  // Choose d so that n / d <= 100000.
  let min_d = n / 100000 + 1
  let d = @quickcheck.frequency([
    (3, @quickcheck.int_range(min_d, min_d + 1000)),
    (1, @quickcheck.pure(if n > 0 { n } else { 1 })),
    (1, @quickcheck.int_range(min_d, @int.MAX_VALUE)),
    (1, @quickcheck.pure(@int.MAX_VALUE)),
  ]).run(size, rs)
  DivArgs((n, d))
}

///|
impl @quickcheck.Shrink for DivArgs with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0)
  .filter(p => p.0 >= 0 && p.1 > 0 && p.0 / p.1 <= 100000)
  .map(p => DivArgs(p))
}

///|
test "qc: div_nonneg / mod_nonneg / div_mod_nonneg agree with / and %" {
  @quickcheck.check(
    (a : DivArgs) => {
      let (n, d) = a.0
      @verified_division.div_nonneg(n, d) == n / d &&
      @verified_division.mod_nonneg(n, d) == n % d &&
      @verified_division.div_mod_nonneg(n, d) == (n / d, n % d)
    },
    observe=a => {
      [
        @quickcheck.classify(a.0.0 == @int.MAX_VALUE, "n = Int max"),
        @quickcheck.classify(a.0.0 < a.0.1, "n < d"),
      ]
    },
    count=1000,
    seed=0xD1_0001,
  )
}

///|
test "regression: div_nonneg with n = Int max" {
  // The loop guard `q < n + 1` overflowed, so the loop never ran.
  @debug.assert_eq(
    @verified_division.div_nonneg(@int.MAX_VALUE, @int.MAX_VALUE),
    1,
  )
  @debug.assert_eq(
    @verified_division.mod_nonneg(@int.MAX_VALUE, @int.MAX_VALUE),
    0,
  )
  @debug.assert_eq(
    @verified_division.div_mod_nonneg(@int.MAX_VALUE, 1 << 30),
    (1, (1 << 30) - 1),
  )
}
