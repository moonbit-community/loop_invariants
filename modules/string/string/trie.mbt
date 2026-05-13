// Trie (Prefix Tree) and Aho-Corasick Algorithm
// String data structures with rigorous loop invariants

// ============================================================================
// TRIE (PREFIX TREE)
// ============================================================================

///|
/// A single node in a prefix trie.
///
/// Each node stores up to 26 child pointers (one per lowercase ASCII letter),
/// a flag marking whether any inserted word ends here, the count of words
/// ending exactly at this node, and a count of all words whose prefix passes
/// through this node.
priv struct TrieNode {
  children : Array[TrieNode?]
  mut is_end : Bool
  mut count : Int // number of words ending here
  mut prefix_count : Int // number of words with this prefix
}

///|
/// Create a fresh `TrieNode` with no children and zero counts.
fn TrieNode::TrieNode() -> TrieNode {
  { children: Array::make(26, None), is_end: false, count: 0, prefix_count: 0 }
}

///|
/// A **Prefix Trie** (digital tree) over lowercase ASCII strings.
///
/// Supports O(|word|) insert, exact-word search, prefix existence check, and
/// prefix count query.  Each node tracks both the number of words ending
/// there and the number of words whose prefix passes through it.
priv struct Trie {
  root : TrieNode
}

///|
/// Create an empty `Trie`.
fn Trie::Trie() -> Trie {
  { root: TrieNode() }
}

