// ============================================================================
// TRIE (Prefix Tree) - Efficient String Storage and Retrieval
// ============================================================================
//
// A Trie is a tree-based data structure for storing strings where each node
// represents a character, and paths from root to nodes represent prefixes.
//
// KEY INSIGHT: Common prefixes are stored only once, enabling efficient
// prefix-based operations like autocomplete and spell-checking.
//
// STRUCTURE:
// For words: "cat", "car", "card", "care"
//
//        (root)
//           |
//          'c'
//           |
//          'a'
//         /   \
//       't'   'r'*
//       *    / | \
//          'd' 'e' (end markers)
//          *   *
//
// * = word end marker
//
// OPERATIONS:
// - insert(word): O(m) where m = word length
// - search(word): O(m) exact match
// - starts_with(prefix): O(p) prefix match
// - delete(word): O(m)
// - autocomplete(prefix): O(p + k) where k = total chars in results
//
// INVARIANTS:
// 1. Each path from root represents a unique prefix
// 2. A node marked as 'is_end' indicates a complete word
// 3. Children are indexed by character for O(1) lookup
//
// SPACE COMPLEXITY: O(ALPHABET_SIZE * N * M) worst case
//   where N = number of words, M = average word length
// Optimizations: Array-based children, compressed trie

///|
/// Internal node for the standard trie.
///
/// Each node represents a character position on some path from the root.
/// Children are indexed by `(char - 'a')` for O(1) lookup. `is_end` is set
/// whenever a complete word terminates at this node. `count` tracks how many
/// times that exact word was inserted (to support duplicate counting and
/// per-copy deletion). `prefix_count` counts how many inserted words pass
/// through this node, enabling O(1) prefix-count queries after an O(m) walk.
priv struct TrieNode {
  children : Array[TrieNode?]
  mut is_end : Bool
  mut count : Int // Number of words ending here
  mut prefix_count : Int // Number of words with this prefix
}

///|
/// Create a new trie node with empty children and zero counts.
fn TrieNode::TrieNode() -> TrieNode {
  { children: Array::make(26, None), is_end: false, count: 0, prefix_count: 0 }
}

///|
/// Standard trie for lowercase ASCII strings (`a..z`).
///
/// The trie stores strings as paths in a tree: each edge corresponds to one
/// character, and nodes on the same path share all characters up to that
/// depth. Supported operations include exact search, prefix queries,
/// autocomplete, duplicate-aware insertion and deletion, and longest-prefix
/// lookup.
///
/// Only lowercase letters `a..z` are meaningful. All other characters are
/// silently skipped during traversal, so "a-b" is treated the same as "ab".
priv struct Trie {
  root : TrieNode
}

///|
/// Create a new, empty trie.
fn Trie::Trie() -> Trie {
  { root: TrieNode() }
}

///|
/// Insert `word` into the trie.
///
/// Each lowercase character in `word` follows or creates one node. The
/// terminal node receives `is_end = true` and has its `count` incremented.
/// Every node along the path has its `prefix_count` incremented so that
/// `count_prefix` can answer queries in O(prefix length) time.
///
/// Non-lowercase characters are skipped; they do not create nodes or consume
/// path slots, but they are effectively removed from the key.
///
/// Time complexity: O(m) where m = `word.length()`.
fn Trie::insert(self : Trie, word : String) -> Unit {
  self.root.prefix_count = self.root.prefix_count + 1
  let current = for i = 0, current = self.root; i < word.length(); {
    let c = word[i].to_int() - 'a'.to_int()
    if c < 0 || c >= 26 {
      continue i + 1, current // Skip non-lowercase characters
    }
    let next = match current.children[c] {
      None => {
        let new_node = TrieNode()
        current.children[c] = Some(new_node)
        new_node
      }
      Some(child) => child
    }
    next.prefix_count = next.prefix_count + 1
    continue i + 1, next
  } nobreak {
    current
  } where {
    proof_invariant: i >= 0 && i <= word.length(),
    proof_reasoning: (
      #|INVARIANT (insert):
      #|current represents prefix word[0..i), and prefix_count is incremented
      #|along the path for all processed characters.
      #|MAINTENANCE:
      #|Follow or create the child for word[i], move current, and increment
      #|prefix_count to record this word passing through the node.
      #|TERMINATION:
      #|At i = word.length(), current represents the full word; setting is_end
      #|and incrementing count records the word occurrence.
    ),
  }
  current.is_end = true
  current.count = current.count + 1
}

