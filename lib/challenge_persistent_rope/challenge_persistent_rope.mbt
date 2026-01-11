// ============================================================================
// Challenge: Persistent Rope
// Immutable concatenation tree for strings
// ============================================================================

///|
pub enum Rope {
  Empty
  Leaf(value~ : String)
  Node(len~ : Int, left~ : Rope, right~ : Rope)
} derive(Show)

///|
pub fn empty() -> Rope {
  Rope::Empty
}

///|
pub fn leaf(value : String) -> Rope {
  Rope::Leaf(value~)
}

///|
pub fn length(r : Rope) -> Int {
  match r {
    Rope::Empty => 0
    Rope::Leaf(value~) => value.length()
    Rope::Node(len~, left=_, right=_) => len
  }
}

///|
pub fn concat(a : Rope, b : Rope) -> Rope {
  match (a, b) {
    (Rope::Empty, _) => b
    (_, Rope::Empty) => a
    _ => Rope::Node(len=length(a) + length(b), left=a, right=b)
  }
}

///|
pub fn to_string(r : Rope) -> String {
  match r {
    Rope::Empty => ""
    Rope::Leaf(value~) => value
    Rope::Node(left~, right~, len=_) => to_string(left) + to_string(right)
  }
}

///|
fn prefix_length(ropes : ArrayView[Rope], n : Int) -> Int {
  if n <= 0 {
    0
  } else {
    prefix_length(ropes, n - 1) + length(ropes[n - 1])
  }
}

///|
/// Concatenate a list of ropes in order.
#warnings("+missing_invariant+missing_reasoning")
pub fn concat_many(ropes : ArrayView[Rope]) -> Rope {
  let n = ropes.length()
  for i = 0, acc = Rope::Empty {
    if i >= n {
      break acc
    } else {
      continue i + 1, concat(acc, ropes[i])
    }
  } where {
    invariant: i >= 0 && i <= n,
    invariant: length(acc) == prefix_length(ropes, i),
    reasoning: (
      #|INVARIANT (Rope fold):
      #|acc equals the concatenation of the first i ropes in order.
      #|MAINTENANCE:
      #|Append ropes[i] to acc, preserving order and total length.
      #|TERMINATION:
      #|At i = n, acc is the full concatenation.
    ),
  }
}

///|
test "persistent_rope" {
  let r1 = Rope::Leaf(value="hello")
  let r2 = Rope::Leaf(value=" ")
  let r3 = Rope::Leaf(value="world")
  let rope = concat_many([r1, r2, r3][:])
  assert_eq(to_string(rope), "hello world")
  assert_eq(length(rope), 11)
}
