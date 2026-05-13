///|
test "verified_upper_bound_examples" {
  let xs = FixedArray::make(6, 0)
  xs[0] = 1
  xs[1] = 3
  xs[2] = 3
  xs[3] = 7
  xs[4] = 9
  xs[5] = 9
  assert_eq(@verified_upper_bound.upper_bound(xs, 0), 0)
  assert_eq(@verified_upper_bound.upper_bound(xs, 3), 3)
  assert_eq(@verified_upper_bound.upper_bound(xs, 8), 4)
  assert_eq(@verified_upper_bound.upper_bound(xs, 9), 6)
}
