///|
test "@verified_isqrt.isqrt" {
  @debug.assert_eq(@verified_isqrt.isqrt(0), 0)
  @debug.assert_eq(@verified_isqrt.isqrt(1), 1)
  @debug.assert_eq(@verified_isqrt.isqrt(2), 1)
  @debug.assert_eq(@verified_isqrt.isqrt(3), 1)
  @debug.assert_eq(@verified_isqrt.isqrt(4), 2)
  @debug.assert_eq(@verified_isqrt.isqrt(15), 3)
  @debug.assert_eq(@verified_isqrt.isqrt(16), 4)
}
