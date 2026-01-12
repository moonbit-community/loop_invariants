# Persistent Deque

Functional deque implemented with two stacks and normalization.

## Example

```mbt check
///|
test "persistent deque" {
  let d0 : @challenge_persistent_deque.Deque[Int] = @challenge_persistent_deque.empty()
  let d1 = @challenge_persistent_deque.push_front(d0, 1)
  let d2 = @challenge_persistent_deque.push_back(d1, 2)
  let d3 = @challenge_persistent_deque.push_front(d2, 0)
  inspect(@challenge_persistent_deque.peek_front(d3), content="Some(0)")
  inspect(@challenge_persistent_deque.peek_back(d3), content="Some(2)")
  guard @challenge_persistent_deque.pop_front(d3) is Some((0, d4)) else {
    fail("expected pop_front")
  }
  guard @challenge_persistent_deque.pop_back(d4) is Some((2, d5)) else {
    fail("expected pop_back")
  }
  inspect(@challenge_persistent_deque.size(d5), content="1")
}
```

## Another Example

```mbt check
///|
test "persistent deque back heavy" {
  let d0 : @challenge_persistent_deque.Deque[Int] = @challenge_persistent_deque.empty()
  let d1 = @challenge_persistent_deque.push_back(d0, 10)
  let d2 = @challenge_persistent_deque.push_back(d1, 20)
  let d3 = @challenge_persistent_deque.push_back(d2, 30)
  guard @challenge_persistent_deque.pop_back(d3) is Some((30, d4)) else {
    fail("expected pop_back")
  }
  inspect(@challenge_persistent_deque.peek_front(d4), content="Some(10)")
  inspect(@challenge_persistent_deque.peek_back(d4), content="Some(20)")
}
```
