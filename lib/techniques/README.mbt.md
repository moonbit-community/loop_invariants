# Algorithmic Techniques (Beginner-Friendly, Example-Heavy)

This chapter is a practical "how to recognize the pattern" guide. It does not
expose a public API. Instead, it teaches the most common problem-solving
templates with small, concrete examples you can copy into your own solutions.

If you are new to algorithms, read this guide in order. Each section follows
the same flow:

1) A plain-English description of the technique.
2) A visual diagram or step-by-step walkthrough.
3) A small MoonBit example you can run with `mbt check`.
4) Common pitfalls and "when to use this".

All diagrams and code are ASCII only for clarity and portability.

## Quick pattern map

Use this as a fast "what should I try first?" checklist.

```
Signal in the problem                         -> Likely technique
------------------------------------------------------------------------
Sorted array + pair/triple finding             -> Two pointers
Contiguous subarray, update as it moves        -> Sliding window
Next greater/smaller, nearest boundary         -> Monotonic stack
Window max/min with many queries               -> Monotonic queue
Answer is "smallest X that works"              -> Binary search on answer
Many offline range queries                     -> Mo's algorithm
Subset problems with n around 30 to 40         -> Meet in the middle
```

## 1. Two pointers

### Intuition

Two pointers move across the array so that every element is touched only a
constant number of times. This is how you turn many O(n^2) scans into O(n).

There are two main styles:

1) **Both ends inward** (sorted arrays).
2) **Slow and fast** (same direction).

### Style A: Both ends inward (sorted two-sum)

Example: find two numbers that sum to 9 in a sorted list.

Array:

```
index: 0 1 2 3 4  5
value: 1 2 4 7 11 15
```

We start with `L` at the left and `R` at the right:

```
L -> 1, R -> 15, sum = 16 (too big, move R)
L -> 1, R -> 11, sum = 12 (too big, move R)
L -> 1, R -> 7,  sum = 8  (too small, move L)
L -> 2, R -> 7,  sum = 9  (found)
```

The key invariant:
- If the sum is too small, moving `L` right is the only way to increase it.
- If the sum is too big, moving `R` left is the only way to decrease it.

```mbt check
///|
fn two_sum_sorted(xs : ArrayView[Int], target : Int) -> (Int, Int)? {
  let n = xs.length()
  if n < 2 {
    return None
  }
  let mut left = 0
  let mut right = n - 1
  while left < right {
    let sum = xs[left] + xs[right]
    if sum == target {
      return Some((left, right))
    }
    if sum < target {
      left = left + 1
    } else {
      right = right - 1
    }
  }
  None
}

///|
test "two pointers: sorted two sum" {
  let xs = [1, 2, 4, 7, 11, 15]
  inspect(two_sum_sorted(xs, 9), content="Some((1, 3))")
}
```

### Style B: Slow and fast (same direction)

Think of `fast` as the scout and `slow` as the builder. `fast` moves every
step, `slow` moves only when a condition is met.

Common uses:

- Remove duplicates in-place in a sorted array.
- Longest subarray with a property.
- Partition arrays (e.g., all zeros to the end).

Visual idea:

```
slow marks the end of the "clean" prefix
fast scans the full array

[1, 1, 2, 2, 3, 3]
 s
 f

After scanning, slow trails behind fast and the prefix [0..slow] is clean.
```

## 2. Sliding window

### Intuition

A sliding window is just two pointers that always keep a contiguous segment.
You update the answer as the segment moves, rather than recomputing from
scratch each time.

There are two variants:

- Fixed-size window
- Variable-size window (expand and shrink)

### Fixed-size window example

Find the maximum sum of any 3 consecutive elements.

```
Array: [2, 1, 5, 1, 3, 2]
Window size k = 3

Start: [2, 1, 5] sum = 8
Slide: [1, 5, 1] sum = 7  (8 - 2 + 1)
Slide: [5, 1, 3] sum = 9  (7 - 1 + 3)  <-- best
Slide: [1, 3, 2] sum = 6
```

