// ============================================================================
// Challenge: Suffix Array + LCP (Kasai)
// ============================================================================

///|
#warnings("+missing_invariant+missing_reasoning")
pub fn suffix_array(s : StringView) -> Array[Int] {
  let n = s.length()
  if n == 0 {
    return []
  }
  let sa = Array::makei(n, fn(i) { i })
  let rank = Array::make(n, 0)
  for i = 0; i < n; i = i + 1 {
    rank[i] = s[i].to_int()
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (initial ranks):
      #|rank[0..i) stores the character codes for s[0..i).
      #|MAINTENANCE:
      #|Assign rank[i] from s[i].
      #|TERMINATION:
      #|At i = n, every suffix is ranked by its first character.
    ),
  }
  for k = 1; k < n; k = k * 2 {
    let get_key = fn(i : Int) -> (Int, Int) {
      let r1 = rank[i]
      let r2 = if i + k < n { rank[i + k] } else { -1 }
      (r1, r2)
    }
    sa.sort_by(fn(a, b) {
      let (a1, a2) = get_key(a)
      let (b1, b2) = get_key(b)
      if a1 != b1 {
        a1 - b1
      } else {
        a2 - b2
      }
    })
    let tmp = Array::make(n, 0)
    tmp[sa[0]] = 0
    for i = 1; i < n; i = i + 1 {
      let prev_key = get_key(sa[i - 1])
      let curr_key = get_key(sa[i])
      tmp[sa[i]] = if prev_key == curr_key {
        tmp[sa[i - 1]]
      } else {
        tmp[sa[i - 1]] + 1
      }
    } where {
      invariant: i >= 1 && i <= n,
      reasoning: (
        #|INVARIANT (rank recompute):
        #|tmp is correct for sa[0..i). Adjacent suffixes with equal keys share
        #|the same rank; otherwise the rank increases by 1.
        #|MAINTENANCE:
        #|Compare current and previous keys to decide whether to increment.
        #|TERMINATION:
        #|At i = n, tmp assigns a rank to every suffix for length 2k prefixes.
      ),
    }
    for i = 0; i < n; i = i + 1 {
      rank[i] = tmp[i]
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (copy ranks):
        #|rank[0..i) has been updated from tmp.
        #|MAINTENANCE:
        #|Copy tmp[i] into rank[i].
        #|TERMINATION:
        #|At i = n, rank reflects the ordering by 2k-length prefixes.
      ),
    }
    if rank[sa[n - 1]] == n - 1 {
      break
    }
  } where {
    invariant: k >= 1 && k <= n * 2,
    reasoning: (
      #|INVARIANT (prefix doubling):
      #|At each iteration, sa is sorted by the first k characters of suffixes,
      #|and rank encodes that ordering.
      #|MAINTENANCE:
      #|Sort by (rank[i], rank[i+k]) to order by 2k characters, then recompute
      #|ranks for the next doubling.
      #|TERMINATION:
      #|When ranks are unique or k >= n, the suffix order is complete.
    ),
  }
  sa
}

///|
#warnings("+missing_invariant+missing_reasoning")
pub fn lcp_array(s : StringView, sa : ArrayView[Int]) -> Array[Int] {
  let n = s.length()
  if n == 0 {
    return []
  }
  let rank = Array::make(n, 0)
  for i = 0; i < n; i = i + 1 {
    rank[sa[i]] = i
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (inverse SA):
      #|rank is filled for sa[0..i), mapping suffix start to its position.
      #|MAINTENANCE:
      #|Set rank[sa[i]] = i.
      #|TERMINATION:
      #|At i = n, rank is the full inverse permutation of sa.
    ),
  }
  let lcp = Array::make(n, 0)
  for i = 0, h = 0 {
    if i >= n {
      break
    }
    if rank[i] == 0 {
      let next_h = if h > 0 { h - 1 } else { 0 }
      continue i + 1, next_h
    }
    let j = sa[rank[i] - 1]
    let new_h = for t = h {
      if i + t < n && j + t < n && s[i + t] == s[j + t] {
        continue t + 1
      } else {
        break t
      }
    } where {
      invariant: t >= h && t <= n,
      reasoning: (
        #|INVARIANT (LCP extend):
        #|t is the length of the common prefix between suffixes at i and j.
        #|MAINTENANCE:
        #|If the next characters match, extend t by one.
        #|TERMINATION:
        #|Stops at mismatch or end, yielding the LCP length.
      ),
    }
    lcp[rank[i]] = new_h
    let next_h = if new_h > 0 { new_h - 1 } else { 0 }
    continue i + 1, next_h
  } where {
    invariant: i >= 0 && i <= n && h >= 0,
    reasoning: (
      #|INVARIANT (Kasai scan):
      #|lcp is correct for suffixes with start < i. h is the current reuse
      #|length that can be decremented by at most 1 each step.
      #|MAINTENANCE:
      #|Compute LCP with the previous suffix in SA order, then set h = max(h-1,0).
      #|TERMINATION:
      #|At i = n, all LCP values are computed in O(n).
    ),
  }
  lcp
}

///|
test "suffix_array_banana" {
  let sa = suffix_array("banana"[:])
  assert_eq(sa, [5, 3, 1, 0, 4, 2])
  let lcp = lcp_array("banana"[:], sa[:])
  assert_eq(lcp, [0, 1, 3, 0, 0, 2])
}

///|
test "suffix_array_empty" {
  assert_eq(suffix_array(""[:]), [])
  assert_eq(lcp_array(""[:], []), [])
}
