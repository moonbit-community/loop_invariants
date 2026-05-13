///|
/// Count the number of non-negative entries in `xs`.
///
/// Linearly scans the array, incrementing a counter whenever `xs[i] >= 0`.
/// The verified version carries the postcondition
/// `count_bounded(xs, result)` which states `0 <= result <= xs.length()`,
/// proved via loop invariants on the running accumulator.
///
/// Parameters:
/// - `xs`: the array to scan.
///
/// Returns: the number of indices `i` where `xs[i] >= 0`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let xs = FixedArray::make(3, 0)
///   xs[0] = 1
///   xs[1] = -2
///   xs[2] = 5
///   @debug.assert_eq(count_nonneg(xs), 2)
/// }
/// ```
pub fn count_nonneg(
  xs : FixedArray[Int],
) -> Int where {
  proof_ensure: result => count_bounded(xs, result),
} {
  for i = 0, count = 0; i < xs.length(); {
    if xs[i] >= 0 {
      continue i + 1, count + 1
    } else {
      continue i + 1, count
    }
  } nobreak {
    count
  } where {
    proof_invariant: 0 <= i,
    proof_invariant: i <= xs.length(),
    proof_invariant: 0 <= count,
    proof_invariant: count <= i,
    proof_reasoning: (
      #| This loop is a direct proof of the accumulator bounds:
      #| `count` is always nonnegative and never exceeds the number of
      #| processed elements `i`.
      #|
      #| Initialization is immediate at `i = 0`, `count = 0`.
      #|
      #| If `xs[i] >= 0`, we increment `count`; otherwise we keep it unchanged.
      #| In both branches, the next value of `count` is still at most the next
      #| prefix length `i + 1`.
      #|
      #| The measure `xs.length() - i` decreases because `i` increases by one
      #| on every iteration.
      #|
      #| When the loop exits, `i == xs.length()`, so these numeric bounds are
      #| exactly the postcondition `count_bounded(xs, count)`.
    ),
  }
}

///|
test "count_nonneg" {
  let xs1 = FixedArray::make(4, 0)
  xs1[0] = 1
  xs1[1] = -2
  xs1[2] = 0
  xs1[3] = 5
  @debug.assert_eq(count_nonneg(xs1), 3)

  let xs2 = FixedArray::make(3, 0)
  xs2[0] = -1
  xs2[1] = -4
  xs2[2] = -8
  @debug.assert_eq(count_nonneg(xs2), 0)

  let xs3 = FixedArray::make(2, 0)
  xs3[0] = 7
  xs3[1] = 9
  @debug.assert_eq(count_nonneg(xs3), 2)
}
