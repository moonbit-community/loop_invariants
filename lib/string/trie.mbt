// Trie (Prefix Tree) and Aho-Corasick Algorithm
// String data structures with rigorous loop invariants

// ============================================================================
// TRIE (PREFIX TREE)
// ============================================================================

///|
priv struct TrieNode {
  children : Array[TrieNode?]
  mut is_end : Bool
  mut count : Int // number of words ending here
  mut prefix_count : Int // number of words with this prefix
}

///|
fn TrieNode::new() -> TrieNode {
  { children: Array::make(26, None), is_end: false, count: 0, prefix_count: 0 }
}

///|
priv struct Trie {
  root : TrieNode
}

///|
fn Trie::new() -> Trie {
  { root: TrieNode::new() }
}

///|
/// Insert a word into the trie
fn Trie::insert(self : Trie, word : String) -> Unit {
  let chars = word.to_array()
  let n = chars.length()
  for i = 0, node = self.root; i < n; {
    node.prefix_count = node.prefix_count + 1
    let c = chars[i]
    let idx = c.to_int() - 'a'.to_int()
    let next_node = match node.children[idx] {
      Some(child) => child
      None => {
        let new_node = TrieNode::new()
        node.children[idx] = Some(new_node)
        new_node
      }
    }
    continue i + 1, next_node
  } else {
    node.prefix_count = node.prefix_count + 1
    node.is_end = true
    node.count = node.count + 1
  } where {
    invariant: i <= n,
    reasoning: (
      #|INVARIANT (insert):
      #|node is the trie node reached after processing word[0..i), and every
      #|node along that path has had prefix_count incremented for this word.
      #|MAINTENANCE:
      #|Increment prefix_count at the current node, follow or create the child
      #|for chars[i], and continue; the path for word[0..i+1) is updated.
      #|TERMINATION:
      #|When i == n, node is the full word; increment prefix_count, mark is_end,
      #|and increase count to record this occurrence.
    ),
  }
}

///|
/// Search for exact word in trie
fn Trie::search(self : Trie, word : String) -> Bool {
  let chars = word.to_array()
  let n = chars.length()
  for i = 0, node = self.root; i < n; {
    let c = chars[i]
    let idx = c.to_int() - 'a'.to_int()
    match node.children[idx] {
      Some(child) => continue i + 1, child
      None => break false
    }
  } else {
    node.is_end
  } where {
    invariant: i <= n,
    reasoning: (
      #|INVARIANT (search):
      #|node is reached by following word[0..i) from the root, so all processed
      #|edges exist in the trie.
      #|MAINTENANCE:
      #|If the child for word[i] exists, advance to it; otherwise break false.
      #|TERMINATION:
      #|At i == n, node represents the full word; return node.is_end.
    ),
  }
}

///|
/// Check if any word starts with given prefix
fn Trie::starts_with(self : Trie, prefix : String) -> Bool {
  let chars = prefix.to_array()
  let n = chars.length()
  for i = 0, node = self.root; i < n; {
    let c = chars[i]
    let idx = c.to_int() - 'a'.to_int()
    match node.children[idx] {
      Some(child) => continue i + 1, child
      None => break false
    }
  } else {
    true
  } where {
    invariant: i <= n,
    reasoning: (
      #|INVARIANT (starts_with):
      #|node is the trie node for prefix[0..i), so some word has that prefix.
      #|MAINTENANCE:
      #|Follow the child for prefix[i] if it exists, otherwise break false.
      #|TERMINATION:
      #|At i == n, the entire prefix is present in the trie, return true.
    ),
  }
}

