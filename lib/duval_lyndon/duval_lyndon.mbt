// ============================================================================
// DUVAL'S ALGORITHM - Lyndon Factorization
// ============================================================================
//
// Duval's algorithm factors a string into a sequence of Lyndon words such that
// the sequence is non-increasing in lexicographic order. The factorization is
// unique and can be found in linear time.
//
// KEY IDEA:
// - Scan with indices (i, j, k) to find the minimal rotation period.
// - Emit repeated factors of length (j - k) while i <= k.
//
// TIME COMPLEXITY: O(n)
// SPACE COMPLEXITY: O(n)

///|
fn slice_string(s : String, start : Int, end : Int) -> String {
  let sb = StringBuilder::new()
  for idx in start..<end {
    let ch = s[idx].to_int()
    sb.write_char(ch.unsafe_to_char())
  }
  sb.to_string()
}

///|
/// Compute Lyndon factorization using Duval's algorithm.
/// Returns factors as strings in non-increasing lexicographic order.
pub fn duval_factorization(s : String) -> Array[String] {
  let n = s.length()
  let factors : Array[String] = []
  let mut i = 0
  for {
    if i >= n {
      break
    }
    let mut j = i + 1
    let mut k = i
    for {
      if j < n && s[k] <= s[j] {
        if s[k] < s[j] {
          k = i
        } else {
          k = k + 1
        }
        j = j + 1
        continue
      }
      break
    } where {
      invariant: i >= 0 && i < n && i <= k && k < j && j <= n,
      reasoning: (
        #|INVARIANT (Duval scan):
        #|s[i..j) is the current candidate, and k tracks the comparison position
        #|within the prefix. The condition s[k] <= s[j] preserves lexicographic
        #|minimality for Lyndon word detection.
        #|MAINTENANCE:
        #|Advance j, resetting k to i on strict increase or moving k forward on
        #|equality, which matches the standard Duval comparison logic.
        #|TERMINATION:
        #|When j reaches n or s[k] > s[j], the Lyndon word length is (j - k).
      ),
    }
    let period = j - k
    for {
      if i <= k {
        factors.push(slice_string(s, i, i + period))
        i = i + period
        continue
      }
      break
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (emit factors):
        #|All positions before i have been emitted as Lyndon factors of length
        #|period, and each factor equals s[i..i+period) in the current block.
        #|MAINTENANCE:
        #|Emit one factor and advance i by period.
        #|TERMINATION:
        #|When i > k, the current Lyndon block is fully emitted.
      ),
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (outer factorization):
      #|factors concatenated equal s[0..i), and each is a Lyndon word.
      #|MAINTENANCE:
      #|Use Duval scan to find the next Lyndon word block and emit its factors.
      #|TERMINATION:
      #|At i = n, the entire string is factorized.
    ),
  }
  factors
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "duval banana" {
  let factors = duval_factorization("banana")
  inspect(factors, content="[\"b\", \"an\", \"an\", \"a\"]")
}

///|
test "duval ababab" {
  let factors = duval_factorization("ababab")
  inspect(factors, content="[\"ab\", \"ab\", \"ab\"]")
}
