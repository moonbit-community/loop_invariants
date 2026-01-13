# Algorithmic Techniques

## Overview

A collection of fundamental algorithmic techniques that form the building blocks
for solving complex problems. These techniques are patterns that appear across
many different problem types.

- **Two Pointers**: O(n) for sorted/sequential data
- **Sliding Window**: O(n) for contiguous subarrays
- **Monotonic Stack/Queue**: O(n) for next greater/smaller
- **Binary Search on Answer**: O(n log M) for optimization

## Core Idea

- Recognize a **structure or monotonicity** that restricts how state changes.
- Use **invariants** (window validity, monotonic stacks, sorted order) to avoid
  rework and keep updates O(1).
- Turn the problem into a **template**: pointer moves, stack pops, or feasibility checks.

## The Key Insight

```
Most algorithmic problems fall into a few technique categories.
Recognizing the pattern leads directly to the solution!

Given problem → Identify technique → Apply template → Solve

Examples:
  "Find pair with sum = k"     → Two pointers (sorted) or Hash
  "Max sum subarray of size k" → Sliding window
  "Next greater element"       → Monotonic stack
  "Minimum time to complete"   → Binary search on answer
```

## Two Pointers

```
Use two pointers that move based on a condition.
Works when the search space can be pruned by pointer movement.

Pattern 1: Start from both ends (sorted array)
  left = 0, right = n-1
  while left < right:
    if condition: left++
    else: right--

Pattern 2: Slow and fast pointer
  slow = 0, fast = 0
  while fast < n:
    process and move fast
    move slow when needed

Example: Two Sum in sorted array
  [1, 2, 4, 7, 11, 15], target = 9
   ↑              ↑
   L              R    sum = 16 > 9, move R
   ↑         ↑
   L         R         sum = 12 > 9, move R
   ↑    ↑
   L    R              sum = 8 < 9, move L
      ↑ ↑
      L R              sum = 6 < 9, move L
        ↑↑
        LR             sum = 11 > 9, done? No!
        Actually: L=2, R=3 gives 4+7=11 still too big
  Hmm, let me redo:
  target = 9: 2 + 7 = 9 ✓ (indices 1 and 3)
```

## Sliding Window

```
Maintain a window that slides through the array.
Track window state efficiently during movement.

Fixed-size window:
  for i in 0..n-k+1:
    process window [i, i+k)
    add element i+k, remove element i

Variable-size window:
  left = 0
  for right in 0..n:
    expand: add arr[right] to window
    while window invalid:
      shrink: remove arr[left], left++
    update answer

Example: Max sum of subarray of size 3
  [2, 1, 5, 1, 3, 2]
   └──┘        window sum = 8
      └──┘     window sum = 7 (8 - 2 + 1)
         └──┘  window sum = 9 ← maximum
            └──┘ window sum = 6
```

## Monotonic Stack

```
Stack that maintains monotonic order (increasing or decreasing).
Elements are pushed/popped to maintain the invariant.

Find next greater element for each position:
  Stack stores indices of elements waiting for their "next greater"

Process: [4, 5, 2, 25]
  i=0: stack=[], push 0        stack=[0]
  i=1: 5 > arr[0]=4, pop, result[0]=5, push 1   stack=[1]
  i=2: 2 < arr[1]=5, push 2    stack=[1,2]
  i=3: 25 > arr[2]=2, pop, result[2]=25
       25 > arr[1]=5, pop, result[1]=25
       push 3                  stack=[3]
  end: remaining have no next greater, result[3]=-1

Result: [5, 25, 25, -1]
```

## Monotonic Queue

```
Deque that maintains monotonic order.
Supports efficient min/max queries for sliding windows.

Max in sliding window of size 3:
  [1, 3, -1, -3, 5, 3, 6, 7]

Deque stores indices, values are decreasing:
  i=0: deque=[0]                    (1)
  i=1: 3>1, pop 0, push 1           (3)
  i=2: -1<3, push 2                 (3,-1)  window max=3
  i=3: -3<-1, push 3, remove 0      (3,-1,-3) → (3,-1,-3) max=3
       but index 0 is out, remove it first
       Actually: deque=[1,2,3] → max=arr[1]=3
  i=4: 5>all, clear, push 4         (5)     max=5
  ...

Key: Front of deque is always the maximum in current window.
```

## Binary Search on Answer