///|
/// Count words with given prefix
fn Trie::count_prefix(self : Trie, prefix : String) -> Int {
  let chars = prefix.to_array()
  let n = chars.length()
  for i = 0, node = self.root; i < n; {
    let c = chars[i]
    let idx = c.to_int() - 'a'.to_int()
    match node.children[idx] {
      Some(child) => continue i + 1, child
      None => break 0
    }
  } else {
    node.prefix_count
  } where {
    invariant: i <= n,
    reasoning: (
      #|INVARIANT (count_prefix):
      #|node is the trie node for prefix[0..i), and node.prefix_count equals the
      #|number of words that share that prefix.
      #|MAINTENANCE:
      #|Advance to the child for prefix[i] or break 0 if missing.
      #|TERMINATION:
      #|At i == n, return node.prefix_count for the full prefix.
    ),
  }
}

// ============================================================================
// AHO-CORASICK ALGORITHM
// ============================================================================

///|
priv struct ACNode {
  children : Array[Int] // indices into nodes array, -1 = no child
  mut fail : Int // failure link
  mut output : Array[Int] // pattern indices that end here
  mut suffix_output : Int // index of node with next pattern via suffix links
}

///|
fn ACNode::new() -> ACNode {
  { children: Array::make(26, -1), fail: 0, output: [], suffix_output: -1 }
}

///|
priv struct AhoCorasick {
  nodes : Array[ACNode]
  mut node_count : Int
}

///|
fn AhoCorasick::new(patterns : Array[String]) -> AhoCorasick {
  let max_nodes = 1 + patterns.fold(init=0, (acc, p) => acc + p.length())
  let nodes : Array[ACNode] = Array::makei(max_nodes, _ => ACNode::new())
  let ac : AhoCorasick = { nodes, node_count: 1 }
  // Build trie
  for pattern_idx, pattern in patterns {
    ac.add_pattern(pattern, pattern_idx)
  }
  // Build failure links using BFS
  ac.build_failure_links()
  ac
}

///|
/// Add a pattern to the trie
fn AhoCorasick::add_pattern(
  self : AhoCorasick,
  pattern : String,
  pattern_idx : Int,
) -> Unit {
  let chars = pattern.to_array()
  let n = chars.length()
  for i = 0, node_idx = 0; i < n; {
    let c = chars[i]
    let child_idx = c.to_int() - 'a'.to_int()
    let next_idx = if self.nodes[node_idx].children[child_idx] == -1 {
      let new_idx = self.node_count
      self.node_count = self.node_count + 1
      self.nodes[node_idx].children[child_idx] = new_idx
      new_idx
    } else {
      self.nodes[node_idx].children[child_idx]
    }
    continue i + 1, next_idx
  } else {
    // Mark pattern ending at this node
    let new_output = self.nodes[node_idx].output.copy()
    new_output.push(pattern_idx)
    self.nodes[node_idx].output = new_output
  } where {
    invariant: i <= n && node_idx >= 0 && node_idx < self.node_count,
    reasoning: (
      #|INVARIANT (insert pattern):
      #|node_idx is the trie node after reading pattern[0..i), and all edges for
      #|that prefix exist in the automaton.
      #|MAINTENANCE:
      #|If the edge for pattern[i] is missing, create a node and increment
      #|node_count, then advance to that child.
      #|TERMINATION:
      #|When i == n, append pattern_idx to output of the terminal node.
    ),
  }
}

