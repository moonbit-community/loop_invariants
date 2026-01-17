# Challenge: Persistent Queue

A **persistent queue** supports enqueue and dequeue while keeping old versions
intact. This implementation uses two immutable stacks and reverses when needed.

This package provides:

- `empty()` to create a queue
- `enqueue(q, value)` to push to the back
- `peek(q)` to read the front
- `dequeue(q)` to pop from the front
- `size(q)` to count elements

---

## Two-stack queue idea

We store the queue as two stacks:

```
front stack: top is the queue front
back stack:  top is the queue back
```

Logical order:

```
front (top to bottom) + reverse(back)
```

Example:

```
front: [a, b]
back:  [d, c]
queue: [a, b, c, d]
```

---

## Normalization

If the front stack is empty, we reverse the back stack and move it to the front.
This makes sure peek/dequeue always read the correct front element.

```
front = []
back  = [c, b, a]

normalize -> front = [a, b, c], back = []
```

The reversal is `O(k)` but only happens when the front is empty, so operations
are amortized `O(1)`.

---

## Persistence

Stacks are immutable linked lists. Every enqueue creates a new node and shares
all old nodes. Old queue versions remain usable.

```
old back:  x -> y
new back:  z -> x -> y
```

---

## Reference implementation

```mbt
///| pub fn[T] empty() -> Queue[T]

///| pub fn[T] enqueue(q : Queue[T], value : T) -> Queue[T]

///| pub fn[T] peek(q : Queue[T]) -> T?

///| pub fn[T] dequeue(q : Queue[T]) -> (T, Queue[T])?

///| pub fn[T] size(q : Queue[T]) -> Int
```

---

## Tests and examples

### Basic enqueue/dequeue

```mbt check
///|
test "persistent queue basic" {
  let q0 = @challenge_persistent_queue.empty()
  let q1 = @challenge_persistent_queue.enqueue(q0, 1)
  let q2 = @challenge_persistent_queue.enqueue(q1, 2)
  let q3 = @challenge_persistent_queue.enqueue(q2, 3)
  inspect(@challenge_persistent_queue.peek(q3), content="Some(1)")
  guard @challenge_persistent_queue.dequeue(q3) is Some((v, q4)) else {
    fail("expected dequeue")
  }
  inspect(v, content="1")
  inspect(@challenge_persistent_queue.peek(q4), content="Some(2)")
}
```

### Persistence across versions

```mbt check
///|
test "persistent queue versions" {
  let q0 = @challenge_persistent_queue.empty()
  let q1 = @challenge_persistent_queue.enqueue(q0, 10)
  let q2 = @challenge_persistent_queue.enqueue(q1, 20)
  inspect(@challenge_persistent_queue.peek(q0), content="None")
  inspect(@challenge_persistent_queue.peek(q1), content="Some(10)")
  inspect(@challenge_persistent_queue.peek(q2), content="Some(10)")
}
```

### Dequeue until empty

```mbt check
///|
test "persistent queue empty" {
  let q0 = @challenge_persistent_queue.empty()
  let q1 = @challenge_persistent_queue.enqueue(q0, 5)
  let q2 = @challenge_persistent_queue.dequeue(q1)
  match q2 {
    None => fail("expected non-empty")
    Some((v, rest)) => {
      inspect(v, content="5")
      inspect(@challenge_persistent_queue.peek(rest), content="None")
    }
  }
}
```

---

## Complexity

- Enqueue: `O(1)`
- Peek/Dequeue: amortized `O(1)`
- Size: `O(n)` (walks both stacks)

---

## Takeaways

- Two immutable stacks give a clean persistent queue.
- Normalization by reversal keeps operations fast.
- Old versions remain valid and share structure.
