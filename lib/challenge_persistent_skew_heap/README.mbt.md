# Persistent Skew Heap

Meldable heap with self-adjusting subtree swaps.

## Example

```mbt check
///|
test "persistent skew heap" {
  let h0 = @challenge_persistent_skew_heap.empty()
  let h1 = @challenge_persistent_skew_heap.insert(h0, 4)
  let h2 = @challenge_persistent_skew_heap.insert(h1, 1)
  let h3 = @challenge_persistent_skew_heap.insert(h2, 6)
  inspect(@challenge_persistent_skew_heap.find_min(h3), content="Some(1)")
  guard @challenge_persistent_skew_heap.delete_min(h3) is Some(h4) else {
    fail("expected delete_min")
  }
  inspect(@challenge_persistent_skew_heap.find_min(h4), content="Some(4)")
  inspect(@challenge_persistent_skew_heap.size(h4), content="2")
}
```

## Another Example

```mbt check
///|
test "persistent skew heap from array" {
  let h = @challenge_persistent_skew_heap.from_array([7, 1, 5][:])
  inspect(@challenge_persistent_skew_heap.find_min(h), content="Some(1)")
  inspect(@challenge_persistent_skew_heap.size(h), content="3")
}
```