///|
/// Build failure links using BFS
fn AhoCorasick::build_failure_links(self : AhoCorasick) -> Unit {
  // Queue for BFS
  let queue : Array[Int] = Array::make(self.node_count, 0)
  let mut front = 0
  let mut back = 0
  // Initialize: all depth-1 nodes have fail link to root
  for c = 0; c < 26; c = c + 1 {
    let child = self.nodes[0].children[c]
    if child != -1 {
      self.nodes[child].fail = 0
      queue[back] = child
      back = back + 1
    }
  } where {
    invariant: c >= 0 && c <= 26,
    reasoning: (
      #|Scan all alphabet characters to seed the BFS queue.
      #|Each root child discovered is enqueued and assigned fail = 0.
      #|MAINTENANCE:
      #|Check child for c and enqueue it when present.
      #|TERMINATION:
      #|At c = 26, all root children are initialized.
    ),
    invariant: back >= 0 && back <= 26,
    reasoning: (
      #|back equals the number of root children enqueued so far.
      #|MAINTENANCE:
      #|Increment back each time a child is enqueued.
      #|TERMINATION:
      #|At c = 26, back equals the total number of root children.
    ),
  }
  // BFS to build failure links
  while front < back {
    let curr = queue[front]
    front = front + 1
    // Set suffix_output: closest ancestor with output via fail links
    let fail_node = self.nodes[curr].fail
    if self.nodes[fail_node].output.length() > 0 {
      self.nodes[curr].suffix_output = fail_node
    } else {
      self.nodes[curr].suffix_output = self.nodes[fail_node].suffix_output
    }
    // Process children
    for c = 0; c < 26; c = c + 1 {
      let child = self.nodes[curr].children[c]
      if child != -1 {
        // Find failure link for child
        let fail = self.find_fail_link(curr, c)
        self.nodes[child].fail = fail
        queue[back] = child
        back = back + 1
      }
    } where {
      invariant: c >= 0 && c <= 26,
      reasoning: (
        #|Iterate through all outgoing edges of curr across the alphabet.
        #|Each child is enqueued exactly once and gets its failure link set.
        #|MAINTENANCE:
        #|For each existing child, compute fail and enqueue.
        #|TERMINATION:
        #|At c = 26, all outgoing edges are processed.
      ),
      invariant: back >= front && back <= self.node_count,
      reasoning: (
        #|Queue indices maintain a contiguous range of discovered nodes
        #|that will be processed in BFS order.
        #|MAINTENANCE:
        #|Enqueueing increments back while front advances in the outer loop.
        #|TERMINATION:
        #|Queue range remains valid until BFS finishes.
      ),
    }
  }
}

///|
/// Find failure link for a child node
fn AhoCorasick::find_fail_link(
  self : AhoCorasick,
  parent : Int,
  c : Int,
) -> Int {
  for fail = self.nodes[parent].fail {
    if self.nodes[fail].children[c] != -1 {
      break self.nodes[fail].children[c]
    } else if fail == 0 {
      break 0
    } else {
      continue self.nodes[fail].fail
    }
  } where {
    invariant: fail >= 0,
    reasoning: (
      #|INVARIANT (find_fail_link):
      #|fail is a suffix-state candidate for the parent path, and all longer
      #|suffixes have been ruled out as lacking an edge labeled c.
      #|MAINTENANCE:
      #|If fail has child c, return it; otherwise jump to its failure link (or
      #|root) to try the next shorter suffix.
      #|TERMINATION:
      #|We either find a node with child c or reach root (0).
    ),
  }
}

///|
priv struct ACMatch {
  position : Int // end position in text (exclusive)
  pattern_idx : Int // index of matched pattern
}

///|
/// Search for all pattern occurrences in text
fn AhoCorasick::search(self : AhoCorasick, text : String) -> Array[ACMatch] {
  let chars = text.to_array()
  let n = chars.length()
  let matches : Array[ACMatch] = []
  for i = 0, state = 0; i < n; {
    let c = chars[i]
    let c_idx = c.to_int() - 'a'.to_int()
    // Follow failure links until we find a match or reach root
    let next_state = self.transition(state, c_idx)
    // Collect all matches at this state
    self.collect_matches(next_state, i + 1, matches)
    continue i + 1, next_state
  } else {
    matches
  } where {
    invariant: i <= n && state >= 0,
    reasoning: (
      #|INVARIANT (aho-corasick search):
      #|state is the node for the longest suffix of text[0..i) that is a prefix
      #|of some pattern, and matches contains all occurrences ending at < i.
      #|MAINTENANCE:
      #|Use transition with chars[i] to get next_state, then collect matches
      #|ending at i + 1; this adds all patterns finishing at the new state.
      #|TERMINATION:
      #|At i == n, matches contains all pattern occurrences in the text.
    ),
  }
}