///|
/// Return `true` if `word` was inserted into the trie and has not been fully
/// deleted.
///
/// Walks the path for `word` and checks `is_end` on the terminal node.
/// Returns `false` if any edge is missing or if the terminal node has
/// `is_end = false`.
///
/// Time complexity: O(m) where m = `word.length()`.
fn Trie::search(self : Trie, word : String) -> Bool {
  match self.find_node(word) {
    Some(node) => node.is_end
    None => false
  }
}

///|
/// Return `true` if at least one inserted word starts with `prefix`.
///
/// Walks the path for `prefix` and returns `true` if the node exists,
/// regardless of whether `prefix` itself is a complete word. This is faster
/// than `autocomplete` because no word collection is needed.
///
/// Time complexity: O(p) where p = `prefix.length()`.
fn Trie::starts_with(self : Trie, prefix : String) -> Bool {
  self.find_node(prefix) is Some(_)
}

///|
/// Return the total number of inserted words (counting duplicates) that begin
/// with `prefix`.
///
/// Reads the `prefix_count` field on the node reached by walking `prefix`.
/// Returns 0 if no such node exists.
///
/// Time complexity: O(p) where p = `prefix.length()`.
fn Trie::count_prefix(self : Trie, prefix : String) -> Int {
  match self.find_node(prefix) {
    Some(node) => node.prefix_count
    None => 0
  }
}

///|
/// Return the number of times `word` was inserted (counting duplicates).
///
/// Reads the `count` field on the terminal node. Returns 0 if the word is
/// not present or if all copies have been deleted.
///
/// Time complexity: O(m) where m = `word.length()`.
fn Trie::count_word(self : Trie, word : String) -> Int {
  match self.find_node(word) {
    Some(node) => node.count
    None => 0
  }
}

///|
/// Walk the trie along the path defined by `s` and return the terminal node,
/// or `None` if any edge is missing.
///
/// Non-lowercase characters are skipped without advancing the node pointer,
/// matching the skip behaviour of `insert`. This is the shared kernel used
/// by `search`, `starts_with`, `count_prefix`, and `count_word`.
///
/// Time complexity: O(n) where n = `s.length()`.
fn Trie::find_node(self : Trie, s : String) -> TrieNode? {
  for i = 0, current = self.root; i < s.length(); {
    let c = s[i].to_int() - 'a'.to_int()
    if c < 0 || c >= 26 {
      continue i + 1, current
    }
    match current.children[c] {
      None => break None
      Some(child) => continue i + 1, child
    }
  } nobreak {
    Some(current)
  } where {
    proof_invariant: i >= 0 && i <= s.length(),
    proof_reasoning: (
      #|INVARIANT (find node):
      #|current represents prefix s[0..i), and all characters so far exist in
      #|the trie path.
      #|MAINTENANCE:
      #|Follow child c for s[i]; if missing, return None immediately.
      #|TERMINATION:
      #|If the loop completes, current is the node for the full string s.
    ),
  }
}

///|
/// Remove one occurrence of `word` from the trie.
///
/// Decrements `prefix_count` along the path and `count` at the terminal node.
/// When `count` reaches zero, `is_end` is cleared so the word is no longer
/// found by `search`. The path nodes themselves are not removed; the trie
/// does not currently compact empty branches.
///
/// Returns `true` if `word` was present and one copy was removed, or `false`
/// if the word was not found (including the case where all copies were
/// previously deleted).
///
/// Time complexity: O(m) where m = `word.length()`.
fn Trie::delete(self : Trie, word : String) -> Bool {
  if !self.search(word) {
    return false
  }
  self.root.prefix_count = self.root.prefix_count - 1
  let current = for i = 0, current = self.root; i < word.length(); {
    let c = word[i].to_int() - 'a'.to_int()
    if c < 0 || c >= 26 {
      continue i + 1, current
    }
    match current.children[c] {
      None => break None
      Some(child) => {
        child.prefix_count = child.prefix_count - 1
        continue i + 1, child
      }
    }
  } nobreak {
    Some(current)
  } where {
    proof_invariant: i >= 0 && i <= word.length(),
    proof_reasoning: (
      #|INVARIANT (delete):
      #|current represents prefix word[0..i), and prefix_count has been
      #|decremented along the path for all processed characters.
      #|MAINTENANCE:
      #|Follow child c (guaranteed to exist) and decrement its prefix_count,
      #|reversing the insert operation.
      #|TERMINATION:
      #|At i = word.length(), current is the node for word; decrement count and
      #|clear is_end if needed. Counts remain consistent.
    ),
  }
  match current {
    None => false
    Some(current) => {
      current.count = current.count - 1
      if current.count == 0 {
        current.is_end = false
      }
      true
    }
  }
}

