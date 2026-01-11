# Challenge: Mo's Algorithm (Range Sum)

Offline range sums by sorting queries into blocks.

## Example

```mbt check
///|
test "mo example" {
  let arr : Array[Int] = [1, 2, 3, 4, 5]
  let qs : Array[(Int, Int)] = [(0, 3), (1, 4), (2, 5), (0, 5)]
  let ans = @challenge_mo_algorithm_sum.mo_range_sum(arr[:], qs[:])
  inspect(ans, content="[6, 9, 12, 15]")
}
```
