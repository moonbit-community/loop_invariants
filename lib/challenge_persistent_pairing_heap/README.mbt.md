# Persistent Pairing Heap

Meldable heap that merges children in pairs after delete-min.

## Example

```mbt check
///|
test "persistent pairing heap" {
  let h0 = @challenge_persistent_pairing_heap.empty()
  let h1 = @challenge_persistent_pairing_heap.insert(h0, 8)
  let h2 = @challenge_persistent_pairing_heap.insert(h1, 3)
  let h3 = @challenge_persistent_pairing_heap.insert(h2, 6)
  inspect(@challenge_persistent_pairing_heap.find_min(h3), content="Some(3)")
  guard @challenge_persistent_pairing_heap.delete_min(h3) is Some(h4) else {
    fail("expected delete_min")
  }
  inspect(@challenge_persistent_pairing_heap.find_min(h4), content="Some(6)")
  inspect(@challenge_persistent_pairing_heap.size(h4), content="2")
}
```

## Another Example

```mbt check
///|
test "persistent pairing heap merge" {
  let h1 = @challenge_persistent_pairing_heap.insert(
    @challenge_persistent_pairing_heap.empty(),
    9,
  )
  let h2 = @challenge_persistent_pairing_heap.insert(
    @challenge_persistent_pairing_heap.empty(),
    1,
  )
  let merged = @challenge_persistent_pairing_heap.merge(h1, h2)
  inspect(
    @challenge_persistent_pairing_heap.find_min(merged),
    content="Some(1)",
  )
  inspect(@challenge_persistent_pairing_heap.size(merged), content="2")
}
```