///|
/// Return every word currently stored in the trie, in lexicographic order.
///
/// Duplicates appear multiple times according to their `count`. This is a
/// full traversal and is primarily intended for testing and debugging; its
/// time complexity is proportional to the total number of characters across
/// all stored words.
fn Trie::all_words(self : Trie) -> Array[String] {
  let result : Array[String] = []
  let current_word : Array[Char] = []
  collect_words(self.root, current_word, result)
  result
}

///|
/// Recursively collect all words rooted at `node` into `result`.
///
/// `current` is a mutable character buffer representing the path from the
/// trie root to `node`. On entry `current` contains the prefix for this
/// subtree; characters are pushed before each recursive call and popped
/// afterwards to restore the buffer. Words that appear multiple times
/// (tracked by `count`) are pushed into `result` once per occurrence.
fn collect_words(
  node : TrieNode,
  current : Array[Char],
  result : Array[String],
) -> Unit {
  if node.is_end {
    let s = for i = 0, s = ""; i < current.length(); {
      continue i + 1, s + current[i].to_string()
    } nobreak {
      s
    } where {
      proof_invariant: i >= 0 && i <= current.length(),
      proof_reasoning: (
        #|INVARIANT (collect_words):
        #|s equals the concatenation of current[0..i) and current itself is
        #|unchanged while we build the string for this terminal node.
        #|MAINTENANCE:
        #|At iteration i, append current[i], extending s to match
        #|current[0..i+1); the prefix of current used by s grows by one.
        #|TERMINATION:
        #|When i == current.length(), s is the full word represented by the
        #|path; s is ready to be pushed node.count times.
      ),
    }
    for j in 0..<node.count {
      result.push(s)
    } where {
      proof_invariant: j >= 0 && j <= node.count,
      proof_reasoning: (
        #|INVARIANT (collect_words copies):
        #|result already includes the original entries plus exactly j copies
        #|of s; node.count is fixed for this node.
        #|MAINTENANCE:
        #|Push one more s to extend the multiset of results to j+1 copies.
        #|TERMINATION:
        #|At j == node.count, we have emitted all occurrences for this word.
      ),
    }
  }
  for c in 0..<26 {
    match node.children[c] {
      Some(child) => {
        current.push(('a'.to_int() + c).unsafe_to_char())
        collect_words(child, current, result)
        let _ = current.pop()
      }
      None => ()
    }
  } where {
    proof_invariant: c >= 0 && c <= 26,
    proof_reasoning: (
      #|INVARIANT (collect_words children):
      #|All child edges with labels < c have been fully explored, and after
      #|each recursive descent the current word is restored to this node's
      #|prefix before trying the next label.
      #|MAINTENANCE:
      #|For label c, if a child exists, append its char to current, recurse,
      #|then pop to restore current; this preserves the prefix for c+1.
      #|TERMINATION:
      #|When c == 26, every possible child edge has been processed.
    ),
  }
}

