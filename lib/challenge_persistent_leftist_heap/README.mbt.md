# Persistent Leftist Heap

Meldable priority queue with null-path length property.

## Example

```mbt check
///|
test "persistent leftist heap" {
  let h0 = @challenge_persistent_leftist_heap.empty()
  let h1 = @challenge_persistent_leftist_heap.insert(h0, 5)
  let h2 = @challenge_persistent_leftist_heap.insert(h1, 3)
  let h3 = @challenge_persistent_leftist_heap.insert(h2, 7)
  inspect(@challenge_persistent_leftist_heap.find_min(h3), content="Some(3)")
  guard @challenge_persistent_leftist_heap.delete_min(h3) is Some(h4) else {
    fail("expected delete_min")
  }
  inspect(@challenge_persistent_leftist_heap.find_min(h4), content="Some(5)")
  inspect(@challenge_persistent_leftist_heap.size(h4), content="2")
}
```

## Another Example

```mbt check
///|
test "persistent leftist heap merge" {
  let h1 = @challenge_persistent_leftist_heap.insert(
    @challenge_persistent_leftist_heap.empty(),
    4,
  )
  let h2 = @challenge_persistent_leftist_heap.insert(
    @challenge_persistent_leftist_heap.empty(),
    2,
  )
  let merged = @challenge_persistent_leftist_heap.merge(h1, h2)
  inspect(
    @challenge_persistent_leftist_heap.find_min(merged),
    content="Some(2)",
  )
  inspect(@challenge_persistent_leftist_heap.size(merged), content="2")
}
```
