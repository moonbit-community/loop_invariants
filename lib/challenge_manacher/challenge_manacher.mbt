// ============================================================================
// Challenge: Manacher's Algorithm (Longest Palindromic Substring)
// ============================================================================

///|
fn min(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
#warnings("+missing_invariant+missing_reasoning")
pub fn manacher_radii(s : StringView) -> (Array[Int], Array[Int]) {
  let n = s.length()
  if n == 0 {
    return ([], [])
  }
  let d1 = Array::make(n, 0)
  for i = 0, l = 0, r = -1 {
    if i >= n {
      break
    }
    let k = if i > r { 1 } else { min(d1[l + r - i], r - i + 1) }
    let len = for t = k {
      if i - t >= 0 && i + t < n && s[i - t] == s[i + t] {
        continue t + 1
      } else {
        break t
      }
    } where {
      invariant: t >= k && t <= n,
      reasoning: (
        #|INVARIANT (odd expand):
        #|t is the current radius such that s[i-t..i+t] is a palindrome.
        #|MAINTENANCE:
        #|If both sides match, increase t to extend the palindrome.
        #|TERMINATION:
        #|When mismatch or bounds stop, t is the maximal odd radius.
      ),
    }
    d1[i] = len
    let right = i + len - 1
    if right > r {
      continue i + 1, i - len + 1, right
    } else {
      continue i + 1, l, r
    }
  } where {
    invariant: i >= 0 && i <= n && (r < 0 || (l >= 0 && l <= r && r < n)),
    reasoning: (
      #|INVARIANT (odd palindromes):
      #|d1[0..i) are correct. [l, r] is the rightmost odd palindrome seen so far.
      #|MAINTENANCE:
      #|Seed k from the mirror when i is inside [l, r], then expand. Update the
      #|window if the palindrome centered at i extends beyond r.
      #|TERMINATION:
      #|At i = n, all odd radii are computed in linear time.
    ),
  }
  let d2 = Array::make(n, 0)
  for i = 0, l = 0, r = -1 {
    if i >= n {
      break
    }
    let k = if i > r { 0 } else { min(d2[l + r - i + 1], r - i + 1) }
    let len = for t = k {
      if i - t - 1 >= 0 && i + t < n && s[i - t - 1] == s[i + t] {
        continue t + 1
      } else {
        break t
      }
    } where {
      invariant: t >= k && t <= n,
      reasoning: (
        #|INVARIANT (even expand):
        #|t is the current radius such that s[i-t..i+t-1] is an even palindrome.
        #|MAINTENANCE:
        #|If both sides match, extend by incrementing t.
        #|TERMINATION:
        #|Stops when mismatch or bounds are reached, giving maximal even radius.
      ),
    }
    d2[i] = len
    let right = i + len - 1
    if right > r {
      continue i + 1, i - len, right
    } else {
      continue i + 1, l, r
    }
  } where {
    invariant: i >= 0 && i <= n && (r < 0 || (l >= 0 && l <= r + 1 && r < n)),
    reasoning: (
      #|INVARIANT (even palindromes):
      #|d2[0..i) are correct. [l, r] is the rightmost even palindrome window
      #|tracked so far (possibly empty with l = r + 1).
      #|MAINTENANCE:
      #|Mirror the radius within [l, r] when possible, then expand and update
      #|the window if the new palindrome extends past r.
      #|TERMINATION:
      #|At i = n, all even radii are computed.
    ),
  }
  (d1, d2)
}

///|
pub fn longest_palindrome_len(s : StringView) -> Int {
  let (d1, d2) = manacher_radii(s)
  let n = s.length()
  let mut best = 0
  for i in 0..<n {
    let odd = d1[i] * 2 - 1
    if odd > best {
      best = odd
    }
    let even = d2[i] * 2
    if even > best {
      best = even
    }
  }
  best
}

///|
test "manacher_basic" {
  assert_eq(longest_palindrome_len("abacaba"[:]), 7)
  assert_eq(longest_palindrome_len("babad"[:]), 3)
  assert_eq(longest_palindrome_len("cbbd"[:]), 2)
}
