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
/// Trie node with children array for lowercase letters
priv struct TrieNode {
  children : Array[TrieNode?]
  mut is_end : Bool
  mut count : Int // Number of words ending here
  mut prefix_count : Int // Number of words with this prefix
}

///|
/// Create a new trie node
fn TrieNode::new() -> TrieNode {
  { children: Array::make(26, None), is_end: false, count: 0, prefix_count: 0 }
}

///|
/// Trie data structure for string storage
priv struct Trie {
  root : TrieNode
}

///|
/// Create a new empty Trie
fn Trie::new() -> Trie {
  { root: TrieNode::new() }
}

///|
/// Insert a word into the trie
/// TIME: O(m) where m = word length
///
/// INVARIANT: After traversing k characters, current node represents prefix[0..k).
/// REASONING: Each character extends the path by one node; at end we mark is_end.
fn Trie::insert(self : Trie, word : String) -> Unit {
  let mut current = self.root
  current.prefix_count = current.prefix_count + 1

  for i = 0; i < word.length(); i = i + 1 {
    let c = word[i].to_int() - 'a'.to_int()
    if c < 0 || c >= 26 {
      continue i + 1 // Skip non-lowercase characters
    }

    match current.children[c] {
      None => {
        let new_node = TrieNode::new()
        current.children[c] = Some(new_node)
        current = new_node
      }
      Some(child) => current = child
    }
    current.prefix_count = current.prefix_count + 1
  } where {
    invariant: i >= 0 && i <= word.length(),
    reasoning: "I: current = root represents empty prefix word[0..0); root.prefix_count incremented to count this word. M: For character word[i], we navigate to children[c] where c = word[i] - 'a'. If child doesn't exist, create it (extending the trie). Move current to child and increment its prefix_count. After iteration i, current represents prefix word[0..i+1). T: After i = word.length()-1, current represents the full word. Setting is_end=true and incrementing count marks this as a complete word. prefix_count at each node correctly reflects how many words pass through it.",
  }

  current.is_end = true
  current.count = current.count + 1
}

///|
/// Search for exact word in trie
/// Returns true if word exists
/// TIME: O(m)
///
/// INVARIANT: After traversing k characters, current node represents prefix[0..k).
fn Trie::search(self : Trie, word : String) -> Bool {
  match self.find_node(word) {
    Some(node) => node.is_end
    None => false
  }
}

///|
/// Check if any word starts with given prefix
/// TIME: O(p) where p = prefix length
fn Trie::starts_with(self : Trie, prefix : String) -> Bool {
  self.find_node(prefix) is Some(_)
}

///|
/// Count words with given prefix
fn Trie::count_prefix(self : Trie, prefix : String) -> Int {
  match self.find_node(prefix) {
    Some(node) => node.prefix_count
    None => 0
  }
}

///|
/// Count exact occurrences of word
fn Trie::count_word(self : Trie, word : String) -> Int {
  match self.find_node(word) {
    Some(node) => node.count
    None => 0
  }
}

///|
/// Find node for given string (helper function)
fn Trie::find_node(self : Trie, s : String) -> TrieNode? {
  let mut current = self.root

  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i].to_int() - 'a'.to_int()
    if c < 0 || c >= 26 {
      continue i + 1
    }

    match current.children[c] {
      None => return None
      Some(child) => current = child
    }
  } where {
    invariant: i >= 0 && i <= s.length(),
    reasoning: "I: current = root represents empty prefix s[0..0). M: For character s[i], compute index c = s[i] - 'a'. If children[c] is None, the prefix s[0..i+1) doesn't exist in the trie, so return None immediately. Otherwise, move current to children[c]. After iteration i, current represents prefix s[0..i+1). The early return ensures we never proceed past a missing character. T: If loop completes without returning None, current is the node for full string s. Return Some(current). Partial match failure returns None.",
  }

  Some(current)
}

