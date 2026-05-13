///|
test "@verified_isqrt.isqrt" {
  assert_eq(@verified_isqrt.isqrt(0), 0)
  assert_eq(@verified_isqrt.isqrt(1), 1)
  assert_eq(@verified_isqrt.isqrt(2), 1)
  assert_eq(@verified_isqrt.isqrt(3), 1)
  assert_eq(@verified_isqrt.isqrt(4), 2)
  assert_eq(@verified_isqrt.isqrt(15), 3)
  assert_eq(@verified_isqrt.isqrt(16), 4)
}
