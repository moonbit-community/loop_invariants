// ============================================================================
// Challenge: Persistent Rope
// Immutable concatenation tree for strings
// ============================================================================

///|
pub enum Rope {
  Empty
  Leaf(value~ : String)
  Node(len~ : Int, left~ : Rope, right~ : Rope)
} derive(Debug)

///|
/// Create an empty rope.
pub fn empty() -> Rope {
  Empty
}

///|
/// Create a leaf rope from a string.
pub fn leaf(value : String) -> Rope {
  Leaf(value~)
}

///|
/// Return the total length of the rope.
pub fn length(r : Rope) -> Int {
  match r {
    Empty => 0
    Leaf(value~) => value.length()
    Node(len~, left=_, right=_) => len
  }
}

///|
/// Concatenate two ropes and return the result.
pub fn concat(a : Rope, b : Rope) -> Rope {
  match (a, b) {
    (Empty, _) => b
    (_, Empty) => a
    _ => Node(len=length(a) + length(b), left=a, right=b)
  }
}

///|
/// Convert the rope to a flat string.
pub fn to_string(r : Rope) -> String {
  match r {
    Empty => ""
    Leaf(value~) => value
    Node(left~, right~, len=_) => to_string(left) + to_string(right)
  }
}

///|

///|
/// Concatenate a list of ropes in order.
pub fn concat_many(ropes : ArrayView[Rope]) -> Rope {
  for r in ropes; acc = Empty {
    continue concat(acc, r)
  } nobreak {
    acc
  }
}
