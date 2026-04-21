// ============================================================================
// BINARY TRIE FOR XOR QUERIES
// ============================================================================
//
// Stores 64-bit integers and supports:
// - insert/remove
// - maximum XOR query
// - minimum XOR query
//
// Each node stores counts to allow deletions and duplicates.
//
// TIME COMPLEXITY: O(B) per operation (B = max_bits + 1)
// SPACE COMPLEXITY: O(N * B)

///|
/// A single node in the binary trie.
///
/// Each node sits at one level of the trie and represents a bit-prefix. The two
/// child slots `next0` and `next1` store indices into the owning trie's `nodes`
/// array (-1 means absent). `count` is the number of currently live values
/// whose bit path passes through this node; it is incremented on `insert` and
/// decremented on `remove`.
pub struct Node {
  mut next0 : Int
  mut next1 : Int
  mut count : Int
}

///|
/// A binary trie that stores `Int64` values and answers XOR queries in O(B)
/// time, where B = `max_bits + 1`.
///
/// Internally, every integer is represented as a root-to-leaf path of length
/// B+1: at level `k` (counting down from `max_bits` to 0) the path follows
/// `next0` if bit `k` of the value is 0, or `next1` if it is 1. Nodes are
/// allocated lazily and stored in a flat `nodes` array; index 0 is always the
/// root.
///
/// Duplicate values are supported via reference counts. `remove` decrements
/// counts without freeing nodes, so allocated memory grows monotonically.
pub struct BinaryTrie {
  max_bits : Int
  nodes : Array[Node]
}

///|
/// Create a new, empty `BinaryTrie` that handles bits `[0..max_bits]`
/// (inclusive).
///
/// `max_bits` is the index of the most significant bit that will be stored. All
/// values must satisfy `0 <= x < 2^(max_bits + 1)` for results to be correct.
/// The root node is pre-allocated; all other nodes are created lazily on the
/// first `insert` that needs them.
///
/// Examples:
/// - values in [0, 255]    -> `max_bits = 7`
/// - values up to ~1e9     -> `max_bits = 29`
/// - full non-negative Int64 -> `max_bits = 62`
pub fn BinaryTrie::BinaryTrie(max_bits : Int) -> BinaryTrie {
  let root : Node = { next0: -1, next1: -1, count: 0 }
  { max_bits, nodes: [root] }
}

///|
/// Return the total number of values currently stored in the trie, counting
/// duplicates.
///
/// This is O(1): the root node's `count` equals the number of live insertions.
pub fn BinaryTrie::size(self : BinaryTrie) -> Int {
  self.nodes[0].count
}

///|
/// Insert `x` into the trie.
///
/// Traverses the trie from the most significant bit (`max_bits`) down to bit 0,
/// creating nodes as needed, and increments the `count` of every node along the
/// path including the root. Inserting the same value multiple times is allowed;
/// each insertion is independently tracked and requires a matching `remove`.
pub fn BinaryTrie::insert(self : BinaryTrie, x : Int64) -> Unit {
  self.nodes[0].count = self.nodes[0].count + 1
  let _ = for bit in self.max_bits>=..0; node = 0 {
    let b = if ((x >> bit) & 1L) == 0L { 0 } else { 1 }
    let next = if b == 0 {
      self.nodes[node].next0
    } else {
      self.nodes[node].next1
    }
    let child = if next == -1 {
      let new_node : Node = { next0: -1, next1: -1, count: 0 }
      self.nodes.push(new_node)
      let idx = self.nodes.length() - 1
      if b == 0 {
        self.nodes[node].next0 = idx
      } else {
        self.nodes[node].next1 = idx
      }
      idx
    } else {
      next
    }
    self.nodes[child].count = self.nodes[child].count + 1
    continue child
  } nobreak {
    node
  }
}

