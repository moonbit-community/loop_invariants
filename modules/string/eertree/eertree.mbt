// ============================================================================
// PALINDROMIC TREE (EERTREE) - All Distinct Palindromic Substrings
// ============================================================================
//
// The Palindromic Tree (also called Eertree) is a data structure that
// represents all distinct palindromic substrings of a string efficiently.
//
// KEY INSIGHT: Each node represents a unique palindrome. By maintaining
// suffix links (similar to suffix automaton), we can add characters
// incrementally and find all palindromes in O(n) total time.
//
// STRUCTURE:
// - Two special roots: one for odd-length palindromes (length -1), one for even (length 0)
// - Each node represents a unique palindrome
// - Edges labeled with characters extend palindromes on both ends
// - Suffix link points to longest proper palindromic suffix
//
// EXAMPLE for "abacaba":
// Palindromes: "", "a", "b", "c", "aba", "aca", "bacab", "abacaba"
//
// Tree structure:
//   root_odd (-1) ---a--> "a" ---b--> "aba" ---c--> "abacaba"
//                    |
//                    b--> "b" ---a--> "bab" (not in string)
//                    |
//                    c--> "c"
//   root_even (0) ----> (empty palindrome "")
//
// INVARIANTS:
// 1. Each node represents a unique palindrome
// 2. suffix_link[v] points to longest palindrome that is proper suffix of v
// 3. For node representing palindrome P, edges create palindrome cPc
//
// TIME COMPLEXITY: O(n) total to build
// SPACE COMPLEXITY: O(n) nodes (at most n distinct palindromes)

///|
/// A single node in the palindromic tree.
///
/// Each node corresponds to exactly one distinct palindromic substring.
/// The two special root nodes (indices 0 and 1) use sentinel lengths -1
/// and 0 respectively; all other nodes hold the actual character length
/// of the palindrome they represent.
///
/// Fields:
/// - `len`: length of the palindrome (-1 for the odd root, 0 for the even root)
/// - `suffix_link`: index of the node whose palindrome is the longest proper
///   palindromic suffix of this node's palindrome
/// - `edges`: transition array indexed by ASCII value; `edges[c]` is the
///   index of the node whose palindrome is `c + this_palindrome + c`
/// - `count`: number of positions in the processed string at which this
///   palindrome occurs as the longest palindromic suffix (before propagation)
priv struct EertreeNode {
  len : Int // Length of palindrome (-1 for odd root, 0 for even root)
  mut suffix_link : Int // Index of longest proper palindromic suffix
  edges : Array[Int] // edges[c] = index of node for palindrome formed by adding c on both ends
  mut count : Int // Number of occurrences of this palindrome
}

///|
fn EertreeNode::EertreeNode(len : Int) -> EertreeNode {
  {
    len,
    suffix_link: 0,
    edges: Array::make(256, -1), // ASCII characters
    count: 0,
  }
}

///|
/// The palindromic tree (eertree) for a string.
///
/// Nodes are stored in `nodes`; indices 0 and 1 are the two permanent roots:
///   - Node 0: odd-length root (imaginary palindrome of length -1).
///     Every single-character palindrome hangs off this root.
///   - Node 1: even-length root (empty palindrome of length 0).
///     Every two-character palindrome hangs off this root.
///
/// `last` tracks the node representing the longest palindromic suffix of the
/// string seen so far, which is the starting point for the next extension.
/// `size` counts the real palindrome nodes (all nodes except the two roots).
priv struct Eertree {
  nodes : Array[EertreeNode]
  text : Array[Int] // Store characters as integers for faster access
  mut last : Int // Index of node representing longest suffix palindrome
  mut size : Int // Number of distinct palindromes (excluding roots)
}

///|
fn Eertree::Eertree() -> Eertree {
  // Create two roots
  let nodes : Array[EertreeNode] = []

  // Node 0: root for odd-length palindromes (imaginary, length -1)
  let odd_root = EertreeNode(-1)
  nodes.push(odd_root)

  // Node 1: root for even-length palindromes (empty string, length 0)
  let even_root = EertreeNode(0)
  nodes.push(even_root)

  // Suffix links: both roots point to odd root
  nodes[0].suffix_link = 0 // Odd root to itself
  nodes[1].suffix_link = 0 // Even root to odd root
  { nodes, text: [], last: 1, size: 0 }
}

