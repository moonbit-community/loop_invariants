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

## 2026-01-16: Prefer for-in for simple copies
- Problem: Trivial index loops with invariants were noisy for straightforward copies.
- Change: Use `for x in xs` (or `for i, x in xs`) and drop invariants for simple scans.
- Result: Cleaner loops while keeping invariants for complex control flow.
- Example:
// Before
for i = 0; i < n; i = i + 1 {
  out.push(values[i])
} where {
  invariant: i >= 0 && i <= n,
  reasoning: (
    #|out contains values[0..i).
  ),
}

// After
for val in values {
  out.push(val)
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

## 2026-01-18: Fold for Batch Updates in Persistent Trees
- Problem: Batch update loops used functional `for` with invariants or mutable accumulators.
- Change: Use `fold` over updates to apply persistent updates in a pure style.
- Result: Simpler code, no invariants needed for trivial iteration.
- Example:
// Before
for i = 0, tree = root {
  if i >= updates.length() {
    break tree
  } else {
    let (l, r, delta) = updates[i]
    continue i + 1, range_add(tree, 0, n, l, r, delta)
  }
}

// After
updates.fold(
  init=root,
  (tree, update) => {
    let (l, r, delta) = update
    range_add(tree, 0, n, l, r, delta)
  },
)

## 2026-01-18: Prefer While for Pointer Scans
- Problem: Pointer-driven scans used nested functional `for` loops with invariants, obscuring the algorithm flow.
- Change: Use `while` loops for the scan and emission phases when loop indices mutate together.
- Result: Same O(n) behavior with less loop-spec noise.
- Example:
// Before
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
}

// After
while j < n && s[k] <= s[j] {
  if s[k] < s[j] {
    k = i
  } else {
    k = k + 1
  }
  j = j + 1
}

## 2026-01-19: Prefer ArrayView for Read-Only Inputs
- Problem: Helpers took `Array[T]` even when only reading, encouraging copies at call sites.
- Change: Accept `ArrayView[T]` (or pattern match with `[..]`) to keep refactors allocation-free.
- Result: Less copying and clearer intent, especially for library utilities.
- Example:
// Before
pub fn build(n : Int, edges : Array[(Int, Int, Int64)]) -> Graph { ... }

// After
pub fn build(n : Int, edges : ArrayView[(Int, Int, Int64)]) -> Graph { ... }

## 2026-01-19: Replace while + mut Front With loop
- Problem: BFS/queue scans used `mut front` with `while queue.get(front) is Some`.
- Change: Use `loop` with an explicit `front` state and `match` on `queue.get`.
- Result: Keeps the queue scan functional and matches the preferred loop style.
- Example:
// Before
let mut front = 0
while queue.get(front) is Some(u) {
  process(u)
  front = front + 1
}

// After
let _ = loop 0 {
  front => {
    match queue.get(front) {
      None => break ()
      Some(u) => {
        process(u)
        continue front + 1
      }
    }
  }
}

## 2026-01-20: Replace while + mut Chain Climb With loop
- Problem: HLD LCA and chain-count routines used `mut` variables and `while`.
- Change: Use a `loop` with a `(u, v, count)` state to perform chain jumps.
- Result: Same logic, fewer mutations, consistent with functional loop style.
- Example:
// Before
let mut a = u
let mut b = v
while head[a] != head[b] {
  if depth[head[a]] < depth[head[b]] { b = parent[head[b]] }
  else { a = parent[head[a]] }
}

// After
loop (u, v) {
  (a, b) => {
    if head[a] == head[b] { break a }
    if depth[head[a]] < depth[head[b]] {
      continue (a, parent[head[b]])
    } else {
      continue (parent[head[a]], b)
    }
  }
}

## 2026-01-21: Prefer for-in Over Index Loops on Edge Lists
- Problem: Edge scans used indexed loops plus invariants for simple traversal.
- Change: Use `for edge in edges` and destructure each tuple.
- Result: Shorter code with no loop-spec overhead for simple scans.
- Example:
// Before
for i = 0; i < edges.length(); i = i + 1 {
  let (u, v, w) = edges[i]
  add_edge(u, v, w)
} where { ... }

// After
for edge in edges {
  let (u, v, w) = edge
  add_edge(u, v, w)
}

## 2026-01-22: Prefer for-in Ranges for Simple DP Rows
- Problem: DP row loops used indexed `for i = ...` forms and loop specs even when
  the state was straightforward.
- Change: Use `for i in 1..=n` and `for j in 1..=m` range loops for row-by-row
  DP table fills when invariants are not needed.
- Result: Clearer iteration without changing complexity or behavior.
- Example:
// Before
for i = 1; i <= n; i = i + 1 {
  for j = 1; j <= m; j = j + 1 {
    update(i, j)
  } where { ... }
} where { ... }

// After
for i in 1..=n {
  for j in 1..=m {
    update(i, j)
  }
}
