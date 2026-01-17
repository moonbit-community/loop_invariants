# Challenge: Difference Array

A difference array lets you apply many range increments in O(1) per update and
reconstruct the final array in O(n).

## Problem statement

You are given:

- a base array `base[0..n-1]`
- a list of range updates `(l, r, delta)` (inclusive)

Apply all updates efficiently and return the updated array.

## Core idea

Instead of updating every element in `[l, r]`, mark only the boundaries:

```
diff[l] += delta
diff[r + 1] -= delta
```

Then take the prefix sum of `diff` to reconstruct all updates.

## Diagram: how it works

Base array:

```
index: 0 1 2 3 4
base : 1 2 3 4 5
```

Updates:

```
(1, 3, +2)
(0, 0, -1)
(2, 4, +1)
```

Difference marks:

```
diff after updates:
index: 0 1 2 3 4 5
 diff: -1 3 1 0 -2 0
```

Prefix sum of diff:

```
run : -1 2 3 3 1
```

Final array:

```
base + run = [0, 4, 6, 7, 6]
```

(After all three updates, the correct result is `[0, 4, 6, 7, 6]` because the
prefix sum reflects the cumulative effect across ranges.)

## Examples

### Example 1: overlapping updates

```mbt check
///|
test "difference array basic" {
  let base : Array[Int] = [1, 2, 3, 4, 5]
  let updates : Array[(Int, Int, Int)] = [(1, 3, 2), (0, 0, -1), (2, 4, 1)]
  let updated = @challenge_difference_array.apply_range_add(base[:], updates[:])
  inspect(updated, content="[0, 4, 6, 7, 6]")
}
```

### Example 2: disjoint ranges

```mbt check
///|
test "difference array disjoint ranges" {
  let base : Array[Int] = [0, 0, 0, 0]
  let updates : Array[(Int, Int, Int)] = [(0, 1, 3), (2, 3, 1)]
  let updated = @challenge_difference_array.apply_range_add(base[:], updates[:])
  inspect(updated, content="[3, 3, 1, 1]")
}
```

### Example 3: negative updates

```mbt check
///|
test "difference array negative" {
  let base : Array[Int] = [10, 10, 10]
  let updates : Array[(Int, Int, Int)] = [(0, 2, -3), (1, 1, -2)]
  let updated = @challenge_difference_array.apply_range_add(base[:], updates[:])
  inspect(updated, content="[7, 5, 7]")
}
```

### Example 4: single element updates

```mbt check
///|
test "difference array single points" {
  let base : Array[Int] = [5, 5, 5, 5]
  let updates : Array[(Int, Int, Int)] = [(2, 2, 4), (0, 0, -1)]
  let updated = @challenge_difference_array.apply_range_add(base[:], updates[:])
  inspect(updated, content="[4, 5, 9, 5]")
}
```

## Complexity

- Each update: O(1)
- Reconstruction: O(n)
- Total: O(n + q)

## Practical notes and pitfalls

- Ranges are **inclusive**.
- Skip invalid ranges (this implementation ignores them).
- `diff` is sized `n+1` so `r+1` is safe when `r == n-1`.

## When to use it

Use a difference array when you have many range increments and only need the
final array, not intermediate values after each update.
