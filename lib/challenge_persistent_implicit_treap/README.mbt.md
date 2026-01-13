# Persistent Implicit Treap

Sequence treap indexed by subtree sizes, supports split/merge and insert.

## Core Idea

Keys are implicit: each node stores subtree size, so the index of a node is
its in-order position. Split by index and merge by priority give efficient
insert/delete, while persistence is achieved by path copying.

## Example

```mbt check
///|
test "persistent implicit treap" {
  let t0 = @challenge_persistent_implicit_treap.empty()
  let t1 = @challenge_persistent_implicit_treap.insert_at(t0, 0, 10)
  let t2 = @challenge_persistent_implicit_treap.insert_at(t1, 1, 20)
  let t3 = @challenge_persistent_implicit_treap.insert_at(t2, 1, 15)
  inspect(
    @challenge_persistent_implicit_treap.to_array(t3),
    content="[10, 15, 20]",
  )
  inspect(@challenge_persistent_implicit_treap.get(t3, 2), content="Some(20)")
  let (l, r) = @challenge_persistent_implicit_treap.split(t3, 2)
  inspect(@challenge_persistent_implicit_treap.to_array(l), content="[10, 15]")
  inspect(@challenge_persistent_implicit_treap.to_array(r), content="[20]")
}
```

## Another Example

```mbt check
///|
test "persistent implicit treap insert" {
  let t0 = @challenge_persistent_implicit_treap.from_array([1, 2][:])
  let t1 = @challenge_persistent_implicit_treap.insert_at(t0, 1, 9)
  inspect(@challenge_persistent_implicit_treap.to_array(t0), content="[1, 2]")
  inspect(
    @challenge_persistent_implicit_treap.to_array(t1),
    content="[1, 9, 2]",
  )
}
```

## Notes

- Expected time is O(log n) per operation.
- Old versions remain available.
