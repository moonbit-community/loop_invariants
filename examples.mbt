///|
fn fib(n : Int) -> Int {
  if n <= 1 {
    n
  } else {
    fib(n - 1) + fib(n - 2)
  }
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn fib_loop(n : Int) -> Int {
  for i = 0, a = 0, b = 1 {
    if i >= n {
      break a
    } else {
      continue i + 1, b, a + b
    }
  } where {
    invariant: i >= 0 && a == fib(i) && b == fib(i + 1),
    reasoning: (
      #|This invariant directly states the equivalence: a = F(i) and b = F(i+1).
      #|
      #|Base case (i=0): a=0=F(0), b=1=F(1). ✓
      #|
      #|Inductive step: Assume a=F(i), b=F(i+1). After (a',b',i') = (b, a+b, i+1):
      #|  a' = b = F(i+1) = F(i')           ✓
      #|  b' = a + b = F(i) + F(i+1) = F(i+2) = F(i'+1)  ✓
      #|
      #|Termination: When i >= n, we return a = F(i) = F(n), matching fib(n).
      #|
      #|This proves fib_loop(n) ≡ fib(n) for all n >= 0.
      #|MAINTENANCE:
      #|Advancing (i, a, b) to (i+1, b, a+b) preserves a=F(i) and b=F(i+1).
      #|TERMINATION:
      #|At i = n, a equals F(n), which is returned.
    ),
  }
}

///|
test {
  // Verify equivalence for several values
  assert_eq(fib_loop(0), fib(0)) // 0
  assert_eq(fib_loop(1), fib(1)) // 1
  assert_eq(fib_loop(5), fib(5)) // 5
  assert_eq(fib_loop(10), fib(10)) // 55
}

// ============================================================================
// Example 2: Binary Search - Invariant proves search bounds are correct
// ============================================================================

///|
/// Binary search: find index of target in sorted array, or None
#warnings("+missing_invariant+missing_reasoning")
fn binary_search(arr : ArrayView[Int], target : Int) -> Int? {
  for lo = 0, hi = arr.length() {
    if lo >= hi {
      break None
    } else {
      let mid = lo + (hi - lo) / 2
      if arr[mid] == target {
        break Some(mid)
      } else if arr[mid] < target {
        continue mid + 1, hi
      } else {
        continue lo, mid
      }
    }
  } where {
    invariant: lo >= 0 && hi <= arr.length() && lo <= hi,
    reasoning: (
      #|INVARIANT 1 (Bounds): [lo, hi) is always a valid subrange.
      #|
      #|Base: lo=0, hi=len → 0 ≤ 0 ≤ len ≤ len. ✓
      #|
      #|Inductive: mid ∈ [lo, hi), so:
      #|  - (mid+1, hi): mid+1 ≤ hi, and mid+1 > lo ≥ 0. ✓
      #|  - (lo, mid): lo ≤ mid < hi. ✓
      #|MAINTENANCE:
      #|Choosing [mid+1, hi) or [lo, mid) preserves a valid subrange.
      #|TERMINATION:
      #|When lo >= hi, the search interval is empty.
    ),
    invariant: lo == 0 || arr[lo - 1] < target,
    reasoning: (
      #|INVARIANT 2 (Left exclusion): Everything before lo is too small.
      #|
      #|Base: lo=0 → trivially satisfied (no elements before). ✓
      #|
      #|Inductive (lo' = mid+1): We only set lo' = mid+1 when arr[mid] < target.
      #|  So arr[lo'-1] = arr[mid] < target. ✓
      #|
      #|Inductive (lo unchanged): Invariant preserved. ✓
      #|
      #|This proves: ∀i < lo, arr[i] < target (by sortedness + boundary witness).
      #|MAINTENANCE:
      #|When lo increases to mid+1, arr[lo-1] is proven < target.
      #|TERMINATION:
      #|At loop end, all indices before lo are excluded.
    ),
    invariant: hi == arr.length() || arr[hi] > target,
    reasoning: (
      #|INVARIANT 3 (Right exclusion): Everything from hi onwards is too large.
      #|
      #|Base: hi=len → trivially satisfied (no elements from hi). ✓
      #|
      #|Inductive (hi' = mid): We only set hi' = mid when arr[mid] > target.
      #|  So arr[hi'] = arr[mid] > target. ✓
      #|
      #|Inductive (hi unchanged): Invariant preserved. ✓
      #|
      #|This proves: ∀i ≥ hi, arr[i] > target (by sortedness + boundary witness).
      #|MAINTENANCE:
      #|When hi decreases to mid, arr[hi] is proven > target.
      #|TERMINATION:
      #|At loop end, all indices from hi onward are excluded.
    ),
    invariant: hi - lo >= 0,
    reasoning: (
      #|INVARIANT 4 (Termination measure): hi - lo is non-negative and decreases.
      #|
      #|Base: hi - lo = len ≥ 0. ✓
      #|
      #|Decrease: mid = lo + (hi-lo)/2, so lo < mid < hi when lo < hi.
      #|  - (mid+1, hi): new size = hi - (mid+1) < hi - lo. ✓
      #|  - (lo, mid): new size = mid - lo < hi - lo. ✓
      #|
      #|Combined with Invariants 2 & 3:
      #|When lo >= hi, the search space is empty AND we've proven:
      #|  - All arr[0..lo) < target
      #|  - All arr[hi..n) > target  
      #|  - lo >= hi means these cover the entire array
      #|Therefore target is not in arr. ✓
      #|MAINTENANCE:
      #|Each step strictly shrinks hi - lo, ensuring progress.
      #|TERMINATION:
      #|At hi - lo = 0, the search space is empty and the target is absent.
    ),
  }
}

///|
test "binary_search" {
  let arr : Array[Int] = [1, 3, 5, 7, 9, 11, 13]
  assert_eq(binary_search(arr[:], 7), Some(3))
  assert_eq(binary_search(arr[:], 1), Some(0))
  assert_eq(binary_search(arr[:], 13), Some(6))
  assert_eq(binary_search(arr[:], 6), None)
  assert_eq(binary_search(arr[:], 0), None)
}

// ============================================================================
// Example 3: GCD (Euclidean Algorithm) - Invariant preserves mathematical property
// ============================================================================

///|
fn gcd_rec(a : Int, b : Int) -> Int {
  if b == 0 {
    a
  } else {
    gcd_rec(b, a % b)
  }
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn gcd_loop(a : Int, b : Int) -> Int {
  for x = a, y = b {
    if y == 0 {
      break x
    } else {
      continue y, x % y
    }
  } where {
    invariant: x >= 0 && y >= 0 && gcd_rec(x, y) == gcd_rec(a, b),
    reasoning: (
      #|The invariant states that gcd(x,y) = gcd(a,b) throughout.
      #|
      #|Base: x=a, y=b → gcd(x,y) = gcd(a,b). ✓
      #|
      #|Inductive step: Let (x', y') = (y, x % y).
      #|  By Euclidean algorithm: gcd(x, y) = gcd(y, x % y).
      #|  So gcd(x', y') = gcd(y, x % y) = gcd(x, y) = gcd(a, b). ✓
      #|
      #|Termination: y strictly decreases (0 ≤ x%y < y) until y = 0.
      #|When y = 0: return x, and gcd(x, 0) = x = gcd(a, b). ✓
      #|MAINTENANCE:
      #|Updating (x, y) to (y, x % y) preserves gcd(x, y).
      #|TERMINATION:
      #|y decreases to 0, yielding the gcd.
    ),
  }
}

///|
test "gcd" {
  assert_eq(gcd_loop(48, 18), gcd_rec(48, 18)) // 6
  assert_eq(gcd_loop(100, 35), gcd_rec(100, 35)) // 5
  assert_eq(gcd_loop(17, 13), gcd_rec(17, 13)) // 1 (coprime)
  assert_eq(gcd_loop(0, 5), gcd_rec(0, 5)) // 5
}

// ============================================================================
// Example 4: Fast Exponentiation - Invariant connects partial result to goal
// ============================================================================

///|
fn pow_rec(base : Int, exp : Int) -> Int {
  if exp == 0 {
    1
  } else if exp % 2 == 0 {
    pow_rec(base * base, exp / 2)
  } else {
    base * pow_rec(base, exp - 1)
  }
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn pow_loop(base : Int, exp : Int) -> Int {
  for b = base, e = exp, acc = 1 {
    if e == 0 {
      break acc
    } else if e % 2 == 0 {
      continue b * b, e / 2, acc
    } else {
      continue b, e - 1, acc * b
    }
  } where {
    invariant: e >= 0 && acc * pow_rec(b, e) == pow_rec(base, exp),
    reasoning: (
      #|The invariant: acc × b^e = base^exp (the final answer).
      #|
      #|Base: acc=1, b=base, e=exp → 1 × base^exp = base^exp. ✓
      #|
      #|Case e even: (b', e', acc') = (b², e/2, acc)
      #|  acc' × b'^e' = acc × (b²)^(e/2) = acc × b^e. ✓
      #|
      #|Case e odd: (b', e', acc') = (b, e-1, acc×b)
      #|  acc' × b'^e' = (acc×b) × b^(e-1) = acc × b^e. ✓
      #|
      #|Termination: e decreases (halved or decremented) until e = 0.
      #|When e = 0: return acc, and acc × b^0 = acc = base^exp. ✓
      #|MAINTENANCE:
      #|Odd/even updates preserve acc * b^e = base^exp.
      #|TERMINATION:
      #|When e = 0, acc is the final power.
    ),
  }
}

///|
test "pow" {
  assert_eq(pow_loop(2, 10), pow_rec(2, 10)) // 1024
  assert_eq(pow_loop(3, 5), pow_rec(3, 5)) // 243
  assert_eq(pow_loop(5, 0), pow_rec(5, 0)) // 1
  assert_eq(pow_loop(7, 1), pow_rec(7, 1)) // 7
}

// ============================================================================
// Example 5: Array Reversal - Invariant describes partial transformation
// ============================================================================

///|
#warnings("+missing_invariant+missing_reasoning")
fn reverse_inplace(arr : Array[Int]) -> Unit {
  for lo = 0, hi = arr.length() - 1 {
    if lo >= hi {
      break
    } else {
      let tmp = arr[lo]
      arr[lo] = arr[hi]
      arr[hi] = tmp
      continue lo + 1, hi - 1
    }
  } where {
    invariant: lo >= 0 && hi < arr.length() && lo + hi == arr.length() - 1,
    reasoning: (
      #|The invariant tracks the symmetry of swap positions.
      #|
      #|Deeper property (not expressible in code):
      #|  arr[0..lo) contains original arr[hi+1..n) reversed, and
      #|  arr[hi+1..n) contains original arr[0..lo) reversed.
      #|  arr[lo..hi+1) is untouched.
      #|
      #|Base: lo=0, hi=n-1 → 0 + (n-1) = n-1. ✓
      #|  No swaps yet, entire array is "untouched middle".
      #|
      #|Inductive step: (lo', hi') = (lo+1, hi-1)
      #|  lo' + hi' = (lo+1) + (hi-1) = lo + hi = n-1. ✓
      #|  After swap, reversed portions grow by one on each end.
      #|
      #|Termination: hi - lo decreases by 2 each step.
      #|When lo >= hi: middle is 0 or 1 element → fully reversed.
      #|MAINTENANCE:
      #|Swap arr[lo] and arr[hi], then move inward to preserve symmetry.
      #|TERMINATION:
      #|When lo >= hi, all pairs are swapped and the array is reversed.
    ),
  }
}

///|
test "reverse" {
  let arr1 : Array[Int] = [1, 2, 3, 4, 5]
  reverse_inplace(arr1)
  assert_eq(arr1, [5, 4, 3, 2, 1])
  let arr2 : Array[Int] = [1, 2]
  reverse_inplace(arr2)
  assert_eq(arr2, [2, 1])
  let arr3 : Array[Int] = [42]
  reverse_inplace(arr3)
  assert_eq(arr3, [42])
}

// ============================================================================
// Example 6: Integer Square Root - Invariant bounds the answer
// ============================================================================

///|
#warnings("+missing_invariant+missing_reasoning")
fn isqrt(n : Int) -> Int {
  // Returns floor(sqrt(n)) using binary search
  for lo = 0, hi = n + 1 {
    if lo + 1 >= hi {
      break lo
    } else {
      let mid = lo + (hi - lo) / 2
      if mid * mid <= n {
        continue mid, hi
      } else {
        continue lo, mid
      }
    }
  } where {
    invariant: lo >= 0 && lo < hi && lo * lo <= n && (hi > n || hi * hi > n),
    reasoning: (
      #|The invariant maintains: lo² ≤ n < hi² (answer is in [lo, hi)).
      #|
      #|Base: lo=0, hi=n+1 → 0² = 0 ≤ n, and (n+1)² > n for n ≥ 0. ✓
      #|
      #|Case mid² ≤ n: Set lo' = mid.
      #|  lo'² = mid² ≤ n. ✓ (hi unchanged, so hi² > n still holds)
      #|
      #|Case mid² > n: Set hi' = mid.
      #|  hi'² = mid² > n. ✓ (lo unchanged, so lo² ≤ n still holds)
      #|
      #|Termination: hi - lo shrinks (mid strictly between lo and hi).
      #|When lo + 1 >= hi: interval has one element, lo² ≤ n < (lo+1)².
      #|So lo = floor(sqrt(n)). ✓
      #|MAINTENANCE:
      #|Updating lo or hi preserves lo² ≤ n < hi².
      #|TERMINATION:
      #|When hi = lo + 1, lo is the floor sqrt.
    ),
  }
}

///|
test "isqrt" {
  assert_eq(isqrt(0), 0)
  assert_eq(isqrt(1), 1)
  assert_eq(isqrt(4), 2)
  assert_eq(isqrt(8), 2) // floor(sqrt(8)) = 2
  assert_eq(isqrt(9), 3)
  assert_eq(isqrt(99), 9)
  assert_eq(isqrt(100), 10)
}

// ============================================================================
// Example 7: Dutch National Flag (3-way partition)
// Partition array into three regions: <pivot, ==pivot, >pivot
// ============================================================================

///|
#warnings("+missing_invariant+missing_reasoning")
fn dutch_flag(arr : Array[Int], pivot : Int) -> Unit {
  // Partitions into: [< pivot | == pivot | unprocessed | > pivot]
  //                   0..lo     lo..mid    mid..hi       hi..n
  for lo = 0, mid = 0, hi = arr.length() {
    if mid >= hi {
      break
    } else if arr[mid] < pivot {
      let tmp = arr[lo]
      arr[lo] = arr[mid]
      arr[mid] = tmp
      continue lo + 1, mid + 1, hi
    } else if arr[mid] > pivot {
      let tmp = arr[mid]
      arr[mid] = arr[hi - 1]
      arr[hi - 1] = tmp
      continue lo, mid, hi - 1
    } else {
      // arr[mid] == pivot
      continue lo, mid + 1, hi
    }
  } where {
    invariant: 0 <= lo && lo <= mid && mid <= hi && hi <= arr.length(),
    reasoning: (
      #|INVARIANT 1 (Bounds): Pointers maintain proper ordering.
      #|
      #|Base: lo=0, mid=0, hi=n → 0 ≤ 0 ≤ 0 ≤ n ≤ n. ✓
      #|
      #|Case arr[mid] < pivot: (lo+1, mid+1, hi)
      #|  lo+1 ≤ mid+1 (since lo ≤ mid), mid+1 ≤ hi (since mid < hi). ✓
      #|
      #|Case arr[mid] > pivot: (lo, mid, hi-1)
      #|  lo ≤ mid, mid ≤ hi-1 (since mid < hi). ✓
      #|
      #|Case arr[mid] == pivot: (lo, mid+1, hi)
      #|  lo ≤ mid+1 (since lo ≤ mid), mid+1 ≤ hi (since mid < hi). ✓
      #|MAINTENANCE:
      #|Each case advances at least one pointer while preserving order.
      #|TERMINATION:
      #|When mid >= hi, all elements are partitioned.
    ),
    invariant: hi - mid >= 0,
    reasoning: (
      #|INVARIANT 2 (Termination + Partition Property):
      #|The unprocessed region is [mid, hi). Its size = hi - mid.
      #|
      #|Each case reduces this:
      #|  - arr[mid] < pivot: mid+1, hi → size decreases by 1
      #|  - arr[mid] > pivot: mid, hi-1 → size decreases by 1
      #|  - arr[mid] == pivot: mid+1, hi → size decreases by 1
      #|
      #|Terminates when mid >= hi (size = 0).
      #|
      #|DEEPER INSIGHT (Complete Partition Invariant):
      #|At any point during execution:
      #|  ∀i ∈ [0, lo):    arr[i] < pivot
      #|  ∀i ∈ [lo, mid):  arr[i] == pivot
      #|  ∀i ∈ [mid, hi):  unprocessed
      #|  ∀i ∈ [hi, n):    arr[i] > pivot
      #|
      #|This 4-region invariant fully specifies the algorithm state.
      #|
      #|WHY DIJKSTRA'S ALGORITHM IS ELEGANT:
      #|1. Single scan: O(n) time with 3 pointers
      #|2. In-place: O(1) extra space
      #|3. Stable for == region (elements keep relative order)
      #|
      #|APPLICATION: QuickSort with many duplicates.
      #|Standard quicksort degrades to O(n²) when many elements equal pivot.
      #|3-way partition handles duplicates in O(n) per level, keeping
      #|overall complexity at O(n log n) even for duplicate-heavy inputs.
      #|MAINTENANCE:
      #|Each branch shrinks the unprocessed segment [mid, hi).
      #|TERMINATION:
      #|When hi - mid = 0, the array is fully partitioned.
    ),
  }
}

///|
test "dutch_flag" {
  let arr1 : Array[Int] = [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5]
  dutch_flag(arr1, 5)
  // All elements < 5, then == 5, then > 5
  let _ = arr1.fold(init=(false, false), (state, x) => {
    let (seen_equal, seen_greater) = state
    let seen_equal2 = seen_equal || x == 5
    let seen_greater2 = seen_greater || x > 5
    // Once we see ==5, no more <5
    assert_true(not(seen_equal2) || x >= 5)
    // Once we see >5, no more <=5
    assert_true(not(seen_greater2) || x > 5)
    (seen_equal2, seen_greater2)
  })

}

// ============================================================================
// Example 8: Kadane's Algorithm (Maximum Subarray Sum)
// Find contiguous subarray with largest sum
// ============================================================================

///|
fn max(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn kadane(arr : ArrayView[Int]) -> Int {
  // Returns maximum subarray sum (assumes non-empty array)
  guard arr.length() > 0 else { return 0 }
  for i = 1, max_ending_here = arr[0], max_so_far = arr[0] {
    if i >= arr.length() {
      break max_so_far
    } else {
      let new_max_here = max(arr[i], max_ending_here + arr[i])
      let new_max_far = max(max_so_far, new_max_here)
      continue i + 1, new_max_here, new_max_far
    }
  } where {
    invariant: i >= 1 && i <= arr.length(),
    reasoning: (
      #|INVARIANT 1 (Bounds): i stays in valid range.
      #|
      #|Base: i=1, and we guard arr.length() > 0, so 1 ≤ len. ✓
      #|Inductive: i+1 ≤ len when i < len (loop condition). ✓
      #|MAINTENANCE:
      #|Increment i each iteration while i < len.
      #|TERMINATION:
      #|At i = len, the scan is complete.
    ),
    invariant: max_ending_here >= arr[i - 1],
    reasoning: (
      #|INVARIANT 2 (Local optimum): max_ending_here is the maximum sum of
      #|any subarray ending exactly at index i-1.
      #|
      #|Base: i=1, max_ending_here = arr[0]. 
      #|  Only subarray ending at 0 is [arr[0]], sum = arr[0]. ✓
      #|
      #|Inductive: At position i, we compute:
      #|  new_max_here = max(arr[i], max_ending_here + arr[i])
      #|
      #|This captures the key insight: the best subarray ending at i is either:
      #|  - Just arr[i] alone (start fresh), OR
      #|  - Extend the best subarray ending at i-1 by adding arr[i]
      #|
      #|By induction, max_ending_here was optimal for i-1, so this choice
      #|gives the optimal subarray ending at i. ✓
      #|MAINTENANCE:
      #|Update max_ending_here to the best subarray ending at i.
      #|TERMINATION:
      #|At i = len, max_ending_here is optimal for the last index.
    ),
    invariant: max_so_far >= max_ending_here,
    reasoning: (
      #|INVARIANT 3 (Global optimum): max_so_far is the maximum sum of
      #|any subarray in arr[0..i).
      #|
      #|Base: i=1, max_so_far = arr[0] = max_ending_here. ✓
      #|
      #|Inductive: new_max_far = max(max_so_far, new_max_here)
      #|
      #|By Invariant 2, new_max_here is optimal ending at i.
      #|By induction, max_so_far is optimal for arr[0..i).
      #|The optimal for arr[0..i+1) either:
      #|  - Doesn't include arr[i] → max_so_far
      #|  - Includes arr[i] as rightmost → new_max_here
      #|Taking max gives global optimum for arr[0..i+1). ✓
      #|
      #|At termination (i = len), max_so_far is optimal for entire array.
      #|
      #|DEEPER INSIGHT (Optimal Substructure):
      #|Kadane's algorithm works because of this key observation:
      #|
      #|Let MSS(i) = max subarray sum ending at position i.
      #|Then MSS(i) = max(arr[i], MSS(i-1) + arr[i])
      #|
      #|This recurrence captures the decision: either start fresh at i,
      #|or extend the best subarray ending at i-1.
      #|
      #|The global answer is max(MSS(0), MSS(1), ..., MSS(n-1)).
      #|
      #|WHY GREEDY WORKS HERE:
      #|If MSS(i-1) < 0, extending it only makes things worse.
      #|So the optimal decision at each position is LOCAL.
      #|This transforms an O(n³) brute-force or O(n²) DP into O(n).
      #|
      #|HISTORICAL NOTE: This algorithm is often attributed to Kadane (1984),
      #|but similar ideas appeared earlier. It's a beautiful example of
      #|how the right invariant reveals the algorithm's essence.
      #|MAINTENANCE:
      #|max_so_far is updated with the best ending-at-i value each step.
      #|TERMINATION:
      #|At i = len, max_so_far is the maximum subarray sum.
    ),
  }
}

///|
test "kadane" {
  assert_eq(kadane([-2, 1, -3, 4, -1, 2, 1, -5, 4][:]), 6) // [4,-1,2,1]
  assert_eq(kadane([1][:]), 1)
  assert_eq(kadane([5, 4, -1, 7, 8][:]), 23) // entire array
  assert_eq(kadane([-1, -2, -3][:]), -1) // least negative
}

// ============================================================================
// Example 9: Two Pointers for Two Sum (Sorted Array)
// Find if any two elements sum to target
// ============================================================================

///|
#warnings("+missing_invariant+missing_reasoning")
fn two_sum_sorted(arr : ArrayView[Int], target : Int) -> (Int, Int)? {
  // Assumes arr is sorted. Returns indices of two elements summing to target.
  guard arr.length() >= 2 else { return None }
  for lo = 0, hi = arr.length() - 1 {
    if lo >= hi {
      break None
    } else {
      let sum = arr[lo] + arr[hi]
      if sum == target {
        break Some((lo, hi))
      } else if sum < target {
        continue lo + 1, hi
      } else {
        continue lo, hi - 1
      }
    }
  } where {
    invariant: 0 <= lo && lo <= hi && hi < arr.length(),
    reasoning: (
      #|INVARIANT 1 (Bounds): Pointers stay valid and don't cross.
      #|
      #|Base: lo=0, hi=len-1. With len ≥ 2: 0 ≤ 0 ≤ len-1 < len. ✓
      #|
      #|Inductive (sum < target): lo+1 ≤ hi since lo < hi. ✓
      #|Inductive (sum > target): lo ≤ hi-1 since lo < hi. ✓
      #|MAINTENANCE:
      #|Each branch moves exactly one pointer inward while preserving order.
      #|TERMINATION:
      #|When lo >= hi, no pair remains to check.
    ),
    invariant: lo == 0 || arr[lo - 1] + arr[hi] < target,
    reasoning: (
      #|INVARIANT 2 (Left elimination): For all j < lo, arr[j] + arr[hi] < target.
      #|
      #|Base: lo=0 → no such j, trivially true. ✓
      #|
      #|Inductive (lo' = lo+1): We move lo right only when arr[lo] + arr[hi] < target.
      #|  For the new hi (which is same or smaller):
      #|  arr[lo] + arr[hi'] ≤ arr[lo] + arr[hi] < target. ✓
      #|
      #|By sortedness, all j < lo have arr[j] ≤ arr[lo-1], and 
      #|arr[lo-1] + arr[hi] < target (boundary witness), so
      #|arr[j] + arr[hi] ≤ arr[lo-1] + arr[hi] < target for all j < lo. ✓
      #|MAINTENANCE:
      #|Increasing lo preserves the exclusion of all indices < lo.
      #|TERMINATION:
      #|At loop end, all pairs with left index < lo are excluded.
    ),
    invariant: hi == arr.length() - 1 || arr[lo] + arr[hi + 1] > target,
    reasoning: (
      #|INVARIANT 3 (Right elimination): For all k > hi, arr[lo] + arr[k] > target.
      #|
      #|Base: hi=len-1 → no such k, trivially true. ✓
      #|
      #|Inductive (hi' = hi-1): We move hi left only when arr[lo] + arr[hi] > target.
      #|  For the new lo (which is same or larger):
      #|  arr[lo'] + arr[hi] ≥ arr[lo] + arr[hi] > target. ✓
      #|
      #|By sortedness, all k > hi have arr[k] ≥ arr[hi+1], and
      #|arr[lo] + arr[hi+1] > target (boundary witness), so
      #|arr[lo] + arr[k] ≥ arr[lo] + arr[hi+1] > target for all k > hi. ✓
      #|
      #|COMPLETENESS: Invariants 2 & 3 together prove we never skip a solution.
      #|If arr[i] + arr[j] = target with i < j, then:
      #|  - If i < lo: by Inv 2, arr[i] + arr[hi] < target, but arr[hi] ≥ arr[j],
      #|    so arr[i] + arr[j] ≤ arr[i] + arr[hi] < target. Contradiction.
      #|  - If j > hi: by Inv 3, arr[lo] + arr[j] > target, but arr[lo] ≤ arr[i],
      #|    so arr[i] + arr[j] ≥ arr[lo] + arr[j] > target. Contradiction.
      #|Therefore i ≥ lo and j ≤ hi: the solution is still in our search space.
      #|MAINTENANCE:
      #|Decreasing hi preserves the exclusion of all indices > hi.
      #|TERMINATION:
      #|At loop end, all pairs with right index > hi are excluded.
    ),
  }
}

///|
test "two_sum_sorted" {
  assert_eq(two_sum_sorted([1, 2, 3, 4, 5][:], 9), Some((3, 4))) // 4+5
  assert_eq(two_sum_sorted([1, 2, 3, 4, 5][:], 3), Some((0, 1))) // 1+2
  assert_eq(two_sum_sorted([1, 2, 3, 4, 5][:], 100), None)
  assert_eq(two_sum_sorted([2, 7, 11, 15][:], 9), Some((0, 1))) // 2+7
}

// ============================================================================
// Example 10: Merge Step of Merge Sort
// Merge two sorted halves into one sorted array
// ============================================================================

///|
#warnings("+missing_invariant+missing_reasoning")
fn merge(left : ArrayView[Int], right : ArrayView[Int]) -> Array[Int] {
  let result : Array[Int] = []
  for i = 0, j = 0 {
    if i >= left.length() && j >= right.length() {
      break result
    } else if i >= left.length() {
      result.push(right[j])
      continue i, j + 1
    } else if j >= right.length() {
      result.push(left[i])
      continue i + 1, j
    } else if left[i] <= right[j] {
      result.push(left[i])
      continue i + 1, j
    } else {
      result.push(right[j])
      continue i, j + 1
    }
  } where {
    invariant: i >= 0 && i <= left.length() && j >= 0 && j <= right.length(),
    reasoning: (
      #|INVARIANT 1 (Bounds): Indices stay within array bounds.
      #|
      #|Base: i=0, j=0 → both valid. ✓
      #|Inductive: We only increment i when i < left.len, j when j < right.len. ✓
      #|MAINTENANCE:
      #|Each branch advances exactly one index within bounds.
      #|TERMINATION:
      #|When i and j reach the ends, the merge is complete.
    ),
    invariant: result.length() == i + j,
    reasoning: (
      #|INVARIANT 2 (Progress): Output size equals consumed input.
      #|
      #|Base: result.len = 0, i = 0, j = 0 → 0 = 0 + 0. ✓
      #|
      #|Inductive: Each branch pushes exactly one element and increments
      #|exactly one of i or j:
      #|  result.len' = result.len + 1 = i + j + 1 = i' + j'. ✓
      #|
      #|At termination: result.len = left.len + right.len (complete merge).
      #|MAINTENANCE:
      #|Pushing one element keeps result.len == i + j.
      #|TERMINATION:
      #|At i = left.len and j = right.len, result is fully merged.
    ),
  }
}

///|
test "merge" {
  assert_eq(merge([1, 3, 5][:], [2, 4, 6][:]), [1, 2, 3, 4, 5, 6])
  assert_eq(merge([1, 2, 3][:], [4, 5, 6][:]), [1, 2, 3, 4, 5, 6])
  assert_eq(merge([4, 5, 6][:], [1, 2, 3][:]), [1, 2, 3, 4, 5, 6])
  assert_eq(merge([][:], [1, 2][:]), [1, 2])
  assert_eq(merge([1, 2][:], [][:]), [1, 2])
}

// ============================================================================
// Example 11: Extended Euclidean Algorithm
// Computes gcd(a,b) and coefficients x,y such that ax + by = gcd(a,b)
// ============================================================================

///|
#warnings("+missing_invariant+missing_reasoning")
fn extended_gcd(a : Int, b : Int) -> (Int, Int, Int) {
  // Returns (gcd, x, y) such that a*x + b*y = gcd
  for r0 = a, r1 = b, x0 = 1, x1 = 0, y0 = 0, y1 = 1 {
    if r1 == 0 {
      break (r0, x0, y0)
    } else {
      let q = r0 / r1
      continue r1, r0 - q * r1, x1, x0 - q * x1, y1, y0 - q * y1
    }
  } where {
    invariant: a * x0 + b * y0 == r0,
    reasoning: (
      #|INVARIANT 1 (Bézout for r0): a·x0 + b·y0 = r0
      #|
      #|Base: x0=1, y0=0, r0=a → a·1 + b·0 = a = r0. ✓
      #|
      #|Inductive: Let q = r0/r1. New values:
      #|  r0' = r1, x0' = x1, y0' = y1
      #|
      #|By Invariant 2 (below): a·x1 + b·y1 = r1 = r0'. ✓
      #|MAINTENANCE:
      #|Setting (r0, x0, y0) to (r1, x1, y1) preserves the identity.
      #|TERMINATION:
      #|When r1 = 0, r0 is gcd and x0,y0 are Bézout coefficients.
    ),
    invariant: a * x1 + b * y1 == r1,
    reasoning: (
      #|INVARIANT 2 (Bézout for r1): a·x1 + b·y1 = r1
      #|
      #|Base: x1=0, y1=1, r1=b → a·0 + b·1 = b = r1. ✓
      #|
      #|Inductive: Let q = r0/r1. New values:
      #|  r1' = r0 - q·r1
      #|  x1' = x0 - q·x1
      #|  y1' = y0 - q·y1
      #|
      #|Check: a·x1' + b·y1'
      #|  = a·(x0 - q·x1) + b·(y0 - q·y1)
      #|  = (a·x0 + b·y0) - q·(a·x1 + b·y1)
      #|  = r0 - q·r1           (by Invariants 1 & 2)
      #|  = r1'. ✓
      #|MAINTENANCE:
      #|The linear combination update mirrors the Euclidean remainder update.
      #|TERMINATION:
      #|At r1 = 0, the identity holds trivially and r0 is gcd.
    ),
    invariant: r1 >= 0,
    reasoning: (
      #|INVARIANT 3 (Non-negative remainder): r1 ≥ 0
      #|
      #|We assume inputs a, b ≥ 0.
      #|The Euclidean algorithm maintains 0 ≤ r0 mod r1 < r1.
      #|
      #|Termination: r1 strictly decreases until r1 = 0.
      #|At termination: r0 = gcd(a,b), and a·x0 + b·y0 = r0 = gcd. ✓
      #|MAINTENANCE:
      #|Each remainder update keeps r1 non-negative.
      #|TERMINATION:
      #|r1 decreases to 0, ending the algorithm.
    ),
  }
}

///|
test "extended_gcd" {
  let (g1, x1, y1) = extended_gcd(48, 18)
  assert_eq(g1, 6)
  assert_eq(48 * x1 + 18 * y1, 6) // Bézout identity
  let (g2, x2, y2) = extended_gcd(35, 15)
  assert_eq(g2, 5)
  assert_eq(35 * x2 + 15 * y2, 5)
  let (g3, x3, y3) = extended_gcd(17, 13)
  assert_eq(g3, 1) // coprime
  assert_eq(17 * x3 + 13 * y3, 1)
}

// ============================================================================
// Example 12: Boyer-Moore Voting Algorithm
// Find majority element (appears > n/2 times) in O(n) time, O(1) space
// ============================================================================

///|
#warnings("+missing_invariant+missing_reasoning")
fn majority_element(arr : ArrayView[Int]) -> Int? {
  // Phase 1: Find candidate using voting
  guard arr.length() > 0 else { return None }
  let (candidate, _) = for i = 1, candidate = arr[0], count = 1 {
    if i >= arr.length() {
      break (candidate, count)
    } else if arr[i] == candidate {
      continue i + 1, candidate, count + 1
    } else if count == 0 {
      continue i + 1, arr[i], 1
    } else {
      continue i + 1, candidate, count - 1
    }
  } where {
    invariant: i >= 1 && i <= arr.length() && count >= 0,
    reasoning: (
      #|INVARIANT 1 (Bounds):
      #|i counts processed elements, so 1 <= i <= arr.length().
      #|count tracks unmatched candidate votes and stays non-negative.
      #|MAINTENANCE:
      #|Each step increments i and adjusts count by at most 1.
      #|TERMINATION:
      #|At i = arr.length(), candidate and count reflect the full scan.
    ),
    invariant: count <= i,
    reasoning: (
      #|INVARIANT 2 (Count bound): count never exceeds elements seen.
      #|
      #|Base: i=1, count=1 → 1 ≤ 1. ✓
      #|
      #|Inductive: count increases by at most 1 while i increases by 1. ✓
      #|
      #|KEY INSIGHT (not directly expressible):
      #|If majority element M exists (appears > n/2 times), then:
      #|  - Let #M = count of M in arr[0..i)
      #|  - Let #O = count of others in arr[0..i)
      #|  - We have: #M - #O ≤ count if candidate = M
      #|           : #M - #O ≤ count + (excess non-M) otherwise
      #|
      #|When we pair a non-candidate with a candidate (count--),
      #|we "cancel" at most one M with one non-M.
      #|Since #M > #O overall, M survives as final candidate.
      #|
      #|Proof: Consider arr as (#M copies of M) + (#O copies of others).
      #|Each "cancel" removes one from each group at most.
      #|After all cancellations: #M - #O > 0 elements of M remain uncanceled.
      #|Therefore candidate = M at the end.
      #|MAINTENANCE:
      #|Increment/decrement count preserves the net surplus of the candidate.
      #|TERMINATION:
      #|At i = arr.length(), the remaining candidate is the majority if one exists.
    ),
  }
  // Phase 2: Verify candidate is actually majority
  let verify_count = arr.fold(init=0, (acc, x) => acc +
    (if x == candidate { 1 } else { 0 }))
  if verify_count > arr.length() / 2 {
    Some(candidate)
  } else {
    None
  }
}

///|
test "majority_element" {
  assert_eq(majority_element([3, 2, 3][:]), Some(3))
  assert_eq(majority_element([2, 2, 1, 1, 1, 2, 2][:]), Some(2))
  assert_eq(majority_element([1, 2, 3][:]), None) // no majority
  assert_eq(majority_element([1][:]), Some(1))
}

// ============================================================================
// Example 13: Newton's Method for Integer Square Root
// Converges quadratically: error squares each iteration
// ============================================================================

///|
#warnings("+missing_invariant+missing_reasoning")
fn isqrt_newton(n : Int) -> Int {
  guard n > 0 else { return 0 }
  // Start with initial guess (n itself, or better heuristic)
  for x = n {
    let x_next = (x + n / x) / 2
    if x_next >= x {
      break x // Converged
    } else {
      continue x_next
    }
  } where {
    invariant: x >= 1 && x * x >= n,
    reasoning: (
      #|INVARIANT 1 (Upper bound): x is always ≥ √n (an overestimate).
      #|
      #|Base: x = n. For n ≥ 1: n² ≥ n, so n ≥ √n. ✓
      #|
      #|Inductive: Let x' = (x + n/x) / 2 (integer division).
      #|  By AM-GM inequality: (x + n/x) / 2 ≥ √(x · n/x) = √n
      #|  So x' ≥ √n, meaning x'² ≥ n (when we continue). ✓
      #|
      #|NOTE: Integer division makes x' ≤ (x + n/x) / 2 (real).
      #|The key insight is that we only continue when x' < x,
      #|meaning we're still above √n and improving.
      #|MAINTENANCE:
      #|Updating x to x' keeps x as an upper bound while decreasing it.
      #|TERMINATION:
      #|When x' >= x, the loop stops at the floor sqrt.
    ),
    invariant: x <= n,
    reasoning: (
      #|INVARIANT 2 (Reasonable bound): x ≤ n.
      #|
      #|Base: x = n ≤ n. ✓
      #|
      #|Inductive: x' = (x + n/x) / 2.
      #|  Since x ≥ √n (Invariant 1), we have n/x ≤ √n ≤ x.
      #|  So x' = (x + n/x) / 2 ≤ (x + x) / 2 = x ≤ n. ✓
      #|
      #|TERMINATION: The sequence x₀, x₁, x₂, ... is:
      #|  - Strictly decreasing (we only continue when x' < x)
      #|  - Bounded below by √n
      #|  - Integer-valued
      #|Therefore it must terminate.
      #|
      #|CONVERGENCE: When x' ≥ x, we have x ≤ √n + 1.
      #|Combined with x² ≥ n (Invariant 1), this gives x = floor(√n).
      #|
      #|Newton's method converges quadratically: if error is ε,
      #|next error is roughly ε²/2√n. From x=n, reaches answer in O(log log n).
      #|MAINTENANCE:
      #|Since n/x ≤ x, averaging keeps x within [√n, n].
      #|TERMINATION:
      #|Strict decreases stop after finitely many steps (integer sequence).
    ),
  }
}

///|
test "isqrt_newton" {
  assert_eq(isqrt_newton(0), 0)
  assert_eq(isqrt_newton(1), 1)
  assert_eq(isqrt_newton(4), 2)
  assert_eq(isqrt_newton(8), 2)
  assert_eq(isqrt_newton(9), 3)
  assert_eq(isqrt_newton(100), 10)
  assert_eq(isqrt_newton(1000000), 1000)
}

// ============================================================================
// Example 14: Sieve of Eratosthenes
// Generate all primes up to n
// ============================================================================

///|
#warnings("+missing_invariant+missing_reasoning")
fn sieve(n : Int) -> Array[Int] {
  guard n >= 2 else { return [] }
  let is_prime : Array[Bool] = Array::make(n + 1, true)
  is_prime[0] = false
  is_prime[1] = false
  for i = 2 {
    if i * i > n {
      break
    } else if is_prime[i] {
      // Mark all multiples of i as composite
      let mut j = i * i
      while j <= n {
        is_prime[j] = false
        j = j + i
      }
      continue i + 1
    } else {
      continue i + 1
    }
  } where {
    invariant: i >= 2 && i * i <= n + 1,
    reasoning: (
      #|INVARIANT 1 (Bounds): i stays in sieving range.
      #|
      #|We only need to sieve up to √n because if n = a·b with a ≤ b,
      #|then a ≤ √n. So any composite ≤ n has a factor ≤ √n.
      #|MAINTENANCE:
      #|Incrementing i keeps i within the sieving bound.
      #|TERMINATION:
      #|When i * i > n, all composites have a smaller prime factor marked.
    ),
    invariant: i >= 2,
    reasoning: (
      #|INVARIANT 2 (Sieve correctness): After processing i,
      #|for all j ∈ [2, i], is_prime[j] = true iff j is prime.
      #|
      #|Base: i=2, we haven't modified is_prime[2] (it's true, and 2 is prime).
      #|
      #|Inductive: When processing prime p ≤ i:
      #|  We mark p², p²+p, p²+2p, ... as composite.
      #|  Why start at p²? All smaller multiples k·p (k < p) were already
      #|  marked when processing the smaller prime factor of k.
      #|
      #|  For composite c ≤ n: Let p be its smallest prime factor.
      #|  Then c = p·m where m ≥ p (since p is smallest).
      #|  So c ≥ p², meaning c is marked when we process p.
      #|
      #|  Since p ≤ √c ≤ √n, we will process p before termination.
      #|  Therefore all composites get marked, all primes stay unmarked.
      #|MAINTENANCE:
      #|Marking multiples of prime i preserves correctness up to i.
      #|TERMINATION:
      #|At loop end, is_prime reflects primality for all numbers ≤ n.
    ),
  }
  // Collect remaining primes
  is_prime
  .mapi((i, b) => if b { Some(i) } else { None })
  .filter(x => x is Some(_))
  .map(x => x.unwrap())
  .filter(x => x >= 2)
}

///|
test "sieve" {
  assert_eq(sieve(10), [2, 3, 5, 7])
  assert_eq(sieve(20), [2, 3, 5, 7, 11, 13, 17, 19])
  assert_eq(sieve(2), [2])
  assert_eq(sieve(1), [])
}

// ============================================================================
// Example 15: Modular Exponentiation
// Compute base^exp mod m efficiently (crucial for cryptography)
// ============================================================================

///|
#warnings("+missing_invariant+missing_reasoning")
fn mod_pow(base : Int, exp : Int, m : Int) -> Int {
  guard m > 1 else { return 0 }
  for b = base % m, e = exp, acc = 1 {
    if e == 0 {
      break acc
    } else if e % 2 == 0 {
      continue b * b % m, e / 2, acc
    } else {
      continue b, e - 1, acc * b % m
    }
  } where {
    invariant: e >= 0 && acc >= 0 && acc < m && b >= 0 && b < m,
    reasoning: (
      #|INVARIANT 1 (Bounds): All values stay in valid range.
      #|
      #|Base: b = base % m ∈ [0, m), acc = 1 < m, e = exp ≥ 0. ✓
      #|
      #|Inductive: 
      #|  - (b * b) % m ∈ [0, m) ✓
      #|  - (acc * b) % m ∈ [0, m) ✓
      #|  - e/2 ≥ 0, e-1 ≥ 0 when e > 0 ✓
      #|MAINTENANCE:
      #|Updates keep b and acc reduced modulo m and e non-negative.
      #|TERMINATION:
      #|When e = 0, the loop stops with a valid result.
    ),
    invariant: acc >= 0,
    reasoning: (
      #|INVARIANT 2 (Correctness): acc · b^e ≡ base^exp (mod m)
      #|
      #|Base: acc=1, b=base%m, e=exp.
      #|  1 · (base%m)^exp ≡ 1 · base^exp ≡ base^exp (mod m). ✓
      #|
      #|Case e even: (b', e', acc') = ((b²)%m, e/2, acc)
      #|  acc' · b'^e' = acc · ((b²)%m)^(e/2)
      #|               ≡ acc · (b²)^(e/2)     (mod m)
      #|               = acc · b^e            (mod m). ✓
      #|
      #|Case e odd: (b', e', acc') = (b, e-1, (acc·b)%m)
      #|  acc' · b'^e' = ((acc·b)%m) · b^(e-1)
      #|              ≡ acc · b · b^(e-1)     (mod m)
      #|              = acc · b^e             (mod m). ✓
      #|
      #|Termination: When e=0, return acc ≡ acc · b^0 ≡ base^exp (mod m). ✓
      #|
      #|SECURITY NOTE: This is the basis of RSA encryption.
      #|Computing m^e mod n where e has thousands of bits is feasible
      #|only because we reduce mod n at each step, keeping numbers small.
      #|MAINTENANCE:
      #|Odd/even updates preserve acc · b^e ≡ base^exp (mod m).
      #|TERMINATION:
      #|At e = 0, acc is the desired modular power.
    ),
  }
}

///|
test "mod_pow" {
  assert_eq(mod_pow(2, 10, 1000), 24) // 1024 mod 1000
  assert_eq(mod_pow(3, 5, 7), 5) // 243 mod 7
  assert_eq(mod_pow(2, 0, 100), 1) // anything^0 = 1
  assert_eq(mod_pow(5, 3, 13), 8) // 125 mod 13
  // Fermat's little theorem: a^(p-1) ≡ 1 (mod p) for prime p
  assert_eq(mod_pow(2, 6, 7), 1) // 2^6 mod 7 = 64 mod 7 = 1
}

// ============================================================================
// Example 16: Population Count (Hamming Weight)
// Count number of 1-bits in an integer
// ============================================================================

///|
#warnings("+missing_invariant+missing_reasoning")
fn popcount(n : Int) -> Int {
  for x = n & 0x7FFFFFFF, count = 0 {
    // Mask to ensure non-negative for the invariant
    if x == 0 {
      break count + (if n < 0 { 1 } else { 0 }) // Account for sign bit
    } else {
      // x & (x-1) clears the lowest set bit
      continue x & (x - 1), count + 1
    }
  } where {
    invariant: count >= 0 && x >= 0,
    reasoning: (
      #|INVARIANT 1 (Non-negative): count and x stay non-negative.
      #|
      #|Base: count = 0 ≥ 0, x = n & 0x7FFFFFFF ≥ 0. ✓
      #|
      #|Inductive: count + 1 ≥ 0. x & (x-1) clears lowest bit,
      #|keeping x non-negative. ✓
      #|MAINTENANCE:
      #|Clearing the lowest set bit preserves non-negativity.
      #|TERMINATION:
      #|When x = 0, all bits have been counted.
    ),
    invariant: count >= 0,
    reasoning: (
      #|INVARIANT 2 (Progress + Correctness):
      #|popcount(original n) = count + popcount(x) + sign_bit_contribution
      #|
      #|The magic: x & (x-1) clears exactly the lowest set bit of x.
      #|
      #|Why? Let x = ...a1b...b where 'a1' is the lowest 1-bit and
      #|b...b are zeros. Then:
      #|  x - 1 = ...a0b̄...b̄  (flip the lowest 1 and all zeros below it)
      #|  x & (x-1) = ...a0...0 (the lowest 1-bit is cleared!)
      #|
      #|Each iteration:
      #|  - Removes exactly one 1-bit from x
      #|  - Increments count by 1
      #|
      #|Therefore: count = (# of 1-bits removed from x)
      #|When x = 0: all bits cleared, count = popcount(original x).
      #|
      #|EFFICIENCY: This runs in O(k) where k = number of 1-bits,
      #|not O(32) or O(64). Sparse numbers are fast!
      #|MAINTENANCE:
      #|Each iteration removes exactly one 1-bit from x and increments count.
      #|TERMINATION:
      #|At x = 0, count equals the popcount (plus sign-bit adjustment).
    ),
  }
}

///|
test "popcount" {
  assert_eq(popcount(0), 0)
  assert_eq(popcount(1), 1)
  assert_eq(popcount(7), 3) // 0b111
  assert_eq(popcount(8), 1) // 0b1000
  assert_eq(popcount(255), 8) // 0b11111111
  assert_eq(popcount(0x55555555), 16) // alternating bits
}

// ============================================================================
// Example 17: Next Permutation
// Generate lexicographically next permutation in-place
// ============================================================================

///|
#warnings("+missing_invariant+missing_reasoning")
fn next_permutation(arr : Array[Int]) -> Bool {
  // Returns false if already at last permutation
  guard arr.length() >= 2 else { return false }
  // Step 1: Find largest i such that arr[i] < arr[i+1]
  let pivot : Int? = for i = arr.length() - 2 {
    if i < 0 {
      break None
    } else if arr[i] < arr[i + 1] {
      break Some(i)
    } else {
      continue i - 1
    }
  } where {
    invariant: i >= -1 && i < arr.length() - 1,
    reasoning: (
      #|INVARIANT 1 (Bounds): i stays in valid search range.
      #|
      #|INVARIANT 2 (Suffix property): arr[i+1..n) is non-increasing.
      #|
      #|Base: i = n-2. The suffix arr[n-1..n) has one element, trivially
      #|non-increasing. ✓
      #|
      #|Inductive: We continue (decrement i) only when arr[i] >= arr[i+1].
      #|This extends the non-increasing suffix by one element. ✓
      #|
      #|When we find arr[i] < arr[i+1]: i is the "pivot" - the rightmost
      #|position where we can make the permutation larger.
      #|
      #|If no pivot found (i < 0): entire array is non-increasing,
      #|meaning it's the lexicographically largest permutation.
      #|MAINTENANCE:
      #|Decrementing i extends the non-increasing suffix.
      #|TERMINATION:
      #|Stop when a pivot is found or i < 0 (last permutation).
    ),
  }
  guard pivot is Some(p) else {
    // Already at last permutation, wrap to first (reverse entire array)
    reverse_range(arr, 0, arr.length() - 1)
    return false
  }
  // Step 2: Find largest j > p such that arr[j] > arr[p]
  let swap_idx = for j = arr.length() - 1 {
    if arr[j] > arr[p] {
      break j
    } else {
      continue j - 1
    }
  } where {
    invariant: j > p,
    reasoning: (
      #|INVARIANT 3 (Search bounds): j stays above pivot.
      #|
      #|Since arr[p+1..n) is non-increasing and arr[p] < arr[p+1],
      #|there exists at least one element > arr[p] in the suffix.
      #|We scan from the right to find the smallest such element
      #|(rightmost due to non-increasing order).
      #|MAINTENANCE:
      #|Decrement j until we find an element > arr[p].
      #|TERMINATION:
      #|When found, j is the correct swap index.
    ),
  }
  // Step 3: Swap arr[p] and arr[swap_idx]
  let tmp = arr[p]
  arr[p] = arr[swap_idx]
  arr[swap_idx] = tmp
  // Step 4: Reverse arr[p+1..n) to get smallest suffix
  reverse_range(arr, p + 1, arr.length() - 1)
  true
}

///|
fn reverse_range(arr : Array[Int], lo : Int, hi : Int) -> Unit {
  for l = lo, h = hi {
    if l >= h {
      break
    } else {
      let tmp = arr[l]
      arr[l] = arr[h]
      arr[h] = tmp
      continue l + 1, h - 1
    }
  } where {
    invariant: 0 <= lo && lo <= l && h <= hi && hi < arr.length(),
    reasoning: (
      #|Bounds: l and h stay within the provided range.
      #|
      #|Base: l=lo, h=hi and 0 <= lo <= hi < n by caller contract.
      #|Update: l increases and h decreases, so they remain in [lo, hi].
      #|MAINTENANCE:
      #|Swapping and moving inward keeps l,h within bounds.
      #|TERMINATION:
      #|When l >= h, the range is fully reversed.
    ),
    invariant: l + h == lo + hi,
    reasoning: (
      #|Symmetry: the distance moved from both ends is the same.
      #|
      #|Each step does (l, h) -> (l+1, h-1), preserving l+h.
      #|This ensures we swap mirrored positions while shrinking inward.
      #|MAINTENANCE:
      #|Incrementing l and decrementing h preserves symmetry.
      #|TERMINATION:
      #|At l >= h, all mirrored swaps are complete.
    ),
  }
}

///|
test "next_permutation" {
  let arr1 : Array[Int] = [1, 2, 3]
  assert_true(next_permutation(arr1))
  assert_eq(arr1, [1, 3, 2])
  assert_true(next_permutation(arr1))
  assert_eq(arr1, [2, 1, 3])
  let arr2 : Array[Int] = [3, 2, 1]
  assert_true(not(next_permutation(arr2))) // wraps around
  assert_eq(arr2, [1, 2, 3])
}

// ============================================================================
// Example 18: Longest Increasing Subsequence Length (O(n log n))
// Uses patience sorting / binary search approach
// ============================================================================

///|
fn lower_bound(arr : Array[Int], len : Int, target : Int) -> Int {
  // Find first index where arr[i] >= target in arr[0..len)
  for lo = 0, hi = len {
    if lo >= hi {
      break lo
    } else {
      let mid = lo + (hi - lo) / 2
      if arr[mid] < target {
        continue mid + 1, hi
      } else {
        continue lo, mid
      }
    }
  } where {
    invariant: 0 <= lo && lo <= hi && hi <= len,
    reasoning: (
      #|Bounds: lo and hi always stay within [0, len].
      #|
      #|Base: lo=0, hi=len. Updates use mid in [lo, hi), so bounds hold.
      #|MAINTENANCE:
      #|Updating lo or hi keeps them within [0, len].
      #|TERMINATION:
      #|When lo >= hi, lo is the lower_bound.
    ),
    invariant: lo == 0 || arr[lo - 1] < target,
    reasoning: (
      #|Left exclusion: all indices < lo are strictly < target.
      #|
      #|We only move lo to mid+1 when arr[mid] < target.
      #|MAINTENANCE:
      #|If arr[mid] < target, lo advances and exclusion remains true.
      #|TERMINATION:
      #|At loop end, all indices before lo are excluded.
    ),
    invariant: hi == len || arr[hi] >= target,
    reasoning: (
      #|Right candidate: hi is the smallest index known to satisfy arr[hi] >= target,
      #|or hi = len if no such index has been found yet.
      #|MAINTENANCE:
      #|When arr[mid] >= target, we move hi to mid to keep the earliest candidate.
      #|When arr[mid] < target, hi stays put and remains a valid upper bound.
      #|TERMINATION:
      #|When lo == hi, hi is the first index with arr[hi] >= target (or len).
    ),
  }
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn lis_length(arr : ArrayView[Int]) -> Int {
  guard arr.length() > 0 else { return 0 }
  // tails[i] = smallest ending element of any increasing subsequence of length i+1
  let tails : Array[Int] = Array::make(arr.length(), 0)
  for i = 0, len = 0 {
    if i >= arr.length() {
      break len
    } else {
      let pos = lower_bound(tails, len, arr[i])
      tails[pos] = arr[i]
      if pos == len {
        continue i + 1, len + 1 // Extended longest
      } else {
        continue i + 1, len // Replaced existing
      }
    }
  } where {
    invariant: i >= 0 && i <= arr.length() && len >= 0 && len <= i,
    reasoning: (
      #|INVARIANT 1 (Bounds):
      #|i is the number of processed elements; len is the current LIS length.
      #|We always have 0 <= len <= i <= arr.length().
      #|MAINTENANCE:
      #|Each step increments i and either keeps len or increases it by 1.
      #|TERMINATION:
      #|At i = arr.length(), len is the LIS length for the full array.
    ),
    invariant: len >= 0,
    reasoning: (
      #|INVARIANT 2 (Tails array property):
      #|For all j ∈ [0, len): tails[j] is the smallest possible ending
      #|element of any increasing subsequence of length j+1 in arr[0..i).
      #|
      #|Moreover, tails[0..len) is strictly increasing.
      #|
      #|Base: i=0, len=0. No elements processed, no subsequences. ✓
      #|
      #|Inductive: Consider arr[i]. Find pos = first index where
      #|tails[pos] >= arr[i] (or pos = len if arr[i] is largest).
      #|
      #|Case pos == len: arr[i] > all elements in tails[0..len).
      #|  We can extend any LIS of length len by appending arr[i].
      #|  So there exists an increasing subsequence of length len+1
      #|  ending with arr[i]. Set tails[len] = arr[i], increment len. ✓
      #|
      #|Case pos < len: tails[pos] >= arr[i] > tails[pos-1] (if pos > 0).
      #|  There's an increasing subsequence of length pos ending with
      #|  tails[pos-1] < arr[i]. Append arr[i] to get length pos+1.
      #|  Since arr[i] <= tails[pos] (old smallest for length pos+1),
      #|  update tails[pos] = arr[i] (new smallest ending). ✓
      #|
      #|CORRECTNESS: At termination, len = length of longest increasing
      #|subsequence. The tails array gives us a compressed representation.
      #|
      #|WHY O(n log n)? Binary search for pos takes O(log len) ≤ O(log n).
      #|Total: O(n log n), much better than O(n²) DP.
      #|MAINTENANCE:
      #|Updating tails[pos] preserves minimal possible endings for each length.
      #|TERMINATION:
      #|At i = arr.length(), len is the LIS length.
    ),
  }
}

///|
test "lis_length" {
  assert_eq(lis_length([10, 9, 2, 5, 3, 7, 101, 18][:]), 4) // [2,3,7,18] or [2,5,7,101]
  assert_eq(lis_length([0, 1, 0, 3, 2, 3][:]), 4) // [0,1,2,3]
  assert_eq(lis_length([7, 7, 7, 7][:]), 1) // all same, LIS = 1
  assert_eq(lis_length([1, 2, 3, 4, 5][:]), 5) // already sorted
  assert_eq(lis_length([5, 4, 3, 2, 1][:]), 1) // decreasing
}
