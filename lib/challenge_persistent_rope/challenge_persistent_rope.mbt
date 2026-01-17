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

///|
/// Concatenate a list of ropes in order.
pub fn concat_many(ropes : ArrayView[Rope]) -> Rope {
  let mut acc = Rope::Empty
  for r in ropes {
    acc = concat(acc, r)
  }
  acc
}
