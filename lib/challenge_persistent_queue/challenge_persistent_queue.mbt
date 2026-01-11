// ============================================================================
// Challenge: Persistent Queue
// Two-stack queue with immutable reversal
// ============================================================================

///|
enum Stack[T] {
  Nil
  Cons(head~ : T, tail~ : Stack[T])
} derive(Show)

///|
struct Queue[T] {
  front : Stack[T]
  back : Stack[T]
} derive(Show)

///|
fn[T] empty() -> Queue[T] {
  { front: Stack::Nil, back: Stack::Nil }
}

///|
fn[T] size_stack(s : Stack[T]) -> Int {
  match s {
    Stack::Nil => 0
    Stack::Cons(head=_, tail~) => 1 + size_stack(tail)
  }
}

///|
fn[T] size(q : Queue[T]) -> Int {
  size_stack(q.front) + size_stack(q.back)
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
      #|INVARIANT (Reversal progress):
      #|rev is the reverse of the processed prefix; cur holds the remainder.
      #|MAINTENANCE:
      #|Move head from cur to rev, preserving the size split and reverse order.
      #|TERMINATION:
      #|When cur is Nil, rev is the full reverse of s.
    ),
  }
}

///|
fn[T] normalize(q : Queue[T]) -> Queue[T] {
  match q.front {
    Stack::Nil => { front: reverse_stack(q.back), back: Stack::Nil }
    _ => q
  }
}

///|
fn[T] enqueue(q : Queue[T], value : T) -> Queue[T] {
  { front: q.front, back: Stack::Cons(head=value, tail=q.back) }
}

///|
fn[T] peek(q : Queue[T]) -> T? {
  let norm = normalize(q)
  match norm.front {
    Stack::Nil => None
    Stack::Cons(head~, tail=_) => Some(head)
  }
}

///|
fn[T] dequeue(q : Queue[T]) -> (T, Queue[T])? {
  let norm = normalize(q)
  match norm.front {
    Stack::Nil => None
    Stack::Cons(head~, tail~) => Some((head, { front: tail, back: norm.back }))
  }
}

///|
test "persistent_queue" {
  let q0 : Queue[Int] = empty()
  let q1 = enqueue(q0, 1)
  let q2 = enqueue(q1, 2)
  let q3 = enqueue(q2, 3)
  assert_eq(peek(q3), Some(1))
  guard dequeue(q3) is Some((1, q4)) else { fail("expected dequeue") }
  assert_eq(peek(q4), Some(2))
  assert_eq(size(q4), 2)
  assert_eq(peek(q2), Some(1))
}