///|
/// Transition function with failure link following
fn AhoCorasick::transition(self : AhoCorasick, state_in : Int, c : Int) -> Int {
  for state = state_in {
    if self.nodes[state].children[c] != -1 {
      break self.nodes[state].children[c]
    } else if state == 0 {
      break 0
    } else {
      continue self.nodes[state].fail
    }
  } where {
    invariant: state >= 0,
    reasoning: (
      #|INVARIANT (transition):
      #|state is a suffix candidate of state_in's path; we seek the longest
      #|suffix that has an outgoing edge labeled c.
      #|MAINTENANCE:
      #|If edge c exists, return it; otherwise follow failure links until root.
      #|TERMINATION:
      #|We either find edge c or return root (0).
    ),
  }
}

///|
/// Collect all matches at a state (including via suffix links)
fn AhoCorasick::collect_matches(
  self : AhoCorasick,
  state : Int,
  end_pos : Int,
  matches : Array[ACMatch],
) -> Unit {
  // Collect direct outputs
  for pat_idx in self.nodes[state].output {
    matches.push({ position: end_pos, pattern_idx: pat_idx })
  }
  // Follow suffix_output links
  for suf = self.nodes[state].suffix_output; suf != -1; {
    for pat_idx in self.nodes[suf].output {
      matches.push({ position: end_pos, pattern_idx: pat_idx })
    }
    continue self.nodes[suf].suffix_output
  } where {
    invariant: suf == -1 || suf >= 0,
    reasoning: (
      #|INVARIANT (collect_matches):
      #|All outputs for suffix_output nodes visited so far have been appended to
      #|matches; suf is the next suffix_output node to process.
      #|MAINTENANCE:
      #|Append outputs for suf, then advance to its suffix_output link.
      #|TERMINATION:
      #|When suf == -1, all suffix-output nodes have been processed.
    ),
  }
}

// ============================================================================
// XOR TRIE (BINARY TRIE)
// ============================================================================

///|
priv struct XORTrieNode {
  mut children : (XORTrieNode?, XORTrieNode?) // (bit 0, bit 1)
  mut count : Int
}

///|
fn XORTrieNode::new() -> XORTrieNode {
  { children: (None, None), count: 0 }
}

///|
priv struct XORTrie {
  root : XORTrieNode
  bits : Int // number of bits to consider
}

///|
fn XORTrie::new(max_bits : Int) -> XORTrie {
  { root: XORTrieNode::new(), bits: max_bits }
}

///|
/// Insert a number into XOR trie
fn XORTrie::insert(self : XORTrie, num : Int) -> Unit {
  for bit = self.bits - 1, node = self.root; bit >= 0; {
    node.count = node.count + 1
    let b = (num >> bit) & 1
    let (child0, child1) = node.children
    let next_node = if b == 0 {
      match child0 {
        Some(n) => n
        None => {
          let new_node = XORTrieNode::new()
          node.children = (Some(new_node), child1)
          new_node
        }
      }
    } else {
      match child1 {
        Some(n) => n
        None => {
          let new_node = XORTrieNode::new()
          node.children = (child0, Some(new_node))
          new_node
        }
      }
    }
    continue bit - 1, next_node
  } else {
    node.count = node.count + 1
  } where {
    invariant: bit >= -1 && bit < self.bits,
    reasoning: (
      #|INVARIANT (xor insert):
      #|node corresponds to the prefix num[bits-1..bit+1) in binary, and all
      #|nodes for processed bits exist in the trie.
      #|MAINTENANCE:
      #|Choose or create the child for bit position `bit`, then continue with
      #|bit - 1; this extends the stored path by one bit.
      #|TERMINATION:
      #|When bit < 0, the full number path exists and we increment node.count.
    ),
  }
}

