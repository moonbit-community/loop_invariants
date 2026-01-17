# Challenge: Persistent Min-Stack

A **persistent min-stack** is a stack that can return the minimum element in
O(1) while remaining fully immutable. Every push returns a new version, and old
versions remain usable.

This package provides:

- `empty()`
- `push(s, value)`
- `pop(s)`
- `min_value(s)`
- `size(s)`
- `from_array(arr)`

---

## Core idea

Each node stores two values:

- `value`: the element at the top
- `min`: the minimum of the entire suffix from this node downward

When you push a new value, the new minimum becomes:

```
min(value, previous_min)
```

Because the minimum is cached at each node, `min_value` is O(1).

---

## Persistence

As with any persistent stack, every push creates a new node that points to the
old stack. The old stack remains valid.

```
Before push:
  s0 -> Nil

After push(5):
  s1 -> [value=5, min=5] -> Nil
  s0 -> Nil  (unchanged)
```

---

## API summary

- `push` is O(1)
- `pop` is O(1)
- `min_value` is O(1)
- `size` is O(n)
- `from_array` is O(n)

---

## Example 1: Push and query min

```mbt check
///|
test "min-stack basic" {
  let s0 : @challenge_persistent_stack_min.MinStack[Int] = @challenge_persistent_stack_min.empty()
  let s1 = @challenge_persistent_stack_min.push(s0, 5)
  let s2 = @challenge_persistent_stack_min.push(s1, 2)
  let s3 = @challenge_persistent_stack_min.push(s2, 7)
  inspect(@challenge_persistent_stack_min.min_value(s3), content="Some(2)")
}
```

Even after pushing `7`, the minimum stays `2`.

---

## Example 2: Pop and restore min

```mbt check
///|
test "min-stack pop" {
  let s0 : @challenge_persistent_stack_min.MinStack[Int] = @challenge_persistent_stack_min.empty()
  let s1 = @challenge_persistent_stack_min.push(s0, 5)
  let s2 = @challenge_persistent_stack_min.push(s1, 2)
  let s3 = @challenge_persistent_stack_min.push(s2, 7)
  guard @challenge_persistent_stack_min.pop(s3) is Some((7, s4)) else {
    fail("expected pop")
  }
  inspect(@challenge_persistent_stack_min.min_value(s4), content="Some(2)")
  guard @challenge_persistent_stack_min.pop(s4) is Some((2, s5)) else {
    fail("expected pop")
  }
  inspect(@challenge_persistent_stack_min.min_value(s5), content="Some(5)")
}
```

After popping `7` and then `2`, the minimum becomes `5`.

---

## Example 3: Building from array

`from_array` preserves array order: the top is `arr[0]`.

```mbt check
///|
test "min-stack from array" {
  let s = @challenge_persistent_stack_min.from_array([4, 1, 6][:])
  inspect(@challenge_persistent_stack_min.min_value(s), content="Some(1)")
  inspect(@challenge_persistent_stack_min.size(s), content="3")
}
```

---

## Example 4: Persistence across versions

```mbt check
///|
test "min-stack versions" {
  let s0 : @challenge_persistent_stack_min.MinStack[Int] = @challenge_persistent_stack_min.empty()
  let s1 = @challenge_persistent_stack_min.push(s0, 10)
  let s2 = @challenge_persistent_stack_min.push(s1, 3)
  let s3 = @challenge_persistent_stack_min.push(s2, 8)
  inspect(@challenge_persistent_stack_min.min_value(s1), content="Some(10)")
  inspect(@challenge_persistent_stack_min.min_value(s2), content="Some(3)")
  inspect(@challenge_persistent_stack_min.min_value(s3), content="Some(3)")
}
```

---

## Complexity

- `push`: `O(1)` time and memory
- `pop`: `O(1)` time
- `min_value`: `O(1)`
- `size`: `O(n)`
- `from_array`: `O(n)`

---

## When to use this structure

Use this package when you need:

- a persistent stack
- fast minimum queries
- immutable versions for branching or rollback

If you do not need persistence, a mutable min-stack can be simpler.

---

## Reference implementation

```mbt
///| pub fn empty[T]() -> MinStack[T]

///| pub fn size[T](s : MinStack[T]) -> Int

///| pub fn min_value[T](s : MinStack[T]) -> T?

///| pub fn push[T : Compare](s : MinStack[T], value : T) -> MinStack[T]

///| pub fn pop[T](s : MinStack[T]) -> (T, MinStack[T])?

///| pub fn from_array[T : Compare](arr : ArrayView[T]) -> MinStack[T]
```
