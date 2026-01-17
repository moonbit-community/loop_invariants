// ============================================================================
// Challenge: Binary Lifting for Ancestor Queries
// ============================================================================

///|
/// Build binary lifting table up[k][v] = 2^k-th ancestor of v.
pub fn build_lift(parent : ArrayView[Int]) -> Array[Array[Int]] {
  let n = parent.length()
  if n == 0 {
    return []
  }
  let log = for k = 1, pow = 1 {
    if pow >= n {
      break k
    } else {
      continue k + 1, pow << 1
    }
  } where {
    invariant: k >= 1 && pow >= 1,
    reasoning: (
      #|INVARIANT (Log growth):
      #|pow = 2^(k-1) and grows until it covers n.
      #|MAINTENANCE:
      #|Shift pow and increment k, preserving the power-of-two relation.
      #|TERMINATION:
      #|When pow >= n, k is the number of levels needed.
    ),
  }
  let up : Array[Array[Int]] = Array::makei(log, _ => Array::make(n, -1))
  for v in 0..<n {
    up[0][v] = parent[v]
  }
  for k in 1..<log {
    for v in 0..<n {
      let mid = up[k - 1][v]
      if mid >= 0 {
        up[k][v] = up[k - 1][mid]
      }
    }
  }
  up
}

///|
/// Lift node v by dist steps using the lifting table.
pub fn lift(up : Array[Array[Int]], v : Int, dist : Int) -> Int {
  let levels = up.length()
  for k = 0, cur = v, d = dist {
    if k >= levels {
      break cur
    } else if (d & 1) == 1 {
      if cur < 0 {
        break -1
      } else {
        continue k + 1, up[k][cur], d >> 1
      }
    } else {
      continue k + 1, cur, d >> 1
    }
  } where {
    invariant: k >= 0 && k <= levels,
    reasoning: (
      #|INVARIANT (Bit lifting):
      #|cur equals the ancestor of v after applying the first k bits of dist.
      #|MAINTENANCE:
      #|If the current bit is 1, jump 2^k; otherwise keep cur unchanged.
      #|TERMINATION:
      #|At k = levels, all bits are processed.
    ),
  }
}

///|
test "binary_lifting" {
  let parent : Array[Int] = [-1, 0, 0, 1, 1, 2]
  let up = build_lift(parent[:])
  assert_eq(lift(up, 4, 1), 1)
  assert_eq(lift(up, 4, 2), 0)
  assert_eq(lift(up, 4, 3), -1)
}
