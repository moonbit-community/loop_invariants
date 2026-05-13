// ============================================================================
// Challenge: Persistent Min-Stack
// Each node stores the minimum of its suffix
// ============================================================================

///|
/// Persistent min-stack: a stack that exposes its minimum in `O(1)`.
///
/// Each cons cell caches the minimum element of the suffix rooted at
/// that node, so `min_value` is a constant-time field lookup rather
/// than a linear scan. `push` computes the new minimum from the
/// incoming value and the previous cached minimum, while `pop`
/// returns the prior suffix unchanged, so both run in `O(1)` and
/// share their tail with the older version. Build with `empty` or
/// `from_array`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let s = @challenge_persistent_stack_min.empty()
///   let s = @challenge_persistent_stack_min.push(s, 3)
///   let s = @challenge_persistent_stack_min.push(s, 1)
///   let s = @challenge_persistent_stack_min.push(s, 2)
///   @debug.assert_eq(@challenge_persistent_stack_min.min_value(s), Some(1))
/// }
/// ```
pub enum MinStack[T] {
  Nil
  Cons(value~ : T, min~ : T, tail~ : MinStack[T])
} derive(Debug)

///|
/// Create an empty min-stack.
pub fn[T] empty() -> MinStack[T] {
  Nil
}

///|
/// Return the number of elements in the stack.
pub fn[T] size(s : MinStack[T]) -> Int {
  match s {
    Nil => 0
    Cons(value=_, min=_, tail~) => 1 + size(tail)
  }
}

///|
/// Return the minimum value, or None if empty.
pub fn[T] min_value(s : MinStack[T]) -> T? {
  match s {
    Nil => None
    Cons(value=_, min~, tail=_) => Some(min)
  }
}

///|
/// Push a value and return the new stack with updated minimum.
pub fn[T : Compare] push(s : MinStack[T], value : T) -> MinStack[T] {
  let new_min = match s {
    Nil => value
    Cons(value=_, min~, tail=_) => if value < min { value } else { min }
  }
  Cons(value~, min=new_min, tail=s)
}

///|
/// Pop the top value and return (value, rest), or None if empty.
pub fn[T] pop(s : MinStack[T]) -> (T, MinStack[T])? {
  match s {
    Nil => None
    Cons(value~, min=_, tail~) => Some((value, tail))
  }
}

///|

///|
/// Build a min-stack that preserves array order (top is arr[0]).
pub fn[T : Compare] from_array(arr : ArrayView[T]) -> MinStack[T] {
  arr.rev_fold(init=Nil, (st, value) => push(st, value))
}
