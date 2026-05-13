///|
test "verified_gcd_small_cases" {
  @debug.assert_eq(@verified_gcd.gcd_euclid(0, 0), 0)
  @debug.assert_eq(@verified_gcd.gcd_euclid(0, 5), 5)
  @debug.assert_eq(@verified_gcd.gcd_euclid(5, 0), 5)
  @debug.assert_eq(@verified_gcd.gcd_euclid(12, 18), 6)
  @debug.assert_eq(@verified_gcd.gcd_euclid(17, 31), 1)
  @debug.assert_eq(@verified_gcd.gcd_binary(0, 0), 0)
  @debug.assert_eq(@verified_gcd.gcd_binary(0, 5), 5)
  @debug.assert_eq(@verified_gcd.gcd_binary(5, 0), 5)
  @debug.assert_eq(@verified_gcd.gcd_binary(12, 18), 6)
  @debug.assert_eq(@verified_gcd.gcd_binary(17, 31), 1)
}

///|
test "verified_gcd_euclid_and_binary_agree" {
  // Sweep all pairs in [0, 30] x [0, 30] and check that the two
  // implementations agree everywhere.
  for a = 0; a <= 30; a = a + 1 {
    for b = 0; b <= 30; b = b + 1 {
      let e = @verified_gcd.gcd_euclid(a, b)
      let s = @verified_gcd.gcd_binary(a, b)
      @debug.assert_eq(e, s)
    }
  }
}

///|
test "verified_gcd_powers_of_two" {
  @debug.assert_eq(@verified_gcd.gcd_euclid(1024, 768), 256)
  @debug.assert_eq(@verified_gcd.gcd_binary(1024, 768), 256)
  @debug.assert_eq(@verified_gcd.gcd_euclid(2048, 2048), 2048)
  @debug.assert_eq(@verified_gcd.gcd_binary(2048, 2048), 2048)
  @debug.assert_eq(@verified_gcd.gcd_euclid(1, 1024), 1)
  @debug.assert_eq(@verified_gcd.gcd_binary(1, 1024), 1)
}

///|
test "verified_gcd_fibonacci_worst_case" {
  // Adjacent Fibonacci numbers are coprime and form the worst case for
  // the Euclidean algorithm (Lamé's theorem).
  // F(19) = 4181, F(20) = 6765, gcd = 1.
  @debug.assert_eq(@verified_gcd.gcd_euclid(6765, 4181), 1)
  @debug.assert_eq(@verified_gcd.gcd_binary(6765, 4181), 1)
  // A few more adjacent Fibonacci pairs for good measure.
  @debug.assert_eq(@verified_gcd.gcd_euclid(2584, 1597), 1)
  @debug.assert_eq(@verified_gcd.gcd_binary(2584, 1597), 1)
}

///|
test "verified_gcd_known_values" {
  @debug.assert_eq(@verified_gcd.gcd_euclid(48, 18), 6)
  @debug.assert_eq(@verified_gcd.gcd_binary(48, 18), 6)
  @debug.assert_eq(@verified_gcd.gcd_euclid(100, 75), 25)
  @debug.assert_eq(@verified_gcd.gcd_binary(100, 75), 25)
  @debug.assert_eq(@verified_gcd.gcd_euclid(81, 27), 27)
  @debug.assert_eq(@verified_gcd.gcd_binary(81, 27), 27)
  @debug.assert_eq(@verified_gcd.gcd_euclid(7, 13), 1)
  @debug.assert_eq(@verified_gcd.gcd_binary(7, 13), 1)
}