```mbt check
///|
fn max_sum_k(xs : ArrayView[Int], k : Int) -> Int? {
  let n = xs.length()
  if k <= 0 || k > n {
    return None
  }
  let mut sum = 0
  for i in 0..<k {
    sum = sum + xs[i]
  }
  let mut best = sum
  for i in k..<n {
    sum = sum - xs[i - k] + xs[i]
    if sum > best {
      best = sum
    }
  }
  Some(best)
}

///|
test "sliding window: max sum of size k" {
  let xs = [2, 1, 5, 1, 3, 2]
  inspect(max_sum_k(xs, 3), content="Some(9)")
}
```

### Variable-size window example

Find the shortest subarray with sum >= 7.

```
Array:  [2, 3, 1, 2, 4, 3]
Target: 7

Expand right:
[2,3,1,2] sum=8  len=4

Shrink left:
[3,1,2]   sum=6  (stop)

Expand:
[3,1,2,4] sum=10 len=4
Shrink:
[1,2,4]   sum=7  len=3
Shrink:
[2,4]     sum=6  (stop)

Expand:
[2,4,3]   sum=9  len=3
Shrink:
[4,3]     sum=7  len=2  <-- best
```

Key rule: each element enters the window once and leaves once, so total work
is O(n).

## 3. Monotonic stack

### Intuition

Maintain a stack that is always increasing or always decreasing. This lets you
find "next greater", "next smaller", or nearest boundary in O(n).

Example: next greater element.

```
Input:  [4, 5, 2, 25]
Output: [5, 25, 25, -1]

Process steps:
stack = []
4 -> push 0
5 -> pop 0, result[0] = 5, push 1
2 -> push 2
25 -> pop 2 (result[2]=25), pop 1 (result[1]=25), push 3
done -> result[3] stays -1
```

```mbt check
///|
fn next_greater(xs : ArrayView[Int]) -> Array[Int] {
  let n = xs.length()
  let result = Array::make(n, -1)
  let stack : Array[Int] = []
  for i in 0..<n {
    let x = xs[i]
    while stack.length() > 0 {
      let j = stack[stack.length() - 1]
      if xs[j] < x {
        ignore(stack.pop())
        result[j] = x
      } else {
        break
      }
    }
    stack.push(i)
  }
  result
}

///|
test "monotonic stack: next greater" {
  let xs = [4, 5, 2, 25]
  inspect(next_greater(xs), content="[5, 25, 25, -1]")
}
```

When to use:
- "Next greater/smaller element"
- "Largest rectangle in histogram"
- "Nearest boundary to left/right"

## 4. Monotonic queue (deque trick)

### Intuition

For sliding window max/min, you want:
- O(1) to add a new element,
- O(1) to remove the element that slides out,
- O(1) to query the max/min.

A deque of indices maintained in monotonic order gives exactly that.

Example: max in each window of size 3.

```
Array: [1, 3, -1, -3, 5, 3, 6, 7]
Deque stores indices with decreasing values:

window [1, 3, -1] -> deque values [3, -1] -> max 3
window [3, -1, -3] -> deque values [3, -1, -3] -> max 3
window [-1, -3, 5] -> deque values [5] -> max 5
window [-3, 5, 3] -> deque values [5, 3] -> max 5
window [5, 3, 6] -> deque values [6] -> max 6
window [3, 6, 7] -> deque values [7] -> max 7
```

The front of the deque is always the current maximum.

Pseudocode outline:

```mbt nocheck
for i in 0..<n {
  // 1) Pop from back while new element is larger
  // 2) Push new index
  // 3) Pop from front if it falls out of the window
  // 4) Front is the max
}
```

## 5. Binary search on answer

### Intuition

Sometimes you do not know the answer directly, but you can check whether a
candidate answer is feasible. If "feasible" is monotonic, you can binary search
over the answer.

Classic shape:

```
False False False True True True
                ^
          first True (the minimum answer)
```

### Example: minimum capacity to ship in D days

Problem:
- You have weights shipped in order.
- You need to finish in D days.
- Find the smallest ship capacity that works.

Feasibility check:
- Given capacity C, simulate loading until full, count days.
- If days <= D, capacity is feasible.

