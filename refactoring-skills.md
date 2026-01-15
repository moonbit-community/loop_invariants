## 2026-01-11: Index Loops For Invariants
- Problem: `for .. in` loops cannot carry `where` invariants, triggering warnings and parse errors when annotated.
- Change: Convert `for .. in` loops to indexed `for i = ...; i < ...; i = i + 1` loops and attach invariants plus reasoning.
- Result: Loop-spec warnings removed while preserving algorithm intent.
- Example:
// Before
for i in 0..<n {
  sum = sum + arr[i]
}

// After
for i = 0; i < n; i = i + 1 {
  sum = sum + arr[i]
} where {
  invariant: i >= 0 && i <= n,
  reasoning: (
    #|sum equals the prefix sum of arr[0..i).
  ),
}

## 2026-01-11: Block Prefix/Suffix Invariants
- Problem: Nested loops building disjoint sparse tables lacked clear loop specs.
- Change: Add invariants that describe block progression and prefix/suffix accumulation.
- Result: Build steps are checkable and warnings removed.
- Example:
// Before
for i = mid - 1; i >= block_start; i = i - 1 {
  row[i] = arr[i] + row[i + 1]
}

// After
for i = mid - 1; i >= block_start; i = i - 1 {
  row[i] = arr[i] + row[i + 1]
} where {
  invariant: i >= block_start - 1 && i < mid,
  reasoning: (
    #|row[i+1..mid] already holds suffix sums to mid.
  ),
}

## 2026-01-15: Pattern Match Deque Peeks
- Problem: Sliding-window deque maintenance used `is_empty()` plus `unwrap()` calls.
- Change: Use `front()`/`back()` with `is Some(...)` in the loop condition and break when the peek is in range.
- Result: Loops are shorter and avoid unwraps while preserving behavior.
- Example:
// Before
while not(dq.is_empty()) && dq.front().unwrap() <= i - k {
  let _ = dq.pop_front()
}

// After
while dq.front() is Some(front) {
  if front <= i - k {
    let _ = dq.pop_front()
  } else {
    break
  }
}

## 2026-01-16: Arrow Lambda for Penalty Test
- Problem: A simple test helper used a verbose `fn` block for the penalty lambda.
- Change: Use an arrow function with an `if` expression.
- Result: Shorter inline helper that matches other lambda usage.
- Example:
// Before
let compute = fn(lambda : Int64) -> (Int64, Int) {
  if lambda < 0L {
    (100L, 5)
  } else if lambda < 10L {
    (50L, 3)
  } else {
    (20L, 1)
  }
}

// After
let compute = lambda =>
  if lambda < 0L {
    (100L, 5)
  } else if lambda < 10L {
    (50L, 3)
  } else {
    (20L, 1)
  }

## 2026-01-17: Deque Peek Without Unwrap in Sliding Window
- Problem: Sliding-window maintenance used `is_empty()` plus `unwrap()` calls for peeks.
- Change: Match on `front()` and `back()` inside the loop and break when in range.
- Result: Removes unwraps while keeping deque logic and invariants intact.
- Example:
// Before
while not(deque.is_empty()) && deque.front().unwrap() <= i - k {
  let _ = deque.pop_front()
}

// After
while deque.front() is Some(front) {
  if front <= i - k {
    let _ = deque.pop_front()
  } else {
    break
  }
}
