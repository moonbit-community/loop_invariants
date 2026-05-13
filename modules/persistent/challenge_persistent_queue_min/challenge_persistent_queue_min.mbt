// ============================================================================
// Challenge: Persistent Min-Queue
// Two min-stacks track queue minimums immutably
// ============================================================================

///|
enum MinStack[T] {
  Nil
  Cons(value~ : T, min~ : T, tail~ : MinStack[T])
} derive(Debug)

///|
/// Persistent FIFO queue that also supports `O(1)` minimum query.
///
/// Built from two `MinStack`s where each node caches the minimum of
/// the suffix starting at that node. `enqueue` pushes onto `back`
/// while updating its cached minimum in `O(1)`. `peek`/`dequeue`
/// consume from `front`, reversing `back` into a fresh `front` when
/// `front` is empty (amortized `O(1)`, worst case `O(n)` per call).
/// `min_queue` reads the cached minimum at the top of each stack and
/// returns the smaller in `O(1)`. Every operation returns a new
/// `MinQueue`, sharing nodes with the previous version. See `empty`,
/// `size`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let q : @challenge_persistent_queue_min.MinQueue[Int] = @challenge_persistent_queue_min.empty()
///   let q = @challenge_persistent_queue_min.enqueue(q, 5)
///   let q = @challenge_persistent_queue_min.enqueue(q, 2)
///   let q = @challenge_persistent_queue_min.enqueue(q, 7)
///   inspect(@challenge_persistent_queue_min.min_queue(q), content="Some(2)")
/// }
/// ```
pub struct MinQueue[T] {
  front : MinStack[T]
  back : MinStack[T]
} derive(Debug)

///|
/// Create an empty min-queue.
pub fn[T] empty() -> MinQueue[T] {
  { front: Nil, back: Nil }
}

///|
fn[T] size_stack(s : MinStack[T]) -> Int {
  match s {
    Nil => 0
    Cons(value=_, min=_, tail~) => 1 + size_stack(tail)
  }
}

///|
/// Return the number of elements in the queue.
pub fn[T] size(q : MinQueue[T]) -> Int {
  size_stack(q.front) + size_stack(q.back)
}

///|
fn[T] min_value(s : MinStack[T]) -> T? {
  match s {
    Nil => None
    Cons(value=_, min~, tail=_) => Some(min)
  }
}

///|
fn[T : Compare] push(s : MinStack[T], value : T) -> MinStack[T] {
  let new_min = match s {
    Nil => value
    Cons(value=_, min~, tail=_) => if value < min { value } else { min }
  }
  Cons(value~, min=new_min, tail=s)
}

///|

///|
fn[T : Compare] reverse_stack_acc(
  cur : MinStack[T],
  acc : MinStack[T],
) -> MinStack[T] {
  match cur {
    Nil => acc
    Cons(value~, min=_, tail~) => reverse_stack_acc(tail, push(acc, value))
  }
}

///|
fn[T : Compare] reverse_stack(s : MinStack[T]) -> MinStack[T] {
  reverse_stack_acc(s, Nil)
}

///|
fn[T : Compare] normalize(q : MinQueue[T]) -> MinQueue[T] {
  match q.front {
    Nil => { front: reverse_stack(q.back), back: Nil }
    _ => q
  }
}

///|
/// Enqueue a value and return the new queue.
pub fn[T : Compare] enqueue(q : MinQueue[T], value : T) -> MinQueue[T] {
  { front: q.front, back: push(q.back, value) }
}

///|
/// Peek the front value without removing it.
pub fn[T : Compare] peek(q : MinQueue[T]) -> T? {
  let norm = normalize(q)
  match norm.front {
    Nil => None
    Cons(value~, min=_, tail=_) => Some(value)
  }
}

///|
/// Dequeue the front value and return (value, rest), or None if empty.
pub fn[T : Compare] dequeue(q : MinQueue[T]) -> (T, MinQueue[T])? {
  let norm = normalize(q)
  match norm.front {
    Nil => None
    Cons(value~, min=_, tail~) =>
      Some((value, { front: tail, back: norm.back }))
  }
}

///|
/// Return the minimum value in the queue, or None if empty.
pub fn[T : Compare] min_queue(q : MinQueue[T]) -> T? {
  match (min_value(q.front), min_value(q.back)) {
    (None, None) => None
    (Some(x), None) => Some(x)
    (None, Some(y)) => Some(y)
    (Some(x), Some(y)) => Some(if x < y { x } else { y })
  }
}

///|
test "persistent_queue_min" {
  let q0 : MinQueue[Int] = empty()
  let q1 = enqueue(q0, 5)
  let q2 = enqueue(q1, 2)
  let q3 = enqueue(q2, 7)
  debug_inspect(peek(q3), content="Some(5)")
  debug_inspect(min_queue(q3), content="Some(2)")
  guard dequeue(q3) is Some((5, q4)) else { fail("expected dequeue") }
  debug_inspect(min_queue(q4), content="Some(2)")
  guard dequeue(q4) is Some((2, q5)) else { fail("expected dequeue") }
  debug_inspect(min_queue(q5), content="Some(7)")
  assert_eq(size(q5), 1)
}
