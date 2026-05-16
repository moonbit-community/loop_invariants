// ============================================================================
// BOYER-MOORE MAJORITY VOTE  -  Boyer & Moore 1981
// ============================================================================
//
// PROBLEM
//
// Given a stream of elements, find the **majority element** -- one that
// appears strictly more than n/2 times -- if it exists, using `O(1)`
// extra space and a single linear pass.
//
// THE ALGORITHM
//
// Maintain a candidate `c` and a counter `cnt = 0`. For each input x:
//
//   if cnt == 0:    c <- x;  cnt <- 1
//   elif c == x:    cnt <- cnt + 1
//   else:            cnt <- cnt - 1
//
// After processing all elements, `c` is the *only possible* majority
// candidate. To be sure it is the majority, do a second pass that
// counts its occurrences.
//
// THE KEY INVARIANT
//
//   "At every step, if we 'pair off' the elements processed so far
//    into cancellations of distinct values plus `cnt` extra copies of
//    `c`, the multiset of processed inputs is exactly reconstructed.
//    Therefore if a majority element exists, it must equal `c` at
//    the end (a majority cannot be fully cancelled by all other
//    values combined)."
//
// COMPLEXITY
//
//   Time   : O(n)        (single pass to find candidate, optional second to verify)
//   Space  : O(1)        (one candidate, one counter)
//
// GENERALISATION: BOYER-MOORE k-MAJORITY  (Misra-Gries 1982)
//
// To find every element occurring more than n/(k+1) times, maintain
// k candidates with k counters. See `techniques/misra_gries_heavy_hitters`
// in this repository for the general case.

///|
/// Find the strict-majority element of `arr`, or `None` if none exists.
///
/// "Strict majority" means: the element appears **more than `n/2`** times.
/// Uses Boyer-Moore voting (`O(n)` time, `O(1)` extra space). Performs
/// a verification pass so the result is exact.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   @debug.assert_eq(@majority_vote.majority([2, 1, 2, 3, 2]), Some(2))
///   @debug.assert_eq(@majority_vote.majority([1, 2, 3]), None)
/// }
/// ```
pub fn[T : Eq] majority(arr : Array[T]) -> T? {
  let n = arr.length()
  if n == 0 {
    return None
  }
  let cand = find_candidate(arr)
  // Verify by counting occurrences.
  let mut cnt = 0
  for x in arr {
    if x == cand {
      cnt = cnt + 1
    }
  }
  if cnt * 2 > n {
    Some(cand)
  } else {
    None
  }
}

///|
/// Find the Boyer-Moore *candidate* without verifying it -- callers who
/// already know a majority exists (e.g. from a problem statement) can
/// skip the second pass.
///
/// Caveat: if no majority exists, the returned element is meaningless
/// (just whatever element happened to survive the cancellations).
pub fn[T : Eq] find_candidate(arr : Array[T]) -> T {
  // Precondition: arr is non-empty; we only call this from `majority`
  // which already guarded. For safety, callers should ensure n >= 1.
  let mut cand = arr[0]
  let mut cnt = 0
  for x in arr {
    if cnt == 0 {
      cand = x
      cnt = 1
    } else if x == cand {
      cnt = cnt + 1
    } else {
      cnt = cnt - 1
    }
  }
  cand
}

///|
test "majority simple" {
  @debug.assert_eq(majority([2, 1, 2, 3, 2]), Some(2))
  @debug.assert_eq(majority([1, 1, 1, 2, 3]), Some(1))
  @debug.assert_eq(majority([5]), Some(5))
}

///|
test "majority absent" {
  @debug.assert_eq(majority([1, 2, 3, 4, 5]), None)
  @debug.assert_eq(majority([1, 2, 1, 2]), None) // tie, no strict majority
}

///|
test "majority empty" {
  let empty : Array[Int] = []
  @debug.assert_eq(majority(empty), None)
}

///|
test "majority exact half is not majority" {
  // 4 of 8 is not strictly more than n/2.
  @debug.assert_eq(majority([1, 1, 1, 1, 2, 2, 2, 2]), None)
  // 5 of 8 is.
  @debug.assert_eq(majority([1, 1, 1, 1, 1, 2, 2, 2]), Some(1))
}

///|
test "majority works with strings" {
  let arr = ["a", "b", "a", "a", "b", "a", "c"]
  @debug.assert_eq(majority(arr), Some("a"))
}

///|
test "majority reproduces classic example" {
  // From the original Boyer-Moore paper:
  let v = ["A", "A", "C", "C", "C", "B", "B", "C", "C", "C", "B", "A", "C", "C"]
  @debug.assert_eq(majority(v), Some("C"))
}

///|
test "find_candidate without verification" {
  // When a majority exists, find_candidate returns it.
  @debug.assert_eq(find_candidate([1, 2, 1, 2, 1]), 1)
  // When no majority exists, the candidate is *some* surviving element;
  // we only check that it's one of the inputs.
  let arr = [3, 4, 5]
  let c = find_candidate(arr)
  let mut found = false
  for x in arr {
    if x == c {
      found = true
      break
    }
  }
  @debug.assert_eq(found, true)
}

///|
test "majority stable under permutation" {
  // The strict-majority element does not depend on input order.
  let a = [1, 1, 1, 2, 3, 4, 1]
  let b = [4, 3, 1, 2, 1, 1, 1]
  @debug.assert_eq(majority(a), majority(b))
}

///|
test "majority by quick brute check" {
  fn brute(arr : Array[Int]) -> Int? {
    let n = arr.length()
    for cand in arr {
      let mut c = 0
      for x in arr {
        if x == cand {
          c = c + 1
        }
      }
      if c * 2 > n {
        return Some(cand)
      }
    }
    None
  }

  let samples = [
    [1, 2, 3, 2, 2],
    [9, 9, 9, 9, 9],
    [1, 2, 3, 4],
    [7, 7, 7, 7, 8, 8, 8],
    [1, 1, 1, 1, 2, 2],
  ]
  for s in samples {
    @debug.assert_eq(majority(s), brute(s))
  }
}
