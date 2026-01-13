// ============================================================================
// Challenge: Palindrome Partition (Min Cuts)
// ============================================================================

///|
const INF : Int = 0x3fffffff

///|
/// Minimum cuts to partition s into palindromes.
#warnings("+missing_invariant+missing_reasoning")
pub fn min_palindrome_cuts(s : String) -> Int {
  let n = s.length()
  if n == 0 {
    return 0
  }
  let pal : Array[Array[Bool]] = Array::makei(n, _ => Array::make(n, false))
  for i = 0; i < n; i = i + 1 {
    pal[i][i] = true
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (Length-1 palindromes):
      #|pal[k][k] is true for all k in [0..i).
      #|MAINTENANCE:
      #|Mark pal[i][i] true.
      #|TERMINATION:
      #|At i = n, all single characters are palindromes.
    ),
  }
  for len = 2; len <= n; len = len + 1 {
    for i = 0; i + len <= n; i = i + 1 {
      let j = i + len - 1
      let ci = s.get_char(i)
      let cj = s.get_char(j)
      if ci is Some(c1) && cj is Some(c2) && c1 == c2 {
        if len == 2 || pal[i + 1][j - 1] {
          pal[i][j] = true
        }
      }
    } where {
      invariant: i >= 0 && i + len <= n,
      reasoning: (
        #|INVARIANT (Palindrome table):
        #|pal for substrings of length len at positions < i is computed.
        #|MAINTENANCE:
        #|Use inner palindrome pal[i+1][j-1] and boundary chars.
        #|TERMINATION:
        #|At i + len = n+1, all length-len substrings are evaluated.
      ),
    }
  } where {
    invariant: len >= 2 && len <= n + 1,
    reasoning: (
      #|INVARIANT (DP by length):
      #|All palindromes of length < len are already computed.
      #|MAINTENANCE:
      #|Compute palindromes of length len using shorter ones.
      #|TERMINATION:
      #|At len = n+1, pal table is complete.
    ),
  }
  let dp = Array::make(n, INF)
  for i = 0; i < n; i = i + 1 {
    for j = 0; j <= i; j = j + 1 {
      if pal[j][i] {
        if j == 0 {
          dp[i] = 0
        } else if dp[j - 1] + 1 < dp[i] {
          dp[i] = dp[j - 1] + 1
        }
      }
    } where {
      invariant: j >= 0 && j <= i + 1,
      reasoning: (
        #|INVARIANT (Cut scan):
        #|dp[i] is the minimum cuts using palindromes starting at j' < j.
        #|MAINTENANCE:
        #|Update dp[i] when s[j..i] is a palindrome.
        #|TERMINATION:
        #|At j = i+1, dp[i] is minimal.
      ),
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (Prefix cuts):
      #|dp[0..i) holds minimum cuts for prefixes ending before i.
      #|MAINTENANCE:
      #|Compute dp[i] using palindromic suffixes.
      #|TERMINATION:
      #|At i = n, dp[n-1] is the answer.
    ),
  }
  dp[n - 1]
}
