// ============================================================================
// Challenge: Persistent Min-Stack
// Each node stores the minimum of its suffix
// ============================================================================

///|
pub enum MinStack[T] {
  Nil
  Cons(value~ : T, min~ : T, tail~ : MinStack[T])
} derive(Show)

///|
/// Create an empty min-stack.
pub fn[T] empty() -> MinStack[T] {
  MinStack::Nil
}

///|
/// Return the number of elements in the stack.
pub fn[T] size(s : MinStack[T]) -> Int {
  match s {
    MinStack::Nil => 0
    MinStack::Cons(value=_, min=_, tail~) => 1 + size(tail)
  }
}

///|
/// Return the minimum value, or None if empty.
pub fn[T] min_value(s : MinStack[T]) -> T? {
  match s {
    MinStack::Nil => None
    MinStack::Cons(value=_, min~, tail=_) => Some(min)
  }
}

///|
/// Push a value and return the new stack with updated minimum.
pub fn[T : Compare] push(s : MinStack[T], value : T) -> MinStack[T] {
  let new_min = match s {
    MinStack::Nil => value
    MinStack::Cons(value=_, min~, tail=_) =>
      if value < min {
        value
      } else {
        min
      }
  }
  MinStack::Cons(value~, min=new_min, tail=s)
}

///|
/// Pop the top value and return (value, rest), or None if empty.
pub fn[T] pop(s : MinStack[T]) -> (T, MinStack[T])? {
  match s {
    MinStack::Nil => None
    MinStack::Cons(value~, min=_, tail~) => Some((value, tail))
  }
}

///|

///|
/// Build a min-stack that preserves array order (top is arr[0]).
pub fn[T : Compare] from_array(arr : ArrayView[T]) -> MinStack[T] {
  arr.rev_fold(init=MinStack::Nil, (st, value) => push(st, value))
}
