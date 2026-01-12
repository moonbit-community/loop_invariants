// ============================================================================
// Challenge: Persistent Min-Queue
// Two min-stacks track queue minimums immutably
// ============================================================================

///|
enum MinStack {
  Nil
  Cons(value~ : Int, min~ : Int, tail~ : MinStack)
} derive(Show)

///|
pub struct MinQueue {
  front : MinStack
  back : MinStack
} derive(Show)

///|
/// Create an empty min-queue.
pub fn empty() -> MinQueue {
  { front: MinStack::Nil, back: MinStack::Nil }
}

///|
fn size_stack(s : MinStack) -> Int {
  match s {
    MinStack::Nil => 0
    MinStack::Cons(value=_, min=_, tail~) => 1 + size_stack(tail)
  }
}

///|
/// Return the number of elements in the queue.
pub fn size(q : MinQueue) -> Int {
  size_stack(q.front) + size_stack(q.back)
}

///|
fn min_value(s : MinStack) -> Int? {
  match s {
    MinStack::Nil => None
    MinStack::Cons(value=_, min~, tail=_) => Some(min)
  }
}

///|
fn push(s : MinStack, value : Int) -> MinStack {
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

///|
#warnings("+missing_invariant+missing_reasoning")
fn reverse_stack(s : MinStack) -> MinStack {
  for cur = s, rev = MinStack::Nil {
    match cur {
      MinStack::Nil => break rev
      MinStack::Cons(value~, min=_, tail~) => continue tail, push(rev, value)
    }
  } where {
    invariant: size_stack(cur) + size_stack(rev) == size_stack(s),
    reasoning: (
      #|INVARIANT (Reversal with min):
      #|rev is the reverse of the processed prefix; cur holds the remainder.
      #|Each push recomputes the min for rev, preserving min correctness.
      #|MAINTENANCE:
      #|Move value from cur to rev, preserving total size and order reversal.
      #|TERMINATION:
      #|When cur is Nil, rev is the fully reversed stack.
    ),
  }
}

///|
fn normalize(q : MinQueue) -> MinQueue {
  match q.front {
    MinStack::Nil => { front: reverse_stack(q.back), back: MinStack::Nil }
    _ => q
  }
}

///|
/// Enqueue a value and return the new queue.
pub fn enqueue(q : MinQueue, value : Int) -> MinQueue {
  { front: q.front, back: push(q.back, value) }
}

///|
/// Peek the front value without removing it.
pub fn peek(q : MinQueue) -> Int? {
  let norm = normalize(q)
  match norm.front {
    MinStack::Nil => None
    MinStack::Cons(value~, min=_, tail=_) => Some(value)
  }
}

///|
/// Dequeue the front value and return (value, rest), or None if empty.
pub fn dequeue(q : MinQueue) -> (Int, MinQueue)? {
  let norm = normalize(q)
  match norm.front {
    MinStack::Nil => None
    MinStack::Cons(value~, min=_, tail~) =>
      Some((value, { front: tail, back: norm.back }))
  }
}

///|
/// Return the minimum value in the queue, or None if empty.
pub fn min_queue(q : MinQueue) -> Int? {
  match (min_value(q.front), min_value(q.back)) {
    (None, None) => None
    (Some(x), None) => Some(x)
    (None, Some(y)) => Some(y)
    (Some(x), Some(y)) => Some(if x < y { x } else { y })
  }
}

///|
test "persistent_queue_min" {
  let q0 = empty()
  let q1 = enqueue(q0, 5)
  let q2 = enqueue(q1, 2)
  let q3 = enqueue(q2, 7)
  assert_eq(peek(q3), Some(5))
  assert_eq(min_queue(q3), Some(2))
  guard dequeue(q3) is Some((5, q4)) else { fail("expected dequeue") }
  assert_eq(min_queue(q4), Some(2))
  guard dequeue(q4) is Some((2, q5)) else { fail("expected dequeue") }
  assert_eq(min_queue(q5), Some(7))
  assert_eq(size(q5), 1)
}
