// ============================================================================
// DOMINATOR TREE - Tests
// ============================================================================

///|
/// Basic dominator tree test with a simple graph.
///
/// GRAPH:
/// ```
///   0 → 1 → 2 → 3 → 4 → 5
///       │   │       ↑
///       │   └───────┘
///       └───────→ 3
///
///   Edges: (0,1), (1,2), (2,3), (1,3), (3,4), (4,5), (2,5)
/// ```
///
/// DOMINATOR TREE:
/// ```
///       0
///       │
///       1
///      /│\
///     2 3 5
///       │
///       4
/// ```
///
/// WHY:
///   - 0 is root, dominates everything
///   - 1 is dominated only by 0 (only path to 1 is 0→1)
///   - 2 is dominated by 1 (path must go through 1)
///   - 3 is dominated by 1 (paths 0→1→2→3 and 0→1→3 both go through 1)
///   - 4 is dominated by 3 (only path through 3)
///   - 5 is dominated by 1 (paths through 2 or 4, but both need 1)
test "dominator tree basic" {
  let edges : Array[(Int, Int)] = [
    (0, 1),
    (1, 2),
    (2, 3),
    (1, 3),
    (3, 4),
    (4, 5),
    (2, 5),
  ]
  let dom = build_dominator_tree(6, edges[:], 0).unwrap()

  // Check immediate dominators
  inspect(dom.idom[0], content="0") // root dominates itself
  inspect(dom.idom[1], content="0")
  inspect(dom.idom[2], content="1")
  inspect(dom.idom[3], content="1")
  inspect(dom.idom[4], content="3")
  inspect(dom.idom[5], content="1")

  // Check dominates relation
  inspect(dom.dominates(1, 5), content="true") // 1 dominates 5
  inspect(dom.dominates(2, 5), content="false") // 2 doesn't dominate 5 (path via 1→3→4→5)
  inspect(dom.dominates(0, 4), content="true") // root dominates all
  inspect(dom.dominates(3, 4), content="true") // 3 dominates 4
}

///|
/// Test with unreachable vertices.
///
/// GRAPH:
/// ```
///   Component 1: 0 → 1
///   Component 2: 2 → 3  (unreachable from root 0)
/// ```
test "dominator tree unreachable" {
  let edges : Array[(Int, Int)] = [(0, 1), (2, 3)]
  let dom = build_dominator_tree(4, edges[:], 0).unwrap()

  // Reachable vertices
  inspect(dom.idom[0], content="0")
  inspect(dom.idom[1], content="0")

  // Unreachable vertices have idom = -1
  inspect(dom.idom[2], content="-1")
  inspect(dom.idom[3], content="-1")

  // Unreachable vertices are not dominated
  inspect(dom.dominates(0, 2), content="false")
  inspect(dom.dominates(2, 3), content="false")
}

///|
/// Test with a diamond pattern (classic CFG structure).
///
/// GRAPH:
/// ```
///       0
///      / \
///     1   2
///      \ /
///       3
/// ```
test "dominator tree diamond" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
  let dom = build_dominator_tree(4, edges[:], 0).unwrap()
  inspect(dom.idom[0], content="0")
  inspect(dom.idom[1], content="0")
  inspect(dom.idom[2], content="0")
  inspect(dom.idom[3], content="0") // 3's idom is 0, not 1 or 2

  // 1 and 2 don't dominate 3 (alternative paths exist)
  inspect(dom.dominates(1, 3), content="false")
  inspect(dom.dominates(2, 3), content="false")
  inspect(dom.dominates(0, 3), content="true")
}

///|
/// Test with a linear chain.
///
/// GRAPH:
/// ```
///   0 → 1 → 2 → 3 → 4
/// ```
test "dominator tree linear" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
  let dom = build_dominator_tree(5, edges[:], 0).unwrap()

  // In a linear chain, each vertex dominates all successors
  inspect(dom.idom[0], content="0")
  inspect(dom.idom[1], content="0")
  inspect(dom.idom[2], content="1")
  inspect(dom.idom[3], content="2")
  inspect(dom.idom[4], content="3")

  // Test dominance chain
  inspect(dom.dominates(0, 4), content="true")
  inspect(dom.dominates(1, 4), content="true")
  inspect(dom.dominates(2, 4), content="true")
  inspect(dom.dominates(3, 4), content="true")
  inspect(dom.dominates(4, 3), content="false") // reverse doesn't hold
}

///|
/// Test with invalid inputs.
test "dominator tree invalid" {
  let edges : Array[(Int, Int)] = [(0, 1)]

  // Invalid root
  inspect(build_dominator_tree(2, edges[:], -1), content="None")
  inspect(build_dominator_tree(2, edges[:], 5), content="None")

  // Invalid n
  inspect(build_dominator_tree(0, edges[:], 0), content="None")
  inspect(build_dominator_tree(-1, edges[:], 0), content="None")
}

///|
/// Test dominator tree children structure.
test "dominator tree children" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (3, 4)]
  let dom = build_dominator_tree(5, edges[:], 0).unwrap()

  // Check tree structure
  // 0's children should include 1, 2, and 3
  inspect(dom.tree[0].length() > 0, content="true")

  // 3's only child should be 4
  inspect(dom.tree[3].contains(4), content="true")
}
