# Challenge: 2D Fenwick Tree

Point updates and rectangle sums in O(log^2 n).

## Example

```mbt check
///|
test "fenwick2d example" {
  let fw = @challenge_fenwick_2d.Fenwick2D::new(3, 3)
  fw.add(0, 0, 5)
  fw.add(1, 2, 3)
  inspect(fw.range_sum(0, 0, 3, 3), content="8")
}
```
