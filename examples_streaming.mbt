// ============================================================================
// Example A: Single-transaction Stock Profit
// ============================================================================

///|
/// Minimum of prices[0..end). end is expected >= 1.
fn min_prefix(prices : ArrayView[Int], end : Int) -> Int {
  guard end > 0 else { return 0 }
  if end == 1 {
    prices[0]
  } else {
    let prev = min_prefix(prices, end - 1)
    let last = prices[end - 1]
    if last < prev {
      last
    } else {
      prev
    }
  }
}

///|
/// Max profit from one buy/sell within prices[0..end).
fn max_profit_prefix(prices : ArrayView[Int], end : Int) -> Int {
  if end <= 1 {
    0
  } else {
    let prev = max_profit_prefix(prices, end - 1)
    let min_prev = min_prefix(prices, end - 1)
    let candidate = prices[end - 1] - min_prev
    if candidate > prev {
      candidate
    } else {
      prev
    }
  }
}

///|
/// Compute maximum profit from a single buy/sell.
#warnings("+missing_invariant+missing_reasoning")
fn max_profit_single(prices : ArrayView[Int]) -> Int {
  guard prices.length() > 0 else { return 0 }
  for i = 1, min_price = prices[0], best = 0 {
    if i >= prices.length() {
      break best
    } else {
      let price = prices[i]
      let profit = price - min_price
      let new_best = if profit > best { profit } else { best }
      let new_min = if price < min_price { price } else { min_price }
      continue i + 1, new_min, new_best
    }
  } where {
    invariant: 1 <= i && i <= prices.length(),
    reasoning: (
      #|INVARIANT (progress):
      #|i counts processed prices, so 1 <= i <= prices.length().
      #|MAINTENANCE:
      #|Each step consumes prices[i] and increments i by 1.
      #|TERMINATION:
      #|At i = prices.length(), all prices are processed.
    ),
    invariant: min_price == min_prefix(prices, i),
    reasoning: (
      #|INVARIANT (min prefix):
      #|min_price equals the minimum of prices[0..i).
      #|MAINTENANCE:
      #|Update min_price only when prices[i] is smaller.
      #|TERMINATION:
      #|At the end, min_price reflects the global minimum.
    ),
    invariant: best == max_profit_prefix(prices, i),
    reasoning: (
      #|INVARIANT (best profit):
      #|best is the maximum profit achievable using only prices[0..i).
      #|MAINTENANCE:
      #|Compare selling at prices[i - 1] vs. the min prefix, then keep the max.
      #|TERMINATION:
      #|At i = prices.length(), best is the optimal single-transaction profit.
    ),
  }
}

///|
test "max_profit_single" {
  assert_eq(max_profit_single([7, 1, 5, 3, 6, 4][:]), 5) // buy 1, sell 6
  assert_eq(max_profit_single([7, 6, 4, 3, 1][:]), 0) // no profit
  assert_eq(max_profit_single([1][:]), 0)
}

// ============================================================================
// Example B: Balanced Parentheses (prefix safety + exact balance)
// ============================================================================

///|
/// Count balance of '(' minus ')' in chars[0..end).
fn balance_prefix(chars : ArrayView[Char], end : Int) -> Int {
  if end <= 0 {
    0
  } else {
    let prev = balance_prefix(chars, end - 1)
    let last = chars[end - 1]
    if last == '(' {
      prev + 1
    } else if last == ')' {
      prev - 1
    } else {
      prev
    }
  }
}

///|
/// Check if parentheses are balanced; non-paren chars are ignored.
#warnings("+missing_invariant+missing_reasoning")
fn is_balanced_parens(chars : ArrayView[Char]) -> Bool {
  for i = 0, balance = 0 {
    if i >= chars.length() {
      break balance == 0
    } else {
      let c = chars[i]
      let next = if c == '(' {
        balance + 1
      } else if c == ')' {
        balance - 1
      } else {
        balance
      }
      if next < 0 {
        break false
      } else {
        continue i + 1, next
      }
    }
  } where {
    invariant: 0 <= i && i <= chars.length(),
    reasoning: (
      #|INVARIANT (progress):
      #|i is the length of the processed prefix, bounded by chars.length().
      #|MAINTENANCE:
      #|Each step consumes one character and increments i by 1.
      #|TERMINATION:
      #|At i = chars.length(), the entire string is processed.
    ),
    invariant: balance == balance_prefix(chars, i),
    reasoning: (
      #|INVARIANT (prefix balance):
      #|balance equals the net '(' minus ')' in chars[0..i).
      #|MAINTENANCE:
      #|Update balance by +1/-1 for parens, leaving it unchanged otherwise.
      #|TERMINATION:
      #|At the end, balance reflects the full-string net balance.
    ),
    invariant: balance >= 0,
    reasoning: (
      #|INVARIANT (non-negative prefix):
      #|balance is never negative for processed prefixes.
      #|MAINTENANCE:
      #|If next would go negative, we stop and return false.
      #|TERMINATION:
      #|If the loop finishes, all prefixes are non-negative.
    ),
  }
}

///|
test "is_balanced_parens" {
  assert_true(is_balanced_parens(['(', ')'][:]))
  assert_true(is_balanced_parens(['(', '(', ')', ')'][:]))
  assert_true(not(is_balanced_parens(['(', ')', ')'][:])))
  assert_true(not(is_balanced_parens(['(', '('][:])))
  let empty : Array[Char] = []
  assert_true(is_balanced_parens(empty[:]))
}