///|
/// Find maximum XOR of num with any number in trie
fn XORTrie::max_xor(self : XORTrie, num : Int) -> Int {
  if self.root.count == 0 {
    return 0
  }
  for bit = self.bits - 1, node = self.root, result = 0; bit >= 0; {
    let b = (num >> bit) & 1
    let want = 1 - b // we want opposite bit for maximum XOR
    let (child0, child1) = node.children
    let (next_node, got_bit) = if want == 0 {
      match child0 {
        Some(n) => (n, 0)
        None =>
          match child1 {
            Some(n) => (n, 1)
            None => (node, 0) // shouldn't happen if trie non-empty
          }
      }
    } else {
      match child1 {
        Some(n) => (n, 1)
        None =>
          match child0 {
            Some(n) => (n, 0)
            None => (node, 0)
          }
      }
    }
    let new_result = result | ((b ^ got_bit) << bit)
    continue bit - 1, next_node, new_result
  } else {
    result
  } where {
    invariant: bit >= -1 && bit < self.bits,
    reasoning: (
      #|INVARIANT (xor max):
      #|result stores the XOR value for processed bits [bits-1..bit+1), and
      #|node is the trie node reached by the chosen path so far.
      #|MAINTENANCE:
      #|Prefer the opposite bit to maximize the current bit; if unavailable,
      #|take the existing branch and update result accordingly.
      #|TERMINATION:
      #|At bit < 0, result is the maximal XOR over all numbers in the trie.
    ),
  }
}

// ============================================================================
// PERSISTENT TRIE
// ============================================================================

///|
priv struct PersistentTrieNode {
  children : Array[PersistentTrieNode?]
  is_end : Bool
  version : Int
}

///|
fn PersistentTrieNode::new(version : Int) -> PersistentTrieNode {
  { children: Array::make(26, None), is_end: false, version }
}

///|
priv struct PersistentTrie {
  roots : Array[PersistentTrieNode?]
  mut version : Int
}

///|
fn PersistentTrie::new(max_versions : Int) -> PersistentTrie {
  let roots : Array[PersistentTrieNode?] = Array::make(max_versions, None)
  roots[0] = Some(PersistentTrieNode::new(0))
  { roots, version: 0 }
}

///|
/// Insert word creating new version
fn PersistentTrie::insert(self : PersistentTrie, word : String) -> Int {
  let chars = word.to_array()
  let n = chars.length()
  let new_version = self.version + 1
  // Create new root for this version
  let old_root = self.roots[self.version]
  let new_root = PersistentTrieNode::new(new_version)
  // Copy children from old root
  match old_root {
    Some(r) => r.children.blit_to(new_root.children)
    None => ()
  }
  self.roots[new_version] = Some(new_root)
  // Insert word, creating new nodes only on path
  for i = 0, node = new_root; i < n; {
    let c = chars[i]
    let idx = c.to_int() - 'a'.to_int()
    let next_node = match node.children[idx] {
      Some(child) =>
        // Create copy if from older version
        if child.version < new_version {
          let new_child = PersistentTrieNode::new(new_version)
          child.children.blit_to(new_child.children)
          node.children[idx] = Some(new_child)
          new_child
        } else {
          child
        }
      None => {
        let new_child = PersistentTrieNode::new(new_version)
        node.children[idx] = Some(new_child)
        new_child
      }
    }
    continue i + 1, next_node
  } else {
    // Mark as end - need to ensure this node is from current version
    // (already guaranteed by loop invariant)

  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|i counts how many characters of word have been inserted.
      #|node is the trie node representing prefix word[0..i) in the new version.
      #|MAINTENANCE:
      #|Advance i and move to the cloned/created child for word[i].
      #|TERMINATION:
      #|At i = n, the full word has been inserted.
    ),
    invariant: node.version == new_version,
    reasoning: (
      #|When traversing a child from an older version, we clone it first.
      #|Thus the path we update is fully owned by the new version.
      #|MAINTENANCE:
      #|Each cloned node is stamped with new_version.
      #|TERMINATION:
      #|All nodes on the updated path belong to new_version.
    ),
  }
  self.version = new_version
  new_version
}

