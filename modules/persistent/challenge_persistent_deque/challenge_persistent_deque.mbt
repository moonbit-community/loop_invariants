// ============================================================================
// Challenge: Persistent Deque
// Two-stack deque with normalization by reversal
// ============================================================================

///|
enum Stack[T] {
  Nil
  Cons(head~ : T, tail~ : Stack[T])
} derive(Debug)

///|
/// A persistent double-ended queue of values of type `T`, implemented as
/// a pair of immutable stacks (`front` and `back`).
///
/// `push_front` and `push_back` prepend to the appropriate stack in
/// `O(1)`; when one side becomes empty, the other is reversed to
/// normalize, giving `O(n)` worst-case but `O(1)` amortized cost per
/// `pop_front`/`pop_back`/`peek_front`/`peek_back`. Each operation
/// returns a new deque that shares the unchanged stack with the source.
/// See `empty`, `push_front`, `push_back`, `peek_front`, `peek_back`,
/// `pop_front`, `pop_back`, and `size`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let d = @challenge_persistent_deque.empty()
///   let d = @challenge_persistent_deque.push_back(d, 1)
///   let d = @challenge_persistent_deque.push_back(d, 2)
///   let d = @challenge_persistent_deque.push_front(d, 0)
///   assert_eq(@challenge_persistent_deque.peek_front(d), Some(0))
///   assert_eq(@challenge_persistent_deque.peek_back(d), Some(2))
/// }
/// ```
pub struct Deque[T] {
  front : Stack[T]
  back : Stack[T]
} derive(Debug)

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