///|
/// Find suffix link for adding character c
/// REASONING: We follow suffix links until we find a position where
/// text[i-len-1] == c (where i is current position and len is palindrome length)
/// This ensures we can extend the palindrome by c on both sides.
fn Eertree::get_suffix_link(self : Eertree, v : Int, i : Int, c : Int) -> Int {
  // INVARIANT: We're looking for longest palindrome ending at position i-1
  // such that character before it equals c (so we can extend to position i)
  for cur = v {
    let len = self.nodes[cur].len
    // Check if we can extend this palindrome with c
    // Position of character before this palindrome is i - len - 1
    let prev_pos = i - len - 1
    if prev_pos >= 0 && self.text[prev_pos] == c {
      break cur
    } else {
      // Follow suffix link to try shorter palindrome
      continue self.nodes[cur].suffix_link
    }
  }
}

///|
/// Add a character to the tree
fn Eertree::add_char(self : Eertree, c : Char) -> Unit {
  let char_val = c.to_int()
  let i = self.text.length()
  self.text.push(char_val)

  // Find longest palindrome suffix that can be extended by c
  let cur = self.get_suffix_link(self.last, i, char_val)

  // Check if palindrome cPc already exists
  if self.nodes[cur].edges[char_val] >= 0 {
    // Palindrome already exists
    self.last = self.nodes[cur].edges[char_val]
    self.nodes[self.last].count = self.nodes[self.last].count + 1
    return
  }

  // Create new node for palindrome cPc
  let new_len = self.nodes[cur].len + 2
  let new_node = EertreeNode(new_len)
  let new_idx = self.nodes.length()
  self.nodes.push(new_node)
  self.nodes[cur].edges[char_val] = new_idx
  self.size = self.size + 1

  // Set suffix link for new node
  if new_len == 1 {
    // Single character palindrome: suffix link to even root (empty string)
    self.nodes[new_idx].suffix_link = 1
  } else {
    // Find suffix link by following parent's suffix link
    let suffix_parent = self.get_suffix_link(
      self.nodes[cur].suffix_link,
      i,
      char_val,
    )
    self.nodes[new_idx].suffix_link = self.nodes[suffix_parent].edges[char_val]
  }
  self.last = new_idx
  self.nodes[self.last].count = 1
}

///|
/// Build from string
fn Eertree::from_string(s : String) -> Eertree {
  let tree = Eertree()
  for c in s {
    tree.add_char(c)
  }
  tree
}

///|
/// Get number of distinct palindromes
fn Eertree::count_distinct(self : Eertree) -> Int {
  self.size
}

///|
/// Propagate counts from children to parents (suffix links)
/// After this, count[v] represents total occurrences of palindrome v
fn Eertree::propagate_counts(self : Eertree) -> Unit {
  // Process nodes in reverse order (children before parents in suffix tree)
  // This ensures when we process a node, all its suffix-children are already processed
  let start = self.nodes.length() - 1
  for i in start>=..2 {
    let suffix = self.nodes[i].suffix_link
    self.nodes[suffix].count = self.nodes[suffix].count + self.nodes[i].count
  }
}

///|
/// Get total number of palindrome occurrences (counting multiplicity)
fn Eertree::count_total(self : Eertree) -> Int {
  self.nodes[2:].fold(init=0, (acc, node) => acc + node.count)
}

///|
/// Get all distinct palindromes as strings
fn Eertree::get_palindromes(self : Eertree) -> Array[String] {
  let result : Array[String] = []

  // DFS from both roots to collect all palindromes
  fn dfs(
    tree : Eertree,
    node : Int,
    current : Array[Int],
    result : Array[String],
  ) -> Unit {
    // Skip roots for output
    if node >= 2 {
      // Build palindrome string
      let len = tree.nodes[node].len
      let sb = StringBuilder::new()
      // current holds characters from center outward.
      // Left half is reverse(current); right half is current (skip center if odd).
      let last = current.length() - 1
      for i in last>=..0 {
        sb.write_char(Int::unsafe_to_char(current[i]))
      }
      let start = if len % 2 == 0 { 0 } else { 1 }
      for i in start..<current.length() {
        sb.write_char(Int::unsafe_to_char(current[i]))
      }
      result.push(sb.to_string())
    }

    // Explore children
    for c in 0..<256 {
      let child = tree.nodes[node].edges[c]
      if child >= 0 {
        current.push(c)
        dfs(tree, child, current, result)
        let _ = current.pop()
      }
    }
  }

  // Start from odd root (single chars and odd palindromes)
  dfs(self, 0, [], result)
  // Start from even root (empty and even palindromes)
  dfs(self, 1, [], result)
  result
}

