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
    proof_invariant: b >= 1,
    proof_reasoning: (
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
  let qs = [
    for i in 0..<q => {
      let (l, r) = queries[i]
      { l, r, idx: i }
    }
  ]
  qs.sort_by((a, b) => {
    if a.l / block != b.l / block {
      a.l / block - b.l / block
    } else {
      a.r - b.r
    }
  })
  let ans = Array::make(q, 0)
  let _ = for target in qs; cur_l = 0, cur_r = 0, sum = 0 {
    let sum1 = if cur_l > target.l {
      for i in cur_l>..target.l; acc = sum {
        continue acc + arr[i]
      } nobreak {
        acc
      }
    } else if cur_l < target.l {
      for i in cur_l..<target.l; acc = sum {
        continue acc - arr[i]
      } nobreak {
        acc
      }
    } else {
      sum
    }
    let sum2 = if cur_r < target.r {
      for i in cur_r..<target.r; acc = sum1 {
        continue acc + arr[i]
      } nobreak {
        acc
      }
    } else if cur_r > target.r {
      for i in cur_r>..target.r; acc = sum1 {
        continue acc - arr[i]
      } nobreak {
        acc
      }
    } else {
      sum1
    }
    ans[target.idx] = sum2
    continue target.l, target.r, sum2
  } nobreak {
    (cur_l, cur_r, sum)
  }
  ans
}

///|
test "mo_range_sum_shrinks_right_boundary" {
  let arr : Array[Int] = [1, 2, 3, 4, 5, 6, 7, 8]
  let queries : Array[(Int, Int)] = [(0, 6), (3, 4)]
  assert_eq(mo_range_sum(arr[:], queries[:]), [21, 4])
}
