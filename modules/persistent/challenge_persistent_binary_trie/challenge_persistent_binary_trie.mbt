// ============================================================================
// Challenge: Persistent Binary Trie
// Path-copying trie for max-xor queries
// ============================================================================

///|
/// A persistent binary trie indexed by bits of non-negative integers,
/// designed for maximum-XOR queries.
///
/// Each node stores a `count` of values that pass through it plus children
/// for the `0` and `1` bit; `insert` walks from the most significant bit
/// to the least, copying just the nodes on the inserted path so older
/// versions remain valid. `insert` and `max_xor` run in
/// `O(max_bit)` time and copy `O(max_bit)` nodes per update. See
/// `empty`, `insert`, `count`, and `max_xor`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let t0 = @challenge_persistent_binary_trie.empty()
///   let t1 = @challenge_persistent_binary_trie.insert(t0, 0b0101, 4)
///   let t2 = @challenge_persistent_binary_trie.insert(t1, 0b1100, 4)
///   assert_eq(@challenge_persistent_binary_trie.max_xor(t2, 0b0011, 4), 0b1111)
/// }
/// ```
pub enum Node {
  Empty
  Node(count~ : Int, zero~ : Node, one~ : Node)
} derive(Debug)

///|
/// Create an empty binary trie.
pub fn empty() -> Node {
  Empty
}

///|
/// Return the number of values stored in the trie.
pub fn count(node : Node) -> Int {
  match node {
    Empty => 0
    Node(count~, zero=_, one=_) => count
  }
}

///|
/// Insert a value and return the new trie.
pub fn insert(node : Node, value : Int, bit : Int) -> Node {
  if bit < 0 {
    match node {
      Empty => Node(count=1, zero=Empty, one=Empty)
      Node(count=c, zero=z, one=o) => Node(count=c + 1, zero=z, one=o)
    }
  } else {
    let b = (value >> bit) & 1
    match node {
      Empty =>
        if b == 0 {
          Node(count=1, zero=insert(Empty, value, bit - 1), one=Empty)
        } else {
          Node(count=1, zero=Empty, one=insert(Empty, value, bit - 1))
        }
      Node(count=c, zero=z, one=o) =>
        if b == 0 {
          Node(count=c + 1, zero=insert(z, value, bit - 1), one=o)
        } else {
          Node(count=c + 1, zero=z, one=insert(o, value, bit - 1))
        }
    }
  }
}

///|
/// Query the maximum xor with value (assumes trie is non-empty).
pub fn max_xor(root : Node, value : Int, max_bit : Int) -> Int {
  for bit in max_bit>=..0; cur = root, acc = 0 {
    match cur {
      Empty => break acc
      Node(count=_, zero=z, one=o) => {
        let b = (value >> bit) & 1
        if b == 0 {
          if count(o) > 0 {
            continue o, acc | (1 << bit)
          } else {
            continue z, acc
          }
        } else if count(z) > 0 {
          continue z, acc | (1 << bit)
        } else {
          continue o, acc
        }
      }
    }
  } nobreak {
    acc
  }
}