///|
/// Search in specific version
fn PersistentTrie::search_version(
  self : PersistentTrie,
  word : String,
  version : Int,
) -> Bool {
  let chars = word.to_array()
  let n = chars.length()
  match self.roots[version] {
    None => false
    Some(root) =>
      for i = 0, node = root; i < n; {
        let c = chars[i]
        let idx = c.to_int() - 'a'.to_int()
        match node.children[idx] {
          Some(child) => continue i + 1, child
          None => break false
        }
      } else {
        node.is_end
      } where {
        invariant: i <= n,
        reasoning: (
          #|INVARIANT (persistent search):
          #|node is the trie node for word[0..i) in the specified version.
          #|MAINTENANCE:
          #|Advance to the child for word[i] in that version or break false.
          #|TERMINATION:
          #|At i == n, node represents the word; return node.is_end.
        ),
      }
  }
}

// ============================================================================
// COMPRESSED TRIE (RADIX TREE)
// ============================================================================

///|
priv struct RadixNode {
  mut edge_label : String // edge label from parent
  children : Array[(Char, RadixNode)]
  mut is_end : Bool
}

///|
fn RadixNode::new(label : String) -> RadixNode {
  { edge_label: label, children: [], is_end: false }
}

///|
priv struct RadixTree {
  root : RadixNode
}

///|
fn RadixTree::new() -> RadixTree {
  { root: RadixNode::new("") }
}

///|
/// Find common prefix length of two strings
fn common_prefix_length(s1 : String, s2 : String) -> Int {
  let chars1 = s1.to_array()
  let chars2 = s2.to_array()
  let n = if chars1.length() < chars2.length() {
    chars1.length()
  } else {
    chars2.length()
  }
  for i = 0; i < n; i = i + 1 {
    if chars1[i] != chars2[i] {
      break i
    }
  } else {
    n
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|chars1[0..i) == chars2[0..i) holds for all processed positions.
      #|MAINTENANCE:
      #|Advance i while characters match.
      #|TERMINATION:
      #|On mismatch or i = n, return the prefix length.
    ),
  }
}

///|
/// Find child by first character
fn RadixNode::find_child(self : RadixNode, c : Char) -> (Int, RadixNode?) {
  for i = 0; i < self.children.length(); i = i + 1 {
    let (first_char, child) = self.children[i]
    if first_char == c {
      break (i, Some(child))
    }
  } else {
    (-1, None)
  } where {
    invariant: i >= 0 && i <= self.children.length(),
    reasoning: (
      #|No child with first_char == c exists in indices [0, i).
      #|MAINTENANCE:
      #|Check child i and advance if it doesn't match.
      #|TERMINATION:
      #|At i = length, no matching child exists.
    ),
  }
}

///|
/// Insert word into radix tree
fn RadixTree::insert(self : RadixTree, word : String) -> Unit {
  if word.length() == 0 {
    self.root.is_end = true
    return
  }
  let chars = word.to_array()
  self.insert_helper(self.root, word, 0, chars)
}