///|
/// Return all words stored in the trie that begin with `prefix`, in
/// lexicographic order.
///
/// Walks to the node for `prefix`, then collects every word in that subtree
/// via `collect_words`. If no word starts with `prefix` an empty array is
/// returned. Duplicate insertions produce duplicate entries in the output.
///
/// Time complexity: O(p + k) where p = `prefix.length()` and k = total
/// characters across all matching words.
fn Trie::autocomplete(self : Trie, prefix : String) -> Array[String] {
  let result : Array[String] = []
  match self.find_node(prefix) {
    None => result
    Some(node) => {
      let current : Array[Char] = []
      for i in 0..<prefix.length() {
        match prefix.get_char(i) {
          Some(c) => current.push(c)
          None => ()
        }
      } where {
        proof_invariant: i >= 0 && i <= prefix.length(),
        proof_reasoning: (
          #|INVARIANT (autocomplete prefix):
          #|current contains the characters prefix[0..i) in order, so the
          #|current array matches the traversed prefix exactly.
          #|MAINTENANCE:
          #|At step i, we append prefix[i] (if present) to extend current to
          #|prefix[0..i+1); indices are in bounds so get_char is Some.
          #|TERMINATION:
          #|At i == prefix.length(), current equals the full prefix, ready for
          #|collect_words to enumerate completions.
        ),
      }
      collect_words(node, current, result)
      result
    }
  }
}

///|
/// Return the longest prefix of `word` that is itself a complete word in the
/// trie.
///
/// Walks the trie character by character along the path for `word`, updating
/// a high-water mark each time a node with `is_end = true` is reached. If
/// no prefix (including the empty string) is a word, the empty string is
/// returned.
///
/// Example: if the trie contains `"a"`, `"app"`, and `"apple"`, then
/// `longest_prefix("application")` returns `"app"`.
///
/// Time complexity: O(m) where m = `word.length()`.
fn Trie::longest_prefix(self : Trie, word : String) -> String {
  let last_end = for i = 0, current = self.root, last_end = 0; i < word.length(); {
    let c = word[i].to_int() - 'a'.to_int()
    if c < 0 || c >= 26 {
      break last_end
    }
    match current.children[c] {
      None => break last_end
      Some(child) =>
        continue i + 1, child, if child.is_end { i + 1 } else { last_end }
    }
  } nobreak {
    last_end
  } where {
    proof_invariant: i >= 0 && i <= word.length(),
    proof_reasoning: (
      #|INVARIANT (longest_prefix):
      #|current is the trie node for prefix word[0..i); last_end is the length
      #|of the longest prefix <= i that ends a word.
      #|MAINTENANCE:
      #|If the next edge exists, advance current and update last_end when the
      #|node is terminal; otherwise break, preserving the best prefix seen.
      #|TERMINATION:
      #|When i reaches word.length() or traversal stops, last_end is the
      #|maximum prefix length present in the trie.
    ),
  }
  word[0:last_end].to_owned()
}

// ============================================================================
// COMPRESSED TRIE (Radix Tree) - Space Efficient
// ============================================================================

///|
/// Internal node for the compressed trie (radix tree).
///
/// Instead of one node per character, edges carry a multi-character `String`
/// label. Each child slot is indexed by the first character of its label so
/// that lookup remains O(1) per level. `is_end` marks whether the path from
/// the root to this node spells a complete word.
///
/// When a new word shares only part of an existing edge label, that edge is
/// split at the common prefix: a new internal node is created for the shared
/// portion, and two children are added for the diverging suffixes.
priv struct CompressedTrieNode {
  children : Array[(String, CompressedTrieNode)?]
  mut is_end : Bool
}

///|
/// Create a new compressed trie node with no children and `is_end = false`.
fn CompressedTrieNode::CompressedTrieNode() -> CompressedTrieNode {
  { children: Array::make(26, None), is_end: false }
}

///|
/// Compressed trie (radix tree) for lowercase ASCII strings.
///
/// Compared to the standard `Trie`, this structure collapses unbranched
/// chains of nodes into single edges with multi-character labels. This
/// reduces both node count and memory usage when many stored words share long
/// common prefixes. The trade-off is slightly more complex insert and search
/// logic (edge splitting and label comparison).
///
/// Like `Trie`, only lowercase letters `a..z` are supported.
priv struct CompressedTrie {
  root : CompressedTrieNode
}

///|
/// Create a new, empty compressed trie.
fn CompressedTrie::CompressedTrie() -> CompressedTrie {
  { root: CompressedTrieNode() }
}

