# Persistent Treap Map

Key-value treap with immutable updates and search.

## Core Idea

Treaps maintain a BST by key and a heap by random priority. Persistence is
achieved by copying nodes along update paths.

## Example

```mbt check
///|
test "persistent treap map" {
  let t0 = @challenge_persistent_treap_map.empty()
  let t1 = @challenge_persistent_treap_map.insert_or_update(t0, 3, 30)
  let t2 = @challenge_persistent_treap_map.insert_or_update(t1, 1, 10)
  let t3 = @challenge_persistent_treap_map.insert_or_update(t2, 3, 31)
  inspect(@challenge_persistent_treap_map.get(t3, 3), content="Some(31)")
  inspect(@challenge_persistent_treap_map.get(t3, 2), content="None")
  inspect(@challenge_persistent_treap_map.contains(t3, 1), content="true")
  inspect(@challenge_persistent_treap_map.size(t3), content="2")
}
```

## Another Example

```mbt check
///|
test "persistent treap map from array" {
  let t = @challenge_persistent_treap_map.from_array([(2, 20), (5, 50)][:])
  inspect(@challenge_persistent_treap_map.get(t, 2), content="Some(20)")
  inspect(@challenge_persistent_treap_map.size(t), content="2")
}
```

## Notes

- Insert/update returns a new version.
- Expected time is O(log n).
