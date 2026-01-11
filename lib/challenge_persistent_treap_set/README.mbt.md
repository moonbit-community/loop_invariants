# Persistent Treap Set

Random-priority BST supporting immutable inserts.

## Example

```mbt check
///|
test "persistent treap set" {
  let t0 = @challenge_persistent_treap_set.empty()
  let t1 = @challenge_persistent_treap_set.insert(t0, 5)
  let t2 = @challenge_persistent_treap_set.insert(t1, 2)
  let t3 = @challenge_persistent_treap_set.insert(t2, 8)
  inspect(@challenge_persistent_treap_set.contains(t3, 2), content="true")
  inspect(@challenge_persistent_treap_set.contains(t3, 6), content="false")
  inspect(@challenge_persistent_treap_set.size(t3), content="3")
}
```