///|
/// Insert `word` into the compressed trie.
///
/// Finds the edge whose label shares the longest common prefix with `word`.
/// Three cases arise:
/// - No matching edge: create a new edge with `word` as its label.
/// - Edge label equals a prefix of `word`: recurse into the child node with
///   the remaining suffix of `word`.
/// - Edge label and `word` diverge mid-label: split the edge at the common
///   prefix, creating an internal node with two children for the diverging
///   suffixes.
///
/// Only the first character of each word or suffix is used to index the
/// children array; the full label is compared character by character.
///
/// Time complexity: O(m) where m = `word.length()`.
fn CompressedTrie::insert(self : CompressedTrie, word : String) -> Unit {
  if word.length() == 0 {
    self.root.is_end = true
    return
  }
  let first_char = word[0].to_int() - 'a'.to_int()
  if first_char < 0 || first_char >= 26 {
    return
  }
  match self.root.children[first_char] {
    None => {
      // Create new edge with entire word
      let new_node = CompressedTrieNode()
      new_node.is_end = true
      self.root.children[first_char] = Some((word, new_node))
    }
    Some((label, child)) => {
      // Find common prefix
      let common_len = common_prefix_len(label, word)
      if common_len == label.length() && common_len == word.length() {
        // Exact match
        child.is_end = true
      } else if common_len == label.length() {
        // Word extends beyond label
        insert_into_node(child, word[common_len:])
      } else {
        // Need to split
        let new_internal = CompressedTrieNode()
        let suffix_label = label[common_len:].to_owned()
        let suffix_word = word[common_len:]

        // Move original child under new internal node
        let first_suffix_char = if suffix_label.length() > 0 {
          suffix_label[0].to_int() - 'a'.to_int()
        } else {
          -1
        }
        if first_suffix_char >= 0 && first_suffix_char < 26 {
          new_internal.children[first_suffix_char] = Some((suffix_label, child))
        }

        // Add new word suffix
        if suffix_word.length() == 0 {
          new_internal.is_end = true
        } else {
          let new_word_node = CompressedTrieNode()
          new_word_node.is_end = true
          let first_word_char = suffix_word[0].to_int() - 'a'.to_int()
          if first_word_char >= 0 && first_word_char < 26 {
            new_internal.children[first_word_char] = Some(
              (suffix_word.to_owned(), new_word_node),
            )
          }
        }

        // Update root's child
        let common_prefix = word[0:common_len].to_owned()
        self.root.children[first_char] = Some((common_prefix, new_internal))
      }
    }
  }
}

///|
/// Recursively insert `word` into the subtree rooted at `node`.
///
/// This is the recursive helper used by `CompressedTrie::insert` after the
/// first character dispatch. It applies the same three-case logic (no edge,
/// edge is a prefix of the remaining word, split needed) at each level of
/// the tree.
fn insert_into_node(node : CompressedTrieNode, word : StringView) -> Unit {
  if word.length() == 0 {
    node.is_end = true
    return
  }
  let first_char = word[0].to_int() - 'a'.to_int()
  if first_char < 0 || first_char >= 26 {
    return
  }
  match node.children[first_char] {
    None => {
      let new_node = CompressedTrieNode()
      new_node.is_end = true
      node.children[first_char] = Some((word.to_owned(), new_node))
    }
    Some((label, child)) => {
      let common_len = common_prefix_len(label, word)
      if common_len == label.length() && common_len == word.length() {
        child.is_end = true
      } else if common_len == label.length() {
        insert_into_node(child, word[common_len:])
      } else {
        // Split node (similar logic as above)
        let new_internal = CompressedTrieNode()
        let suffix_label = label[common_len:].to_owned()
        let suffix_word = word[common_len:]
        let first_suffix_char = if suffix_label.length() > 0 {
          suffix_label[0].to_int() - 'a'.to_int()
        } else {
          -1
        }
        if first_suffix_char >= 0 && first_suffix_char < 26 {
          new_internal.children[first_suffix_char] = Some((suffix_label, child))
        }
        if suffix_word.length() == 0 {
          new_internal.is_end = true
        } else {
          let new_word_node = CompressedTrieNode()
          new_word_node.is_end = true
          let first_word_char = suffix_word[0].to_int() - 'a'.to_int()
          if first_word_char >= 0 && first_word_char < 26 {
            new_internal.children[first_word_char] = Some(
              (suffix_word.to_owned(), new_word_node),
            )
          }
        }
        let common_prefix = word[0:common_len].to_owned()
        node.children[first_char] = Some((common_prefix, new_internal))
      }
    }
  }
}