```
When the answer has monotonic property (feasible/infeasible threshold),
binary search to find the boundary.

Pattern:
  lo, hi = answer_bounds
  while lo < hi:
    mid = (lo + hi) / 2
    if is_feasible(mid):
      hi = mid      // or lo = mid + 1 for max
    else:
      lo = mid + 1  // or hi = mid - 1 for max

Example: Minimum time to complete tasks
  Tasks: [3, 1, 2], Workers: 2

  Can complete in time T?
    Greedily assign tasks, check if 2 workers enough

  Binary search on T:
    T=1: [3] can't fit → infeasible
    T=2: [3] can't fit → infeasible
    T=3: [3], [1,2] → feasible! ✓
    T=4: also feasible

  Answer: T = 3
```

## Mo's Algorithm

```
Process offline range queries in O((n+q)√n) time.
Order queries by (block of left, right) to minimize pointer movement.

Queries on [l, r]:
  1. Sort queries by (l/√n, r)
  2. Maintain current answer for [cur_l, cur_r]
  3. For each query, move cur_l and cur_r

Movement analysis:
  - Right pointer moves O(n) per block, O(n√n) total
  - Left pointer moves O(√n) per query, O(q√n) total
  - Total: O((n+q)√n)

Works for: distinct count, frequency queries, XOR queries
```

## Meet in the Middle

```
Split problem in half, solve each half, combine results.
Reduces O(2^n) to O(2^(n/2)).

Example: Subset sum
  Array: [1, 2, 3, 4, 5, 6] (n=6), target = 10

  Split: [1,2,3] and [4,5,6]
  Left sums:  {0,1,2,3,3,4,5,6}
  Right sums: {0,4,5,6,9,10,11,15}

  For each left sum s, check if (target-s) in right sums.
  s=0: need 10 ✓ (in right)
  s=1: need 9 ✓
  s=2: need 8 ✗
  ...

  O(2^3) + O(2^3) instead of O(2^6)
```

## Algorithm Walkthrough: Sliding Window

```
Find minimum length subarray with sum >= target

Array: [2, 3, 1, 2, 4, 3], target = 7

left=0, right=0, sum=0, min_len=∞

right=0: sum=2 < 7
right=1: sum=5 < 7
right=2: sum=6 < 7
right=3: sum=8 >= 7
  → shrink: left=0, sum=8, len=4 → min_len=4
  → left++, sum=6 < 7, stop shrinking
right=4: sum=10 >= 7
  → shrink: len=4, left=1, sum=7 >= 7, len=3 → min_len=3
  → left++, sum=4 < 7, stop
right=5: sum=7 >= 7
  → shrink: len=3, left=2, sum=4 < 7, stop

Answer: min_len = 2 (subarray [4,3])
Wait, let me recheck...
  [4,3] at indices 4-5: sum=7, len=2 ✓
```

## Common Applications

### 1. Two Pointers
```
- Two sum / Three sum
- Container with most water
- Trapping rain water
- Remove duplicates from sorted array
- Merge sorted arrays
```

### 2. Sliding Window
```
- Maximum/minimum in window
- Longest substring without repeating characters
- Minimum window substring
- Subarray with sum = k
```

### 3. Monotonic Stack/Queue
```
- Next greater/smaller element
- Largest rectangle in histogram
- Stock span problem
- Sliding window maximum
```

### 4. Binary Search on Answer
```
- Minimum time to complete
- Maximum minimum distance
- Allocate minimum pages
- Capacity to ship packages
```

## Complexity Summary

| Technique | Time | Space | When to Use |
|-----------|------|-------|-------------|
| Two Pointers | O(n) | O(1) | Sorted data, pair/triplet finding |
| Sliding Window | O(n) | O(k) | Contiguous subarray problems |
| Monotonic Stack | O(n) | O(n) | Next greater/smaller queries |
| Monotonic Queue | O(n) | O(k) | Sliding window min/max |
| Binary Search Answer | O(n log M) | O(1) | Optimization with monotonic check |
| Mo's Algorithm | O((n+q)√n) | O(n) | Offline range queries |
| Meet in Middle | O(2^(n/2)) | O(2^(n/2)) | Exponential with small n |

## Implementation Notes

- For two pointers: ensure the invariant that justifies pointer movement
- For sliding window: track add/remove operations separately
- For monotonic stack: decide increasing vs decreasing based on query type
- For binary search: carefully handle boundary (lo < hi vs lo <= hi)
- For Mo's: handle add/remove in both directions for correctness
