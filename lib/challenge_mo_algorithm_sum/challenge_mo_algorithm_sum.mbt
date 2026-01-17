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
  let qs = Array::makei(q, i => {
    let (l, r) = queries[i]
    { l, r, idx: i }
  })
  qs.sort_by((a, b) => if a.l / block != b.l / block {
    a.l / block - b.l / block
  } else {
    a.r - b.r
  })
  let ans = Array::make(q, 0)
  let mut cur_l = 0
  let mut cur_r = 0
  let mut sum = 0
  for target in qs {
    if cur_l > target.l {
      for i in cur_l >.. target.l {
        sum = sum + arr[i]
      }
    } else if cur_l < target.l {
      for i in cur_l..<target.l {
        sum = sum - arr[i]
      }
    }
    cur_l = target.l
    if cur_r < target.r {
      for i in cur_r..<target.r {
        sum = sum + arr[i]
      }
    } else if cur_r > target.r {
      for i in cur_r >.. target.r {
        sum = sum - arr[i]
      }
    }
    cur_r = target.r
    ans[target.idx] = sum
  }
  ans
}
