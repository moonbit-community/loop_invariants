# Challenge: Sqrt Decomposition (Range Sum)

Block decomposition for fast range sums with point updates.

## Example

```mbt check
///|
test "sqrt decomposition example" {
  let arr : Array[Int] = [1, 2, 3, 4, 5, 6]
  let sd = @challenge_sqrt_decomposition_sum.build_sqrt_decomp(arr[:])
  inspect(@challenge_sqrt_decomposition_sum.range_sum(sd, 2, 6), content="18")
}
```