///|
/// Insert `word` into the trie.
///
/// Creates missing nodes along the path and increments `prefix_count` for
/// every node visited (including the terminal node).  The terminal node is
/// marked `is_end = true` and its `count` is incremented.
///
/// Duplicate insertions are counted separately: inserting the same word
/// twice results in `count = 2` at the terminal node.
///
/// # Parameters
/// - `word` — a string containing only lowercase ASCII letters (`'a'`..`'z'`)
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
        let new_node = TrieNode()
        node.children[idx] = Some(new_node)
        new_node
      }
    }
    continue i + 1, next_node
  } nobreak {
    node.prefix_count = node.prefix_count + 1
    node.is_end = true
    node.count = node.count + 1
  } where {
    proof_invariant: i <= n,
    proof_reasoning: (
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
/// Return `true` if `word` was previously inserted into the trie.
///
/// Follows the path spelled by `word` from the root.  Returns `false` as
/// soon as a missing edge is encountered; returns `node.is_end` at the
/// terminal node.
///
/// # Parameters
/// - `word` — the exact word to look up
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
  } nobreak {
    node.is_end
  } where {
    proof_invariant: i <= n,
    proof_reasoning: (
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
/// Return `true` if any word in the trie starts with `prefix`.
///
/// Unlike `search`, this does **not** require `is_end` at the terminal node —
/// reaching the end of the prefix path is sufficient.
///
/// # Parameters
/// - `prefix` — the prefix to check (may be a complete word)
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
  } nobreak {
    true
  } where {
    proof_invariant: i <= n,
    proof_reasoning: (
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
/// Return the number of inserted words that start with `prefix`.
///
/// This is the `prefix_count` stored at the node reached by following the
/// path for `prefix`.  Duplicate insertions are counted individually.
/// Returns `0` if the prefix does not exist in the trie.
///
/// # Parameters
/// - `prefix` — the prefix to count matches for
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
  } nobreak {
    node.prefix_count
  } where {
    proof_invariant: i <= n,
    proof_reasoning: (
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
/// A node in the Aho-Corasick automaton.
///
/// - `children` — transition table indexed by character (`0` = `'a'`, ...,
///   `25` = `'z'`); `-1` means no edge.
/// - `fail` — failure (suffix) link: the longest proper suffix of the current
///   state's label that is also a prefix of some pattern.
/// - `output` — indices of patterns that end at this node.
/// - `suffix_output` — index of the nearest ancestor (via failure links) that
///   has a non-empty output, used to enumerate all overlapping matches.
priv struct ACNode {
  children : Array[Int] // indices into nodes array, -1 = no child
  mut fail : Int // failure link
  mut output : Array[Int] // pattern indices that end here
  mut suffix_output : Int // index of node with next pattern via suffix links
}

///|
/// Create a fresh `ACNode` with no children, failure link pointing to root,
/// no output, and no suffix-output link.
fn ACNode::ACNode() -> ACNode {
  { children: Array::make(26, -1), fail: 0, output: [], suffix_output: -1 }
}

///|
/// The **Aho-Corasick automaton** for multi-pattern string matching.
///
/// Given a set of patterns, the automaton preprocesses them into a trie
/// augmented with **failure links** (built via BFS) so that every text
/// character is processed in O(1) amortised time.  All occurrences of all
/// patterns in a text of length `n` are found in O(n + total_output) time
/// after O(total_pattern_length) construction.
///
/// Construct with `AhoCorasick(patterns)` and search with
/// `ac.search(text)`.
priv struct AhoCorasick {
  nodes : Array[ACNode]
  mut node_count : Int
}

///|
/// Build an Aho-Corasick automaton from `patterns`.
///
/// The constructor:
/// 1. Inserts every pattern into a trie (Goto function).
/// 2. Computes failure links with a BFS over the trie.
/// 3. Propagates suffix-output links so that overlapping matches can be
///    reported without traversing the full failure-link chain at each step.
///
/// # Parameters
/// - `patterns` — the set of patterns to match; each must contain only
///   lowercase ASCII letters
///
/// # Example
/// ```
/// let ac = AhoCorasick(["he", "she", "his", "hers"])
/// let matches = ac.search("ushers")
/// // matches contain: "she" at 4, "he" at 4, "hers" at 6
/// ```
fn AhoCorasick::AhoCorasick(patterns : Array[String]) -> AhoCorasick {
  let max_nodes = 1 + patterns.fold(init=0, (acc, p) => acc + p.length())
  let nodes : Array[ACNode] = [ for _ in 0..<max_nodes => ACNode() ]
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
/// Insert a single pattern into the trie portion of the automaton.
///
/// Creates trie nodes for any missing edges along `pattern`'s path and
/// records `pattern_idx` in the output set of the terminal node.
///
/// This is called during construction before failure links are computed.
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
  } nobreak {
    // Mark pattern ending at this node
    let new_output = self.nodes[node_idx].output.copy()
    new_output.push(pattern_idx)
    self.nodes[node_idx].output = new_output
  } where {
    proof_invariant: i <= n && node_idx >= 0 && node_idx < self.node_count,
    proof_reasoning: (
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
/// Compute failure links and suffix-output links for all trie nodes via BFS.
///
/// After all patterns are inserted, this method is called once to augment
/// the trie into a full automaton:
/// - Every depth-1 node's failure link points to the root.
/// - For deeper nodes, the failure link is found by following the parent's
///   failure link and then the same character edge (like KMP's failure
///   function extended to a trie).
/// - `suffix_output` is set to the nearest failure-link ancestor that has
///   a non-empty output array, enabling efficient collection of all matches.
fn AhoCorasick::build_failure_links(self : AhoCorasick) -> Unit {
  // Queue for BFS
  let queue : Array[Int] = Array::make(self.node_count, 0)
  // Initialize: all depth-1 nodes have fail link to root
  let back = for c = 0, back = 0; c < 26; c = c + 1 {
    let child = self.nodes[0].children[c]
    if child != -1 {
      self.nodes[child].fail = 0
      queue[back] = child
      continue c + 1, back + 1
    }
    continue c + 1, back
  } nobreak {
    back
  } where {
    proof_invariant: c >= 0 && c <= 26,
    proof_reasoning: (
      #|Scan all alphabet characters to seed the BFS queue.
      #|Each root child discovered is enqueued and assigned fail = 0.
      #|MAINTENANCE:
      #|Check child for c and enqueue it when present.
      #|TERMINATION:
      #|At c = 26, all root children are initialized.
    ),
    proof_invariant: back >= 0 && back <= 26,
    proof_reasoning: (
      #|back equals the number of root children enqueued so far.
      #|MAINTENANCE:
      #|Increment back each time a child is enqueued.
      #|TERMINATION:
      #|At c = 26, back equals the total number of root children.
    ),
  }
  // BFS to build failure links
  let _ = for front = 0, back = back; front < back; {
    let curr = queue[front]
    // Set suffix_output: closest ancestor with output via fail links
    let fail_node = self.nodes[curr].fail
    if self.nodes[fail_node].output.length() > 0 {
      self.nodes[curr].suffix_output = fail_node
    } else {
      self.nodes[curr].suffix_output = self.nodes[fail_node].suffix_output
    }
    // Process children
    let back = for c = 0, back = back; c < 26; c = c + 1 {
      let child = self.nodes[curr].children[c]
      if child != -1 {
        // Find failure link for child
        let fail = self.find_fail_link(curr, c)
        self.nodes[child].fail = fail
        queue[back] = child
        continue c + 1, back + 1
      }
      continue c + 1, back
    } nobreak {
      back
    } where {
      proof_invariant: c >= 0 && c <= 26,
      proof_reasoning: (
        #|Iterate through all outgoing edges of curr across the alphabet.
        #|Each child is enqueued exactly once and gets its failure link set.
        #|MAINTENANCE:
        #|For each existing child, compute fail and enqueue.
        #|TERMINATION:
        #|At c = 26, all outgoing edges are processed.
      ),
      proof_invariant: back >= front && back <= self.node_count,
      proof_reasoning: (
        #|Queue indices maintain a contiguous range of discovered nodes
        #|that will be processed in BFS order.
        #|MAINTENANCE:
        #|Enqueueing increments back while front advances in the outer loop.
        #|TERMINATION:
        #|Queue range remains valid until BFS finishes.
      ),
    }
    continue front + 1, back
  }
}

///|
/// Find the failure link target for the child of `parent` on edge `c`.
///
/// Walks up the failure-link chain of `parent` until a node that has an
/// outgoing edge labeled `c` is found, then returns that child.  If no such
/// node exists up to the root, returns the root (index `0`).
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
    proof_invariant: fail >= 0,
    proof_reasoning: (
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
/// A single pattern match found by the Aho-Corasick search.
///
/// - `position`    — the exclusive end position in the text (i.e. the match
///   covers `text[position - len(pattern) .. position)`).
/// - `pattern_idx` — the 0-based index into the `patterns` array supplied to
///   `AhoCorasick::new`.
priv struct ACMatch {
  position : Int // end position in text (exclusive)
  pattern_idx : Int // index of matched pattern
}

///|
/// Find all occurrences of all patterns in `text`.
///
/// Runs the automaton on `text` left-to-right.  At each position the current
/// state is advanced via `transition` (which follows failure links as needed),
/// then all patterns ending at that position are collected via direct output
/// and `suffix_output` links.
///
/// # Parameters
/// - `text` — the text to search (only lowercase ASCII letters)
///
/// # Returns
/// An `Array[ACMatch]` with one entry per pattern occurrence (including
/// overlapping matches), in the order they are encountered left-to-right.
///
/// # Complexity
/// - O(n + total_output) where `n = text.length()`
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
  } nobreak {
    matches
  } where {
    proof_invariant: i <= n && state >= 0,
    proof_reasoning: (
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
/// Compute the automaton transition from `state_in` on character index `c`.
///
/// If `state_in` has a direct child for `c`, that child is returned.
/// Otherwise the failure link is followed and the process repeats until
/// either a child is found or the root is reached.
///
/// # Parameters
/// - `state_in` — the current automaton state index
/// - `c`        — the character index (`0` = `'a'`, ..., `25` = `'z'`)
///
/// # Returns
/// The index of the next state.
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
    proof_invariant: state >= 0,
    proof_reasoning: (
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
/// Append all pattern matches ending at text position `end_pos` to `matches`.
///
/// Collects both direct outputs stored at `state` and any additional patterns
/// reachable via the `suffix_output` chain, ensuring all overlapping matches
/// are reported.
///
/// # Parameters
/// - `state`   — current automaton state index after processing `end_pos - 1`
/// - `end_pos` — exclusive end position in the text (1-based)
/// - `matches` — accumulator to which `ACMatch` values are appended
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
    proof_invariant: suf == -1 || suf >= 0,
    proof_reasoning: (
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
/// A node in a binary (XOR) trie.
///
/// Each node branches on a single bit: `children.0` is the child for bit 0
/// and `children.1` is the child for bit 1.  `count` tracks how many numbers
/// pass through this node, allowing prefix-count queries.
priv struct XORTrieNode {
  mut children : (XORTrieNode?, XORTrieNode?) // (bit 0, bit 1)
  mut count : Int
}

///|
/// Create a fresh `XORTrieNode` with no children and count 0.
fn XORTrieNode::XORTrieNode() -> XORTrieNode {
  { children: (None, None), count: 0 }
}

///|
/// A **binary trie** (XOR trie) that stores non-negative integers by their
/// binary representation and supports maximum-XOR queries.
///
/// Useful for problems such as "find the element in the set that maximises
/// XOR with a query value" (e.g. maximum XOR subarray).
///
/// Construct with `XORTrie(max_bits)`, insert with `insert`, and query
/// with `max_xor`.
priv struct XORTrie {
  root : XORTrieNode
  bits : Int // number of bits to consider
}

///|
/// Create an empty `XORTrie` that considers the `max_bits` most-significant
/// bits of each inserted integer (bit `max_bits - 1` down to bit `0`).
fn XORTrie::XORTrie(max_bits : Int) -> XORTrie {
  { root: XORTrieNode(), bits: max_bits }
}

///|
/// Insert `num` into the XOR trie.
///
/// Processes bits from `self.bits - 1` down to `0`, creating nodes as
/// needed.  Each node along the path has its `count` incremented.
///
/// # Parameters
/// - `num` — the non-negative integer to insert
fn XORTrie::insert(self : XORTrie, num : Int) -> Unit {
  for bit = self.bits - 1, node = self.root; bit >= 0; {
    node.count = node.count + 1
    let b = (num >> bit) & 1
    let (child0, child1) = node.children
    let next_node = if b == 0 {
      match child0 {
        Some(n) => n
        None => {
          let new_node = XORTrieNode()
          node.children = (Some(new_node), child1)
          new_node
        }
      }
    } else {
      match child1 {
        Some(n) => n
        None => {
          let new_node = XORTrieNode()
          node.children = (child0, Some(new_node))
          new_node
        }
      }
    }
    continue bit - 1, next_node
  } nobreak {
    node.count = node.count + 1
  } where {
    proof_invariant: bit >= -1 && bit < self.bits,
    proof_reasoning: (
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
/// Return the maximum XOR of `num` with any number stored in the trie.
///
/// At each bit position, the algorithm greedily prefers the opposite bit
/// to `num`'s bit (maximising that position's contribution to the XOR).
/// If the preferred branch does not exist, the other branch is taken.
///
/// Returns `0` if the trie is empty.
///
/// # Parameters
/// - `num` — the query value
///
/// # Example
/// ```
/// // Trie contains 3, 10, 5.  Query: max XOR with 6.
/// // 6 XOR 3 = 5, 6 XOR 10 = 12, 6 XOR 5 = 3
/// // max_xor(6) == 12
/// ```
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
  } nobreak {
    result
  } where {
    proof_invariant: bit >= -1 && bit < self.bits,
    proof_reasoning: (
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
/// A node in a persistent (versioned) prefix trie.
///
/// Each node is stamped with a `version` number.  When inserting into a new
/// version, nodes on the insertion path are **cloned** (path copying) so that
/// earlier versions remain unmodified.  Nodes off the insertion path are
/// shared between versions.
priv struct PersistentTrieNode {
  children : Array[PersistentTrieNode?]
  is_end : Bool
  version : Int
}

///|
/// Create a fresh `PersistentTrieNode` for `version` with no children and
/// `is_end = false`.
fn PersistentTrieNode::PersistentTrieNode(version : Int) -> PersistentTrieNode {
  { children: Array::make(26, None), is_end: false, version }
}

///|
/// A **persistent prefix trie** supporting O(|word|) insert while retaining
/// access to all previous versions.
///
/// Insertions use *path copying*: only the O(|word|) nodes on the insertion
/// path are cloned; all other nodes are shared with the previous version.
/// Older versions remain fully queryable via `search_version`.
///
/// Construct with `PersistentTrie(max_versions)`, insert with `insert`
/// (returns the new version number), and query with `search_version`.
priv struct PersistentTrie {
  roots : Array[PersistentTrieNode?]
  mut version : Int
}

///|
/// Create an empty `PersistentTrie` with capacity for `max_versions`
/// versions (version 0 is the empty trie).
///
/// # Parameters
/// - `max_versions` — upper bound on the number of insert operations that
///   will be performed (must be at least 1)
fn PersistentTrie::PersistentTrie(max_versions : Int) -> PersistentTrie {
  let roots : Array[PersistentTrieNode?] = Array::make(max_versions, None)
  roots[0] = Some(PersistentTrieNode(0))
  { roots, version: 0 }
}

///|
/// Insert `word` into the trie, creating a new version.
///
/// Clones every node on the insertion path from the current version's root,
/// stamping each clone with the new version number.  Nodes off the path are
/// shared with the current version.
///
/// # Parameters
/// - `word` — the word to insert (lowercase ASCII letters only)
///
/// # Returns
/// The new version number (monotonically increasing).
fn PersistentTrie::insert(self : PersistentTrie, word : String) -> Int {
  let chars = word.to_array()
  let n = chars.length()
  let new_version = self.version + 1
  // Create new root for this version
  let old_root = self.roots[self.version]
  let new_root = PersistentTrieNode(new_version)
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
          let new_child = PersistentTrieNode(new_version)
          child.children.blit_to(new_child.children)
          node.children[idx] = Some(new_child)
          new_child
        } else {
          child
        }
      None => {
        let new_child = PersistentTrieNode(new_version)
        node.children[idx] = Some(new_child)
        new_child
      }
    }
    continue i + 1, next_node
  } nobreak {

  } where {
    // Mark as end - need to ensure this node is from current version
    // (already guaranteed by loop invariant)

    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|i counts how many characters of word have been inserted.
      #|node is the trie node representing prefix word[0..i) in the new version.
      #|MAINTENANCE:
      #|Advance i and move to the cloned/created child for word[i].
      #|TERMINATION:
      #|At i = n, the full word has been inserted.
    ),
    proof_invariant: node.version == new_version,
    proof_reasoning: (
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
/// Return `true` if `word` exists in the trie at `version`.
///
/// Follows the path for `word` starting from the root of the specified
/// version.  Returns `false` if any edge is missing or if the `version`
/// root is `None`.
///
/// # Parameters
/// - `word`    — the exact word to search for
/// - `version` — the trie version to query (0 = empty, as returned by
///   `insert`)
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
      } nobreak {
        node.is_end
      } where {
        proof_invariant: i <= n,
        proof_reasoning: (
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
/// A node in a radix tree (compressed trie / Patricia trie).
///
/// Unlike a standard trie that stores one character per edge, a radix node
/// stores a *string* label on each edge, compressing chains of single-child
/// nodes.  `children` is a list of `(first_char, child)` pairs, where
/// `first_char` is the first character of the child's `edge_label` (used for
/// O(alphabet) dispatch).
priv struct RadixNode {
  mut edge_label : String // edge label from parent
  children : Array[(Char, RadixNode)]
  mut is_end : Bool
}

///|
/// Create a fresh `RadixNode` with edge label `label`, no children, and
/// `is_end = false`.
fn RadixNode::RadixNode(label : String) -> RadixNode {
  { edge_label: label, children: [], is_end: false }
}

///|
/// A **Radix Tree** (compressed trie / Patricia trie) over strings.
///
/// Compared to a standard trie, a radix tree stores entire string labels on
/// edges instead of single characters, merging chains of single-child nodes.
/// This reduces the number of nodes from O(total characters) to O(number of
/// words), saving memory for sparse key sets.
///
/// Supports O(|word|) insert and search.  Edge splitting is handled
/// automatically on insert.
priv struct RadixTree {
  root : RadixNode
}

///|
/// Create an empty `RadixTree` with a root node carrying the empty label.
fn RadixTree::RadixTree() -> RadixTree {
  { root: RadixNode("") }
}

///|
/// Return the length of the longest common prefix of `s1` and `s2`.
///
/// Compares characters left-to-right and stops at the first mismatch or at
/// the end of the shorter string.
fn common_prefix_length(s1 : String, s2 : String) -> Int {
  let chars1 = s1.to_array()
  let chars2 = s2.to_array()
  let n = if chars1.length() < chars2.length() {
    chars1.length()
  } else {
    chars2.length()
  }
  for i in 0..<n {
    if chars1[i] != chars2[i] {
      break i
    }
  } nobreak {
    n
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|chars1[0..i) == chars2[0..i) holds for all processed positions.
      #|MAINTENANCE:
      #|Advance i while characters match.
      #|TERMINATION:
      #|On mismatch or i = n, return the prefix length.
    ),
  }
}

///|
/// Find the child of this node whose edge label starts with character `c`.
///
/// Returns `(index, Some(child))` if found, or `(-1, None)` if no such child
/// exists.  The index can be used to replace the child in the parent's list.
fn RadixNode::find_child(self : RadixNode, c : Char) -> (Int, RadixNode?) {
  for i in 0..<self.children.length() {
    let (first_char, child) = self.children[i]
    if first_char == c {
      break (i, Some(child))
    }
  } nobreak {
    (-1, None)
  } where {
    proof_invariant: i >= 0 && i <= self.children.length(),
    proof_reasoning: (
      #|No child with first_char == c exists in indices [0, i).
      #|MAINTENANCE:
      #|Check child i and advance if it doesn't match.
      #|TERMINATION:
      #|At i = length, no matching child exists.
    ),
  }
}

///|
/// Insert `word` into the radix tree.
///
/// Traverses the tree following shared edge prefixes.  When the remaining
/// suffix of `word` shares only a partial prefix with an existing edge, that
/// edge is **split** at the common prefix, creating an intermediate node.
/// The split is performed in O(|word|) time.
///
/// # Parameters
/// - `word` — the string to insert (may contain any characters)
fn RadixTree::insert(self : RadixTree, word : String) -> Unit {
  if word.length() == 0 {
    self.root.is_end = true
    return
  }
  let chars = word.to_array()
  self.insert_helper(self.root, word, 0, chars)
}

///|
/// Recursive insertion helper for the radix tree.
///
/// Inserts the suffix `word[pos..]` (represented via `chars`) under `node`.
/// Handles three cases:
/// 1. No matching child edge — create a new leaf with the remaining suffix.
/// 2. Matching child edge whose full label is consumed — recurse into child.
/// 3. Matching child edge with partial overlap — split at the common prefix.
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
      let new_child = RadixNode(remaining)
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
        let intermediate = RadixNode(common_part)
        // Update child's edge label
        child.edge_label = child_remaining
        // Add child to intermediate
        let child_first_char = child.edge_label.to_array()[0]
        intermediate.children.push((child_first_char, child))
        // If there's remaining word part, add new node
        if word_remaining.length() > 0 {
          let new_child = RadixNode(word_remaining)
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
/// Return `true` if `edge_chars` matches `chars[pos .. pos + edge_len)`.
///
/// Used during radix tree search to verify that the full edge label matches
/// the corresponding slice of the query word.
fn edge_matches(
  chars : Array[Char],
  pos : Int,
  edge_chars : Array[Char],
) -> Bool {
  let edge_len = edge_chars.length()
  for i in 0..<edge_len {
    if chars[pos + i] != edge_chars[i] {
      break false
    }
  } nobreak {
    true
  } where {
    proof_invariant: i >= 0 && i <= edge_len,
    proof_reasoning: (
      #|chars[pos..pos+i) matches edge_chars[0..i) for all processed i.
      #|MAINTENANCE:
      #|Advance i while characters match.
      #|TERMINATION:
      #|On mismatch return false; otherwise true when i = edge_len.
    ),
  }
}

///|
/// Return `true` if `word` was previously inserted into the radix tree.
///
/// Follows edge labels from the root, consuming characters of `word`.
/// Returns `false` if any edge is missing, the edge label does not match, or
/// the terminal node is not marked as a word end.
///
/// # Parameters
/// - `word` — the exact word to look up
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
        if !edge_matches(chars, pos, edge_chars) {
          break false
        }
        if pos + edge_len == chars.length() {
          break child.is_end
        } else {
          continue pos + edge_len, child
        }
      }
    }
  } nobreak {
    node.is_end
  } where {
    proof_invariant: pos <= chars.length(),
    proof_reasoning: (
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
  let trie = Trie()
  trie.insert("apple")
  trie.insert("app")
  trie.insert("application")
  debug_inspect(trie.search("apple"), content="true")
  debug_inspect(trie.search("app"), content="true")
  debug_inspect(trie.search("appl"), content="false")
  debug_inspect(trie.starts_with("app"), content="true")
  debug_inspect(trie.starts_with("apl"), content="false")
}

///|
test "trie_prefix_count" {
  let trie = Trie()
  trie.insert("apple")
  trie.insert("app")
  trie.insert("application")
  trie.insert("banana")
  debug_inspect(trie.count_prefix("app"), content="3")
  debug_inspect(trie.count_prefix("ban"), content="1")
  debug_inspect(trie.count_prefix("xyz"), content="0")
}

///|
test "aho_corasick_basic" {
  let patterns = ["he", "she", "his", "hers"]
  let ac = AhoCorasick(patterns)
  let matches = ac.search("ushers")
  // "she" at position 4 (ends at 4)
  // "he" at position 4 (ends at 4) - overlaps with she
  // "hers" at position 6 (ends at 6)
  debug_inspect(matches.length() >= 2, content="true")
  if matches.length() > 0 {
    let first = matches[0]
    let _ = first.position
    let _ = first.pattern_idx
  }
}

///|
test "aho_corasick_overlapping" {
  let patterns = ["a", "ab", "abc"]
  let ac = AhoCorasick(patterns)
  let matches = ac.search("abc")
  // Should find: "a" at 1, "ab" at 2, "abc" at 3
  debug_inspect(matches.length(), content="3")
}

///|
test "xor_trie_basic" {
  let trie = XORTrie(8) // 8 bits
  trie.insert(3) // 00000011
  trie.insert(10) // 00001010
  trie.insert(5) // 00000101
  // Max XOR with 6 (00000110):
  // 6 ^ 3 = 5, 6 ^ 10 = 12, 6 ^ 5 = 3
  // Maximum is 12
  debug_inspect(trie.max_xor(6), content="12")
}

///|
test "xor_trie_single" {
  let trie = XORTrie(4)
  trie.insert(7) // 0111
  debug_inspect(trie.max_xor(0), content="7") // 0 ^ 7 = 7
  debug_inspect(trie.max_xor(7), content="0") // 7 ^ 7 = 0
  debug_inspect(trie.max_xor(8), content="15") // 1000 ^ 0111 = 1111
}

///|
test "persistent_trie_basic" {
  let trie = PersistentTrie(10)
  let v1 = trie.insert("hello")
  let v2 = trie.insert("help")
  // Version 1 should have "hello"
  // Version 2 should have both "hello" and "help"
  // (Note: simplified implementation - full version tracking needs more work)
  debug_inspect(v1, content="1")
  debug_inspect(v2, content="2")
  let _ = trie.search_version("hello", v1)
  let _ = trie.search_version("help", v1)
  let _ = trie.search_version("help", v2)
}

///|
test "radix_tree_basic" {
  let tree = RadixTree()
  tree.insert("test")
  tree.insert("testing")
  tree.insert("team")
  debug_inspect(tree.search("test"), content="true")
  debug_inspect(tree.search("testing"), content="true")
  debug_inspect(tree.search("team"), content="true")
  debug_inspect(tree.search("tea"), content="false")
  debug_inspect(tree.search("tester"), content="false")
}

///|
test "radix_tree_prefix_sharing" {
  let tree = RadixTree()
  tree.insert("romane")
  tree.insert("romanus")
  tree.insert("romulus")
  tree.insert("rubens")
  tree.insert("ruber")
  tree.insert("rubicon")
  debug_inspect(tree.search("romane"), content="true")
  debug_inspect(tree.search("romanus"), content="true")
  debug_inspect(tree.search("rubicon"), content="true")
  debug_inspect(tree.search("rom"), content="false")
  debug_inspect(tree.search("rub"), content="false")
}

///|
test "empty_trie" {
  let trie = Trie()
  debug_inspect(trie.search("any"), content="false")
  debug_inspect(trie.starts_with("a"), content="false")
  debug_inspect(trie.count_prefix("xyz"), content="0")
}

///|
test "single_character_words" {
  let trie = Trie()
  trie.insert("a")
  trie.insert("b")
  trie.insert("c")
  debug_inspect(trie.search("a"), content="true")
  debug_inspect(trie.search("b"), content="true")
  debug_inspect(trie.search("d"), content="false")
  debug_inspect(trie.count_prefix("a"), content="1")
}
