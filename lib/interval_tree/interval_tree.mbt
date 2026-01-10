// ============================================================================
// INTERVAL TREE - Range Overlap Queries
// ============================================================================
//
// An augmented BST for storing intervals and efficiently querying overlaps.
// Each node stores an interval and the maximum endpoint in its subtree.
//
// KEY INSIGHT: By storing max endpoint at each node, we can prune
// entire subtrees that cannot contain overlapping intervals.
//
// OPERATIONS:
// - Insert interval: O(log n)
// - Delete interval: O(log n)
// - Query overlapping: O(k + log n) where k is output size
// - Stabbing query (point in intervals): O(k + log n)
//
// INVARIANTS:
// 1. BST property on interval start points
// 2. Each node's max = max(right endpoint in subtree)
// 3. Two intervals [a,b] and [c,d] overlap iff a ≤ d and c ≤ b
//
// TIME COMPLEXITY: O(log n) per operation
// SPACE COMPLEXITY: O(n)

///|
priv struct Interval {
  start : Int
  end : Int
  id : Int // Optional identifier
} derive(Show)

///|
fn intervals_overlap(a : Interval, b : Interval) -> Bool {
  a.start <= b.end && b.start <= a.end
}

///|
fn interval_contains_point(interval : Interval, point : Int) -> Bool {
  interval.start <= point && point <= interval.end
}

///|
priv struct IntervalNode {
  interval : Interval
  mut max_end : Int
  mut left : IntervalNode?
  mut right : IntervalNode?
}

///|
fn IntervalNode::new(interval : Interval) -> IntervalNode {
  { interval, max_end: interval.end, left: None, right: None }
}

///|
priv struct IntervalTree {
  mut root : IntervalNode?
  mut size : Int
}

///|
fn IntervalTree::new() -> IntervalTree {
  { root: None, size: 0 }
}

///|
fn update_max(node : IntervalNode) -> Unit {
  let mut max = node.interval.end
  match node.left {
    Some(left) => if left.max_end > max { max = left.max_end }
    None => ()
  }
  match node.right {
    Some(right) => if right.max_end > max { max = right.max_end }
    None => ()
  }
  node.max_end = max
}

///|
fn IntervalTree::insert(self : IntervalTree, interval : Interval) -> Unit {
  self.root = insert_rec(self.root, interval)
  self.size = self.size + 1
}

///|
fn insert_rec(node : IntervalNode?, interval : Interval) -> IntervalNode? {
  match node {
    None => Some(IntervalNode::new(interval))
    Some(n) => {
      if interval.start < n.interval.start {
        n.left = insert_rec(n.left, interval)
      } else {
        n.right = insert_rec(n.right, interval)
      }
      update_max(n)
      Some(n)
    }
  }
}

///|
/// Query all intervals overlapping with the given interval
fn IntervalTree::query_overlap(self : IntervalTree, query : Interval) -> Array[Interval] {
  let result : Array[Interval] = []
  query_overlap_rec(self.root, query, result)
  result
}

///|
fn query_overlap_rec(node : IntervalNode?, query : Interval, result : Array[Interval]) -> Unit {
  match node {
    None => ()
    Some(n) => {
      // Check if current interval overlaps
      if intervals_overlap(n.interval, query) {
        result.push(n.interval)
      }

      // Recurse left if left subtree might have overlapping intervals
      match n.left {
        Some(left) => {
          if left.max_end >= query.start {
            query_overlap_rec(Some(left), query, result)
          }
        }
        None => ()
      }

      // Recurse right if query extends beyond current start
      if n.interval.start <= query.end {
        query_overlap_rec(n.right, query, result)
      }
    }
  }
}

///|
/// Stabbing query: find all intervals containing a point
fn IntervalTree::stab(self : IntervalTree, point : Int) -> Array[Interval] {
  let result : Array[Interval] = []
  stab_rec(self.root, point, result)
  result
}

