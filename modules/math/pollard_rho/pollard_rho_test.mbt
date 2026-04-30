///|
test "pollard rho composite with repeats" {
  let factors = @pollard_rho.factorize_with_counts(360L)
  inspect(factors, content="[(2, 3), (3, 2), (5, 1)]")
}