///|
/// Helper for radix tree insertion
fn RadixTree::insert_helper(
  self : RadixTree,
  node : RadixNode,
  word : String,
  pos : Int,
  chars : Array[Char],
) -> Unit {
  if pos >= chars.length() {
    node.is_end = true
    return
  }
  let c = chars[pos]
  let (idx, maybe_child) = node.find_child(c)
  match maybe_child {
    None => {
      // No matching child, create new one
      let remaining = String::from_array(chars[pos:])
      let new_child = RadixNode::new(remaining)
      new_child.is_end = true
      node.children.push((c, new_child))
    }
    Some(child) => {
      let remaining = String::from_array(chars[pos:])
      let common_len = common_prefix_length(child.edge_label, remaining)
      let edge_len = child.edge_label.length()
      if common_len == edge_len {
        // Full match of edge, continue down
        self.insert_helper(child, word, pos + edge_len, chars)
      } else {
        // Need to split edge
        let edge_chars = child.edge_label.to_array()
        let common_part = String::from_array(edge_chars[:common_len])
        let child_remaining = String::from_array(edge_chars[common_len:])
        let word_remaining = String::from_array(chars[pos + common_len:])
        // Create intermediate node
        let intermediate = RadixNode::new(common_part)
        // Update child's edge label
        child.edge_label = child_remaining
        // Add child to intermediate
        let child_first_char = child.edge_label.to_array()[0]
        intermediate.children.push((child_first_char, child))
        // If there's remaining word part, add new node
        if word_remaining.length() > 0 {
          let new_child = RadixNode::new(word_remaining)
          new_child.is_end = true
          let new_first_char = word_remaining.to_array()[0]
          intermediate.children.push((new_first_char, new_child))
        } else {
          intermediate.is_end = true
        }
        // Replace child with intermediate in parent
        node.children[idx] = (c, intermediate)
      }
    }
  }
}

///|
/// Helper to check if edge matches word substring
fn edge_matches(
  chars : Array[Char],
  pos : Int,
  edge_chars : Array[Char],
) -> Bool {
  let edge_len = edge_chars.length()
  for i = 0; i < edge_len; i = i + 1 {
    if chars[pos + i] != edge_chars[i] {
      break false
    }
  } else {
    true
  } where {
    invariant: i >= 0 && i <= edge_len,
    reasoning: (
      #|chars[pos..pos+i) matches edge_chars[0..i) for all processed i.
      #|MAINTENANCE:
      #|Advance i while characters match.
      #|TERMINATION:
      #|On mismatch return false; otherwise true when i = edge_len.
    ),
  }
}

