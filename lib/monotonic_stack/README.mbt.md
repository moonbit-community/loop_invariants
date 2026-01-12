# Monotonic Stack

## Overview

A **Monotonic Stack** maintains elements in sorted order (increasing or decreasing)
to efficiently answer "next greater/smaller element" queries in **O(n)** total time.

## The Problem

Given an array, for each element find the **next greater element** to its right.

```
Array:  [4, 5, 2, 10, 8]
Answer: [5, 10, 10, -1, -1]

For 4: next greater is 5
For 5: next greater is 10
For 2: next greater is 10
For 10: no greater element exists (-1)
For 8: no greater element exists (-1)
```

## How It Works

Maintain a stack of indices where values are **monotonically decreasing**:

```
Process array [4, 5, 2, 10, 8] left to right:

i=0, val=4:
  Stack: []
  Push 0
  Stack: [0]          (values: [4])

i=1, val=5:
  Stack: [0]          (values: [4])
  5 > 4? Pop 0, answer[0] = 5
  Stack: []
  Push 1
  Stack: [1]          (values: [5])

i=2, val=2:
  Stack: [1]          (values: [5])
  2 > 5? No
  Push 2
  Stack: [1, 2]       (values: [5, 2])

i=3, val=10:
  Stack: [1, 2]       (values: [5, 2])
  10 > 2? Pop 2, answer[2] = 10
  10 > 5? Pop 1, answer[1] = 10
  Stack: []
  Push 3
  Stack: [3]          (values: [10])

i=4, val=8:
  Stack: [3]          (values: [10])
  8 > 10? No
  Push 4
  Stack: [3, 4]       (values: [10, 8])

Remaining in stack have no next greater: answer[3] = answer[4] = -1

Final: [5, 10, 10, -1, -1]
```

## Why O(n)?

Each element is pushed **once** and popped **at most once**.

```
n pushes + n pops = O(n) total operations
```

## Visual: Stack States

```
Array: [3, 1, 4, 1, 5, 9, 2, 6]

Step  Value  Stack (indices)  Stack (values)  Action
────────────────────────────────────────────────────
0     3      [0]              [3]             push
1     1      [0,1]            [3,1]           push
2     4      [2]              [4]             pop 1,0; push
3     1      [2,3]            [4,1]           push
4     5      [4]              [5]             pop 3,2; push
5     9      [5]              [9]             pop 4; push
6     2      [5,6]            [9,2]           push
7     6      [5,7]            [9,6]           pop 6; push

Stack is always monotonically decreasing!
```

## Common Applications

### 1. Next Greater Element
```
Input:  [2, 1, 2, 4, 3]
Output: [4, 2, 4, -1, -1]
```

### 2. Previous Smaller Element
Use decreasing stack, scan left to right:
```
Input:  [3, 5, 2, 7, 6]
Output: [-1, 3, -1, 2, 2]
```

### 3. Largest Rectangle in Histogram

```
Heights: [2, 1, 5, 6, 2, 3]

      _
     | |
   _ | |
  | || |   _
_ | || | _| |
|_||_||_||_||_|
2  1  5  6  2  3

Largest rectangle = 10 (height 5, width 2)
```

### 4. Trapping Rain Water

```
Heights: [0, 1, 0, 2, 1, 0, 1, 3, 2, 1, 2, 1]

       |
   |   ||~|
_|~||_|||||||
 0 1 0 2 1 0 1 3 2 1 2 1

Water trapped = 6 units
```

### 5. Stock Span Problem

For each day, count consecutive days with price ≤ today:
```
Prices: [100, 80, 60, 70, 60, 75, 85]
Spans:  [1,   1,  1,  2,  1,  4,  6]
```

## Variations

| Variant | Stack Order | Finds |
|---------|-------------|-------|
| Next Greater | Decreasing | First larger to right |
| Next Smaller | Increasing | First smaller to right |
| Prev Greater | Decreasing | First larger to left |
| Prev Smaller | Increasing | First smaller to left |

## Complexity

| Operation | Time | Space |
|-----------|------|-------|
| Build answers | O(n) | O(n) |
| Per element | O(1) amortized | - |

## Implementation Pattern

```
Decreasing stack (for next greater):
  for i in 0..n:
    while stack not empty AND arr[stack.top()] < arr[i]:
      answer[stack.pop()] = arr[i]
    stack.push(i)

Increasing stack (for next smaller):
  for i in 0..n:
    while stack not empty AND arr[stack.top()] > arr[i]:
      answer[stack.pop()] = arr[i]
    stack.push(i)
```

## Key Insight

The stack maintains a "candidate" list:
- Elements still waiting for their answer
- Sorted by value (monotonic property)
- When a new element arrives, it "answers" all smaller/larger elements
