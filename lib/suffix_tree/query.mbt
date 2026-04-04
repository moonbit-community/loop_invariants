// ============================================================================
// SUFFIX TREE - Query Operations
// ============================================================================
//
// Substring queries on the suffix tree. Both operations work by walking down
// the tree, matching the query pattern against edge labels.
//
// KEY INSIGHT:
//   Every substring of text is a prefix of some suffix.
//   Walking from the root, matching query characters, locates the substring.
//   The subtree below the matching position represents all suffixes that
//   contain the pattern, so its leaf count equals the occurrence count.
//
// TIME: O(m) where m = pattern length (independent of text length).

///|
/// Check whether `pattern` occurs as a substring in the indexed text.
///
/// The search walks from the root, matching pattern characters against edge
/// labels one by one. Three outcomes are possible at each step:
///
/// - No edge starts with the current pattern character: pattern not found,
///   return `false`.
/// - The pattern is exhausted before or at an edge boundary: pattern found,
///   return `true`. (A match ending mid-edge is still a valid substring.)
/// - The edge label is exhausted before the pattern: descend to the child node
///   and continue matching.
/// - A character mismatch occurs mid-edge: pattern not found, return `false`.
///
/// Parameters:
/// - `self`    - The suffix tree to query.
/// - `pattern` - The substring to search for.
///
/// Returns `true` if `pattern` appears at least once in the indexed text,
/// `false` otherwise. An empty pattern always returns `true`.
///
/// Time: O(m)  Space: O(m) for the pattern character array.
///
/// Example:
/// ```mbt check
/// test {
///   let tree = @suffix_tree.SuffixTree::new("banana")
///   assert_true(tree.contains("ana")) // occurs at positions 1 and 3
///   assert_true(tree.contains("ban")) // prefix of text
///   assert_false(tree.contains("xyz")) // not in text
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
    } nobreak {
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
      proof_invariant: k >= edge.start && k <= edge.end && pi >= i && pi <= p.length(),
      proof_reasoning: (
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
    proof_invariant: node >= 0 &&
    node < self.nodes.length() &&
    i >= 0 &&
    i <= p.length(),
    proof_reasoning: (
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
/// Count the number of (possibly overlapping) occurrences of `pattern` in the
/// indexed text.
///
/// The algorithm first walks down the tree matching `pattern`, exactly as in
/// `contains`. If the pattern is found, the `leaf_count` of the node (or edge
/// child) where the match ends is returned. Each leaf under that node
/// represents one suffix that begins with `pattern`, so the leaf count equals
/// the number of times the pattern occurs.
///
/// Example for `"banana"`:
/// ```
/// count_occurrences("ana") = 2
///   leaf 1: suffix "anana$" — "ana" appears at its start (text position 1)
///   leaf 2: suffix "ana$"   — "ana" is the full suffix   (text position 3)
///
/// count_occurrences("na") = 2
///   leaf 1: suffix "nana$"  — "na" at its start (text position 2)
///   leaf 2: suffix "na$"    — "na" is the full suffix (text position 4)
///
/// count_occurrences("ban") = 1
///   Only suffix "banana$" contains "ban".
/// ```
///
/// Parameters:
/// - `self`    - The suffix tree to query.
/// - `pattern` - The substring whose occurrences are to be counted.
///
/// Returns the number of times `pattern` appears in the text. Returns 0 for
/// an empty pattern (by convention) and 0 when the pattern is not found.
///
/// Time: O(m)  Space: O(m) for the pattern character array.
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
    } nobreak {
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
      proof_invariant: k >= edge.start && k <= edge.end && pi >= i && pi <= p.length(),
      proof_reasoning: (
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
    proof_invariant: node >= 0 &&
    node < self.nodes.length() &&
    i >= 0 &&
    i <= p.length(),
    proof_reasoning: (
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