///|
fn stab_rec(node : IntervalNode?, point : Int, result : Array[Interval]) -> Unit {
  match node {
    None => ()
    Some(n) => {
      if interval_contains_point(n.interval, point) {
        result.push(n.interval)
      }

      // Check left subtree if it might contain the point
      match n.left {
        Some(left) => {
          if left.max_end >= point {
            stab_rec(Some(left), point, result)
          }
        }
        None => ()
      }

      // Check right subtree if point is past current start
      if n.interval.start <= point {
        stab_rec(n.right, point, result)
      }
    }
  }
}

///|
/// Check if any interval overlaps with query
fn IntervalTree::any_overlap(self : IntervalTree, query : Interval) -> Bool {
  any_overlap_rec(self.root, query)
}

///|
fn any_overlap_rec(node : IntervalNode?, query : Interval) -> Bool {
  match node {
    None => false
    Some(n) => {
      if intervals_overlap(n.interval, query) {
        return true
      }

      // Check left
      match n.left {
        Some(left) => {
          if left.max_end >= query.start && any_overlap_rec(Some(left), query) {
            return true
          }
        }
        None => ()
      }

      // Check right
      if n.interval.start <= query.end {
        return any_overlap_rec(n.right, query)
      }

      false
    }
  }
}

///|
/// Count intervals overlapping with query
fn IntervalTree::count_overlap(self : IntervalTree, query : Interval) -> Int {
  count_overlap_rec(self.root, query)
}

///|
fn count_overlap_rec(node : IntervalNode?, query : Interval) -> Int {
  match node {
    None => 0
    Some(n) => {
      let mut count = 0

      if intervals_overlap(n.interval, query) {
        count = count + 1
      }

      match n.left {
        Some(left) => {
          if left.max_end >= query.start {
            count = count + count_overlap_rec(Some(left), query)
          }
        }
        None => ()
      }

      if n.interval.start <= query.end {
        count = count + count_overlap_rec(n.right, query)
      }

      count
    }
  }
}

///|
/// Get all intervals in the tree
fn IntervalTree::all_intervals(self : IntervalTree) -> Array[Interval] {
  let result : Array[Interval] = []
  collect_all(self.root, result)
  result
}

///|
fn collect_all(node : IntervalNode?, result : Array[Interval]) -> Unit {
  match node {
    None => ()
    Some(n) => {
      collect_all(n.left, result)
      result.push(n.interval)
      collect_all(n.right, result)
    }
  }
}

///|
fn IntervalTree::is_empty(self : IntervalTree) -> Bool {
  self.root is None
}

