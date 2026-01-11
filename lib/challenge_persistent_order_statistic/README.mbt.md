# Persistent Order Statistic Tree

Persistent segment tree that supports kth-order statistics.

## Example

```mbt check
///|
test "persistent order statistic" {
  let os0 = @challenge_persistent_order_statistic.make(0, 10)
  let os1 = @challenge_persistent_order_statistic.add(os0, 5)
  let os2 = @challenge_persistent_order_statistic.add(os1, 2)
  let os3 = @challenge_persistent_order_statistic.add(os2, 7)
  let os4 = @challenge_persistent_order_statistic.add(os3, 2)
  inspect(@challenge_persistent_order_statistic.kth(os4, 0), content="Some(2)")
  inspect(@challenge_persistent_order_statistic.kth(os4, 2), content="Some(5)")
  inspect(@challenge_persistent_order_statistic.size(os4), content="4")
}
```
