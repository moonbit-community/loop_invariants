# Challenge: Meet-in-the-Middle

Split a set into two halves to reduce exponential search from O(2^n) to
O(2^(n/2)). Used here for subset sum.

## What you learn

- Enumerating subset sums for each half
- Sorting one half and binary searching for the best complement
- Combining results safely within a limit

## Core Idea

Split the array into two halves. Enumerate all subset sums for each half.
Sort one side, then for each sum in the other side, binary search the best
complement that keeps the total within the limit.

## Pseudocode sketch

```mbt nocheck
left_sums = all_subset_sums(left)
right_sums = all_subset_sums(right)
sort(right_sums)
for s in left_sums:
  best = max(best, s + best_leq(right_sums, limit - s))
```

## Example

```mbt check
///|
test "meet in middle basic" {
  let nums : Array[Int] = [3, 34, 4, 12, 5, 2]
  let best = @challenge_meet_in_middle.best_subset_sum_leq(nums[:], 9)
  inspect(best, content="9")
}
```

## Another Example

```mbt check
///|
test "meet in middle small limit" {
  let nums : Array[Int] = [8, 1, 2, 7]
  let best = @challenge_meet_in_middle.best_subset_sum_leq(nums[:], 10)
  inspect(best, content="10")
}
```

## Notes

- Time complexity: O(2^(n/2) log 2^(n/2))
- Useful when n is around 40
