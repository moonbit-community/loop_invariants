// ============================================================================
// SUFFIX TREE - Insertion Algorithm
// ============================================================================
//
// This file contains the core suffix insertion logic. The algorithm inserts
// one suffix at a time by walking down from the root, matching characters
// along edge labels, and either:
//   1. Creating a new leaf edge when no matching edge exists
//   2. Splitting an existing edge when a mismatch occurs mid-edge
//   3. Continuing to the next node when the edge is fully matched
//
// TIME COMPLEXITY: O(n) per suffix, O(n^2) total for all suffixes
// SPACE COMPLEXITY: O(n^2) nodes in worst case

///|
/// Find the index of the edge starting with character `ch` from a given node.
///
/// ALGORITHM:
///   Linear scan through outgoing edges, comparing first character.
///
/// PARAMETERS:
///   - nodes: The node array of the suffix tree
///   - text: The character array of the original text
///   - node_idx: Index of the node to search from
///   - ch: The character to match
///
/// RETURNS:
///   - Some(index) of matching edge in nodes[node_idx].edges, or None if not found
///
/// TIME: O(alphabet_size) worst case, typically O(1) for small alphabets
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
/// Insert a single suffix into the suffix tree.
///
/// ALGORITHM OVERVIEW:
/// ```
/// Starting from root, for suffix text[start..n):
///   1. Find edge matching text[pos] (current position in suffix)
///   2. If no edge found: create new leaf edge, done
///   3. Match suffix against edge label character by character
///   4. If edge fully matched: move to child node, continue from step 1
///   5. If mismatch mid-edge: split edge, create leaf, done
/// ```
///
/// EDGE SPLITTING (the tricky part):
/// ```
/// Before split at position k:
///
///   current ──[start..end)──► child
///                  ↑
///            mismatch at k
///
/// After split:
///
///   current ──[start..k)──► split ──[k..end)──► child (original subtree)
///                              │
///                              └──[j..n)───► leaf (new suffix)
/// ```
///
/// WHY THIS WORKS:
///   - The split node represents the longest common prefix
///   - Original subtree preserved under split node
///   - New suffix branches off at the point of divergence
///   - Tree remains a valid suffix tree after each insertion
///
/// PARAMETERS:
///   - nodes: Mutable node array (will be extended)
///   - text: Character array of the text
///   - start: Starting position of the suffix to insert
///
/// INVARIANT: After insertion, text[start..n) is represented by a root-to-leaf path
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
      invariant: k >= edge.start && k <= edge.end && j >= pos && j <= n,
      reasoning: (
        #|INVARIANT (edge label matching):
        #|  text[edge.start..k) == text[pos..j)
        #|
        #|TERMINATION:
        #|  - k reaches edge.end (edge exhausted, continue outer~ to child)
        #|  - j reaches n or mismatch (split edge, break outer~)
      ),
    }
  } where {
    invariant: pos >= start && pos <= n,
    reasoning: (
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
/// Compute leaf counts for all nodes via post-order DFS.
///
/// ALGORITHM:
///   For each node, leaf_count = sum of children's leaf_counts.
///   Leaf nodes (no edges) have leaf_count = 1.
///
/// PURPOSE:
///   After this, node.leaf_count equals the number of distinct suffixes
///   passing through that node, which equals the number of occurrences
///   of the substring represented by the path from root to that node.
///
/// PARAMETERS:
///   - nodes: The node array (leaf_count fields will be modified)
///   - node_idx: Index of node to process
///
/// RETURNS:
///   The leaf count of the subtree rooted at node_idx
///
/// TIME: O(n) - visits each node exactly once
fn compute_leaf_counts(nodes : Array[Node], node_idx : Int) -> Int {
  // Base case: leaf node
  if nodes[node_idx].edges.length() == 0 {
    nodes[node_idx].leaf_count = 1
    return 1
  }

  // Recursive case: sum children's leaf counts using fold
  let total = nodes[node_idx].edges.fold(init=0, fn(acc, edge) {
    acc + compute_leaf_counts(nodes, edge.child)
  })
  nodes[node_idx].leaf_count = total
  total
}

///|
/// Build a suffix tree from a string using naive O(n^2) construction.
///
/// ALGORITHM:
///   1. Append sentinel to ensure all suffixes end at leaves
///   2. Insert each suffix text[i..n) for i = 0, 1, ..., n-1
///   3. Compute leaf counts for occurrence queries
///
/// EXAMPLE for "banana":
/// ```
///   Insert "banana$"  -> creates path for full string
///   Insert "anana$"   -> shares "ana" prefix, splits
///   Insert "nana$"    -> creates new branch from root
///   Insert "ana$"     -> shares with "anana$"
///   Insert "na$"      -> shares with "nana$"
///   Insert "a$"       -> shares prefix
///   Insert "$"        -> single edge from root
/// ```
///
/// PARAMETERS:
///   - s: The input string
///
/// RETURNS:
///   A suffix tree supporting O(m) substring queries
///
/// TIME: O(n^2) construction
/// SPACE: O(n^2) nodes and edges
pub fn SuffixTree::new(s : String) -> SuffixTree {
  let text = s.to_array()
  text.push(SENTINEL)
  let nodes : Array[Node] = [Node::new()]

  // Insert all suffixes
  for start = 0; start < text.length(); start = start + 1 {
    insert_suffix(nodes, text, start)
  } where {
    invariant: start >= 0 && start <= text.length(),
    reasoning: (
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
