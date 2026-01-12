# Persistent Binomial Heap

Binomial heap with immutable merges and deletes via path copying.

## Example

```mbt check
///|
test "persistent binomial heap" {
  let h0 = @challenge_persistent_binomial_heap.empty()
  let h1 = @challenge_persistent_binomial_heap.insert(h0, 4)
  let h2 = @challenge_persistent_binomial_heap.insert(h1, 1)
  let h3 = @challenge_persistent_binomial_heap.insert(h2, 7)
  inspect(@challenge_persistent_binomial_heap.find_min(h3), content="Some(1)")
  guard @challenge_persistent_binomial_heap.delete_min(h3) is Some(h4) else {
    fail("expected delete_min")
  }
  inspect(@challenge_persistent_binomial_heap.find_min(h4), content="Some(4)")
}
```

## Another Example

```mbt check
///|
test "persistent binomial heap merge" {
  let h1 = @challenge_persistent_binomial_heap.insert(
    @challenge_persistent_binomial_heap.empty(),
    3,
  )
  let h2 = @challenge_persistent_binomial_heap.insert(
    @challenge_persistent_binomial_heap.empty(),
    1,
  )
  let merged = @challenge_persistent_binomial_heap.merge(h1, h2)
  inspect(
    @challenge_persistent_binomial_heap.find_min(merged),
    content="Some(1)",
  )
  inspect(@challenge_persistent_binomial_heap.find_min(h1), content="Some(3)")
}
```
