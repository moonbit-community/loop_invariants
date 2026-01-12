// ============================================================================
// Challenge: Mo's Algorithm (Offline Range Sum)
// ============================================================================

///|
fn sqrt_ceil(n : Int) -> Int {
  if n <= 0 {
    return 1
  }
  for b = 1 {
    if b * b >= n {
      break b
    } else {
      continue b + 1
    }
  } where {
    invariant: b >= 1,
    reasoning: (
      #|INVARIANT (sqrt ceil):
      #|b is the smallest candidate tested so far; all smaller values satisfy
      #|b^2 < n.
      #|MAINTENANCE:
      #|Increment b while b^2 < n.
      #|TERMINATION:
      #|The first b with b^2 >= n is the ceiling of sqrt(n).
    ),
  }
}

///|
priv struct Query {
  l : Int
  r : Int
  idx : Int
}

///|
/// Answer offline range sum queries using Mo's algorithm.
#warnings("+missing_invariant+missing_reasoning")
pub fn mo_range_sum(
  arr : ArrayView[Int],
  queries : ArrayView[(Int, Int)],
) -> Array[Int] {
  let n = arr.length()
  let q = queries.length()
  if q == 0 {
    return []
  }
  let block = sqrt_ceil(n)
  let qs = Array::makei(q, fn(i) {
    let (l, r) = queries[i]
    { l, r, idx: i }
  })
  qs.sort_by(fn(a, b) {
    let ba = a.l / block
    let bb = b.l / block
    if ba != bb {
      ba - bb
    } else {
      a.r - b.r
    }
  })
  let ans = Array::make(q, 0)
  let mut cur_l = 0
  let mut cur_r = 0
  let mut sum = 0
  for qi = 0; qi < q; qi = qi + 1 {
    let target = qs[qi]
    let (l1, sum1) = for l = cur_l, s = sum {
      if l <= target.l {
        break (l, s)
      } else {
        let l2 = l - 1
        continue l2, s + arr[l2]
      }
    } where {
      invariant: l >= target.l && l <= cur_l,
      reasoning: (
        #|INVARIANT (extend left):
        #|s equals sum over arr[l..cur_r). We extend the window leftward until
        #|l reaches target.l.
        #|MAINTENANCE:
        #|Decrement l and add the new element arr[l].
        #|TERMINATION:
        #|At l = target.l, the left boundary matches the target.
      ),
    }
    let (r1, sum2) = for r = cur_r, s = sum1 {
      if r >= target.r {
        break (r, s)
      } else {
        continue r + 1, s + arr[r]
      }
    } where {
      invariant: r >= cur_r && r <= target.r,
      reasoning: (
        #|INVARIANT (extend right):
        #|s equals sum over arr[l1..r). We extend the window rightward until
        #|r reaches target.r.
        #|MAINTENANCE:
        #|Add arr[r] and increment r.
        #|TERMINATION:
        #|At r = target.r, the right boundary matches the target.
      ),
    }
    let (l2, sum3) = for l = l1, s = sum2 {
      if l >= target.l {
        break (l, s)
      } else {
        continue l + 1, s - arr[l]
      }
    } where {
      invariant: l >= l1 && l <= target.l,
      reasoning: (
        #|INVARIANT (shrink left):
        #|s equals sum over arr[l..r1). We move l rightward to target.l.
        #|MAINTENANCE:
        #|Subtract arr[l] and increment l.
        #|TERMINATION:
        #|At l = target.l, the left boundary is aligned.
      ),
    }
    let (r2, sum4) = for r = r1, s = sum3 {
      if r <= target.r {
        break (r, s)
      } else {
        let r2 = r - 1
        continue r2, s - arr[r2]
      }
    } where {
      invariant: r >= target.r && r <= r1,
      reasoning: (
        #|INVARIANT (shrink right):
        #|s equals sum over arr[l2..r). We move r leftward to target.r.
        #|MAINTENANCE:
        #|Decrement r and subtract arr[r].
        #|TERMINATION:
        #|At r = target.r, the right boundary is aligned.
      ),
    }
    cur_l = l2
    cur_r = r2
    sum = sum4
    ans[target.idx] = sum
  } where {
    invariant: qi >= 0 && qi <= q && cur_l >= 0 && cur_l <= cur_r,
    reasoning: (
      #|INVARIANT (Mo scan):
      #|After processing qs[0..qi), sum equals the range sum for the current
      #|window [cur_l, cur_r) associated with the last processed query.
      #|MAINTENANCE:
      #|Move the window to the next query by adjusting boundaries and updating
      #|sum accordingly.
      #|TERMINATION:
      #|At qi = q, all queries are answered in their original order.
    ),
  }
  ans
}

///|
test "mo_algorithm_sum" {
  let arr : Array[Int] = [1, 2, 3, 4, 5]
  let qs : Array[(Int, Int)] = [(0, 3), (1, 4), (2, 5), (0, 5)]
  assert_eq(mo_range_sum(arr[:], qs[:]), [6, 9, 12, 15])
}
