# Sliding Window Techniques

## Overview

**Sliding window** is a technique for processing contiguous subarrays efficiently.
Instead of recomputing from scratch, we update incrementally as the window slides.

- **Fixed window**: Window of constant size k
- **Variable window**: Window expands/shrinks based on constraints

## Fixed-Size Window

Find maximum sum of any k consecutive elements:

```
Array: [1, 4, 2, 10, 2, 3, 1, 0, 20], k = 3

Window slides:
[1, 4, 2]  10, 2, 3, 1, 0, 20   sum = 7
 1, [4, 2, 10] 2, 3, 1, 0, 20   sum = 16
 1,  4, [2, 10, 2] 3, 1, 0, 20  sum = 14
 1,  4,  2, [10, 2, 3] 1, 0, 20 sum = 15
 ...

Maximum = 23 at [1, 0, 20]

Update rule: new_sum = old_sum - leaving + entering
```

## Variable-Size Window

Find shortest subarray with sum ≥ target:

```
Array: [2, 3, 1, 2, 4, 3], target = 7

left=0, right expands until sum >= 7:
[2, 3, 1, 2] sum=8 >= 7, length=4

Shrink from left:
[3, 1, 2] sum=6 < 7, expand right

[3, 1, 2, 4] sum=10 >= 7, length=4
[1, 2, 4] sum=7 >= 7, length=3
[2, 4] sum=6 < 7, expand

[2, 4, 3] sum=9 >= 7, length=3
[4, 3] sum=7 >= 7, length=2  <- minimum!

Answer: 2
```

## Sliding Window Maximum (Deque)

Find maximum in each window of size k:

```
Array: [1, 3, -1, -3, 5, 3, 6, 7], k = 3

Use deque to maintain indices of potential maximums:

Window        Deque (indices)  Deque (values)  Max
─────────────────────────────────────────────────
[1, 3, -1]    [1, 2]           [3, -1]          3
[3, -1, -3]   [1, 2, 3]        [3, -1, -3]      3
[-1, -3, 5]   [4]              [5]              5
[-3, 5, 3]    [4, 5]           [5, 3]           5
[5, 3, 6]     [6]              [6]              6
[3, 6, 7]     [7]              [7]              7

Deque property: Values are monotonically decreasing
Front of deque = maximum in current window
```

## The Two-Pointer Pattern

```
left = 0
for right = 0 to n-1:
    add arr[right] to window

    while window is invalid:
        remove arr[left] from window
        left++

    update answer with current window [left, right]
```

## Common Applications

### 1. Maximum Sum Subarray of Size K
```
Array: [2, 1, 5, 1, 3, 2], k = 3
Answer: 9 (subarray [5, 1, 3])
```

### 2. Longest Substring Without Repeating Characters
```
String: "abcabcbb"
Answer: 3 ("abc")

Window: Track character counts
Shrink when: duplicate found
```

### 3. Minimum Window Substring
```
String: "ADOBECODEBANC", pattern: "ABC"
Answer: "BANC"

Window: Track character frequencies
Expand: until all pattern chars found
Shrink: while still valid
```

### 4. Subarrays with K Distinct Elements
```
Array: [1, 2, 1, 2, 3], k = 2
Subarrays: [1,2], [2,1], [1,2], [2,1,2], [1,2,1,2], [2,3]
Count: 7
```

### 5. Maximum of All Subarrays of Size K
```
Array: [1, 2, 3, 1, 4, 5, 2, 3, 6], k = 3
Output: [3, 3, 4, 5, 5, 5, 6]
```

## Complexity Analysis

| Problem Type | Time | Space |
|--------------|------|-------|
| Fixed window sum | O(n) | O(1) |
| Variable window | O(n) | O(1)* |
| Window max/min (deque) | O(n) | O(k) |
| Distinct elements | O(n) | O(k) |

*Plus space for any auxiliary data structures

## Why O(n)?

Each element is added to window **once** and removed **at most once**:

```
Total operations = n adds + n removes = O(n)

Even though there's a while loop inside the for loop,
the total iterations across ALL while loops is bounded by n.
```

## Sliding Window vs Other Approaches

| Approach | Time | When to Use |
|----------|------|-------------|
| Brute force | O(n²) or O(n*k) | Never for this problem type |
| Prefix sum | O(n) | Fixed-size sum queries |
| **Sliding window** | O(n) | Contiguous subarray constraints |
| Segment tree | O(n log n) | Arbitrary range queries |

## Key Patterns

### Fixed Window
```
1. Initialize window with first k elements
2. Slide: remove leftmost, add rightmost
3. Update answer at each position
```

### Variable Window (Shrinking)
```
1. Expand right pointer
2. While constraint violated: shrink left
3. Update answer with valid window
```

### Variable Window (Expanding)
```
1. While constraint satisfied: expand right, update answer
2. Shrink left pointer
3. Repeat
```

## Implementation Tips

- Use hash map to track element counts
- Use deque for min/max queries
- Track window state incrementally (sum, count, frequency)
- Be careful with window boundaries
