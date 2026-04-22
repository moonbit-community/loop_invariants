// ============================================================================
// SUFFIX TREE - Insertion Algorithm
// ============================================================================
//
// This file contains the core suffix insertion logic. The algorithm inserts
// one suffix at a time by walking down from the root, matching characters
// along edge labels, and either:
//   1. Creating a new leaf edge when no matching edge exists.
//   2. Splitting an existing edge when a mismatch occurs mid-edge.
//   3. Continuing to the next node when the edge is fully matched.
//
// TIME COMPLEXITY: O(n) per suffix, O(n^2) total for all suffixes.
// SPACE COMPLEXITY: O(n^2) nodes in the worst case (many repeated characters).

///|
/// Find the index of the outgoing edge from `node_idx` whose label starts with
/// character `ch`.
///
/// The search is a linear scan because no two edges from the same node share
/// the same first character (a required suffix-tree invariant). For typical
/// alphabets the average number of edges per node is small, so in practice
/// this is fast.
///
/// Parameters:
/// - `nodes`    - The flat node array of the suffix tree.
/// - `text`     - The character array of the indexed text.
/// - `node_idx` - Index of the node whose outgoing edges are searched.
/// - `ch`       - The first character of the desired edge label.
///
/// Returns `Some(i)` where `i` is the position of the matching edge inside
/// `nodes[node_idx].edges`, or `None` if no such edge exists.
///
/// Time: O(|alphabet|) worst case, O(1) on average for small alphabets.
fn find_edge(
  nodes : Array[Node],
  text : Array[Char],
  node_idx : Int,
  ch : Char,
) -> Int? {
  let edges = nodes[node_idx].edges
  edges.search_by(e => text[e.start] == ch)
}

///|
/// Insert a single suffix `text[start..n)` into the suffix tree.
///
/// The algorithm walks from the root, consuming the suffix character by
/// character along edge labels. Three cases arise during the walk:
///
/// Case A — no matching edge:
///   A new leaf edge spanning `text[pos..n)` is added directly to the current
///   node. The suffix is now fully represented.
///
/// Case B — edge fully matched:
///   All characters of the current edge label matched. Descend to the child
///   node and continue matching the remaining suffix.
///
/// Case C — mismatch mid-edge:
///   The suffix and the edge label diverge at position `k` inside the edge.
///   The edge is split by inserting a new internal (split) node:
///
/// ```
/// Before split at offset k inside [edge.start, edge.end):
///
///   current ──[edge.start .. edge.end)──► child
///                        ↑ mismatch here (offset k)
///
/// After split:
///
///   current ──[edge.start .. k)──► split ──[k .. edge.end)──► child
///                                      │
///                                      └──[j .. n)──────────► leaf
/// ```
///
/// The split node holds the longest common prefix; the original subtree and
/// the new leaf branch off below it.
///
/// Parameters:
/// - `nodes` - Mutable node array (new nodes are appended during splits).
/// - `text`  - Character array of the full text (including sentinel).
/// - `start` - Starting index of the suffix to insert.
///
/// Post-condition: `text[start..n)` is represented by a unique root-to-leaf
/// path in the tree.
fn insert_suffix(nodes : Array[Node], text : Array[Char], start : Int) -> Unit {
  let n = text.length()

  // Main insertion loop: walk down tree, matching suffix characters
  outer~: for current = 0, pos = start {
    // Base case: entire suffix has been matched (shouldn't happen with sentinel)
    guard pos < n else { break }

    // Step 1: Find edge starting with current suffix character
    // Case A: No matching edge - create new leaf
    guard find_edge(nodes, text, current, text[pos]) is Some(edge_idx) else {
      let leaf = nodes.length()
      nodes.push(Node::new())
      nodes[current].edges.push({ start: pos, end: n, child: leaf })
      break
    }

    // Step 2: Match suffix against edge label
    let edge = nodes[current].edges[edge_idx]

    // Match characters until mismatch or edge end
    for k = edge.start, j = pos {
      // Case B: Edge fully matched - continue to child node
      if k == edge.end {
        continue outer~ edge.child, j
      }
      // Continue matching if characters match
      guard j < n && text[k] == text[j] else {
        // Case C: Mismatch mid-edge - must split
        //
        // BEFORE:
        //   current ──[edge.start..edge.end)──► edge.child
        //
        // AFTER:
        //   current ──[edge.start..k)──► split ──[k..edge.end)──► edge.child
        //                                   └──[j..n)──────────► leaf
        //
        let split = nodes.length()
        nodes.push(Node::new())
        let leaf = nodes.length()
        nodes.push(Node::new())

        // Wire up the split: original subtree becomes child of split
        nodes[split].edges.push({ start: k, end: edge.end, child: edge.child })
        // New leaf for remaining suffix
        nodes[split].edges.push({ start: j, end: n, child: leaf })
        // Update original edge to point to split (shortened label)
        nodes[current].edges[edge_idx] = {
          start: edge.start,
          end: k,
          child: split,
        }
        break outer~
      }
      continue k + 1, j + 1
    } where {
      proof_invariant: k >= edge.start && k <= edge.end && j >= pos && j <= n,
      proof_reasoning: (
        #|INVARIANT (edge label matching):
        #|  text[edge.start..k) == text[pos..j)
        #|
        #|TERMINATION:
        #|  - k reaches edge.end (edge exhausted, continue outer~ to child)
        #|  - j reaches n or mismatch (split edge, break outer~)
      ),
    }
  } where {
    proof_invariant: pos >= start && pos <= n,
    proof_reasoning: (
      #|INVARIANT (suffix progress):
      #|  text[start..pos) is represented by the path from root to current.
      #|  text[pos..n) remains to be inserted.
      #|
      #|MAINTENANCE:
      #|  When edge is fully matched, continue outer~ to child node.
      #|
      #|TERMINATION:
      #|  - New leaf created (no matching edge)
      #|  - Edge split (mismatch mid-edge)
      #|  - pos reaches n (suffix fully matched, rare with sentinel)
    ),
  }
}

