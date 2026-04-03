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
  let _ = for i = 0 {
    if i >= n {
      break ()
    }
    let (j, k) = for j = i + 1, k = i; j < n && s[k] <= s[j]; {
      if s[k] < s[j] {
        continue j + 1, i
      } else {
        continue j + 1, k + 1
      }
    } nobreak {
      (j, k)
    }
    let period = j - k
    let next_i = for curr_i = i; curr_i <= k; {
      factors.push(slice_string(s, curr_i, curr_i + period))
      continue curr_i + period
    } nobreak {
      curr_i
    }
    continue next_i
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
