// ============================================================================
// Challenge: Persistent Deque
// Two-stack deque with normalization by reversal
// ============================================================================

///|
enum Stack[T] {
  Nil
  Cons(head~ : T, tail~ : Stack[T])
} derive(Show)

///|
pub struct Deque[T] {
  front : Stack[T]
  back : Stack[T]
} derive(Show)

///|
fn[T] size_stack(s : Stack[T]) -> Int {
  match s {
    Nil => 0
    Cons(head=_, tail~) => 1 + size_stack(tail)
  }
}

///|
/// Return the number of elements in the deque.
pub fn[T] size(d : Deque[T]) -> Int {
  size_stack(d.front) + size_stack(d.back)
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
fn[T] normalize_front(d : Deque[T]) -> Deque[T] {
  match d.front {
    Nil => { front: reverse_stack(d.back), back: Nil }
    _ => d
  }
}

///|
fn[T] normalize_back(d : Deque[T]) -> Deque[T] {
  match d.back {
    Nil => { front: Nil, back: reverse_stack(d.front) }
    _ => d
  }
}

///|
/// Create an empty persistent deque.
pub fn[T] empty() -> Deque[T] {
  { front: Nil, back: Nil }
}

///|
/// Push a value to the front and return the new deque.
pub fn[T] push_front(d : Deque[T], value : T) -> Deque[T] {
  { front: Cons(head=value, tail=d.front), back: d.back }
}

///|
/// Push a value to the back and return the new deque.
pub fn[T] push_back(d : Deque[T], value : T) -> Deque[T] {
  { front: d.front, back: Cons(head=value, tail=d.back) }
}

///|
/// Peek the front value without removing it.
pub fn[T] peek_front(d : Deque[T]) -> T? {
  let norm = normalize_front(d)
  match norm.front {
    Nil => None
    Cons(head~, tail=_) => Some(head)
  }
}

///|
/// Peek the back value without removing it.
pub fn[T] peek_back(d : Deque[T]) -> T? {
  let norm = normalize_back(d)
  match norm.back {
    Nil => None
    Cons(head~, tail=_) => Some(head)
  }
}

///|
/// Pop the front value and return (value, rest), or None if empty.
pub fn[T] pop_front(d : Deque[T]) -> (T, Deque[T])? {
  let norm = normalize_front(d)
  match norm.front {
    Nil => None
    Cons(head~, tail~) => Some((head, { front: tail, back: norm.back }))
  }
}

///|
/// Pop the back value and return (value, rest), or None if empty.
pub fn[T] pop_back(d : Deque[T]) -> (T, Deque[T])? {
  let norm = normalize_back(d)
  match norm.back {
    Nil => None
    Cons(head~, tail~) => Some((head, { front: norm.front, back: tail }))
  }
}
