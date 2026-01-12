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
    Stack::Nil => 0
    Stack::Cons(head=_, tail~) => 1 + size_stack(tail)
  }
}

///|
/// Return the number of elements in the deque.
pub fn[T] size(d : Deque[T]) -> Int {
  size_stack(d.front) + size_stack(d.back)
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn[T] reverse_stack(s : Stack[T]) -> Stack[T] {
  for cur = s, rev = Stack::Nil {
    match cur {
      Stack::Nil => break rev
      Stack::Cons(head~, tail~) => continue tail, Stack::Cons(head~, tail=rev)
    }
  } where {
    invariant: size_stack(cur) + size_stack(rev) == size_stack(s),
    reasoning: (
      #|INVARIANT (Reverse stack):
      #|rev is the reverse of the processed prefix; cur holds the remainder.
      #|MAINTENANCE:
      #|Move head from cur to rev, preserving the size split.
      #|TERMINATION:
      #|When cur is Nil, rev is the reverse of s.
    ),
  }
}

///|
fn[T] normalize_front(d : Deque[T]) -> Deque[T] {
  match d.front {
    Stack::Nil => { front: reverse_stack(d.back), back: Stack::Nil }
    _ => d
  }
}

///|
fn[T] normalize_back(d : Deque[T]) -> Deque[T] {
  match d.back {
    Stack::Nil => { front: Stack::Nil, back: reverse_stack(d.front) }
    _ => d
  }
}

///|
/// Create an empty persistent deque.
pub fn[T] empty() -> Deque[T] {
  { front: Stack::Nil, back: Stack::Nil }
}

///|
/// Push a value to the front and return the new deque.
pub fn[T] push_front(d : Deque[T], value : T) -> Deque[T] {
  { front: Stack::Cons(head=value, tail=d.front), back: d.back }
}

///|
/// Push a value to the back and return the new deque.
pub fn[T] push_back(d : Deque[T], value : T) -> Deque[T] {
  { front: d.front, back: Stack::Cons(head=value, tail=d.back) }
}

///|
/// Peek the front value without removing it.
pub fn[T] peek_front(d : Deque[T]) -> T? {
  let norm = normalize_front(d)
  match norm.front {
    Stack::Nil => None
    Stack::Cons(head~, tail=_) => Some(head)
  }
}

///|
/// Peek the back value without removing it.
pub fn[T] peek_back(d : Deque[T]) -> T? {
  let norm = normalize_back(d)
  match norm.back {
    Stack::Nil => None
    Stack::Cons(head~, tail=_) => Some(head)
  }
}

///|
/// Pop the front value and return (value, rest), or None if empty.
pub fn[T] pop_front(d : Deque[T]) -> (T, Deque[T])? {
  let norm = normalize_front(d)
  match norm.front {
    Stack::Nil => None
    Stack::Cons(head~, tail~) => Some((head, { front: tail, back: norm.back }))
  }
}

///|
/// Pop the back value and return (value, rest), or None if empty.
pub fn[T] pop_back(d : Deque[T]) -> (T, Deque[T])? {
  let norm = normalize_back(d)
  match norm.back {
    Stack::Nil => None
    Stack::Cons(head~, tail~) => Some((head, { front: norm.front, back: tail }))
  }
}

///|
test "persistent_deque" {
  let d0 : Deque[Int] = empty()
  let d1 = push_front(d0, 1)
  let d2 = push_back(d1, 2)
  let d3 = push_front(d2, 0)
  assert_eq(peek_front(d3), Some(0))
  assert_eq(peek_back(d3), Some(2))
  guard pop_front(d3) is Some((0, d4)) else { fail("expected pop_front") }
  guard pop_back(d4) is Some((2, d5)) else { fail("expected pop_back") }
  assert_eq(peek_front(d5), Some(1))
  assert_eq(size(d5), 1)
}
