# Challenge: Persistent Stack

A **persistent stack** is a purely functional stack. Every operation returns a
new stack, and old versions remain available.

This package provides:

- `empty()`
- `push(s, value)`
- `pop(s)`
- `peek(s)`
- `size(s)`
- `from_array(arr)`
- `to_array(s)`

---

## Core idea

A stack is just a linked list. `push` creates a new node and points to the old
stack. Since nothing is mutated, old versions stay valid.

```
Before push:
  s0 -> Nil

After push(10):
  s1 -> [10] -> Nil
  s0 -> Nil  (unchanged)
```

Every `push` adds one node, and that new node is the only allocation.

---

## Persistence in action

If you push multiple times, each version is still usable:

```
s0: Nil
s1: [10] -> Nil
s2: [20] -> [10] -> Nil
s3: [30] -> [20] -> [10] -> Nil
```

You can query or pop from any version without affecting the others.

---

## API summary

- `push` is O(1)
- `pop` is O(1)
- `peek` is O(1)
- `size` is O(n)
- `from_array` builds a stack with the first element on top
- `to_array` converts back to a list in top-to-bottom order

---

## Example 1: Push, peek, pop

```mbt check
///|
test "stack basic" {
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

---

## Example 2: Versions stay alive

```mbt check
///|
test "stack versions" {
  let s0 : @challenge_persistent_stack.Stack[Int] = @challenge_persistent_stack.empty()
  let s1 = @challenge_persistent_stack.push(s0, 10)
  let s2 = @challenge_persistent_stack.push(s1, 20)

  // s1 still only has 10
  inspect(@challenge_persistent_stack.to_array(s1), content="[10]")

  // s2 has 20 on top of 10
  inspect(@challenge_persistent_stack.to_array(s2), content="[20, 10]")
}
```

---

## Example 3: Build from array

`from_array` preserves the array order: the top of the stack is `arr[0]`.

```mbt check
///|
test "stack from array" {
  let s = @challenge_persistent_stack.from_array([7, 1, 5][:])
  inspect(@challenge_persistent_stack.to_array(s), content="[7, 1, 5]")
  inspect(@challenge_persistent_stack.peek(s), content="Some(7)")
}
```

### Why is the top `arr[0]`?

`from_array` walks the array from right to left (using `rev_fold`), and conses
each element. That preserves the original order.

---

## Example 4: Convert back to array

```mbt check
///|
test "stack to array" {
  let s0 = @challenge_persistent_stack.empty()
  let s1 = @challenge_persistent_stack.push(s0, 3)
  let s2 = @challenge_persistent_stack.push(s1, 8)
  let s3 = @challenge_persistent_stack.push(s2, 2)
  inspect(@challenge_persistent_stack.to_array(s3), content="[2, 8, 3]")
}
```

---

## Complexity

- `push`: `O(1)` time and memory
- `pop`: `O(1)` time
- `peek`: `O(1)`
- `size`: `O(n)`
- `from_array`: `O(n)`
- `to_array`: `O(n)`

---

## When to use this structure

Use this package when you need:

- persistence (older versions remain valid)
- a simple LIFO structure
- fast updates with no mutation

If you do not need persistence, a mutable array-based stack might be simpler.

---

## Reference implementation

```mbt
///| pub fn empty[T]() -> Stack[T]

///| pub fn is_empty[T](s : Stack[T]) -> Bool

///| pub fn push[T](s : Stack[T], value : T) -> Stack[T]

///| pub fn pop[T](s : Stack[T]) -> (T, Stack[T])?

///| pub fn peek[T](s : Stack[T]) -> T?

///| pub fn size[T](s : Stack[T]) -> Int

///| pub fn from_array[T](arr : ArrayView[T]) -> Stack[T]

///| pub fn to_array[T](s : Stack[T]) -> Array[T]
```
