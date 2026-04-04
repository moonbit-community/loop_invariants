# Challenge: Persistent Min-Queue

A **min-queue** supports queue operations plus fast access to the minimum
value. This implementation is **persistent**, so all old versions remain valid.

It uses two **min-stacks** (stacks that store the minimum of their contents).

This package provides:

- `empty()` to create a queue
- `enqueue(q, value)` to push to the back
- `peek(q)` to view the front
- `dequeue(q)` to pop from the front
- `min_queue(q)` to get the minimum value
- `size(q)` to count elements

---

## Min-stack idea

A min-stack stores each element along with the minimum so far:

```
Cons(value, min, tail)
```

So the top node always knows the minimum of the stack in `O(1)`.

---

## Two-stack queue

We represent a queue using two stacks:

- `front` stack: top is the queue front
- `back` stack: top is the queue back

Logical order:

```
front (top to bottom) + reverse(back)
```

When `front` is empty, we reverse `back` into `front`.

---

## Getting the minimum

The minimum of the queue is the min of the two stack minimums:

```
min_queue = min(min(front), min(back))
```

Each is `O(1)`, so the overall min query is `O(1)`.

---

## Persistence

All stacks are immutable lists. Every enqueue or dequeue creates new nodes
and shares old ones. Past versions remain valid.

---

## Reference implementation

```mbt nocheck
///| pub fn[T] empty() -> MinQueue[T]

///| pub fn[T : Compare] enqueue(q : MinQueue[T], value : T) -> MinQueue[T]

///| pub fn[T : Compare] peek(q : MinQueue[T]) -> T?

///| pub fn[T : Compare] dequeue(q : MinQueue[T]) -> (T, MinQueue[T])?

///| pub fn[T : Compare] min_queue(q : MinQueue[T]) -> T?

///| pub fn[T] size(q : MinQueue[T]) -> Int
```

---

## Tests and examples

### Basic usage

```mbt check
///|
test "min queue basic" {
  let q0 = @challenge_persistent_queue_min.empty()
  let q1 = @challenge_persistent_queue_min.enqueue(q0, 5)
  let q2 = @challenge_persistent_queue_min.enqueue(q1, 2)
  let q3 = @challenge_persistent_queue_min.enqueue(q2, 7)
  inspect(@challenge_persistent_queue_min.peek(q3), content="Some(5)")
  inspect(@challenge_persistent_queue_min.min_queue(q3), content="Some(2)")
}
```

### Dequeue keeps min correct

```mbt check
///|
test "min queue dequeue" {
  let q0 = @challenge_persistent_queue_min.empty()
  let q1 = @challenge_persistent_queue_min.enqueue(q0, 5)
  let q2 = @challenge_persistent_queue_min.enqueue(q1, 2)
  let q3 = @challenge_persistent_queue_min.enqueue(q2, 7)
  guard @challenge_persistent_queue_min.dequeue(q3) is Some((5, q4)) else {
    fail("expected dequeue")
  }
  inspect(@challenge_persistent_queue_min.min_queue(q4), content="Some(2)")
  guard @challenge_persistent_queue_min.dequeue(q4) is Some((2, q5)) else {
    fail("expected dequeue")
  }
  inspect(@challenge_persistent_queue_min.min_queue(q5), content="Some(7)")
}
```

### Persistence across versions

```mbt check
///|
test "min queue persistence" {
  let q0 = @challenge_persistent_queue_min.empty()
  let q1 = @challenge_persistent_queue_min.enqueue(q0, 4)
  let q2 = @challenge_persistent_queue_min.enqueue(q1, 1)
  inspect(@challenge_persistent_queue_min.min_queue(q0), content="None")
  inspect(@challenge_persistent_queue_min.min_queue(q1), content="Some(4)")
  inspect(@challenge_persistent_queue_min.min_queue(q2), content="Some(1)")
}
```

---

## Complexity

- Enqueue: `O(1)`
- Peek/Dequeue: amortized `O(1)`
- Min query: `O(1)`
- Size: `O(n)` (walks both stacks)

---

## Takeaways

- Two min-stacks give a queue with constant-time minimum.
- Persistence keeps all versions intact.
- Normalization by reversal keeps amortized bounds small.
