# Challenge: Persistent Deque

A **persistent deque** supports pushing and popping at both ends, while keeping
old versions intact. This implementation uses two immutable stacks and
normalizes by reversing when one side becomes empty.

This package provides:

- `empty()` to create a deque
- `push_front`, `push_back` to add values
- `peek_front`, `peek_back` to read without removing
- `pop_front`, `pop_back` to remove values
- `size` to count elements

---

## Two-stack idea

We store the deque as two stacks:

```
front stack: top is the front element
back stack:  top is the back element
```

Visual:

```
front stack (top)        back stack (top)
[ a, b, c ]              [ z, y, x ]
 ^ front                   ^ back
```

The logical deque order is:

```
front stack (top to bottom) + reverse(back stack)
```

---

## Normalization

If we want to peek/pop from the front but the front stack is empty, we reverse
the back stack and move it to the front (and vice versa).

```
front empty, back has [z, y, x]

reverse(back) -> [x, y, z]
front = [x, y, z], back = []
```

This makes the next front operation possible. Reversal is `O(k)` but happens
only when one side is empty, so amortized complexity stays good.

---

## Persistence (path copying)

All stacks are immutable linked lists. Every push or pop creates a new stack
node, while old stacks remain valid and share the unchanged tail.

```
old stack:  a -> b -> c
new stack:  x -> a -> b -> c
```

Only one new node is created.

---

## Reference implementation

```mbt nocheck
///| pub fn[T] empty() -> Deque[T]

///| pub fn[T] push_front(d : Deque[T], value : T) -> Deque[T]

///| pub fn[T] push_back(d : Deque[T], value : T) -> Deque[T]

///| pub fn[T] peek_front(d : Deque[T]) -> T?

///| pub fn[T] peek_back(d : Deque[T]) -> T?

///| pub fn[T] pop_front(d : Deque[T]) -> (T, Deque[T])?

///| pub fn[T] pop_back(d : Deque[T]) -> (T, Deque[T])?

///| pub fn[T] size(d : Deque[T]) -> Int
```

---

## Tests and examples

### Push and peek

```mbt check
///|
test "persistent deque push/peek" {
  let d0 = @challenge_persistent_deque.empty()
  let d1 = @challenge_persistent_deque.push_front(d0, 2)
  let d2 = @challenge_persistent_deque.push_back(d1, 5)
  debug_inspect(@challenge_persistent_deque.peek_front(d2), content="Some(2)")
  debug_inspect(@challenge_persistent_deque.peek_back(d2), content="Some(5)")
}
```

### Pop from both ends

```mbt check
///|
test "persistent deque pop" {
  let d0 = @challenge_persistent_deque.empty()
  let d1 = @challenge_persistent_deque.push_back(d0, 1)
  let d2 = @challenge_persistent_deque.push_back(d1, 2)
  let d3 = @challenge_persistent_deque.push_back(d2, 3)
  let front = @challenge_persistent_deque.pop_front(d3)
  match front {
    None => fail("expected non-empty deque")
    Some((v, rest)) => {
      debug_inspect(v, content="1")
      debug_inspect(
        @challenge_persistent_deque.peek_front(rest),
        content="Some(2)",
      )
    }
  }
  let back = @challenge_persistent_deque.pop_back(d3)
  match back {
    None => fail("expected non-empty deque")
    Some((v, rest)) => {
      debug_inspect(v, content="3")
      debug_inspect(
        @challenge_persistent_deque.peek_back(rest),
        content="Some(2)",
      )
    }
  }
}
```

### Persistence across versions

```mbt check
///|
test "persistent deque versions" {
  let d0 = @challenge_persistent_deque.empty()
  let d1 = @challenge_persistent_deque.push_front(d0, 9)
  let d2 = @challenge_persistent_deque.push_back(d1, 4)
  debug_inspect(@challenge_persistent_deque.peek_front(d0), content="None")
  debug_inspect(@challenge_persistent_deque.peek_front(d1), content="Some(9)")
  debug_inspect(@challenge_persistent_deque.peek_back(d2), content="Some(4)")
}
```

---

## Complexity

Let `n` be the number of elements.

- `push_front`, `push_back`: `O(1)`
- `pop_front`, `pop_back`: amortized `O(1)`
- `peek_front`, `peek_back`: amortized `O(1)`
- `size`: `O(n)` (it walks both stacks)

---

## Takeaways

- Two stacks give a simple persistent deque.
- Normalization by reversal keeps operations fast on average.
- Old versions stay valid because stacks are immutable.