///|
/// Return the length of the longest common prefix of string views `a` and `b`.
///
/// Compares characters pairwise from index 0 until a mismatch or the end of
/// the shorter string. Returns 0 if the strings share no common prefix, and
/// `min(a.length(), b.length())` if one is a prefix of the other.
///
/// Time complexity: O(min(|a|, |b|)).
fn common_prefix_len(a : StringView, b : StringView) -> Int {
  let min_len = if a.length() < b.length() { a.length() } else { b.length() }
  for i in 0..<min_len {
    if a[i] != b[i] {
      return i
    }
  } where {
    proof_invariant: i >= 0 && i <= min_len,
    proof_reasoning: (
      #|INVARIANT (common prefix):
      #|a[0..i) equals b[0..i); all characters before i match.
      #|MAINTENANCE:
      #|Compare a[i] and b[i]; on mismatch, return i as the first differing
      #|position.
      #|TERMINATION:
      #|If the loop completes, the common prefix length is min_len.
    ),
  }
  min_len
}

///|
/// Return `true` if `word` was inserted into the compressed trie.
///
/// Dispatches on the first character of `word` to find the matching root
/// edge, then delegates to `search_in_node` for label-by-label traversal.
///
/// Time complexity: O(m) where m = `word.length()`.
fn CompressedTrie::search(self : CompressedTrie, word : String) -> Bool {
  if word.length() == 0 {
    return self.root.is_end
  }
  let first_char = word[0].to_int() - 'a'.to_int()
  if first_char < 0 || first_char >= 26 {
    return false
  }
  match self.root.children[first_char] {
    None => false
    Some((label, child)) => search_in_node(label, child, word)
  }
}