///|
/// Delete a word from trie (decrement count)
/// Returns true if word was found and deleted
fn Trie::delete(self : Trie, word : String) -> Bool {
  if not(self.search(word)) {
    return false
  }

  let mut current = self.root
  current.prefix_count = current.prefix_count - 1

  for i = 0; i < word.length(); i = i + 1 {
    let c = word[i].to_int() - 'a'.to_int()
    if c < 0 || c >= 26 {
      continue i + 1
    }

    match current.children[c] {
      None => return false
      Some(child) => {
        current = child
        current.prefix_count = current.prefix_count - 1
      }
    }
  } where {
    invariant: i >= 0 && i <= word.length(),
    reasoning: "I: Word existence verified by search(); current = root; root.prefix_count decremented. M: For each character word[i], navigate to children[c]. Since word exists (verified), children[c] is guaranteed non-None. Move to child and decrement its prefix_count. This exactly reverses the insert operation's prefix_count increments. T: After loop, current is the node for word. Decrement count; if count reaches 0, clear is_end. prefix_count at each ancestor correctly reflects the reduced word count. Note: nodes are not physically removed (lazy deletion), but counts are correct.",
  }

  current.count = current.count - 1
  if current.count == 0 {
    current.is_end = false
  }
  true
}

///|
/// Get all words in trie (for testing/debugging)
fn Trie::all_words(self : Trie) -> Array[String] {
  let result : Array[String] = []
  let current_word : Array[Char] = []
  collect_words(self.root, current_word, result)
  result
}

///|
fn collect_words(node : TrieNode, current : Array[Char], result : Array[String]) -> Unit {
  if node.is_end {
    let mut s = ""
    for i = 0; i < current.length(); i = i + 1 {
      s = s + current[i].to_string()
    } where {
      invariant: i >= 0 && i <= current.length(),
      reasoning: (
        #|s is the concatenation of current[0..i).
      ),
    }
    for j = 0; j < node.count; j = j + 1 {
      result.push(s)
    } where {
      invariant: j >= 0 && j <= node.count,
      reasoning: (
        #|result has received j copies of the word for this terminal node.
      ),
    }
  }

  for c = 0; c < 26; c = c + 1 {
    match node.children[c] {
      Some(child) => {
        current.push(('a'.to_int() + c).unsafe_to_char())
        collect_words(child, current, result)
        let _ = current.pop()
      }
      None => ()
    }
  } where {
    invariant: c >= 0 && c <= 26,
    reasoning: (
      #|All child edges with labels < c have been explored; current is restored
      #|after each recursive descent.
    ),
  }
}

///|
/// Autocomplete: find all words with given prefix
fn Trie::autocomplete(self : Trie, prefix : String) -> Array[String] {
  let result : Array[String] = []

  match self.find_node(prefix) {
    None => result
    Some(node) => {
      let current : Array[Char] = []
      for i = 0; i < prefix.length(); i = i + 1 {
        match prefix.get_char(i) {
          Some(c) => current.push(c)
          None => ()
        }
      } where {
        invariant: i >= 0 && i <= prefix.length(),
        reasoning: (
          #|current contains the characters prefix[0..i) in order.
        ),
      }
      collect_words(node, current, result)
      result
    }
  }
}

///|
/// Find longest prefix of word that exists in trie
fn Trie::longest_prefix(self : Trie, word : String) -> String {
  let mut current = self.root
  let mut last_end = 0

  for i = 0; i < word.length(); i = i + 1 {
    let c = word[i].to_int() - 'a'.to_int()
    if c < 0 || c >= 26 {
      break
    }

    match current.children[c] {
      None => break
      Some(child) => {
        current = child
        if current.is_end {
          last_end = i + 1
        }
      }
    }
  } where {
    invariant: i >= 0 && i <= word.length(),
    reasoning: (
      #|current represents prefix word[0..i); last_end is the longest prefix
      #|length <= i where a word ends in the trie.
    ),
  }

  (try? word[0:last_end]).or("").to_string()
}

// ============================================================================
// COMPRESSED TRIE (Radix Tree) - Space Efficient
// ============================================================================

///|
/// Compressed Trie node - stores edge labels as strings
priv struct CompressedTrieNode {
  children : Array[(String, CompressedTrieNode)?]
  mut is_end : Bool
}

