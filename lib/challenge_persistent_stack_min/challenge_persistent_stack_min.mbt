// ============================================================================
// Challenge: Persistent Min-Stack
// Each node stores the minimum of its suffix
// ============================================================================

///|
pub enum MinStack {
  Nil
  Cons(value~ : Int, min~ : Int, tail~ : MinStack)
} derive(Show)

///|
/// Create an empty min-stack.
pub fn empty() -> MinStack {
  MinStack::Nil
}

///|
/// Return the number of elements in the stack.
pub fn size(s : MinStack) -> Int {
  match s {
    MinStack::Nil => 0
    MinStack::Cons(value=_, min=_, tail~) => 1 + size(tail)
  }
}

///|
/// Return the minimum value, or None if empty.
pub fn min_value(s : MinStack) -> Int? {
  match s {
    MinStack::Nil => None
    MinStack::Cons(value=_, min~, tail=_) => Some(min)
  }
}

///|
/// Push a value and return the new stack with updated minimum.
pub fn push(s : MinStack, value : Int) -> MinStack {
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
pub fn pop(s : MinStack) -> (Int, MinStack)? {
  match s {
    MinStack::Nil => None
    MinStack::Cons(value~, min=_, tail~) => Some((value, tail))
  }
}

///|
fn min_suffix(arr : ArrayView[Int], i : Int) -> Int? {
  if i >= arr.length() {
    None
  } else {
    let tail = min_suffix(arr, i + 1)
    match tail {
      None => Some(arr[i])
      Some(m) => Some(if arr[i] < m { arr[i] } else { m })
    }
  }
}

///|
/// Build a min-stack that preserves array order (top is arr[0]).
#warnings("+missing_invariant+missing_reasoning")
pub fn from_array(arr : ArrayView[Int]) -> MinStack {
  let n = arr.length()
  for i = n, st = MinStack::Nil {
    if i <= 0 {
      break st
    } else {
      let next_i = i - 1
      continue next_i, push(st, arr[next_i])
    }
  } where {
    invariant: i >= 0 && i <= n,
    invariant: size(st) == n - i,
    invariant: min_value(st) == min_suffix(arr, i),
    reasoning: (
      #|INVARIANT (Min stack suffix):
      #|st stores arr[i..n) in order, and its top min equals min(arr[i..n)).
      #|MAINTENANCE:
      #|Push arr[i-1], updating the stored min with min(value, previous min).
      #|TERMINATION:
      #|At i = 0, st represents the whole array with correct minima.
    ),
  }
}

///|
test "persistent_stack_min" {
  let s0 = empty()
  let s1 = push(s0, 5)
  let s2 = push(s1, 3)
  let s3 = push(s2, 7)
  assert_eq(min_value(s0), None)
  assert_eq(min_value(s1), Some(5))
  assert_eq(min_value(s2), Some(3))
  assert_eq(min_value(s3), Some(3))
  let built = from_array([5, 3, 7][:])
  assert_eq(min_value(built), Some(3))
  guard pop(s3) is Some((7, s2b)) else { fail("expected pop") }
  assert_eq(min_value(s2b), Some(3))
}