///|
/// Get length of longest palindrome
fn Eertree::longest_length(self : Eertree) -> Int {
  self.nodes[2:].iter().map(n => n.len).maximum().unwrap_or(0)
}

///|
/// Check if string is palindrome using the tree
/// We navigate from appropriate root following character edges
fn Eertree::contains_palindrome(self : Eertree, p : String) -> Bool {
  if p.length() == 0 {
    return true
  }

  // First check if p is actually a palindrome
  for i in 0..<(p.length() / 2) {
    if p[i] != p[p.length() - 1 - i] {
      return false // Not a palindrome
    }
  }

  // Navigate tree: edges from node with palindrome P and char c lead to cPc
  // So we traverse from inside out: start from center, add chars outward
  let start = if p.length() % 2 == 1 { 0 } else { 1 }

  // For odd length: traverse from center outward
  // For even length: traverse from middle pair outward
  let mid = p.length() / 2
  let start_idx = if p.length() % 2 == 1 { mid } else { mid - 1 }

  // Navigate outward from center
  let node = for i = start_idx, cur = start {
    if i < 0 {
      break cur
    }
    let c = p[i].to_int()
    let next = self.nodes[cur].edges[c]
    if next < 0 {
      break -1
    } else {
      continue i - 1, next
    }
  }
  if node < 0 {
    return false
  }

  // Check if we reached a node with correct length
  self.nodes[node].len == p.length()
}

///|
/// Get the palindrome represented by a node
fn Eertree::get_palindrome_at(self : Eertree, node_idx : Int) -> String {
  if node_idx < 2 {
    return ""
  }

  // Find the path from root to this node
  let path : Array[Int] = []

  // Find which character leads to this node
  fn find_path(
    tree : Eertree,
    target : Int,
    current : Int,
    path : Array[Int],
  ) -> Bool {
    if current == target {
      return true
    }
    for c in 0..<256 {
      let child = tree.nodes[current].edges[c]
      if child >= 0 && child == target {
        path.push(c)
        return true
      }
      if child >= 0 {
        path.push(c)
        if find_path(tree, target, child, path) {
          return true
        }
        let _ = path.pop()
      }
    }
    false
  }

  // Try from odd root
  let start = if self.nodes[node_idx].len % 2 == 1 { 0 } else { 1 }
  let _ = find_path(self, node_idx, start, path)

  // Build palindrome string
  let len = self.nodes[node_idx].len
  let sb = StringBuilder::new()
  let last = path.length() - 1
  for i in last>=..0 {
    sb.write_char(Int::unsafe_to_char(path[i]))
  }
  let start = if len % 2 == 0 { 0 } else { 1 }
  for i in start..<path.length() {
    sb.write_char(Int::unsafe_to_char(path[i]))
  }
  sb.to_string()
}

///|
/// Count the number of distinct palindromic substrings in `s`.
///
/// Each position in the string contributes at most one new palindrome,
/// so the result is always between 0 and `s.length()` inclusive.
///
/// Time complexity: O(n) where n = s.length().
///
/// Example:
/// ```
/// distinct_count("ababa")  // => 5  ("a", "b", "aba", "bab", "ababa")
/// distinct_count("aaaa")   // => 4  ("a", "aa", "aaa", "aaaa")
/// distinct_count("")        // => 0
/// ```
pub fn distinct_count(s : String) -> Int {
  Eertree::from_string(s).count_distinct()
}

///|
/// Return the length of the longest palindromic substring of `s`.
///
/// Builds the palindromic tree in O(n) and scans all real nodes for the
/// maximum length in O(n).  Returns 0 for the empty string.
///
/// Example:
/// ```
/// longest_length("abacaba")  // => 7  (the whole string)
/// longest_length("abba")     // => 4  ("abba")
/// longest_length("")          // => 0
/// ```
pub fn longest_length(s : String) -> Int {
  Eertree::from_string(s).longest_length()
}

