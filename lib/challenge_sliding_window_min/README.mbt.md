# Challenge: Sliding Window Minimum

Maintain the minimum of each fixed-size window using a monotonic deque.

## What you learn

- Keeping indices in increasing order
- Maintaining increasing values to keep the minimum at the front
- Removing expired indices as the window moves

## Core Idea

Use a deque of indices with increasing values. The front always holds the
minimum for the current window. When the window slides, drop indices that fall
out of range and remove larger values from the back before pushing the new one.

## Pseudocode sketch

```mbt nocheck
for i in 0..n-1:
  drop indices < i-k+1
  drop larger values from the back
  push i
  answer is arr[deque.front]
```

## Example

```mbt check
///|
test "sliding window min basic" {
  let arr : Array[Int] = [4, 2, 12, 3, 5, 1]
  let mins = @challenge_sliding_window_min.sliding_window_min(arr[:], 3)
  inspect(mins, content="[2, 2, 3, 1]")
}
```

## Another Example

```mbt check
///|
test "sliding window min classic" {
  let arr : Array[Int] = [1, 3, -1, -3, 5, 3, 6, 7]
  let mins = @challenge_sliding_window_min.sliding_window_min(arr[:], 3)
  inspect(mins, content="[-1, -3, -3, -3, 3, 3]")
}
```

## Notes

- Time complexity: O(n)
- Space complexity: O(k)
