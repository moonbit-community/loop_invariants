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
/// Create an empty rope.
pub fn empty() -> Rope {
  Rope::Empty
}

///|
/// Create a leaf rope from a string.
pub fn leaf(value : String) -> Rope {
  Rope::Leaf(value~)
}

///|
/// Return the total length of the rope.
pub fn length(r : Rope) -> Int {
  match r {
    Rope::Empty => 0
    Rope::Leaf(value~) => value.length()
    Rope::Node(len~, left=_, right=_) => len
  }
}

///|
/// Concatenate two ropes and return the result.
pub fn concat(a : Rope, b : Rope) -> Rope {
  match (a, b) {
    (Rope::Empty, _) => b
    (_, Rope::Empty) => a
    _ => Rope::Node(len=length(a) + length(b), left=a, right=b)
  }
}

///|
/// Convert the rope to a flat string.
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
