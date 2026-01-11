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
/// A node in the palindromic tree
priv struct EertreeNode {
  len : Int // Length of palindrome (-1 for odd root, 0 for even root)
  mut suffix_link : Int // Index of longest proper palindromic suffix
  edges : Array[Int] // edges[c] = index of node for palindrome formed by adding c on both ends
  mut count : Int // Number of occurrences of this palindrome
}

///|
fn EertreeNode::new(len : Int) -> EertreeNode {
  {
    len,
    suffix_link: 0,
    edges: Array::make(256, -1), // ASCII characters
    count: 0,
  }
}

///|
/// Palindromic Tree (Eertree)
priv struct Eertree {
  nodes : Array[EertreeNode]
  text : Array[Int] // Store characters as integers for faster access
  mut last : Int // Index of node representing longest suffix palindrome
  mut size : Int // Number of distinct palindromes (excluding roots)
}

///|
fn Eertree::new() -> Eertree {
  // Create two roots
  let nodes : Array[EertreeNode] = []

  // Node 0: root for odd-length palindromes (imaginary, length -1)
  let odd_root = EertreeNode::new(-1)
  nodes.push(odd_root)

  // Node 1: root for even-length palindromes (empty string, length 0)
  let even_root = EertreeNode::new(0)
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
    }
    // Follow suffix link to try shorter palindrome
    continue self.nodes[cur].suffix_link
  } where {
    invariant: cur >= 0 && cur < self.nodes.length(),
    reasoning: (
      #|INVARIANT (suffix search):
      #|cur is a palindromic suffix of text[0..i), and all longer suffix
      #|palindromes have already been checked and cannot be extended by c.
      #|MAINTENANCE:
      #|If the character before this palindrome is not c, move to the suffix
      #|link, which is the next shorter palindromic suffix.
      #|TERMINATION:
      #|Lengths strictly decrease along suffix links and eventually reach the
      #|odd root (len = -1), for which prev_pos = i and text[i] == c, so the
      #|loop always finds a valid extendable suffix.
    ),
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
  let new_node = EertreeNode::new(new_len)
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
  let tree = Eertree::new()
  for i = 0; i < s.length(); i = i + 1 {
    let char_code = s[i].to_int()
    // Convert UInt16 to Char for add_char
    tree.add_char(Int::unsafe_to_char(char_code))
  } where {
    invariant: i >= 0 && i <= s.length() && tree.text.length() == i,
    reasoning: (
      #|INVARIANT (prefix build):
      #|The tree contains all distinct palindromes from s[0..i), and the
      #|stored text length equals i (processed prefix length).
      #|MAINTENANCE:
      #|Insert s[i], extending the tree with all palindromes ending at i.
      #|TERMINATION:
      #|At i = s.length(), the tree represents all palindromes of the string.
    ),
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
  for i = self.nodes.length() - 1; i >= 2; i = i - 1 {
    let suffix = self.nodes[i].suffix_link
    self.nodes[suffix].count = self.nodes[suffix].count + self.nodes[i].count
  } where {
    invariant: i >= 1 && i < self.nodes.length(),
    reasoning: (
      #|INVARIANT (count propagation):
      #|All nodes with index > i have already pushed their counts to their
      #|suffix links, so their parents reflect those occurrences.
      #|MAINTENANCE:
      #|Add node i's count to its suffix link, aggregating occurrences of
      #|longer palindromes into their largest proper palindromic suffix.
      #|TERMINATION:
      #|After i = 1, every node's count includes contributions from all
      #|palindromes that have it as a suffix.
    ),
  }
}

///|
/// Get total number of palindrome occurrences (counting multiplicity)
fn Eertree::count_total(self : Eertree) -> Int {
  let mut total = 0
  for i = 2; i < self.nodes.length(); i = i + 1 {
    total = total + self.nodes[i].count
  } where {
    invariant: i >= 2 && i <= self.nodes.length(),
    reasoning: (
      #|INVARIANT (sum counts):
      #|total equals the sum of counts for nodes in [2, i).
      #|MAINTENANCE:
      #|Add node i's count to the running total.
      #|TERMINATION:
      #|At i = nodes.length(), total is the sum over all palindrome nodes.
    ),
  }
  total
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
      // First half (including middle for odd length)
      for i = 0; i < current.length(); i = i + 1 {
        sb.write_char(Int::unsafe_to_char(current[i]))
      } where {
        invariant: i >= 0 && i <= current.length(),
        reasoning: (
          #|INVARIANT (first half):
          #|sb contains the characters of current[0..i) in order, so it is
          #|the prefix used to build the palindrome string.
          #|MAINTENANCE:
          #|Append current[i] to extend the prefix by one character.
          #|TERMINATION:
          #|At i = current.length(), the first half (and middle if odd) is built.
        ),
      }
      // Second half (reverse, skip middle for odd length)
      let start = if len % 2 == 0 {
        current.length() - 1
      } else {
        current.length() - 2
      }
      for i = start; i >= 0; i = i - 1 {
        sb.write_char(Int::unsafe_to_char(current[i]))
      } where {
        invariant: i >= -1 && i <= start,
        reasoning: (
          #|INVARIANT (mirror half):
          #|sb already contains the first half, and the mirrored suffix for
          #|indices (i+1..start] has been appended in reverse order.
          #|MAINTENANCE:
          #|Append current[i] to extend the mirrored half by one character.
          #|TERMINATION:
          #|At i = -1, the full palindrome string is constructed.
        ),
      }
      result.push(sb.to_string())
    }

    // Explore children
    for c = 0; c < 256; c = c + 1 {
      let child = tree.nodes[node].edges[c]
      if child >= 0 {
        current.push(c)
        dfs(tree, child, current, result)
        let _ = current.pop()

      }
    } where {
      invariant: c >= 0 && c <= 256,
      reasoning: (
        #|INVARIANT (child DFS):
        #|All outgoing edges with labels < c have been explored, and current
        #|has been restored to the path for node after each recursive call.
        #|MAINTENANCE:
        #|If an edge exists, push its label, recurse, then pop to backtrack.
        #|TERMINATION:
        #|At c = 256, every child edge has been visited exactly once.
      ),
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
  let mut max_len = 0
  for i = 2; i < self.nodes.length(); i = i + 1 {
    if self.nodes[i].len > max_len {
      max_len = self.nodes[i].len
    }
  } where {
    invariant: i >= 2 && i <= self.nodes.length(),
    reasoning: (
      #|INVARIANT (max length):
      #|max_len equals the maximum palindrome length among nodes in [2, i).
      #|MAINTENANCE:
      #|Update max_len when a longer node is found.
      #|TERMINATION:
      #|At i = nodes.length(), max_len is the longest palindrome length.
    ),
  }
  max_len
}

///|
/// Check if string is palindrome using the tree
/// We navigate from appropriate root following character edges
fn Eertree::contains_palindrome(self : Eertree, p : String) -> Bool {
  if p.length() == 0 {
    return true
  }

  // First check if p is actually a palindrome
  for i = 0; i < p.length() / 2; i = i + 1 {
    if p[i] != p[p.length() - 1 - i] {
      return false // Not a palindrome
    }
  } where {
    invariant: i >= 0 && i <= p.length() / 2,
    reasoning: (
      #|INVARIANT (palindrome check):
      #|All checked pairs in indices [0, i) are symmetric, so the prefix tested
      #|so far remains palindromic.
      #|MAINTENANCE:
      #|Compare the next symmetric pair; return false on mismatch.
      #|TERMINATION:
      #|At i = p.length()/2, all symmetric pairs match and p is a palindrome.
    ),
  }

  // Navigate tree: edges from node with palindrome P and char c lead to cPc
  // So we traverse from inside out: start from center, add chars outward
  let start = if p.length() % 2 == 1 { 0 } else { 1 }
  let mut node = start

  // For odd length: traverse from center outward
  // For even length: traverse from middle pair outward
  let mid = p.length() / 2
  let start_idx = if p.length() % 2 == 1 { mid } else { mid - 1 }

  // Navigate outward from center
  for i = start_idx; i >= 0; i = i - 1 {
    let c = p[i].to_int()
    let next = self.nodes[node].edges[c]
    if next < 0 {
      return false
    }
    node = next
  } where {
    invariant: i >= -1 && i <= start_idx,
    reasoning: (
      #|INVARIANT (center expansion):
      #|node represents the palindrome built from the center using characters
      #|p[i+1..start_idx], added symmetrically outward.
      #|MAINTENANCE:
      #|Follow the edge labeled by p[i]; failure means the palindrome is not
      #|represented in the tree.
      #|TERMINATION:
      #|At i = -1, node represents the full palindrome p.
    ),
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
    for c = 0; c < 256; c = c + 1 {
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
    } where {
      invariant: c >= 0 && c <= 256,
      reasoning: (
        #|INVARIANT (path search):
        #|All outgoing edges with labels < c have been explored, and path has
        #|been restored after backtracking from any explored child.
        #|MAINTENANCE:
        #|Try edge c; if it does not lead to target, backtrack and continue.
        #|TERMINATION:
        #|At c = 256, all children have been tried with no path found.
      ),
    }
    false
  }

  // Try from odd root
  let start = if self.nodes[node_idx].len % 2 == 1 { 0 } else { 1 }
  let _ = find_path(self, node_idx, start, path)

  // Build palindrome string
  let len = self.nodes[node_idx].len
  let sb = StringBuilder::new()
  for i = 0; i < path.length(); i = i + 1 {
    sb.write_char(Int::unsafe_to_char(path[i]))
  } where {
    invariant: i >= 0 && i <= path.length(),
    reasoning: (
      #|INVARIANT (prefix build):
      #|sb contains path[0..i) in order, forming the first half of the palindrome.
      #|MAINTENANCE:
      #|Append path[i] to extend the prefix by one character.
      #|TERMINATION:
      #|At i = path.length(), the first half is complete.
    ),
  }
  let rev_start = if len % 2 == 0 {
    path.length() - 1
  } else {
    path.length() - 2
  }
  for i = rev_start; i >= 0; i = i - 1 {
    sb.write_char(Int::unsafe_to_char(path[i]))
  } where {
    invariant: i >= -1 && i <= rev_start,
    reasoning: (
      #|INVARIANT (mirror build):
      #|sb already contains the first half and the mirrored suffix for indices
      #|(i+1..rev_start] has been appended in reverse order.
      #|MAINTENANCE:
      #|Append path[i] to extend the mirrored half.
      #|TERMINATION:
      #|At i = -1, the palindrome string is fully constructed.
    ),
  }
  sb.to_string()
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

  // Palindromes: "a", "b", "c", "aba", "aca", "bacab"... wait let me count
  // Actually: "a"(4), "b"(2), "c"(1), "aba"(2), "bacab"(1), "abacaba"(1)
  // But distinct count doesn't include "aca" as it's not a substring
  // Let me reconsider: "a", "b", "c", "aba", "bacab", "abacaba" = 6
  // Wait, is "aca" in "abacaba"? Position 2-4: "aca" yes!
  // So: "a", "b", "c", "aba", "aca", "bacab", "abacaba" = 7
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
  for i = 0; i < palindromes.length(); i = i + 1 {
    let p = palindromes[i]
    let is_palindrome = for j = 0; j < p.length() / 2; j = j + 1 {
      if p[j] != p[p.length() - 1 - j] {
        break false
      }
    } else {
      true
    } where {
      invariant: j >= 0 && j <= p.length() / 2,
      reasoning: (
        #|All checked pairs (0..j) are symmetric for this palindrome candidate.
      ),
    }
    guard is_palindrome else { fail("Not a palindrome: " + p) }
  } where {
    invariant: i >= 0 && i <= palindromes.length(),
    reasoning: (
      #|All palindromes in palindromes[0..i) have been verified.
    ),
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
  let tree = Eertree::new()
  tree.add_char('a')
  inspect(tree.count_distinct(), content="1")
  tree.add_char('b')
  inspect(tree.count_distinct(), content="2")
  tree.add_char('a')
  // Now we have "aba" as new palindrome
  inspect(tree.count_distinct(), content="3")
}
