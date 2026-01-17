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
pub struct Node {
  mut next0 : Int
  mut next1 : Int
  mut count : Int
}

///|
/// Binary trie for XOR queries.
pub struct BinaryTrie {
  max_bits : Int
  nodes : Array[Node]
}

///|
/// Create a binary trie with bit width [0..max_bits].
pub fn BinaryTrie::new(max_bits : Int) -> BinaryTrie {
  let root : Node = { next0: -1, next1: -1, count: 0 }
  { max_bits, nodes: [root] }
}

///|
/// Number of values stored in the trie.
pub fn BinaryTrie::size(self : BinaryTrie) -> Int {
  self.nodes[0].count
}

///|
/// Insert a value into the trie.
pub fn BinaryTrie::insert(self : BinaryTrie, x : Int64) -> Unit {
  let mut node = 0
  self.nodes[node].count = self.nodes[node].count + 1
  for bit in self.max_bits >=.. 0 {
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
    node = child
    self.nodes[node].count = self.nodes[node].count + 1
  }
}

///|
/// Remove a value if present. Returns true on success.
pub fn BinaryTrie::remove(self : BinaryTrie, x : Int64) -> Bool {
  if self.nodes[0].count == 0 {
    return false
  }
  let path : Array[Int] = [0]
  let mut node = 0
  for bit in self.max_bits >=.. 0 {
    let b = if ((x >> bit) & 1L) == 0L { 0 } else { 1 }
    let next = if b == 0 {
      self.nodes[node].next0
    } else {
      self.nodes[node].next1
    }
    if next == -1 {
      return false
    }
    path.push(next)
    node = next
  }
  if self.nodes[node].count == 0 {
    return false
  }
  for idx in path {
    self.nodes[idx].count = self.nodes[idx].count - 1
  }
  true
}

///|
/// Maximum xor value with x among stored keys.
pub fn BinaryTrie::max_xor(self : BinaryTrie, x : Int64) -> Int64 {
  if self.nodes[0].count == 0 {
    return 0L
  }
  // Traverse trie, preferring the opposite bit to maximize XOR
  for bit = self.max_bits, node = 0, result = 0L; bit >= 0; {
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
      continue bit - 1, preferred_child, result | (1L << bit)
    } else if other_child != -1 && self.nodes[other_child].count > 0 {
      continue bit - 1, other_child, result
    } else {
      break result
    }
  } else {
    result
  } where {
    invariant: bit >= -1 && bit <= self.max_bits,
    reasoning: (
      #|INVARIANT (maximize xor):
      #|The chosen prefix yields the maximum possible XOR for processed bits.
      #|MAINTENANCE:
      #|Prefer the opposite bit when it exists; otherwise follow the same bit.
      #|TERMINATION:
      #|At bit < 0, result is the maximum XOR value (returned via else branch).
    ),
  }
}

///|
/// Minimum xor value with x among stored keys.
pub fn BinaryTrie::min_xor(self : BinaryTrie, x : Int64) -> Int64 {
  if self.nodes[0].count == 0 {
    return 0L
  }
  // Traverse trie, preferring the same bit to minimize XOR
  for bit = self.max_bits, node = 0, result = 0L; bit >= 0; {
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
      continue bit - 1, preferred_child, result
    } else if other_child != -1 && self.nodes[other_child].count > 0 {
      continue bit - 1, other_child, result | (1L << bit)
    } else {
      break result
    }
  } else {
    result
  } where {
    invariant: bit >= -1 && bit <= self.max_bits,
    reasoning: (
      #|INVARIANT (minimize xor):
      #|The chosen prefix yields the minimum possible XOR for processed bits.
      #|MAINTENANCE:
      #|Prefer the same bit when it exists; otherwise take the opposite bit.
      #|TERMINATION:
      #|At bit < 0, result is the minimum XOR value (returned via else branch).
    ),
  }
}
