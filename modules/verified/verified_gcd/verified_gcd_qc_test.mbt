///|
priv struct NonNeg(Int) derive(Debug)

///|
impl @quickcheck.Arbitrary for NonNeg with fn arbitrary(size, rs) {
  let g = @quickcheck.frequency([
    (3, @quickcheck.int_range(0, 64)),
    (2, @quickcheck.int_range(0, 100000).map(x => x * 6)),
    (1, @quickcheck.int_range(0, 31).map(k => 1 << k)),
    (1, @quickcheck.elements([@int.MAX_VALUE, 1 << 30, 3 * (1 << 29)])),
    (2, @quickcheck.int_range(0, @int.MAX_VALUE)),
  ])
  NonNeg(g.run(size, rs))
}

///|
impl @quickcheck.Shrink for NonNeg with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).filter(x => x >= 0).map(x => NonNeg(x))
}

///|
fn naive_gcd(a : Int, b : Int) -> Int {
  if a == 0 {
    return b
  }
  if b == 0 {
    return a
  }
  for d = (if a < b { a } else { b }); d >= 1; d = d - 1 {
    if a % d == 0 && b % d == 0 {
      return d
    }
  }
  1
}

///|
test "qc: gcd_euclid and gcd_binary agree with divisor search (small)" {
  @quickcheck.check(
    (p : (Int, Int)) => {
      let a = (p.0 % 300).abs()
      let b = (p.1 % 300).abs()
      let g = naive_gcd(a, b)
      @verified_gcd.gcd_euclid(a, b) == g && @verified_gcd.gcd_binary(a, b) == g
    },
    count=500,
    seed=0x6C_0001,
  )
}

///|
test "qc: gcd_euclid == gcd_binary, divides both, coprime cofactors" {
  @quickcheck.check(
    (p : (NonNeg, NonNeg)) => {
      let a = p.0.0
      let b = p.1.0
      let g = @verified_gcd.gcd_euclid(a, b)
      g == @verified_gcd.gcd_binary(a, b) &&
      (if a == 0 && b == 0 {
        g == 0
      } else {
        g > 0 &&
        a % g == 0 &&
        b % g == 0 &&
        @verified_gcd.gcd_euclid(a / g, b / g) == 1
      })
    },
    observe=p => {
      [
        @quickcheck.classify(
          @verified_gcd.gcd_euclid(p.0.0, p.1.0) > 1,
          "non-trivial gcd",
        ),
        @quickcheck.classify(p.0.0 == 0 || p.1.0 == 0, "zero argument"),
      ]
    },
    count=1000,
    seed=0x6C_0002,
  )
}