///|
/// Return all distinct palindromic substrings of `s` as an array of strings.
///
/// The array contains exactly `distinct_count(s)` elements.  The order
/// follows the DFS traversal of the palindromic tree: odd-length palindromes
/// (rooted at the imaginary -1 node) come before even-length ones, and
/// within each group siblings appear in ascending character order.
///
/// Time and space complexity: O(n) for building the tree plus O(n * L) in
/// the worst case to materialise the strings, where L is the average
/// palindrome length.
///
/// Example:
/// ```
/// palindromes("aba")   // => ["a", "b", "aba"]  (order may vary)
/// palindromes("abba")  // => ["a", "b", "bb", "abba"]  (order may vary)
/// palindromes("")       // => []
/// ```
pub fn palindromes(s : String) -> Array[String] {
  Eertree::from_string(s).get_palindromes()
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "eertree basic" {
  let tree = Eertree::from_string("abba")

  // Distinct palindromes: "a", "b", "bb", "abba"
  inspect(tree.count_distinct(), content="4")
}

///|
test "eertree single char" {
  let tree = Eertree::from_string("aaaa")

  // Distinct palindromes: "a", "aa", "aaa", "aaaa"
  inspect(tree.count_distinct(), content="4")
}

///|
test "eertree all different" {
  let tree = Eertree::from_string("abcd")

  // Distinct palindromes: "a", "b", "c", "d"
  inspect(tree.count_distinct(), content="4")
}

///|
test "eertree abacaba" {
  let tree = Eertree::from_string("abacaba")

  // Distinct palindromes: "a", "b", "c", "aba", "aca", "bacab", "abacaba"
  inspect(tree.count_distinct(), content="7")
}

///|
test "eertree longest" {
  let tree = Eertree::from_string("abacaba")
  inspect(tree.longest_length(), content="7") // "abacaba"
}

///|
test "eertree total count" {
  let tree = Eertree::from_string("aaa")
  tree.propagate_counts()

  // "a" appears 3 times, "aa" appears 2 times, "aaa" appears 1 time
  // Total = 3 + 2 + 1 = 6
  inspect(tree.count_total(), content="6")
}

///|
test "eertree contains" {
  let tree = Eertree::from_string("abacaba")
  inspect(tree.contains_palindrome("aba"), content="true")
  inspect(tree.contains_palindrome("abacaba"), content="true")
  inspect(tree.contains_palindrome("a"), content="true")
  inspect(tree.contains_palindrome("xyz"), content="false")
  inspect(tree.contains_palindrome("ab"), content="false") // not a palindrome
}

///|
test "eertree empty" {
  let tree = Eertree::from_string("")
  inspect(tree.count_distinct(), content="0")
  inspect(tree.longest_length(), content="0")
}

///|
test "eertree get palindromes" {
  let tree = Eertree::from_string("aba")
  let palindromes = tree.get_palindromes()
  // Should contain "a", "b", "aba"
  inspect(palindromes.length(), content="3")

  // Verify each is a palindrome
  for p in palindromes {
    let is_palindrome = for j in 0..<(p.length() / 2) {
      if p[j] != p[p.length() - 1 - j] {
        break false
      }
    } nobreak {
      true
    }
    guard is_palindrome else { fail("Not a palindrome: " + p) }
  }

  // Test get_palindrome_at for a specific node
  // Node 2 should be first palindrome after roots
  let p = tree.get_palindrome_at(2)
  guard p.length() > 0 else { fail("Expected non-empty palindrome") }
}

///|
test "eertree mississippi" {
  let tree = Eertree::from_string("mississippi")

  // Has various palindromes including "i", "s", "p", "ss", "sis", "issi", etc.
  let count = tree.count_distinct()
  guard count > 5 else { fail("Expected more palindromes") }

  // Longest should be "ississi" (7) or similar
  let longest = tree.longest_length()
  guard longest >= 3 else { fail("Expected longer palindrome") }
}

///|
test "eertree incremental" {
  let tree = Eertree()
  tree.add_char('a')
  inspect(tree.count_distinct(), content="1")
  tree.add_char('b')
  inspect(tree.count_distinct(), content="2")
  tree.add_char('a')
  // Now we have "aba" as new palindrome
  inspect(tree.count_distinct(), content="3")
}