///|
fn CompressedTrieNode::new() -> CompressedTrieNode {
  { children: Array::make(26, None), is_end: false }
}

///|
priv struct CompressedTrie {
  root : CompressedTrieNode
}

///|
fn CompressedTrie::new() -> CompressedTrie {
  { root: CompressedTrieNode::new() }
}

///|
/// Insert word into compressed trie
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
      let new_node = CompressedTrieNode::new()
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
        insert_into_node(child, (try? word[common_len:]).or("").to_string())
      } else {
        // Need to split
        let new_internal = CompressedTrieNode::new()
        let suffix_label = (try? label[common_len:]).or("").to_string()
        let suffix_word = (try? word[common_len:]).or("").to_string()

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
          let new_word_node = CompressedTrieNode::new()
          new_word_node.is_end = true
          let first_word_char = suffix_word[0].to_int() - 'a'.to_int()
          if first_word_char >= 0 && first_word_char < 26 {
            new_internal.children[first_word_char] = Some((suffix_word, new_word_node))
          }
        }

        // Update root's child
        let common_prefix = (try? word[0:common_len]).or("").to_string()
        self.root.children[first_char] = Some((common_prefix, new_internal))
      }
    }
  }
}

///|
fn insert_into_node(node : CompressedTrieNode, word : String) -> Unit {
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
      let new_node = CompressedTrieNode::new()
      new_node.is_end = true
      node.children[first_char] = Some((word, new_node))
    }
    Some((label, child)) => {
      let common_len = common_prefix_len(label, word)

      if common_len == label.length() && common_len == word.length() {
        child.is_end = true
      } else if common_len == label.length() {
        insert_into_node(child, (try? word[common_len:]).or("").to_string())
      } else {
        // Split node (similar logic as above)
        let new_internal = CompressedTrieNode::new()
        let suffix_label = (try? label[common_len:]).or("").to_string()
        let suffix_word = (try? word[common_len:]).or("").to_string()

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
          let new_word_node = CompressedTrieNode::new()
          new_word_node.is_end = true
          let first_word_char = suffix_word[0].to_int() - 'a'.to_int()
          if first_word_char >= 0 && first_word_char < 26 {
            new_internal.children[first_word_char] = Some((suffix_word, new_word_node))
          }
        }

        let common_prefix = (try? word[0:common_len]).or("").to_string()
        node.children[first_char] = Some((common_prefix, new_internal))
      }
    }
  }
}

///|
fn common_prefix_len(a : String, b : String) -> Int {
  let min_len = if a.length() < b.length() { a.length() } else { b.length() }
  for i = 0; i < min_len; i = i + 1 {
    if a[i] != b[i] {
      return i
    }
  } where {
    invariant: i >= 0 && i <= min_len,
    reasoning: "I: i=0; no characters compared yet; trivially a[0..0) == b[0..0). M: Compare a[i] and b[i]. If they differ, return i immediately (first mismatch position). If equal, increment i. After iteration i, we know a[0..i+1) == b[0..i+1). T: If loop completes without mismatch, a[0..min_len) == b[0..min_len), and min_len is the common prefix length. If one string is a prefix of the other, this correctly returns the shorter length.",
  }
  min_len
}