```mbt check
///|
fn can_ship(weights : ArrayView[Int], days : Int, cap : Int) -> Bool {
  if days <= 0 {
    return false
  }
  let mut used = 1
  let mut cur = 0
  for w in weights {
    if w > cap {
      return false
    }
    if cur + w <= cap {
      cur = cur + w
    } else {
      used = used + 1
      if used > days {
        return false
      }
      cur = w
    }
  }
  true
}

///|
fn max_and_sum(weights : ArrayView[Int]) -> (Int, Int) {
  let mut max_w = 0
  let mut sum = 0
  for w in weights {
    if w > max_w {
      max_w = w
    }
    sum = sum + w
  }
  (max_w, sum)
}

///|
fn min_capacity(weights : ArrayView[Int], days : Int) -> Int? {
  if weights.length() == 0 || days <= 0 {
    return None
  }
  let (lo, hi) = max_and_sum(weights)
  let mut low = lo
  let mut high = hi
  while low < high {
    let mid = low + (high - low) / 2
    if can_ship(weights, days, mid) {
      high = mid
    } else {
      low = mid + 1
    }
  }
  Some(low)
}

///|
test "binary search on answer: shipping" {
  let weights = [3, 2, 2, 4, 1, 4]
  inspect(min_capacity(weights, 3), content="Some(6)")
}
```

## 6. Mo's algorithm (offline queries)

### Intuition

You have many range queries over the same array. If you answer them in a smart
order, you can update the answer by only adding or removing a few elements each
time.

Split the array into blocks of size sqrt(n). Sort queries by:
1) block of left endpoint, then
2) right endpoint.

Example with block size 3:

```
Query list (l, r):
(0, 4) (2, 6) (3, 8) (1, 3) (5, 7)

Blocks: [0..2], [3..5], [6..8]

Sorted order by block(l), then r:
(0, 4) (1, 3) (2, 6) (3, 8) (5, 7)
```

As you move from one query to the next, the window shifts only a little.

Works well for:
- Distinct count in ranges
- Frequency queries
- XOR or sum over ranges with add/remove updates

## 7. Meet in the middle

### Intuition

If n is around 30 to 40, brute force 2^n is too big. Split into two halves:
2^(n/2) on each side is small enough.

Example: subset sum.

```
Array: [1, 2, 3, 4, 5, 6]
Split: [1, 2, 3] and [4, 5, 6]

Left sums:  0 1 2 3 3 4 5 6
Right sums: 0 4 5 6 9 10 11 15

Target 10 can be made by:
  0 + 10
  1 + 9
  4 + 6
```

```mbt check
///|
fn subset_sums(xs : ArrayView[Int]) -> Array[Int] {
  let n = xs.length()
  let sums : Array[Int] = []
  for mask in 0..<(1 << n) {
    let mut sum = 0
    for i in 0..<n {
      if ((mask >> i) & 1) == 1 {
        sum = sum + xs[i]
      }
    }
    sums.push(sum)
  }
  sums
}

///|
test "meet in the middle: subset sum" {
  let left = [1, 2, 3]
  let right = [4, 5, 6]
  let target = 10
  let left_sums = subset_sums(left)
  let right_sums = subset_sums(right)
  for s in left_sums {
    for t in right_sums {
      if s + t == target {
        inspect(true, content="true")
        return
      }
    }
  }
  fail("expected to find target sum")
}
```

## Common pitfalls

- Two pointers on unsorted data: the direction rule no longer holds.
- Sliding window on non-contiguous problems: window only applies to ranges.
- Monotonic stack with wrong monotonicity: pick increasing or decreasing based
  on "next greater" vs "next smaller".
- Binary search without monotonic feasibility: if feasibility is not monotonic,
  binary search will lie to you.
- Mo's algorithm used online: it is strictly offline.

## Summary table (with intuition)

```
Technique            Time (typical)     Why it works
-------------------------------------------------------------------
Two pointers         O(n)              Each pointer moves at most n
Sliding window       O(n)              Each element enters/leaves once
Monotonic stack      O(n)              Each index pushed/popped once
Monotonic queue      O(n)              Deque ops are amortized O(1)
Binary search answer O(n log M)        Feasible/infeasible boundary
Mo's algorithm       O((n+q)*sqrt(n))  Small window movement per query
Meet in the middle   O(2^(n/2))        Split exponential in half
```
