// ============================================================================
// Challenge: LIS Length (O(n log n))
// Patience sorting with binary search
// ============================================================================

///|
/// Return the length of the longest increasing subsequence.
#warnings("+missing_invariant+missing_reasoning")
pub fn lis_length(nums : ArrayView[Int]) -> Int {
  let n = nums.length()
  let tails : Array[Int] = []
  for i = 0; i < n; i = i + 1 {
    let x = nums[i]
    let pos = for lo = 0, hi = tails.length() {
      if lo >= hi {
        break lo
      } else {
        let mid = (lo + hi) / 2
        if tails[mid] < x {
          continue mid + 1, hi
        } else {
          continue lo, mid
        }
      }
    } where {
      invariant: lo >= 0 && lo <= hi && hi <= tails.length(),
      reasoning: (
        #|INVARIANT (Lower bound search):
        #|All indices < lo have tails[idx] < x and indices >= hi have tails[idx] >= x.
        #|MAINTENANCE:
        #|Shrink [lo, hi) based on comparison at mid.
        #|TERMINATION:
        #|At lo = hi, lo is the first position with tails[lo] >= x.
      ),
    }
    if pos == tails.length() {
      tails.push(x)
    } else {
      tails[pos] = x
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (Tails array):
      #|tails[k] is the minimum possible tail of an increasing subsequence
      #|of length k+1 among nums[0..i).
      #|MAINTENANCE:
      #|Replace or extend the appropriate tail to keep tails minimal.
      #|TERMINATION:
      #|At i = n, tails.length() is the LIS length.
    ),
  }
  tails.length()
}

///|
test "lis_length_basic" {
  let nums : Array[Int] = [3, 1, 2, 1, 8, 5, 6]
  assert_eq(lis_length(nums[:]), 4)
}

///|
test "lis_length_decreasing" {
  let nums : Array[Int] = [5, 4, 3]
  assert_eq(lis_length(nums[:]), 1)
}
