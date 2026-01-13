// ============================================================================
// SUFFIX TREE - Naive O(n^2) Construction with Edge Compression
// ============================================================================
//
// A suffix tree indexes all suffixes of a string. Each edge stores a substring
// label by (start, end) indices into the original text. This implementation
// builds the tree by inserting all suffixes and splitting edges as needed.
//
// NOTE:
// - We append a sentinel character '\u0000' to ensure every suffix ends at a
//   leaf (no suffix is a prefix of another).
// - The algorithm uses UTF-16 code units (Char) from String::to_array().
//
// TIME COMPLEXITY: O(n^2)
// SPACE COMPLEXITY: O(n^2)

///|
const SENTINEL : Char = '\u0000'

///|
pub(all) struct Edge {
  start : Int
  end : Int // exclusive
  child : Int
}

///|
pub(all) struct Node {
  edges : Array[Edge]
  mut leaf_count : Int
}

///|
pub struct SuffixTree {
  text : Array[Char]
  nodes : Array[Node]
}

///|
fn Node::new() -> Node {
  { edges: [], leaf_count: 0 }
}

///|
fn find_edge(
  nodes : Array[Node],
  text : Array[Char],
  node_idx : Int,
  ch : Char,
) -> Int {
  let edges = nodes[node_idx].edges
  for i = 0; i < edges.length(); i = i + 1 {
    let e = edges[i]
    if text[e.start] == ch {
      return i
    }
  } where {
    invariant: i >= 0 && i <= edges.length(),
    reasoning: (
      #|INVARIANT (find edge):
      #|Edges[0..i) do not start with ch. If an edge starts with ch, it is found.
      #|MAINTENANCE:
      #|Check edge i's first character and return if it matches.
      #|TERMINATION:
      #|At i = deg(node), no outgoing edge starts with ch.
    ),
  }
  -1
}

///|
fn insert_suffix(nodes : Array[Node], text : Array[Char], start : Int) -> Unit {
  let mut current = 0
  let mut pos = start
  let n = text.length()
  for {
    if pos >= n {
      break
    }
    let edge_idx = find_edge(nodes, text, current, text[pos])
    if edge_idx < 0 {
      let leaf = nodes.length()
      nodes.push(Node::new())
      nodes[current].edges.push({ start: pos, end: n, child: leaf })
      break
    }
    let edge = nodes[current].edges[edge_idx]
    let mut k = edge.start
    let mut j = pos
    for {
      if k < edge.end && j < n && text[k] == text[j] {
        k = k + 1
        j = j + 1
        continue
      }
      break
    } where {
      invariant: k >= edge.start && k <= edge.end && j >= pos && j <= n,
      reasoning: (
        #|INVARIANT (edge match):
        #|text[edge.start..k) equals text[pos..j). We are matching the current
        #|suffix against the edge label until a mismatch or edge end.
        #|MAINTENANCE:
        #|Advance both k and j while characters match.
        #|TERMINATION:
        #|When mismatch or end is reached, k and j mark the split point.
      ),
    }
    if k == edge.end {
      current = edge.child
      pos = j
      continue
    }

    // Split edge at position k
    let split = nodes.length()
    nodes.push(Node::new())
    let leaf = nodes.length()
    nodes.push(Node::new())

    // Existing edge becomes child of split
    nodes[split].edges.push({ start: k, end: edge.end, child: edge.child })
    // New leaf edge for the remaining suffix
    nodes[split].edges.push({ start: j, end: n, child: leaf })
    // Update edge from current to point to split
    nodes[current].edges[edge_idx] = { start: edge.start, end: k, child: split }
    break
  } where {
    invariant: pos >= start && pos <= n,
    reasoning: (
      #|INVARIANT (suffix insertion):
      #|The substring text[start..pos) is already represented on the path from
      #|root to current. The remaining suffix text[pos..n) is yet to be inserted.
      #|MAINTENANCE:
      #|Match along an edge or split it to insert the remaining suffix.
      #|TERMINATION:
      #|Insertion ends when a new leaf is created or the suffix is fully matched.
    ),
  }
}