///|
/// Compute leaf counts for all nodes via a post-order depth-first traversal.
///
/// After this call, `node.leaf_count` equals the number of leaf descendants of
/// that node, which is the number of suffixes that pass through it. Because
/// each leaf corresponds to exactly one suffix, this count also equals the
/// number of occurrences of the path-label (the string spelled out from the
/// root to that node) in the text.
///
/// Base case: a leaf node (no outgoing edges) has `leaf_count = 1`.
/// Recursive case: `leaf_count = sum of children's leaf_counts`.
///
/// Parameters:
/// - `nodes`    - The node array whose `leaf_count` fields will be updated.
/// - `node_idx` - Index of the subtree root to process.
///
/// Returns the leaf count of the subtree rooted at `node_idx`.
///
/// Time: O(n) — each node is visited exactly once.
fn compute_leaf_counts(nodes : Array[Node], node_idx : Int) -> Int {
  // Base case: leaf node
  if nodes[node_idx].edges.length() == 0 {
    nodes[node_idx].leaf_count = 1
    return 1
  }

  // Recursive case: sum children's leaf counts using fold
  let total = nodes[node_idx].edges.fold(init=0, (acc, edge) => {
    acc + compute_leaf_counts(nodes, edge.child)
  })
  nodes[node_idx].leaf_count = total
  total
}

///|
/// Build a suffix tree for string `s` using naive O(n²) construction.
///
/// Construction steps:
/// 1. Append `SENTINEL` (`\0`) to `s` so that every suffix ends at a leaf and
///    no suffix is a prefix of another.
/// 2. Insert each suffix `text[i..n)` for `i = 0, 1, …, n-1` using
///    `insert_suffix`, which handles edge splitting as needed.
/// 3. Run `compute_leaf_counts` so that every node's `leaf_count` is ready for
///    `count_occurrences` queries.
///
/// Example insertion order for `"banana"`:
/// ```
/// Insert "banana$"  -> path for the full string from root
/// Insert "anana$"   -> shares no prefix with existing paths, new branch
/// Insert "nana$"    -> new branch from root
/// Insert "ana$"     -> shares "ana" with "anana$", triggers a split
/// Insert "na$"      -> shares "na" with "nana$", triggers a split
/// Insert "a$"       -> shares "a", triggers a split
/// Insert "$"        -> single sentinel edge from root
/// ```
///
/// Parameters:
/// - `s` - The input string to index.
///
/// Returns a `SuffixTree` supporting O(m) `contains` and `count_occurrences`
/// queries on the original text.
///
/// Time: O(n²)  Space: O(n²)
pub fn SuffixTree::new(s : String) -> SuffixTree {
  let text = s.to_array()
  text.push(SENTINEL)
  let nodes : Array[Node] = [Node::new()]

  // Insert all suffixes
  for start in 0..<text.length() {
    insert_suffix(nodes, text, start)
  } where {
    proof_invariant: start >= 0 && start <= text.length(),
    proof_reasoning: (
      #|INVARIANT (suffix coverage):
      #|  All suffixes text[i..n) for i in [0..start) have been inserted.
      #|  The tree contains exactly those suffix paths.
      #|
      #|MAINTENANCE:
      #|  insert_suffix adds text[start..n) to the tree.
      #|
      #|TERMINATION:
      #|  At start = n, all n suffixes are present.
    ),
  }

  // Compute leaf counts for occurrence queries
  let _ = compute_leaf_counts(nodes, 0)
  { text, nodes }
}
