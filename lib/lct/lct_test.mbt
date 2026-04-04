// ============================================================================
// LCT - Tests
// ============================================================================

///|
/// Test basic link and connectivity operations.
///
/// TREE STRUCTURE:
/// ```
///   0 <- 1 <- 2
///   (1 is child of 0, 2 is child of 1)
/// ```
test "lct basic operations" {
  // Create a forest of 5 isolated nodes
  let lct = LinkCutTree::new(5)

  // Initially, each node is its own root
  inspect(lct.find_root(0), content="0")
  inspect(lct.find_root(1), content="1")
  inspect(lct.find_root(2), content="2")

  // Link: 1 -> 0 (1 becomes child of 0)
  lct.link(1, 0)
  inspect(lct.find_root(1), content="0")
  inspect(lct.connected(0, 1), content="true")

  // Link: 2 -> 1 (2 becomes child of 1)
  lct.link(2, 1)
  inspect(lct.find_root(2), content="0")
  inspect(lct.connected(0, 2), content="true")
}

///|
/// Test cut operation.
///
/// TREE STRUCTURE:
/// ```
///   Before: 0 <- 1 <- 2 <- 3
///   After cut(2): {0 <- 1} and {2 <- 3}
/// ```
test "lct cut operation" {
  let lct = LinkCutTree::new(4)

  // Build tree: 0 <- 1 <- 2 <- 3
  lct.link(1, 0)
  lct.link(2, 1)
  lct.link(3, 2)
  inspect(lct.find_root(3), content="0")

  // Cut 2 from 1
  lct.cut(2)

  // Now 2 and 3 are in separate tree from 0 and 1
  inspect(lct.find_root(3), content="2")
  inspect(lct.find_root(1), content="0")
  inspect(lct.connected(1, 3), content="false")
}

///|
/// Test path sum aggregation.
///
/// TREE STRUCTURE:
/// ```
///   0(10) <- 1(20) <- 2(30) <- 3(40) <- 4(50)
///
///   Path sum from 4 to root = 10+20+30+40+50 = 150
///   Path sum from 2 to root = 10+20+30 = 60
/// ```
test "lct path sum" {
  let values = [10, 20, 30, 40, 50]
  let lct = LinkCutTree::with_values(values)

  // Build tree: 0 <- 1 <- 2 <- 3 <- 4
  lct.link(1, 0)
  lct.link(2, 1)
  lct.link(3, 2)
  lct.link(4, 3)

  // Path sum from 4 to root (0): 10 + 20 + 30 + 40 + 50 = 150
  inspect(lct.path_sum(4), content="150")

  // Path sum from 2 to root (0): 10 + 20 + 30 = 60
  inspect(lct.path_sum(2), content="60")

  // Path sum from 0 to root (0): just 10
  inspect(lct.path_sum(0), content="10")

  // Update value and check path sum changes
  lct.update_value(2, 100)
  inspect(lct.path_sum(4), content="220") // 10+20+100+40+50
}

///|
/// Test LCA (Lowest Common Ancestor) queries.
///
/// TREE STRUCTURE:
/// ```
///       0
///      / \
///     1   2
///    / \   \
///   3   4   5
///       |
///       6
///
///   LCA(3, 4) = 1
///   LCA(3, 5) = 0
///   LCA(6, 3) = 1
/// ```
test "lct lca" {
  let lct = LinkCutTree::new(7)

  // Build tree structure
  lct.link(1, 0)
  lct.link(2, 0)
  lct.link(3, 1)
  lct.link(4, 1)
  lct.link(5, 2)
  lct.link(6, 4)

  // LCA of 3 and 4 is 1 (their common parent)
  inspect(lct.lca(3, 4), content="1")

  // LCA of 3 and 5 is 0 (root, as they're in different subtrees)
  inspect(lct.lca(3, 5), content="0")

  // LCA of 6 and 3 is 1 (6's grandparent = 3's parent)
  inspect(lct.lca(6, 3), content="1")
}

///|
/// Test make_root (re-rooting operation).
///
/// TREE STRUCTURE:
/// ```
///   Before: 0 <- 1 <- 2 <- 3  (root = 0)
///   After make_root(2): 2 becomes root
/// ```
test "lct make root" {
  let lct = LinkCutTree::new(4)

  // Build tree: 0 <- 1 <- 2 <- 3
  lct.link(1, 0)
  lct.link(2, 1)
  lct.link(3, 2)
  inspect(lct.find_root(3), content="0")

  // Make 2 the new root
  lct.make_root(2)
  inspect(lct.find_root(3), content="2")
  inspect(lct.find_root(0), content="2")
}

///|
/// Stress test with larger tree.
test "lct stress test" {
  let n = 50
  let lct = LinkCutTree::new(n)

  // Build a path: 0 <- 1 <- 2 <- ... <- 49
  for i in 1..<n {
    lct.link(i, i - 1)
  } where {
    proof_invariant: i >= 1 && i <= n,
    proof_reasoning: (
      #|INVARIANT (build chain):
      #|  Nodes [0..i) form a single chain rooted at 0.
      #|
      #|MAINTENANCE:
      #|  Link node i to i-1 to extend the chain.
      #|
      #|TERMINATION:
      #|  At i = n, the full chain 0←1←...←49 is built.
    ),
  }

  // All should have root 0
  for i in 0..<n {
    guard lct.find_root(i) == 0 else { fail("Wrong root") }
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (verify roots):
      #|  Nodes [0..i) are verified to have root 0.
      #|
      #|MAINTENANCE:
      #|  Check node i.
      #|
      #|TERMINATION:
      #|  At i = n, all verified.
    ),
  }

  // Cut in the middle
  lct.cut(25)

  // Nodes 0-24 have root 0, nodes 25-49 have root 25
  inspect(lct.find_root(24), content="0")
  inspect(lct.find_root(25), content="25")
  inspect(lct.find_root(49), content="25")
  inspect(lct.connected(24, 25), content="false")
}

///|
/// Test DynamicForest wrapper.
test "dynamic forest" {
  let forest = DynamicForest::new(5)

  // Initially disconnected
  inspect(forest.connected(0, 1), content="false")

  // Link 0-1
  inspect(forest.link(0, 1), content="true")
  inspect(forest.connected(0, 1), content="true")

  // Link 1-2, 2-3, 3-4
  let _ = forest.link(1, 2)
  let _ = forest.link(2, 3)
  let _ = forest.link(3, 4)
  inspect(forest.connected(0, 4), content="true")

  // Cut 2-3
  inspect(forest.cut(2, 3), content="true")
  inspect(forest.connected(0, 2), content="true")
  inspect(forest.connected(3, 4), content="true")
  inspect(forest.connected(0, 4), content="false")
}
