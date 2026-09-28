///|
/// Exact `p * p > m` for `0 < p < 2^32`, `m >= 0` (the square fits in UInt64).
fn exact_guard(p : Int64, m : Int64) -> Bool {
  p.reinterpret_as_uint64() * p.reinterpret_as_uint64() >
  m.reinterpret_as_uint64()
}

///|
test "square guard square_exceeds is exact where p * p wraps Int64" {
  // Fast, always-on coverage for the fix of the `p * p` overflow in the
  // trial-division loop (the end-to-end regression test is #skip'd because
  // it runs ~10^9 iterations).
  let big_prime = 9223372036854775783L // > 3037000499^2
  let max = 9223372036854775807L
  // 3037000501 * 3037000501 wraps to a negative Int64, so the old guard
  // `p * p > m` gave the wrong answer here; the new one must not.
  @debug.assert_eq(3037000501L * 3037000501L < 0L, true)
  @debug.assert_eq(square_exceeds(3037000501L, big_prime), true)
  for
    m in [big_prime, max, max - 1L, 9223372030926249001L, 9223372030926249000L] {
    for p in 3037000490L..<=3037000510L {
      @debug.assert_eq(square_exceeds(p, m), exact_guard(p, m))
    }
  }
  // exhaustive on small values, including perfect squares and neighbours
  for m in 0L..<=400L {
    for p in 1L..<=25L {
      @debug.assert_eq(square_exceeds(p, m), exact_guard(p, m))
    }
  }
}