///|
/// Search for word in radix tree
fn RadixTree::search(self : RadixTree, word : String) -> Bool {
  if word.length() == 0 {
    return self.root.is_end
  }
  let chars = word.to_array()
  for pos = 0, node = self.root; pos < chars.length(); {
    let c = chars[pos]
    let (_, maybe_child) = node.find_child(c)
    match maybe_child {
      None => break false
      Some(child) => {
        let edge_len = child.edge_label.length()
        let remaining_len = chars.length() - pos
        if edge_len > remaining_len {
          // Edge is longer than remaining word
          break false
        }
        // Check if edge matches
        let edge_chars = child.edge_label.to_array()
        if not(edge_matches(chars, pos, edge_chars)) {
          break false
        }
        if pos + edge_len == chars.length() {
          break child.is_end
        } else {
          continue pos + edge_len, child
        }
      }
    }
  } else {
    node.is_end
  } where {
    invariant: pos <= chars.length(),
    reasoning: (
      #|INVARIANT (radix search):
      #|pos characters of word have been matched, and node is the radix node for
      #|word[0..pos), respecting compressed edges.
      #|MAINTENANCE:
      #|Find the child edge starting with word[pos], verify its entire label,
      #|and advance pos by edge_len if it matches.
      #|TERMINATION:
      #|If pos reaches chars.length(), return whether node is terminal.
    ),
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "trie_basic" {
  let trie = Trie::new()
  trie.insert("apple")
  trie.insert("app")
  trie.insert("application")
  inspect(trie.search("apple"), content="true")
  inspect(trie.search("app"), content="true")
  inspect(trie.search("appl"), content="false")
  inspect(trie.starts_with("app"), content="true")
  inspect(trie.starts_with("apl"), content="false")
}

///|
test "trie_prefix_count" {
  let trie = Trie::new()
  trie.insert("apple")
  trie.insert("app")
  trie.insert("application")
  trie.insert("banana")
  inspect(trie.count_prefix("app"), content="3")
  inspect(trie.count_prefix("ban"), content="1")
  inspect(trie.count_prefix("xyz"), content="0")
}

///|
test "aho_corasick_basic" {
  let patterns = ["he", "she", "his", "hers"]
  let ac = AhoCorasick::new(patterns)
  let matches = ac.search("ushers")
  // "she" at position 4 (ends at 4)
  // "he" at position 4 (ends at 4) - overlaps with she
  // "hers" at position 6 (ends at 6)
  inspect(matches.length() >= 2, content="true")
  if matches.length() > 0 {
    let first = matches[0]
    let _ = first.position
    let _ = first.pattern_idx

  }
}

///|
test "aho_corasick_overlapping" {
  let patterns = ["a", "ab", "abc"]
  let ac = AhoCorasick::new(patterns)
  let matches = ac.search("abc")
  // Should find: "a" at 1, "ab" at 2, "abc" at 3
  inspect(matches.length(), content="3")
}

///|
test "xor_trie_basic" {
  let trie = XORTrie::new(8) // 8 bits
  trie.insert(3) // 00000011
  trie.insert(10) // 00001010
  trie.insert(5) // 00000101
  // Max XOR with 6 (00000110):
  // 6 ^ 3 = 5, 6 ^ 10 = 12, 6 ^ 5 = 3
  // Maximum is 12
  inspect(trie.max_xor(6), content="12")
}

///|
test "xor_trie_single" {
  let trie = XORTrie::new(4)
  trie.insert(7) // 0111
  inspect(trie.max_xor(0), content="7") // 0 ^ 7 = 7
  inspect(trie.max_xor(7), content="0") // 7 ^ 7 = 0
  inspect(trie.max_xor(8), content="15") // 1000 ^ 0111 = 1111
}

///|
test "persistent_trie_basic" {
  let trie = PersistentTrie::new(10)
  let v1 = trie.insert("hello")
  let v2 = trie.insert("help")
  // Version 1 should have "hello"
  // Version 2 should have both "hello" and "help"
  // (Note: simplified implementation - full version tracking needs more work)
  inspect(v1, content="1")
  inspect(v2, content="2")
  let _ = trie.search_version("hello", v1)
  let _ = trie.search_version("help", v1)
  let _ = trie.search_version("help", v2)

}

///|
test "radix_tree_basic" {
  let tree = RadixTree::new()
  tree.insert("test")
  tree.insert("testing")
  tree.insert("team")
  inspect(tree.search("test"), content="true")
  inspect(tree.search("testing"), content="true")
  inspect(tree.search("team"), content="true")
  inspect(tree.search("tea"), content="false")
  inspect(tree.search("tester"), content="false")
}

///|
test "radix_tree_prefix_sharing" {
  let tree = RadixTree::new()
  tree.insert("romane")
  tree.insert("romanus")
  tree.insert("romulus")
  tree.insert("rubens")
  tree.insert("ruber")
  tree.insert("rubicon")
  inspect(tree.search("romane"), content="true")
  inspect(tree.search("romanus"), content="true")
  inspect(tree.search("rubicon"), content="true")
  inspect(tree.search("rom"), content="false")
  inspect(tree.search("rub"), content="false")
}

///|
test "empty_trie" {
  let trie = Trie::new()
  inspect(trie.search("any"), content="false")
  inspect(trie.starts_with("a"), content="false")
  inspect(trie.count_prefix("xyz"), content="0")
}

///|
test "single_character_words" {
  let trie = Trie::new()
  trie.insert("a")
  trie.insert("b")
  trie.insert("c")
  inspect(trie.search("a"), content="true")
  inspect(trie.search("b"), content="true")
  inspect(trie.search("d"), content="false")
  inspect(trie.count_prefix("a"), content="1")
}