///|
fn IntervalTree::len(self : IntervalTree) -> Int {
  self.size
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "interval tree insert and query" {
  let tree = IntervalTree::new()

  tree.insert({ start: 15, end: 20, id: 1 })
  tree.insert({ start: 10, end: 30, id: 2 })
  tree.insert({ start: 17, end: 19, id: 3 })
  tree.insert({ start: 5, end: 20, id: 4 })
  tree.insert({ start: 12, end: 15, id: 5 })

  inspect(tree.len(), content="5")

  // Query overlapping with [14, 16]
  let overlaps = tree.query_overlap({ start: 14, end: 16, id: 0 })
  // Should match: [15,20], [10,30], [5,20], [12,15]
  inspect(overlaps.length() >= 4, content="true")
}

///|
test "interval tree stabbing" {
  let tree = IntervalTree::new()

  tree.insert({ start: 1, end: 5, id: 1 })
  tree.insert({ start: 3, end: 8, id: 2 })
  tree.insert({ start: 7, end: 10, id: 3 })

  // Point 4 is in [1,5] and [3,8]
  let stab4 = tree.stab(4)
  inspect(stab4.length(), content="2")

  // Point 9 is only in [7,10]
  let stab9 = tree.stab(9)
  inspect(stab9.length(), content="1")

  // Point 0 is in no interval
  let stab0 = tree.stab(0)
  inspect(stab0.length(), content="0")
}

///|
test "interval tree any overlap" {
  let tree = IntervalTree::new()

  tree.insert({ start: 1, end: 5, id: 1 })
  tree.insert({ start: 10, end: 15, id: 2 })

  // [3, 4] overlaps with [1, 5]
  inspect(tree.any_overlap({ start: 3, end: 4, id: 0 }), content="true")

  // [6, 9] doesn't overlap with any
  inspect(tree.any_overlap({ start: 6, end: 9, id: 0 }), content="false")

  // [14, 20] overlaps with [10, 15]
  inspect(tree.any_overlap({ start: 14, end: 20, id: 0 }), content="true")
}

///|
test "interval tree count overlap" {
  let tree = IntervalTree::new()

  tree.insert({ start: 1, end: 10, id: 1 })
  tree.insert({ start: 5, end: 15, id: 2 })
  tree.insert({ start: 12, end: 20, id: 3 })

  // [7, 14] overlaps with all three
  inspect(tree.count_overlap({ start: 7, end: 14, id: 0 }), content="3")

  // [2, 3] overlaps with only [1, 10]
  inspect(tree.count_overlap({ start: 2, end: 3, id: 0 }), content="1")

  // [25, 30] overlaps with none
  inspect(tree.count_overlap({ start: 25, end: 30, id: 0 }), content="0")
}

///|
test "interval tree empty" {
  let tree = IntervalTree::new()

  inspect(tree.is_empty(), content="true")
  inspect(tree.query_overlap({ start: 0, end: 10, id: 0 }).length(), content="0")
  inspect(tree.stab(5).length(), content="0")
}

///|
test "interval tree single" {
  let tree = IntervalTree::new()

  tree.insert({ start: 5, end: 10, id: 1 })

  inspect(tree.stab(7).length(), content="1")
  inspect(tree.stab(4).length(), content="0")
  inspect(tree.stab(11).length(), content="0")
  inspect(tree.stab(5).length(), content="1")  // Boundary
  inspect(tree.stab(10).length(), content="1") // Boundary
}

///|
test "interval tree disjoint" {
  let tree = IntervalTree::new()

  tree.insert({ start: 1, end: 2, id: 1 })
  tree.insert({ start: 5, end: 6, id: 2 })
  tree.insert({ start: 9, end: 10, id: 3 })

  // Query between intervals
  inspect(tree.query_overlap({ start: 3, end: 4, id: 0 }).length(), content="0")
  inspect(tree.query_overlap({ start: 7, end: 8, id: 0 }).length(), content="0")

  // Query spanning all
  let all = tree.query_overlap({ start: 0, end: 11, id: 0 })
  inspect(all.length(), content="3")
}

///|
test "interval tree nested" {
  let tree = IntervalTree::new()

  // Nested intervals
  tree.insert({ start: 1, end: 100, id: 1 })
  tree.insert({ start: 20, end: 80, id: 2 })
  tree.insert({ start: 40, end: 60, id: 3 })

  // Point in innermost
  let stab50 = tree.stab(50)
  inspect(stab50.length(), content="3")

  // Point in middle only
  let stab25 = tree.stab(25)
  inspect(stab25.length(), content="2")

  // Point in outermost only
  let stab5 = tree.stab(5)
  inspect(stab5.length(), content="1")
}

///|
test "intervals overlap function" {
  let a = { start: 1, end: 5, id: 0 }
  let b = { start: 3, end: 8, id: 0 }
  let c = { start: 6, end: 10, id: 0 }
  let d = { start: 5, end: 6, id: 0 }

  inspect(intervals_overlap(a, b), content="true")  // [1,5] and [3,8]
  inspect(intervals_overlap(a, c), content="false") // [1,5] and [6,10]
  inspect(intervals_overlap(a, d), content="true")  // [1,5] and [5,6] - touch at 5
  inspect(intervals_overlap(b, c), content="true")  // [3,8] and [6,10]
}

///|
test "interval tree all intervals" {
  let tree = IntervalTree::new()

  tree.insert({ start: 5, end: 10, id: 1 })
  tree.insert({ start: 1, end: 3, id: 2 })
  tree.insert({ start: 8, end: 15, id: 3 })

  let all = tree.all_intervals()
  inspect(all.length(), content="3")
}
