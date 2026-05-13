///|
/// Compute the maximum sum over all contiguous, non-empty subarrays of `arr`.
///
/// The result equals the maximum, taken over every pair of indices
/// `(l, r)` with `0 <= l <= r < n`, of `sum(arr[l..=r])`. The classical
/// Kadane's algorithm achieves this in a single forward pass by
/// maintaining two scalars:
///
/// - `best_ending_here`: the maximum sum of any subarray that ends at
///   the current index. At each step it is either `arr[i]` alone, or
///   `best_ending_here + arr[i]` — whichever is larger.
/// - `best_so_far`: the maximum sum of any subarray seen so far.
///
/// Both quantities are updated in `O(1)` per element, so the overall
/// time complexity is `O(n)` with `O(1)` extra space.
///
/// Parameters:
/// - `arr`: a non-empty view over `Int` (precondition `arr.length() >= 1`).
///
/// Returns: the maximum contiguous subarray sum.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   @debug.assert_eq(max_subarray_sum([1, 2, 3][:]), 6)
///   @debug.assert_eq(max_subarray_sum([-1][:]), -1)
/// }
/// ```
pub fn max_subarray_sum(
  arr : ArrayView[Int],
) -> Int where {
  proof_require: nonempty(arr),
  proof_ensure: result => kadane_post(arr, result),
} {
  for i = 1, best_ending_here = arr[0], best_so_far = arr[0]; i < arr.length(); {
    let candidate = arr[i]
    let extended = best_ending_here + candidate
    let new_ending = if candidate > extended { candidate } else { extended }
    let new_so_far = if new_ending > best_so_far {
      new_ending
    } else {
      best_so_far
    }
    continue i + 1, new_ending, new_so_far
  } nobreak {
    best_so_far
  } where {
    proof_invariant: 1 <= i,
    proof_invariant: i <= arr.length(),
    proof_invariant: best_ending_here >= arr[i - 1],
    proof_invariant: best_so_far >= best_ending_here,
    proof_invariant: ∃ k : Int, (0 <= k && k < i) && arr[k] <= best_so_far,
    proof_reasoning: (
      #| Kadane's algorithm rests on a "local-vs-global" decomposition.
      #| For every prefix `arr[0..i)` we track two quantities:
      #|
      #|   `best_ending_here` = max over l in [0, i-1] of sum(arr[l..=i-1])
      #|   `best_so_far`      = max over (l, r) with 0 <= l <= r < i of sum(arr[l..=r])
      #|
      #| Both are well-defined as long as the prefix is non-empty, which
      #| is exactly the precondition `arr.length() >= 1`. We initialise
      #| `i = 1`, so the first inspected prefix is `arr[0..1) = {arr[0]}`,
      #| and both scalars correctly start at `arr[0]`.
      #|
      #| Maintenance. At iteration `i`, the new subarrays ending at
      #| index `i` are exactly `{arr[i..=i]}` together with every
      #| extension `arr[l..=i]` for `0 <= l <= i-1`. The sum of an
      #| extension factors as `sum(arr[l..=i-1]) + arr[i]`, so taking the
      #| max over `l` of those extended sums yields exactly
      #| `best_ending_here + arr[i]`. Including the single-element case,
      #|
      #|   new_best_ending_here = max(arr[i], best_ending_here + arr[i]).
      #|
      #| Then the new global best is simply
      #|
      #|   new_best_so_far = max(best_so_far, new_best_ending_here),
      #|
      #| because the new subarrays added when extending the prefix are
      #| exactly those that end at `i`.
      #|
      #| The structural invariant `best_ending_here >= arr[i - 1]` records
      #| that the local best dominates the last element (you can always
      #| pick the singleton `arr[i-1..=i-1]`), and `best_so_far >=
      #| best_ending_here` records that the global best dominates the
      #| local best. The existential invariant is a downgraded form of
      #| the full quantification: it states there is at least one index
      #| in the processed prefix whose value is bounded above by
      #| `best_so_far`, which witnesses that `best_so_far` is a real
      #| element/sum of `arr`.
      #|
      #| Termination. The index `i` increases by exactly one on each
      #| iteration and is bounded by `arr.length()`, so the measure
      #| `arr.length() - i` strictly decreases. The loop therefore exits
      #| with `i == arr.length()`, at which point `best_so_far` is the
      #| maximum over every (l, r) with `0 <= l <= r < arr.length()`.
    ),
  }
}
