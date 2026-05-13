// ============================================================================
// Challenge: Persistent Stack
// Immutable stack with array conversions
// ============================================================================

///|
/// Persistent stack: an immutable last-in-first-out sequence.
///
/// Represented as a cons list, so `push` and `pop` run in `O(1)` and
/// produce new stacks that share their tail with the previous version
/// rather than mutating it. `peek` inspects the top without copying,
/// `size` is `O(n)`, and `from_array`/`to_array` convert with the
/// array's first element kept at the top. Build with `empty` or
/// `from_array`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let s = @challenge_persistent_stack.empty()
///   let s1 = @challenge_persistent_stack.push(s, 1)
///   let s2 = @challenge_persistent_stack.push(s1, 2)
///   assert_eq(@challenge_persistent_stack.peek(s2), Some(2))
///   assert_eq(@challenge_persistent_stack.peek(s1), Some(1))
/// }
/// ```
pub enum Stack[T] {
  Nil
  Cons(head~ : T, tail~ : Stack[T])
} derive(Debug)

///|
/// Create an empty persistent stack.
pub fn[T] empty() -> Stack[T] {
  Nil
}

///|
/// Return true if the stack is empty.
pub fn[T] is_empty(s : Stack[T]) -> Bool {
  s is Nil
}

///|
/// Push a value onto the stack and return the new stack.
pub fn[T] push(s : Stack[T], value : T) -> Stack[T] {
  Cons(head=value, tail=s)
}

///|
/// Pop the top element and return (value, rest), or None if empty.
pub fn[T] pop(s : Stack[T]) -> (T, Stack[T])? {
  match s {
    Nil => None
    Cons(head~, tail~) => Some((head, tail))
  }
}

///|
/// Peek the top element without removing it.
pub fn[T] peek(s : Stack[T]) -> T? {
  match s {
    Nil => None
    Cons(head~, tail=_) => Some(head)
  }
}

///|
/// Return the number of elements in the stack.
pub fn[T] size(s : Stack[T]) -> Int {
  match s {
    Nil => 0
    Cons(head=_, tail~) => 1 + size(tail)
  }
}

///|
/// Build a stack that preserves array order (top is arr[0]).
pub fn[T] from_array(arr : ArrayView[T]) -> Stack[T] {
  arr.rev_fold(init=Nil, (st, value) => Cons(head=value, tail=st))
}

///|
/// Convert a stack to an array in top-to-bottom order.
pub fn[T] to_array(s : Stack[T]) -> Array[T] {
  let out = Array::new()
  fill_to_array(s, out)
  out
}

///|
fn[T] fill_to_array(cur : Stack[T], out : Array[T]) -> Unit {
  match cur {
    Nil => ()
    Cons(head~, tail~) => {
      out.push(head)
      fill_to_array(tail, out)
    }
  }
}