///|
/// Recursively search for `word` starting at an edge with the given `label`
/// leading to `node`.
///
/// First verifies that `word` starts with `label`. If `word` equals `label`,
/// checks `node.is_end`. If `word` extends beyond `label`, dispatches on the
/// next character to find the appropriate child edge and recurses.
///
/// Returns `false` immediately if `word` is shorter than `label` or if any
/// character comparison fails.
fn search_in_node(
  label : String,
  node : CompressedTrieNode,
  word : StringView,
) -> Bool {
  let label_len = label.length()
  let word_len = word.length()

  // Check if word starts with label
  if word_len < label_len {
    return false
  }
  for i in 0..<label_len {
    if word[i] != label[i] {
      return false
    }
  } where {
    proof_invariant: i >= 0 && i <= label_len,
    proof_reasoning: (
      #|INVARIANT (compressed search):
      #|word[0..i) matches label[0..i), so the label prefix is verified.
      #|MAINTENANCE:
      #|Compare word[i] and label[i]; on mismatch, return false immediately.
      #|TERMINATION:
      #|If i reaches label_len, the entire edge label matches the word prefix.
    ),
  }
  if word_len == label_len {
    return node.is_end
  }

  // Continue searching
  let remaining = word[label_len:]
  if remaining.length() == 0 {
    return node.is_end
  }
  let next_char = remaining[0].to_int() - 'a'.to_int()
  if next_char < 0 || next_char >= 26 {
    return false
  }
  match node.children[next_char] {
    None => false
    Some((next_label, next_node)) =>
      search_in_node(next_label, next_node, remaining)
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "trie basic insert and search" {
  let trie = Trie()
  trie.insert("hello")
  trie.insert("world")
  trie.insert("help")
  debug_inspect(trie.search("hello"), content="true")
  debug_inspect(trie.search("world"), content="true")
  debug_inspect(trie.search("help"), content="true")
  debug_inspect(trie.search("hell"), content="false")
  debug_inspect(trie.search("helper"), content="false")
}

///|
test "trie starts_with" {
  let trie = Trie()
  trie.insert("hello")
  trie.insert("help")
  trie.insert("world")
  debug_inspect(trie.starts_with("hel"), content="true")
  debug_inspect(trie.starts_with("hello"), content="true")
  debug_inspect(trie.starts_with("wor"), content="true")
  debug_inspect(trie.starts_with("xyz"), content="false")
}

///|
test "trie delete" {
  let trie = Trie()
  trie.insert("hello")
  trie.insert("hello")
  trie.insert("help")
  debug_inspect(trie.count_word("hello"), content="2")
  debug_inspect(trie.delete("hello"), content="true")
  debug_inspect(trie.count_word("hello"), content="1")
  debug_inspect(trie.search("hello"), content="true")
  debug_inspect(trie.delete("hello"), content="true")
  debug_inspect(trie.search("hello"), content="false")
  debug_inspect(trie.search("help"), content="true")
}

///|
test "trie prefix count" {
  let trie = Trie()
  trie.insert("car")
  trie.insert("card")
  trie.insert("care")
  trie.insert("cat")
  debug_inspect(trie.count_prefix("ca"), content="4")
  debug_inspect(trie.count_prefix("car"), content="3")
  debug_inspect(trie.count_prefix("card"), content="1")
  debug_inspect(trie.count_prefix("dog"), content="0")
}

///|
test "trie autocomplete" {
  let trie = Trie()
  trie.insert("car")
  trie.insert("card")
  trie.insert("care")
  trie.insert("cat")
  let results = trie.autocomplete("car")
  debug_inspect(results.length(), content="3") // car, card, care
}

///|
test "trie autocomplete contents and skipped characters" {
  let trie = Trie()
  trie.insert("car")
  trie.insert("card")
  trie.insert("care")
  trie.insert("care")
  trie.insert("a-b")
  trie.insert("app")
  trie.insert("apple")
  let results = trie.autocomplete("car")
  debug_inspect(results.length(), content="4")
  debug_inspect(results[0], content=(
    #|"car"
  ))
  debug_inspect(results[1], content=(
    #|"card"
  ))
  debug_inspect(results[2], content=(
    #|"care"
  ))
  debug_inspect(results[3], content=(
    #|"care"
  ))
  debug_inspect(trie.search("ab"), content="true")
  debug_inspect(trie.delete("a-b"), content="true")
  debug_inspect(trie.search("ab"), content="false")
  debug_inspect(trie.longest_prefix("app!zz"), content=(
    #|"app"
  ))
}

///|
test "trie all_words" {
  let trie = Trie()
  trie.insert("a")
  trie.insert("ab")
  trie.insert("abc")
  let words = trie.all_words()
  debug_inspect(words.length(), content="3")
}

///|
test "trie empty" {
  let trie = Trie()
  debug_inspect(trie.search("anything"), content="false")
  debug_inspect(trie.starts_with("any"), content="false")
}

///|
test "trie single char" {
  let trie = Trie()
  trie.insert("a")
  debug_inspect(trie.search("a"), content="true")
  debug_inspect(trie.search("b"), content="false")
}

///|
test "trie longest prefix" {
  let trie = Trie()
  trie.insert("a")
  trie.insert("app")
  trie.insert("apple")
  debug_inspect(trie.longest_prefix("application"), content=(
    #|"app"
  ))
  debug_inspect(trie.longest_prefix("apple"), content=(
    #|"apple"
  ))
  debug_inspect(trie.longest_prefix("appetizer"), content=(
    #|"app"
  ))
}

///|
test "compressed trie basic" {
  let trie = CompressedTrie()
  trie.insert("hello")
  trie.insert("help")
  trie.insert("world")
  debug_inspect(trie.search("hello"), content="true")
  debug_inspect(trie.search("help"), content="true")
  debug_inspect(trie.search("world"), content="true")
  debug_inspect(trie.search("hel"), content="false")
}

///|
test "compressed trie shared prefix" {
  let trie = CompressedTrie()
  trie.insert("test")
  trie.insert("testing")
  trie.insert("tested")
  debug_inspect(trie.search("test"), content="true")
  debug_inspect(trie.search("testing"), content="true")
  debug_inspect(trie.search("tested"), content="true")
  debug_inspect(trie.search("tes"), content="false")
}

///|
test "trie duplicate insert" {
  let trie = Trie()
  trie.insert("hello")
  trie.insert("hello")
  trie.insert("hello")
  debug_inspect(trie.count_word("hello"), content="3")
  debug_inspect(trie.count_prefix("hello"), content="3")
}

///|
test "common prefix len" {
  debug_inspect(common_prefix_len("hello", "help"), content="3")
  debug_inspect(common_prefix_len("abc", "xyz"), content="0")
  debug_inspect(common_prefix_len("test", "testing"), content="4")
}
