# Persistent KD-Tree (2D)

Immutable KD-tree with alternating split axis.

## Example

```mbt check
///|
test "persistent kd tree" {
  let p1 = @challenge_persistent_kd_tree.Point::{ x: 2, y: 3 }
  let p2 = @challenge_persistent_kd_tree.Point::{ x: 5, y: 4 }
  let p3 = @challenge_persistent_kd_tree.Point::{ x: 1, y: 7 }
  let t0 = @challenge_persistent_kd_tree.empty()
  let t1 = @challenge_persistent_kd_tree.insert(t0, p1)
  let t2 = @challenge_persistent_kd_tree.insert(t1, p2)
  let t3 = @challenge_persistent_kd_tree.insert(t2, p3)
  inspect(@challenge_persistent_kd_tree.contains(t3, p2), content="true")
  inspect(@challenge_persistent_kd_tree.contains_iter(t3, p3), content="true")
  inspect(
    @challenge_persistent_kd_tree.contains_iter(t3, @challenge_persistent_kd_tree.Point::{
      x: 4,
      y: 4,
    }),
    content="false",
  )
}
```
