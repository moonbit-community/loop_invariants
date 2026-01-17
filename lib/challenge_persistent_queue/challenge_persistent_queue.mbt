// ============================================================================
// Challenge: Persistent Queue
// Two-stack queue with immutable reversal
// ============================================================================

///|
enum Stack[T] {
  Nil
  Cons(head~ : T, tail~ : Stack[T])
} derive(Show)

///|
pub struct Queue[T] {
  front : Stack[T]
  back : Stack[T]
} derive(Show)

///|
/// Create an empty persistent queue.
pub fn[T] empty() -> Queue[T] {
  { front: Stack::Nil, back: Stack::Nil }
}

///|
fn[T] size_stack(s : Stack[T]) -> Int {
  match s {
    Stack::Nil => 0
    Stack::Cons(head=_, tail~) => 1 + size_stack(tail)
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
    Stack::Nil => acc
    Stack::Cons(head~, tail~) =>
      reverse_stack_acc(tail, Stack::Cons(head~, tail=acc))
  }
}

///|
fn[T] reverse_stack(s : Stack[T]) -> Stack[T] {
  reverse_stack_acc(s, Stack::Nil)
}

///|
fn[T] normalize(q : Queue[T]) -> Queue[T] {
  match q.front {
    Stack::Nil => { front: reverse_stack(q.back), back: Stack::Nil }
    _ => q
  }
}

///|
/// Enqueue a value and return the new queue.
pub fn[T] enqueue(q : Queue[T], value : T) -> Queue[T] {
  { front: q.front, back: Stack::Cons(head=value, tail=q.back) }
}

///|
/// Peek the front value without removing it.
pub fn[T] peek(q : Queue[T]) -> T? {
  let norm = normalize(q)
  match norm.front {
    Stack::Nil => None
    Stack::Cons(head~, tail=_) => Some(head)
  }
}

///|
/// Dequeue the front value and return (value, rest), or None if empty.
pub fn[T] dequeue(q : Queue[T]) -> (T, Queue[T])? {
  let norm = normalize(q)
  match norm.front {
    Stack::Nil => None
    Stack::Cons(head~, tail~) => Some((head, { front: tail, back: norm.back }))
  }
}
