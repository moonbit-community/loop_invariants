# Persistent Min-Stack

Stack that tracks the minimum value of each suffix.

## Example

```mbt check
///|
test "persistent min stack" {
  let s0 = @challenge_persistent_stack_min.empty()
  let s1 = @challenge_persistent_stack_min.push(s0, 5)
  let s2 = @challenge_persistent_stack_min.push(s1, 3)
  let s3 = @challenge_persistent_stack_min.push(s2, 7)
  inspect(@challenge_persistent_stack_min.min_value(s3), content="Some(3)")
  guard @challenge_persistent_stack_min.pop(s3) is Some((7, s2b)) else {
    fail("expected pop")
  }
  inspect(@challenge_persistent_stack_min.min_value(s2b), content="Some(3)")
  inspect(@challenge_persistent_stack_min.size(s2b), content="2")
}
```

## Another Example

```mbt check
///|
test "persistent min stack drop min" {
  let s0 = @challenge_persistent_stack_min.empty()
  let s1 = @challenge_persistent_stack_min.push(s0, 4)
  let s2 = @challenge_persistent_stack_min.push(s1, 2)
  let s3 = @challenge_persistent_stack_min.push(s2, 6)
  guard @challenge_persistent_stack_min.pop(s3) is Some((6, s2b)) else {
    fail("expected pop")
  }
  inspect(@challenge_persistent_stack_min.min_value(s2b), content="Some(2)")
  guard @challenge_persistent_stack_min.pop(s2b) is Some((2, s1b)) else {
    fail("expected pop")
  }
  inspect(@challenge_persistent_stack_min.min_value(s1b), content="Some(4)")
}
```
