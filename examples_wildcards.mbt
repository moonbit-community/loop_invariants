// ============================================================================
// Example E: Parentheses with Wildcards ("*" can be "(", ")", or empty)
// ============================================================================

///|
fn clamp_nonneg(x : Int) -> Int {
  if x < 0 {
    0
  } else {
    x
  }
}

///|
/// Unclamped min/max balance for chars[0..end).
/// "(" adds 1, ")" subtracts 1, "*" can do both.
fn range_prefix(chars : ArrayView[Char], end : Int) -> (Int, Int) {
  if end <= 0 {
    (0, 0)
  } else {
    let (lo, hi) = range_prefix(chars, end - 1)
    let c = chars[end - 1]
    if c == '(' {
      (lo + 1, hi + 1)
    } else if c == ')' {
      (lo - 1, hi - 1)
    } else if c == '*' {
      (lo - 1, hi + 1)
    } else {
      (lo, hi)
    }
  }
}

///|
/// Check if there exists an assignment of '*' that makes the string balanced.
#warnings("+missing_invariant+missing_reasoning")
fn is_balanced_parens_star(chars : ArrayView[Char]) -> Bool {
  for i = 0, low = 0, high = 0 {
    if i >= chars.length() {
      break low == 0
    } else {
      let c = chars[i]
      let next_low = if c == '(' {
        low + 1
      } else if c == ')' {
        low - 1
      } else if c == '*' {
        low - 1
      } else {
        low
      }
      let next_high = if c == '(' {
        high + 1
      } else if c == ')' {
        high - 1
      } else if c == '*' {
        high + 1
      } else {
        high
      }
      if next_high < 0 {
        break false
      } else {
        let clamped_low = clamp_nonneg(next_low)
        continue i + 1, clamped_low, next_high
      }
    }
  } where {
    invariant: 0 <= i && i <= chars.length(),
    reasoning: (
      #|INVARIANT (progress):
      #|i is the length of the processed prefix, within [0..chars.length()].
      #|MAINTENANCE:
      #|Each step consumes one character and increments i by 1.
      #|TERMINATION:
      #|At i = chars.length(), all characters are processed.
    ),
    invariant: high == range_prefix(chars, i).1,
    reasoning: (
      #|INVARIANT (max balance):
      #|high equals the maximum possible balance after i characters.
      #|MAINTENANCE:
      #|Update high by +1/-1 for '(' or ')', or +1 for '*'.
      #|TERMINATION:
      #|At the end, high bounds the maximum feasible balance.
    ),
    invariant: low == clamp_nonneg(range_prefix(chars, i).0),
    reasoning: (
      #|INVARIANT (min balance):
      #|low equals the minimum feasible balance after i characters, clamped at 0.
      #|MAINTENANCE:
      #|Update low by -1/+1 for ')' or '(', and widen for '*', then clamp.
      #|TERMINATION:
      #|At the end, low bounds the minimum feasible balance.
    ),
    invariant: low <= high,
    reasoning: (
      #|INVARIANT (interval):
      #|Possible balances form a contiguous interval [low, high].
      #|MAINTENANCE:
      #|Each update preserves contiguity; if high < 0 we stop early.
      #|TERMINATION:
      #|At completion, low <= high indicates a feasible balance range.
    ),
  }
}

///|
test "is_balanced_parens_star" {
  let empty : Array[Char] = []
  assert_true(is_balanced_parens_star(empty[:]))
  assert_true(is_balanced_parens_star(['(', ')'][:]))
  assert_true(is_balanced_parens_star(['(', '*', ')'][:]))
  assert_true(is_balanced_parens_star(['(', '*', ')', ')'][:])) // * = '('
  assert_true(is_balanced_parens_star(['(', '*', '(', ')'][:])) // * = ')'
  assert_true(is_balanced_parens_star(['*'][:])) // * = empty
  assert_true(not(is_balanced_parens_star([')', '*', '('][:])))
  assert_true(not(is_balanced_parens_star(['(', ')', ')', '*'][:])))
  assert_true(not(is_balanced_parens_star(['(', '(', '*'][:])))
}
