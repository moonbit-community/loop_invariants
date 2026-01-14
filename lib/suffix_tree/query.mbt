// ============================================================================
// SUFFIX TREE - Query Operations
// ============================================================================
//
// Substring queries on the suffix tree. Both operations work by walking down
// the tree, matching the query pattern against edge labels.
//
// KEY INSIGHT:
//   Every substring of text is a prefix of some suffix.
//   Walking down from root, matching query characters, finds the substring.
//   The subtree below represents all suffixes containing that substring.
//
// TIME: O(m) where m = pattern length (independent of text length!)

///|
/// Check whether a pattern occurs as a substring in the indexed text.
///
/// ALGORITHM:
/// ```
///   Walk down from root, matching pattern characters against edge labels.
///
///   At each node:
///     1. Find edge starting with pattern[i]
///     2. If no edge: pattern not found, return false
///     3. Match pattern against edge label
///     4. If pattern exhausted: found! return true
///     5. If edge exhausted: move to child, continue
///     6. If mismatch mid-edge: not found, return false
/// ```
///
/// WHY THIS WORKS:
///   - If pattern exists in text, it's a prefix of some suffix
///   - That suffix has a root-to-leaf path in the tree
///   - We can match the pattern along that path
///   - Partial matches (ending mid-edge) are still valid substrings
///
/// PARAMETERS:
///   - self: The suffix tree
///   - pattern: The substring to search for
///
/// RETURNS:
///   true if pattern occurs in text, false otherwise
///
/// TIME: O(m) where m = pattern.length()
/// SPACE: O(m) for pattern array conversion
///
/// EXAMPLE:
/// ```mbt check
/// test {
///   let tree = @suffix_tree.SuffixTree::new("banana")
///   assert_true(tree.contains("ana")) // true - occurs at positions 1 and 3
///   assert_true(tree.contains("ban")) // true - prefix of text
///   assert_false(tree.contains("xyz")) // false - not in text
/// }
/// ```
pub fn SuffixTree::contains(self : SuffixTree, pattern : String) -> Bool {
  let p = pattern.to_array()

  // Empty pattern is always found
  if p.length() == 0 {
    return true
  }

  // Walk down tree matching pattern
  outer~: for node = 0, i = 0 {
    guard i < p.length() else { break true }

    // Find edge starting with p[i]
    let edges = self.nodes[node].edges
    let edge_idx : Int = for idx, edge in edges {
      if self.text[edge.start] == p[i] {
        break idx
      }
    } else {
      break outer~ false
    }

    // Match pattern against edge label
    let edge = edges[edge_idx]
    for k = edge.start, pi = i {
      // Pattern fully matched (possibly mid-edge)
      if pi == p.length() {
        break outer~ true
      }
      // Edge fully matched - continue to child
      if k == edge.end {
        continue outer~ edge.child, pi
      }
      // Mismatch mid-edge - pattern not found
      guard self.text[k] == p[pi] else { break outer~ false }
      continue k + 1, pi + 1
    } where {
      invariant: k >= edge.start && k <= edge.end && pi >= i && pi <= p.length(),
      reasoning: (
        #|INVARIANT (edge label matching):
        #|  self.text[edge.start..k) == p[i..pi)
        #|
        #|TERMINATION:
        #|  - pi reaches p.length() (pattern matched)
        #|  - k reaches edge.end (edge exhausted, continue to child)
        #|  - character mismatch (pattern not found)
      ),
    }
  } where {
    invariant: node >= 0 &&
    node < self.nodes.length() &&
    i >= 0 &&
    i <= p.length(),
    reasoning: (
      #|INVARIANT (tree walk progress):
      #|  p[0..i) has been matched along the path from root to node.
      #|  We are at a valid node in the tree.
      #|
      #|MAINTENANCE:
      #|  When edge is fully matched, we move to child and advance i.
      #|
      #|TERMINATION:
      #|  - i reaches p.length() (pattern found)
      #|  - No matching edge (pattern not found)
      #|  - Mismatch mid-edge (pattern not found)
    ),
  }
}

///|
/// Count the number of occurrences of a pattern in the indexed text.
///
/// ALGORITHM:
/// ```
///   1. Walk down tree matching pattern (same as contains)
///   2. If pattern found, return leaf_count of the subtree
///   3. leaf_count = number of suffixes passing through = occurrences
/// ```
///
/// KEY INSIGHT:
///   Each leaf represents a unique suffix. If we reach a subtree after
///   matching pattern P, every leaf below represents a suffix starting
///   with P. The number of leaves = number of occurrences.
///
/// EXAMPLE for "banana":
/// ```
///   count_occurrences("ana") = 2
///     - "anana$" suffix contains "ana" at start
///     - "ana$" suffix is "ana"
///     Both are leaves under the "ana" subtree
///
///   count_occurrences("na") = 2
///     - "nana$" contains "na" at start
///     - "na$" is "na"
///
///   count_occurrences("ban") = 1
///     - Only "banana$" contains "ban"
/// ```
///
/// PARAMETERS:
///   - self: The suffix tree
///   - pattern: The substring to count
///
/// RETURNS:
///   Number of (possibly overlapping) occurrences of pattern in text.
///   Empty pattern returns 0 by convention.
///
/// TIME: O(m) where m = pattern.length()
pub fn SuffixTree::count_occurrences(
  self : SuffixTree,
  pattern : String,
) -> Int {
  let p = pattern.to_array()

  // Convention: empty pattern has 0 occurrences
  if p.length() == 0 {
    return 0
  }
  outer~: for node = 0, i = 0 {
    guard i < p.length() else { break 0 }

    // Find edge starting with p[i]
    let edges = self.nodes[node].edges
    let edge_idx : Int = for idx, edge in edges {
      if self.text[edge.start] == p[i] {
        break idx
      }
    } else {
      break outer~ 0
    }

    // Match pattern against edge label
    let edge = edges[edge_idx]
    for k = edge.start, pi = i {
      // Pattern matched - return leaf count of child subtree
      if pi == p.length() {
        break outer~ self.nodes[edge.child].leaf_count
      }
      // Edge fully matched - continue to child
      if k == edge.end {
        continue outer~ edge.child, pi
      }
      // Mismatch mid-edge
      guard self.text[k] == p[pi] else { break outer~ 0 }
      continue k + 1, pi + 1
    } where {
      invariant: k >= edge.start && k <= edge.end && pi >= i && pi <= p.length(),
      reasoning: (
        #|INVARIANT (edge label matching):
        #|  self.text[edge.start..k) == p[i..pi)
        #|
        #|TERMINATION:
        #|  - pi reaches p.length() (pattern matched)
        #|  - k reaches edge.end (edge exhausted, continue to child)
        #|  - character mismatch (return 0)
      ),
    }
  } where {
    invariant: node >= 0 &&
    node < self.nodes.length() &&
    i >= 0 &&
    i <= p.length(),
    reasoning: (
      #|INVARIANT (tree walk progress):
      #|  p[0..i) has been matched along the path from root to node.
      #|  We are at a valid node in the tree.
      #|
      #|MAINTENANCE:
      #|  When edge is fully matched, we move to child and advance i.
      #|
      #|TERMINATION:
      #|  - i reaches p.length() (pattern found, return leaf count)
      #|  - No matching edge (return 0)
      #|  - Mismatch mid-edge (return 0)
    ),
  }
}
