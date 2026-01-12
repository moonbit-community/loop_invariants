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
#warnings("+missing_invariant+missing_reasoning")
pub fn[T] from_array(arr : ArrayView[T]) -> Stack[T] {
  let n = arr.length()
  for i = n, st = Stack::Nil {
    if i <= 0 {
      break st
    } else {
      let next_i = i - 1
      continue next_i, Stack::Cons(head=arr[next_i], tail=st)
    }
  } where {
    invariant: i >= 0 && i <= n,
    invariant: size(st) == n - i,
    reasoning: (
      #|INVARIANT (Suffix stack):
      #|st stores arr[i..n) in order, so its size is n - i.
      #|MAINTENANCE:
      #|Decrement i and cons arr[i-1]; this extends st with the next element.
      #|TERMINATION:
      #|At i = 0, st represents the entire array in stack order.
    ),
  }
}

///|
/// Convert a stack to an array in top-to-bottom order.
#warnings("+missing_invariant+missing_reasoning")
pub fn[T] to_array(s : Stack[T]) -> Array[T] {
  let out = Array::new()
  for cur = s, idx = 0 {
    match cur {
      Stack::Nil => break out
      Stack::Cons(head~, tail~) => {
        out.push(head)
        continue tail, idx + 1
      }
    }
  } where {
    invariant: idx >= 0 && idx == out.length(),
    invariant: idx + size(cur) == size(s),
    reasoning: (
      #|INVARIANT (Prefix materialization):
      #|out contains the first idx elements of s in order; cur holds the rest.
      #|MAINTENANCE:
      #|Append head to out and advance cur, increasing idx by one.
      #|TERMINATION:
      #|When cur is Nil, out is the full stack materialization.
    ),
  }
}

///|
test "persistent_stack" {
  let s0 : Stack[Int] = empty()
  let s1 = push(s0, 1)
  let s2 = push(s1, 2)
  assert_eq(is_empty(s0), true)
  assert_eq(to_array(s0), [])
  assert_eq(to_array(s1), [1])
  assert_eq(to_array(s2), [2, 1])
  let built = from_array([1, 2, 3][:])
  assert_eq(to_array(built), [1, 2, 3])
  guard pop(s2) is Some((2, s1b)) else { fail("expected pop") }
  assert_eq(to_array(s1b), [1])
  assert_eq(peek(s1b), Some(1))
}
