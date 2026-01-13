# Challenge: Sqrt Decomposition (Range Sum)

Block decomposition for fast range sums with point updates.

## Core Idea

Split the array into blocks of size about √n. Store the sum of each block.
To answer a range sum:

1. Scan the left partial block.
2. Add full block sums in the middle.
3. Scan the right partial block.

Point updates change one element and update its block sum.

## Example

```mbt check
///|
test "sqrt decomposition example" {
  let arr : Array[Int] = [1, 2, 3, 4, 5, 6]
  let sd = @challenge_sqrt_decomposition_sum.build_sqrt_decomp(arr[:])
  inspect(@challenge_sqrt_decomposition_sum.range_sum(sd, 2, 6), content="18")
}
```

## Another Example

```mbt check
///|
test "sqrt decomposition update" {
  let arr : Array[Int] = [1, 2, 3, 4]
  let sd = @challenge_sqrt_decomposition_sum.build_sqrt_decomp(arr[:])
  @challenge_sqrt_decomposition_sum.update(sd, 1, 10)
  inspect(@challenge_sqrt_decomposition_sum.range_sum(sd, 0, 2), content="11")
}
```

## Notes

- Query time is O(√n).
- Update time is O(1).
