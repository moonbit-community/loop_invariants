# Persistent Stack

Immutable stack with push/pop/peek operations.

## Example

```mbt check
///|
test "persistent stack" {
  let s0 : @challenge_persistent_stack.Stack[Int] = @challenge_persistent_stack.empty()
  let s1 = @challenge_persistent_stack.push(s0, 1)
  let s2 = @challenge_persistent_stack.push(s1, 2)
  inspect(@challenge_persistent_stack.peek(s2), content="Some(2)")
  guard @challenge_persistent_stack.pop(s2) is Some((2, s3)) else {
    fail("expected pop")
  }
  inspect(@challenge_persistent_stack.to_array(s3), content="[1]")
  inspect(@challenge_persistent_stack.size(s3), content="1")
}
```

## Another Example

```mbt check
///|
test "persistent stack versions" {
  let s0 : @challenge_persistent_stack.Stack[Int] = @challenge_persistent_stack.empty()
  let s1 = @challenge_persistent_stack.push(s0, 10)
  let s2 = @challenge_persistent_stack.push(s1, 20)
  inspect(@challenge_persistent_stack.to_array(s1), content="[10]")
  inspect(@challenge_persistent_stack.to_array(s2), content="[20, 10]")
}
```
