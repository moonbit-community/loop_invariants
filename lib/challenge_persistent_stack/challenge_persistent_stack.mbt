// ============================================================================
// Challenge: Persistent Stack
// Immutable stack with array conversions
// ============================================================================

///|
pub enum Stack[T] {
  Nil
  Cons(head~ : T, tail~ : Stack[T])
} derive(Show)

///|
/// Create an empty persistent stack.
pub fn[T] empty() -> Stack[T] {
  Stack::Nil
}

///|
/// Return true if the stack is empty.
pub fn[T] is_empty(s : Stack[T]) -> Bool {
  s is Stack::Nil
}

///|
/// Push a value onto the stack and return the new stack.
pub fn[T] push(s : Stack[T], value : T) -> Stack[T] {
  Stack::Cons(head=value, tail=s)
}

///|
/// Pop the top element and return (value, rest), or None if empty.
pub fn[T] pop(s : Stack[T]) -> (T, Stack[T])? {
  match s {
    Stack::Nil => None
    Stack::Cons(head~, tail~) => Some((head, tail))
  }
}

///|
/// Peek the top element without removing it.
pub fn[T] peek(s : Stack[T]) -> T? {
  match s {
    Stack::Nil => None
    Stack::Cons(head~, tail=_) => Some(head)
  }
}

///|
/// Return the number of elements in the stack.
pub fn[T] size(s : Stack[T]) -> Int {
  match s {
    Stack::Nil => 0
    Stack::Cons(head=_, tail~) => 1 + size(tail)
  }
}

///|
/// Build a stack that preserves array order (top is arr[0]).
pub fn[T] from_array(arr : ArrayView[T]) -> Stack[T] {
  arr.rev_fold(init=Stack::Nil, (st, value) => Stack::Cons(head=value, tail=st))
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
    Stack::Nil => ()
    Stack::Cons(head~, tail~) => {
      out.push(head)
      fill_to_array(tail, out)
    }
  }
}
