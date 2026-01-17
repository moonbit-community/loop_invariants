# Sliding Window (Beginner‑Friendly Guide)

Sliding window is a simple but powerful idea for **contiguous subarrays**.
Instead of recomputing from scratch, you update the window as it moves.

There are two main styles:

1. **Fixed size** (window size = k)
2. **Variable size** (window expands/shrinks to satisfy a condition)

---

## 1. Fixed‑size window

Example: maximum sum of any 3 consecutive elements.

Array:

```
[1, 4, 2, 10, 2, 3, 1, 0, 20]
k = 3
```

Window sums:

```
[1, 4, 2]  sum = 7
   [4, 2, 10] sum = 16
      [2, 10, 2] sum = 14
         [10, 2, 3] sum = 15
            [2, 3, 1] sum = 6
               [3, 1, 0] sum = 4
                  [1, 0, 20] sum = 21  <- max
```

Update rule:

```
new_sum = old_sum - leaving + entering
```

---

## 2. Variable‑size window

Example: shortest subarray with sum ≥ 7.

Array:

```
[2, 3, 1, 2, 4, 3]
```

Walkthrough:

```
expand right until sum >= 7:
[2,3,1,2] sum=8  length=4

shrink from left:
[3,1,2] sum=6 (<7) stop shrinking

expand right:
[3,1,2,4] sum=10 length=4
[1,2,4] sum=7 length=3

shrink more:
[2,4] sum=6 (<7)

expand:
[2,4,3] sum=9 length=3
[4,3] sum=7 length=2  <- best
```

Answer = 2.

---

## 3. Sliding window maximum (deque trick)

Example: max in each window of size 3.

Array:

```
[1, 3, -1, -3, 5, 3, 6, 7]
```

We keep a deque of indices in **decreasing value order**.

```
Window      Deque(values)     Max
[1,3,-1]    [3,-1]            3
[3,-1,-3]   [3,-1,-3]         3
[-1,-3,5]   [5]               5
[-3,5,3]    [5,3]             5
[5,3,6]     [6]               6
[3,6,7]     [7]               7
```

Deque front is always the maximum.

---

## 4. Two‑pointer template

```mbt nocheck
left = 0
for right in 0..n-1:
  add(arr[right])

  while window invalid:
    remove(arr[left])
    left++

  update answer with [left, right]
```

Each element enters and leaves at most once, so total work is O(n).

---

## 5. Common beginner problems

### A. Max sum of size k
```
[2, 1, 5, 1, 3, 2], k=3 -> max sum = 9 ([5,1,3])
```

### B. Longest substring without repeating characters
```
"abcabcbb" -> 3 ("abc")
```

### C. Minimum window substring
```
"ADOBECODEBANC", pattern "ABC" -> "BANC"
```

---

## 6. Why O(n)?

Every index:

- enters the window once,
- leaves the window once.

So even if you have nested `while` loops, the total work is linear.

---

## 7. When to use sliding window

Use sliding window when:

- the data is **contiguous**,
- you can update the answer when the window shifts,
- you want O(n) instead of O(n^2).

---

## 8. Summary

Sliding window is one of the most useful tricks in algorithm practice:

- fixed window: moving sum / average / max,
- variable window: shortest/longest subarray satisfying a condition,
- deque trick: sliding window max/min.

Once you recognize the pattern, many problems become linear‑time.
