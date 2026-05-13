// ============================================================================
// Challenge: Persistent Queue
// Two-stack queue with immutable reversal
// ============================================================================

///|
enum Stack[T] {
  Nil
  Cons(head~ : T, tail~ : Stack[T])
} derive(Debug)

///|
/// Persistent FIFO queue built from two singly-linked stacks.
///
/// `front` holds elements in dequeue order (head first); `back` holds
/// recently enqueued elements in reverse order. `enqueue` conses onto
/// `back` in `O(1)`; `peek` and `dequeue` consult `front`, reversing
/// `back` into a new `front` when `front` is empty. The reversal makes
/// the worst-case dequeue `O(n)`, but the amortized cost per element
/// is `O(1)`. Because both stacks are immutable, every operation
/// returns a fresh `Queue` while older versions remain valid. See
/// `empty` and `size`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let q : @challenge_persistent_queue.Queue[Int] = @challenge_persistent_queue.empty()
///   let q = @challenge_persistent_queue.enqueue(q, 1)
///   let q = @challenge_persistent_queue.enqueue(q, 2)
///   guard @challenge_persistent_queue.dequeue(q) is Some((x, _)) else {
///     fail("expected dequeue")
///   }
///   @debug.assert_eq(x, 1)
/// }
/// ```
pub struct Queue[T] {
  front : Stack[T]
  back : Stack[T]
} derive(Debug)

///|
/// Create an empty persistent queue.
pub fn[T] empty() -> Queue[T] {
  { front: Nil, back: Nil }
}

///|
fn[T] size_stack(s : Stack[T]) -> Int {
  match s {
    Nil => 0
    Cons(head=_, tail~) => 1 + size_stack(tail)
  }
}

///|
/// Return the number of elements in the queue.
pub fn[T] size(q : Queue[T]) -> Int {
  size_stack(q.front) + size_stack(q.back)
}

///|
fn[T] reverse_stack_acc(cur : Stack[T], acc : Stack[T]) -> Stack[T] {
  match cur {
    Nil => acc
    Cons(head~, tail~) => reverse_stack_acc(tail, Cons(head~, tail=acc))
  }
}

///|
fn[T] reverse_stack(s : Stack[T]) -> Stack[T] {
  reverse_stack_acc(s, Nil)
}

///|
fn[T] normalize(q : Queue[T]) -> Queue[T] {
  match q.front {
    Nil => { front: reverse_stack(q.back), back: Nil }
    _ => q
  }
}

///|
/// Enqueue a value and return the new queue.
pub fn[T] enqueue(q : Queue[T], value : T) -> Queue[T] {
  { front: q.front, back: Cons(head=value, tail=q.back) }
}

///|
/// Peek the front value without removing it.
pub fn[T] peek(q : Queue[T]) -> T? {
  let norm = normalize(q)
  match norm.front {
    Nil => None
    Cons(head~, tail=_) => Some(head)
  }
}

///|
/// Dequeue the front value and return (value, rest), or None if empty.
pub fn[T] dequeue(q : Queue[T]) -> (T, Queue[T])? {
  let norm = normalize(q)
  match norm.front {
    Nil => None
    Cons(head~, tail~) => Some((head, { front: tail, back: norm.back }))
  }
}
