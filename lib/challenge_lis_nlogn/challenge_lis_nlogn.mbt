// ============================================================================
// Challenge: LIS Length (O(n log n))
// Patience sorting with binary search
// ============================================================================

///|
/// Return the length of the longest increasing subsequence.
#warnings("+missing_invariant+missing_reasoning")
pub fn lis_length(nums : ArrayView[Int]) -> Int {
  let tails : Array[Int] = []
  for x in nums {
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
  }
  tails.length()
}