///|
/// Remove one occurrence of `x` from the trie. Returns `true` on success,
/// `false` if `x` is not present (either never inserted or already fully
/// removed).
///
/// The function first walks the full bit path for `x`. If any node along the
/// path is missing or its count is zero, the value is absent and `false` is
/// returned without modifying any counts. On success, the `count` of every node
/// along the path (including the root) is decremented by one. The nodes
/// themselves are not freed; their counts reaching zero simply means that
/// subtree is logically empty.
pub fn BinaryTrie::remove(self : BinaryTrie, x : Int64) -> Bool {
  if self.nodes[0].count == 0 {
    return false
  }
  let path : Array[Int] = [0]
  let node = for bit in self.max_bits>=..0; node = 0 {
    let b = if ((x >> bit) & 1L) == 0L { 0 } else { 1 }
    let next = if b == 0 {
      self.nodes[node].next0
    } else {
      self.nodes[node].next1
    }
    if next == -1 {
      break -1
    }
    path.push(next)
    continue next
  } nobreak {
    node
  }
  if node == -1 || self.nodes[node].count == 0 {
    return false
  }
  for idx in path {
    self.nodes[idx].count = self.nodes[idx].count - 1
  }
  true
}

///|
/// Return the maximum XOR value achievable by XOR-ing `x` with any value
/// currently stored in the trie. Returns 0 if the trie is empty.
///
/// The algorithm traverses B levels (B = `max_bits + 1`). At each level it
/// inspects bit `k` of `x` and tries to follow the child whose bit **differs**
/// (so the XOR bit at position `k` becomes 1, maximising the result). If the
/// preferred child is absent or empty it follows the only available child
/// instead (XOR bit becomes 0 at that position). The accumulated XOR of the
/// chosen bits is returned.
///
/// Example: trie contains {1, 5, 7}, max_bits = 2.
/// ```
///   max_xor(2) -> 7   (2 XOR 5 = 7)
/// ```
pub fn BinaryTrie::max_xor(self : BinaryTrie, x : Int64) -> Int64 {
  if self.nodes[0].count == 0 {
    return 0L
  }
  // Traverse trie, preferring the opposite bit to maximize XOR
  for bit in self.max_bits>=..0; node = 0, result = 0L {
    let b = if ((x >> bit) & 1L) == 0L { 0 } else { 1 }
    let preferred = if b == 0 { 1 } else { 0 }
    let preferred_child = if preferred == 0 {
      self.nodes[node].next0
    } else {
      self.nodes[node].next1
    }
    let other_child = if preferred == 0 {
      self.nodes[node].next1
    } else {
      self.nodes[node].next0
    }
    if preferred_child != -1 && self.nodes[preferred_child].count > 0 {
      continue preferred_child, result | (1L << bit)
    } else if other_child != -1 && self.nodes[other_child].count > 0 {
      continue other_child, result
    } else {
      break result
    }
  } nobreak {
    result
  }
}

///|
/// Return the minimum XOR value achievable by XOR-ing `x` with any value
/// currently stored in the trie. Returns 0 if the trie is empty.
///
/// The algorithm traverses B levels (B = `max_bits + 1`). At each level it
/// inspects bit `k` of `x` and tries to follow the child whose bit **matches**
/// (so the XOR bit at position `k` becomes 0, minimising the result). If the
/// preferred child is absent or empty it follows the only available child
/// instead (XOR bit becomes 1 at that position). The accumulated XOR of the
/// chosen bits is returned.
///
/// Example: trie contains {1, 5, 7}, max_bits = 2.
/// ```
///   min_xor(2) -> 3   (2 XOR 1 = 3)
/// ```
pub fn BinaryTrie::min_xor(self : BinaryTrie, x : Int64) -> Int64 {
  if self.nodes[0].count == 0 {
    return 0L
  }
  // Traverse trie, preferring the same bit to minimize XOR
  for bit in self.max_bits>=..0; node = 0, result = 0L {
    let b = if ((x >> bit) & 1L) == 0L { 0 } else { 1 }
    let preferred = if b == 0 { 0 } else { 1 }
    let preferred_child = if preferred == 0 {
      self.nodes[node].next0
    } else {
      self.nodes[node].next1
    }
    let other_child = if preferred == 0 {
      self.nodes[node].next1
    } else {
      self.nodes[node].next0
    }
    if preferred_child != -1 && self.nodes[preferred_child].count > 0 {
      continue preferred_child, result
    } else if other_child != -1 && self.nodes[other_child].count > 0 {
      continue other_child, result | (1L << bit)
    } else {
      break result
    }
  } nobreak {
    result
  }
}