///|
fn compute_leaf_counts(nodes : Array[Node], node_idx : Int) -> Int {
  if nodes[node_idx].edges.length() == 0 {
    nodes[node_idx].leaf_count = 1
    return 1
  }
  let mut total = 0
  for i = 0; i < nodes[node_idx].edges.length(); i = i + 1 {
    let child = nodes[node_idx].edges[i].child
    total = total + compute_leaf_counts(nodes, child)
  } where {
    invariant: i >= 0 && i <= nodes[node_idx].edges.length(),
    reasoning: (
      #|INVARIANT (leaf count):
      #|total equals the sum of leaf counts for edges[0..i).
      #|MAINTENANCE:
      #|Accumulate the child's leaf count into total.
      #|TERMINATION:
      #|At i = deg(node), total is the leaf count of this subtree.
    ),
  }
  nodes[node_idx].leaf_count = total
  total
}

///|
/// Build a suffix tree from a string (naive O(n^2) construction).
pub fn SuffixTree::new(s : String) -> SuffixTree {
  let text = s.to_array()
  text.push(SENTINEL)
  let nodes : Array[Node] = [Node::new()]
  for start = 0; start < text.length(); start = start + 1 {
    insert_suffix(nodes, text, start)
  } where {
    invariant: start >= 0 && start <= text.length(),
    reasoning: (
      #|INVARIANT (all suffixes):
      #|All suffixes starting at positions [0..start) have been inserted into
      #|the tree. The tree contains exactly those suffix paths.
      #|MAINTENANCE:
      #|Insert the suffix starting at position start.
      #|TERMINATION:
      #|At start = n, all suffixes are present.
    ),
  }
  let _ = compute_leaf_counts(nodes, 0)
  { text, nodes }
}

///|
/// Check whether the pattern occurs in the text.
pub fn SuffixTree::contains(self : SuffixTree, pattern : String) -> Bool {
  let p = pattern.to_array()
  if p.length() == 0 {
    return true
  }
  let mut node = 0
  let mut i = 0
  while i < p.length() {
    let edge_idx = find_edge(self.nodes, self.text, node, p[i])
    if edge_idx < 0 {
      return false
    }
    let edge = self.nodes[node].edges[edge_idx]
    let mut k = edge.start
    while k < edge.end && i < p.length() && self.text[k] == p[i] {
      k = k + 1
      i = i + 1
    }
    if i == p.length() {
      return true
    }
    if k == edge.end {
      node = edge.child
    } else {
      return false
    }
  }
  true
}

///|
/// Count occurrences of a pattern in the text.
/// Empty pattern returns 0 by convention.
pub fn SuffixTree::count_occurrences(
  self : SuffixTree,
  pattern : String,
) -> Int {
  let p = pattern.to_array()
  if p.length() == 0 {
    return 0
  }
  let mut node = 0
  let mut i = 0
  while i < p.length() {
    let edge_idx = find_edge(self.nodes, self.text, node, p[i])
    if edge_idx < 0 {
      return 0
    }
    let edge = self.nodes[node].edges[edge_idx]
    let mut k = edge.start
    while k < edge.end && i < p.length() && self.text[k] == p[i] {
      k = k + 1
      i = i + 1
    }
    if i == p.length() {
      return self.nodes[edge.child].leaf_count
    }
    if k == edge.end {
      node = edge.child
    } else {
      return 0
    }
  }
  0
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "suffix tree contains" {
  let tree = SuffixTree::new("banana")
  inspect(tree.contains("ana"), content="true")
  inspect(tree.contains("apple"), content="false")
}

///|
test "suffix tree count" {
  let tree = SuffixTree::new("banana")
  inspect(tree.count_occurrences("ana"), content="2")
  inspect(tree.count_occurrences("na"), content="2")
  inspect(tree.count_occurrences("ban"), content="1")
}
