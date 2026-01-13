# Challenge: LIS Length

Patience sorting approach with binary search for longest increasing subsequence length.

## Core Idea

Maintain an array `tails` where `tails[k]` is the minimum possible tail value
of an increasing subsequence of length `k+1`. For each number:

1. Binary search the leftmost position in `tails` with value ≥ current.
2. Replace that position (or append if none).

The length of `tails` is the LIS length.

## Example

```mbt check
///|
test "lis example" {
  let nums : Array[Int] = [3, 1, 2, 1, 8, 5, 6]
  let len = @challenge_lis_nlogn.lis_length(nums[:])
  inspect(len, content="4")
}
```

## Another Example

```mbt check
///|
test "lis classic" {
  let nums : Array[Int] = [10, 9, 2, 5, 3, 7, 101, 18]
  let len = @challenge_lis_nlogn.lis_length(nums[:])
  inspect(len, content="4")
}
```

## Notes

- This computes the length only (not the actual subsequence).
- Time complexity is O(n log n).
