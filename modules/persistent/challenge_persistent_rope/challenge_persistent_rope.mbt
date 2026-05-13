// ============================================================================
// Challenge: Persistent Rope
// Immutable concatenation tree for strings
// ============================================================================

///|
/// Persistent rope: an immutable concatenation tree of strings.
///
/// A `Leaf` wraps a `String`; an internal `Node` stores its cached
/// total `len` along with `left` and `right` subropes. `concat` glues
/// two ropes in `O(1)` by building a single internal node, so building
/// a long rope by repeated concatenation never copies the underlying
/// strings. `length` is `O(1)` via the cached length. `to_string`
/// flattens the rope in `O(n)`. Because nodes are never mutated,
/// older ropes remain valid after any operation. See `empty`, `leaf`,
/// `concat_many`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let a = @challenge_persistent_rope.leaf("Hello, ")
///   let b = @challenge_persistent_rope.leaf("world!")
///   let r = @challenge_persistent_rope.concat(a, b)
///   @debug.assert_eq(@challenge_persistent_rope.to_string(r), "Hello, world!")
///   @debug.assert_eq(@challenge_persistent_rope.length(r), 13)
/// }
/// ```
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
