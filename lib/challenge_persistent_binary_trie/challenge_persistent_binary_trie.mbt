// ============================================================================
// Challenge: Persistent Binary Trie
// Path-copying trie for max-xor queries
// ============================================================================

///|
pub enum Node {
  Empty
  Node(count~ : Int, zero~ : Node, one~ : Node)
} derive(Show)

///|
/// Create an empty binary trie.
pub fn empty() -> Node {
  Node::Empty
}

///|
/// Return the number of values stored in the trie.
pub fn count(node : Node) -> Int {
  match node {
    Node::Empty => 0
    Node::Node(count~, zero=_, one=_) => count
  }
}

///|
/// Insert a value and return the new trie.
pub fn insert(node : Node, value : Int, bit : Int) -> Node {
  if bit < 0 {
    match node {
      Node::Empty => Node::Node(count=1, zero=Node::Empty, one=Node::Empty)
      Node::Node(count=c, zero=z, one=o) =>
        Node::Node(count=c + 1, zero=z, one=o)
    }
  } else {
    let b = (value >> bit) & 1
    match node {
      Node::Empty =>
        if b == 0 {
          Node::Node(
            count=1,
            zero=insert(Node::Empty, value, bit - 1),
            one=Node::Empty,
          )
        } else {
          Node::Node(
            count=1,
            zero=Node::Empty,
            one=insert(Node::Empty, value, bit - 1),
          )
        }
      Node::Node(count=c, zero=z, one=o) =>
        if b == 0 {
          Node::Node(count=c + 1, zero=insert(z, value, bit - 1), one=o)
        } else {
          Node::Node(count=c + 1, zero=z, one=insert(o, value, bit - 1))
        }
    }
  }
}

///|
/// Query the maximum xor with value (assumes trie is non-empty).
#warnings("+missing_invariant+missing_reasoning")
pub fn max_xor(root : Node, value : Int, max_bit : Int) -> Int {
  for bit = max_bit, cur = root, acc = 0 {
    match cur {
      Node::Empty => break acc
      Node::Node(count=_, zero=z, one=o) => {
        let b = (value >> bit) & 1
        if b == 0 {
          if count(o) > 0 {
            continue bit - 1, o, acc | (1 << bit)
          } else {
            continue bit - 1, z, acc
          }
        } else if count(z) > 0 {
          continue bit - 1, z, acc | (1 << bit)
        } else {
          continue bit - 1, o, acc
        }
      }
    }
  } where {
    invariant: bit >= -1 && bit <= max_bit,
    invariant: count(cur) >= 0,
    reasoning: (
      #|INVARIANT (Xor walk):
      #|acc is the xor value determined by the chosen prefix; cur is the
      #|subtrie for the remaining bits.
      #|MAINTENANCE:
      #|Choose the opposite bit when possible to maximize xor at this position.
      #|TERMINATION:
      #|After the last bit, acc is the maximum xor achievable in the trie.
    ),
  }
}
