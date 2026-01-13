///|
test "pollard rho primes" {
  assert_true(@pollard_rho.is_prime(2L))
  assert_true(@pollard_rho.is_prime(3L))
  assert_true(@pollard_rho.is_prime(99991L))
  assert_true(not(@pollard_rho.is_prime(1L)))
  assert_true(not(@pollard_rho.is_prime(221L))) // 13 * 17
}

///|
test "pollard rho factorize" {
  let factors = @pollard_rho.factorize_with_counts(8051L)
  inspect(factors, content="[(83, 1), (97, 1)]")
}

///|
test "pollard rho composite with repeats" {
  let factors = @pollard_rho.factorize_with_counts(360L)
  inspect(factors, content="[(2, 3), (3, 2), (5, 1)]")
}
