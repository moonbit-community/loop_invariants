// ============================================================================
// LI CHAO TREE - Tests
// ============================================================================

///|
/// Test basic single line insertion and queries.
///
/// LINE: y = 2x + 1
/// ```
///   x=0: 2(0)+1 = 1
///   x=5: 2(5)+1 = 11
///   x=-3: 2(-3)+1 = -5
/// ```
test "lichao basic max" {
  let tree = LiChaoTree::new(-100L, 100L)

  // Insert y = 2x + 1
  tree.insert(2L, 1L)
  inspect(tree.query(0L), content="1")
  inspect(tree.query(5L), content="11")
  inspect(tree.query(-3L), content="-5")
}

///|
/// Test multiple lines finding correct maximum.
///
/// LINES:
/// ```
///   y = 2x + 1   (steep positive slope)
///   y = -x + 5   (negative slope)
///   y = x + 2    (gentle positive slope)
///
///   At x=0: max(1, 5, 2) = 5   (y = -x + 5 wins)
///   At x=1: max(3, 4, 3) = 4   (y = -x + 5 wins)
///   At x=3: max(7, 2, 5) = 7   (y = 2x + 1 wins)
///   At x=-2: max(-3, 7, 0) = 7 (y = -x + 5 wins)
/// ```
test "lichao multiple lines max" {
  let tree = LiChaoTree::new(-10L, 10L)
  tree.insert(2L, 1L)
  tree.insert(-1L, 5L)
  tree.insert(1L, 2L)
  inspect(tree.query(0L), content="5")
  inspect(tree.query(1L), content="4")
  inspect(tree.query(3L), content="7")
  inspect(tree.query(-2L), content="7")
}

///|
/// Test single line on positive range.
test "lichao single line" {
  let tree = LiChaoTree::new(0L, 100L)
  tree.insert(3L, 5L) // y = 3x + 5
  inspect(tree.query(0L), content="5")
  inspect(tree.query(10L), content="35")
  inspect(tree.query(100L), content="305")
}

///|
/// Test horizontal lines (slope = 0).
///
/// When all lines are horizontal, the one with highest intercept wins.
test "lichao horizontal lines" {
  let tree = LiChaoTree::new(0L, 100L)
  tree.insert(0L, 10L) // y = 10
  tree.insert(0L, 20L) // y = 20
  tree.insert(0L, 5L) // y = 5

  // All queries should return 20 (maximum horizontal line)
  inspect(tree.query(0L), content="20")
  inspect(tree.query(50L), content="20")
  inspect(tree.query(100L), content="20")
}

///|
/// Test crossing lines.
///
/// LINES: y = x and y = -x + 10
/// ```
///   They cross at x = 5 where both equal 5
///
///   For x < 5: -x + 10 > x
///   For x > 5: x > -x + 10
///   At x = 5: tie (both equal 5)
///
///        y
///        |  \    /
///        |   \  /
///        |    \/  cross at (5,5)
///        |    /\
///        |   /  \
///        |__/____\__ x
///        0   5   10
/// ```
test "lichao crossing lines" {
  let tree = LiChaoTree::new(-100L, 100L)
  tree.insert(1L, 0L) // y = x
  tree.insert(-1L, 10L) // y = -x + 10
  inspect(tree.query(0L), content="10") // max(0, 10) = 10
  inspect(tree.query(5L), content="5") // max(5, 5) = 5
  inspect(tree.query(10L), content="10") // max(10, 0) = 10
  inspect(tree.query(-5L), content="15") // max(-5, 15) = 15
}

///|
/// Test minimum queries basic.
///
/// LINES: y = 2x + 1, y = -x + 5
/// ```
///   At x=0: min(1, 5) = 1
///   At x=1: min(3, 4) = 3
///   At x=-2: min(-3, 7) = -3
/// ```
test "lichao min basic" {
  let tree = LiChaoTreeMin::new(-100L, 100L)
  tree.insert(2L, 1L)
  tree.insert(-1L, 5L)
  inspect(tree.query(0L), content="1")
  inspect(tree.query(1L), content="3")
  inspect(tree.query(-2L), content="-3")
}

///|
/// Test minimum with multiple lines.
test "lichao min multiple" {
  let tree = LiChaoTreeMin::new(0L, 100L)
  tree.insert(1L, 100L) // y = x + 100
  tree.insert(2L, 0L) // y = 2x
  tree.insert(-1L, 200L) // y = -x + 200

  // At x = 0: min(100, 0, 200) = 0
  inspect(tree.query(0L), content="0")

  // At x = 50: min(150, 100, 150) = 100
  inspect(tree.query(50L), content="100")

  // At x = 100: min(200, 200, 100) = 100
  inspect(tree.query(100L), content="100")
}

///|
/// Test with large coordinate range.
test "lichao large range" {
  let tree = LiChaoTree::new(-1000000000L, 1000000000L)
  tree.insert(1L, 0L)
  tree.insert(-1L, 0L)
  inspect(tree.query(0L), content="0")
  inspect(tree.query(1000000L), content="1000000")
  inspect(tree.query(-1000000L), content="1000000")
}

///|
/// Test node efficiency (lazy allocation).
test "lichao node efficiency" {
  let tree = LiChaoTree::new(0L, 1000000L)

  // Insert several lines
  for i in 0..<10 {
    tree.insert(i.to_int64(), (10 - i).to_int64())
  }

  // Should create relatively few nodes (O(L log N))
  let nodes = tree.node_count()
  inspect(nodes < 100, content="true")
}

///|
/// Test query on empty tree (no lines inserted).
test "lichao empty query" {
  let tree = LiChaoTree::new(0L, 100L)

  // Query on empty tree returns minimum value
  let result = tree.query(50L)
  inspect(result < 0L, content="true")
}

///|
/// Test parallel lines (same slope, different intercepts).
///
/// For parallel lines with same slope, the one with highest intercept
/// dominates everywhere (for max queries).
test "lichao parallel lines" {
  let tree = LiChaoTree::new(0L, 100L)
  tree.insert(2L, 1L) // y = 2x + 1
  tree.insert(2L, 5L) // y = 2x + 5
  tree.insert(2L, 3L) // y = 2x + 3

  // The one with highest intercept always wins
  inspect(tree.query(0L), content="5")
  inspect(tree.query(50L), content="105")
}

///|
/// Test steep slopes (large magnitude).
test "lichao steep slopes" {
  let tree = LiChaoTree::new(-10L, 10L)
  tree.insert(100L, 0L) // Very steep positive
  tree.insert(-100L, 0L) // Very steep negative

  // At x = 0: max(0, 0) = 0
  inspect(tree.query(0L), content="0")

  // At x = 5: max(500, -500) = 500
  inspect(tree.query(5L), content="500")

  // At x = -5: max(-500, 500) = 500
  inspect(tree.query(-5L), content="500")
}

///|
/// Test node count for minimum tree.
test "lichao min node count" {
  let tree = LiChaoTreeMin::new(0L, 1000L)
  tree.insert(1L, 0L)
  tree.insert(-1L, 100L)
  tree.insert(0L, 50L)

  // Verify node count is reasonable
  inspect(tree.node_count() < 50, content="true")
}