///|
/// Search in compressed trie
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
fn search_in_node(label : String, node : CompressedTrieNode, word : String) -> Bool {
  let label_len = label.length()
  let word_len = word.length()

  // Check if word starts with label
  if word_len < label_len {
    return false
  }

  for i = 0; i < label_len; i = i + 1 {
    if word[i] != label[i] {
      return false
    }
  } where {
    invariant: i >= 0 && i <= label_len,
    reasoning: (
      #|word[0..i) matches label[0..i).
    ),
  }

  if word_len == label_len {
    return node.is_end
  }

  // Continue searching
  let remaining = (try? word[label_len:]).or("").to_string()
  if remaining.length() == 0 {
    return node.is_end
  }

  let next_char = remaining[0].to_int() - 'a'.to_int()
  if next_char < 0 || next_char >= 26 {
    return false
  }

  match node.children[next_char] {
    None => false
    Some((next_label, next_node)) => search_in_node(next_label, next_node, remaining)
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "trie basic insert and search" {
  let trie = Trie::new()
  trie.insert("hello")
  trie.insert("world")
  trie.insert("help")

  inspect(trie.search("hello"), content="true")
  inspect(trie.search("world"), content="true")
  inspect(trie.search("help"), content="true")
  inspect(trie.search("hell"), content="false")
  inspect(trie.search("helper"), content="false")
}

///|
test "trie starts_with" {
  let trie = Trie::new()
  trie.insert("hello")
  trie.insert("help")
  trie.insert("world")

  inspect(trie.starts_with("hel"), content="true")
  inspect(trie.starts_with("hello"), content="true")
  inspect(trie.starts_with("wor"), content="true")
  inspect(trie.starts_with("xyz"), content="false")
}

///|
test "trie delete" {
  let trie = Trie::new()
  trie.insert("hello")
  trie.insert("hello")
  trie.insert("help")

  inspect(trie.count_word("hello"), content="2")
  inspect(trie.delete("hello"), content="true")
  inspect(trie.count_word("hello"), content="1")
  inspect(trie.search("hello"), content="true")
  inspect(trie.delete("hello"), content="true")
  inspect(trie.search("hello"), content="false")
  inspect(trie.search("help"), content="true")
}

///|
test "trie prefix count" {
  let trie = Trie::new()
  trie.insert("car")
  trie.insert("card")
  trie.insert("care")
  trie.insert("cat")

  inspect(trie.count_prefix("ca"), content="4")
  inspect(trie.count_prefix("car"), content="3")
  inspect(trie.count_prefix("card"), content="1")
  inspect(trie.count_prefix("dog"), content="0")
}

///|
test "trie autocomplete" {
  let trie = Trie::new()
  trie.insert("car")
  trie.insert("card")
  trie.insert("care")
  trie.insert("cat")

  let results = trie.autocomplete("car")
  inspect(results.length(), content="3") // car, card, care
}

///|
test "trie all_words" {
  let trie = Trie::new()
  trie.insert("a")
  trie.insert("ab")
  trie.insert("abc")

  let words = trie.all_words()
  inspect(words.length(), content="3")
}

///|
test "trie empty" {
  let trie = Trie::new()
  inspect(trie.search("anything"), content="false")
  inspect(trie.starts_with("any"), content="false")
}

///|
test "trie single char" {
  let trie = Trie::new()
  trie.insert("a")
  inspect(trie.search("a"), content="true")
  inspect(trie.search("b"), content="false")
}

///|
test "trie longest prefix" {
  let trie = Trie::new()
  trie.insert("a")
  trie.insert("app")
  trie.insert("apple")

  inspect(trie.longest_prefix("application"), content="app")
  inspect(trie.longest_prefix("apple"), content="apple")
  inspect(trie.longest_prefix("appetizer"), content="app")
}

///|
test "compressed trie basic" {
  let trie = CompressedTrie::new()
  trie.insert("hello")
  trie.insert("help")
  trie.insert("world")

  inspect(trie.search("hello"), content="true")
  inspect(trie.search("help"), content="true")
  inspect(trie.search("world"), content="true")
  inspect(trie.search("hel"), content="false")
}

///|
test "compressed trie shared prefix" {
  let trie = CompressedTrie::new()
  trie.insert("test")
  trie.insert("testing")
  trie.insert("tested")

  inspect(trie.search("test"), content="true")
  inspect(trie.search("testing"), content="true")
  inspect(trie.search("tested"), content="true")
  inspect(trie.search("tes"), content="false")
}

///|
test "trie duplicate insert" {
  let trie = Trie::new()
  trie.insert("hello")
  trie.insert("hello")
  trie.insert("hello")

  inspect(trie.count_word("hello"), content="3")
  inspect(trie.count_prefix("hello"), content="3")
}

///|
test "common prefix len" {
  inspect(common_prefix_len("hello", "help"), content="3")
  inspect(common_prefix_len("abc", "xyz"), content="0")
  inspect(common_prefix_len("test", "testing"), content="4")
}
