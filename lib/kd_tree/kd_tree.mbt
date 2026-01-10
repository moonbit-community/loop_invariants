// ============================================================================
// K-D TREE - K-Dimensional Binary Search Tree
// ============================================================================
//
// K-D Tree is a space-partitioning data structure for organizing points in k-dimensional space.
// Enables efficient nearest neighbor queries and range searches.
//
// KEY INSIGHT: At each level, split points by one dimension (cycling through dimensions).
// Left subtree contains points with smaller value in that dimension.
//
// BUILDING:
// 1. Choose splitting dimension (cycle: depth mod k)
// 2. Find median point in that dimension
// 3. Recursively build left and right subtrees
//
// NEAREST NEIGHBOR:
// 1. Traverse to leaf (as if inserting query point)
// 2. Backtrack, checking if other subtree could contain closer point
// 3. Only explore if splitting plane is closer than current best
//
// INVARIANTS:
// 1. All points in left subtree have p[dim] < node.point[dim]
// 2. All points in right subtree have p[dim] >= node.point[dim]
// 3. Dimension cycles: dim = depth mod k
//
// TIME COMPLEXITY: O(n log n) build, O(log n) average query, O(n) worst case
// SPACE COMPLEXITY: O(n)

///|
priv struct KDPoint {
  coords : Array[Double]
}

///|
fn KDPoint::new(coords : Array[Double]) -> KDPoint {
  { coords }
}

///|
fn KDPoint::dim(self : KDPoint) -> Int {
  self.coords.length()
}

///|
fn KDPoint::get(self : KDPoint, i : Int) -> Double {
  self.coords[i]
}

///|
fn KDPoint::distance_sq(self : KDPoint, other : KDPoint) -> Double {
  let mut sum = 0.0
  for i = 0; i < self.dim(); i = i + 1 {
    let d = self.coords[i] - other.coords[i]
    sum = sum + d * d
  }
  sum
}

///|
priv struct KDNode {
  point : KDPoint
  mut left : Int
  mut right : Int
}

///|
priv struct KDTree {
  nodes : Array[KDNode]
  mut root : Int
  k : Int // Number of dimensions
}

///|
fn KDTree::new(k : Int) -> KDTree {
  { nodes: [], root: -1, k }
}

///|
fn KDTree::build(points : Array[KDPoint]) -> KDTree {
  if points.length() == 0 {
    return KDTree::new(2)
  }
  let k = points[0].dim()
  let tree = KDTree::new(k)

  // Copy points for sorting
  let pts = Array::make(points.length(), points[0])
  for i = 0; i < points.length(); i = i + 1 {
    pts[i] = points[i]
  }

  tree.root = tree.build_rec(pts, 0, pts.length(), 0)
  tree
}

///|
fn KDTree::build_rec(
  self : KDTree,
  points : Array[KDPoint],
  start : Int,
  end : Int,
  depth : Int
) -> Int {
  if start >= end {
    return -1
  }

  let dim = depth % self.k

  // Sort by current dimension (simple selection for median)
  // For efficiency, we'd use nth_element, but here we sort the range
  for i = start; i < end; i = i + 1 {
    let mut min_idx = i
    for j = i + 1; j < end; j = j + 1 {
      if points[j].get(dim) < points[min_idx].get(dim) {
        min_idx = j
      }
    }
    if min_idx != i {
      let tmp = points[i]
      points[i] = points[min_idx]
      points[min_idx] = tmp
    }
  }

  let mid = (start + end) / 2
  let node_idx = self.nodes.length()
  self.nodes.push({ point: points[mid], left: -1, right: -1 })

  self.nodes[node_idx].left = self.build_rec(points, start, mid, depth + 1)
  self.nodes[node_idx].right = self.build_rec(points, mid + 1, end, depth + 1)

  node_idx
}

///|
fn KDTree::nearest_neighbor(self : KDTree, query : KDPoint) -> KDPoint? {
  if self.root < 0 {
    return None
  }

  let best_dist = 1.0e308 // Large number
  let best_point : KDPoint? = None

  fn search(
    tree : KDTree,
    node : Int,
    query : KDPoint,
    depth : Int,
    best_dist : Double,
    best_point : KDPoint?
  ) -> (Double, KDPoint?) {
    if node < 0 {
      return (best_dist, best_point)
    }

    let point = tree.nodes[node].point
    let dist = query.distance_sq(point)
    let mut bd = best_dist
    let mut bp = best_point

    if dist < bd {
      bd = dist
      bp = Some(point)
    }

    let dim = depth % tree.k
    let diff = query.get(dim) - point.get(dim)

    // Visit closer subtree first
    let (first, second) = if diff < 0.0 {
      (tree.nodes[node].left, tree.nodes[node].right)
    } else {
      (tree.nodes[node].right, tree.nodes[node].left)
    }

    let (bd2, bp2) = search(tree, first, query, depth + 1, bd, bp)
    bd = bd2
    bp = bp2

    // Check if we need to visit other subtree
    if diff * diff < bd {
      let (bd3, bp3) = search(tree, second, query, depth + 1, bd, bp)
      bd = bd3
      bp = bp3
    }

    (bd, bp)
  }

  let (_, result) = search(self, self.root, query, 0, best_dist, best_point)
  result
}

///|
fn KDTree::k_nearest(self : KDTree, query : KDPoint, k_count : Int) -> Array[KDPoint] {
  if self.root < 0 || k_count <= 0 {
    return []
  }

  // Simple approach: collect all with distances, sort, take k
  let all : Array[(Double, KDPoint)] = []

  fn collect(tree : KDTree, node : Int, query : KDPoint, all : Array[(Double, KDPoint)]) -> Unit {
    if node < 0 {
      return
    }
    let point = tree.nodes[node].point
    let dist = query.distance_sq(point)
    all.push((dist, point))
    collect(tree, tree.nodes[node].left, query, all)
    collect(tree, tree.nodes[node].right, query, all)
  }

  collect(self, self.root, query, all)

  // Sort by distance
  for i = 0; i < all.length(); i = i + 1 {
    let mut min_idx = i
    for j = i + 1; j < all.length(); j = j + 1 {
      if all[j].0 < all[min_idx].0 {
        min_idx = j
      }
    }
    if min_idx != i {
      let tmp = all[i]
      all[i] = all[min_idx]
      all[min_idx] = tmp
    }
  }

  let result : Array[KDPoint] = []
  let count = if k_count < all.length() { k_count } else { all.length() }
  for i = 0; i < count; i = i + 1 {
    result.push(all[i].1)
  }
  result
}

///|
/// Range query: find all points within given rectangle
fn KDTree::range_query(
  self : KDTree,
  min_bounds : Array[Double],
  max_bounds : Array[Double]
) -> Array[KDPoint] {
  let result : Array[KDPoint] = []

  fn search(
    tree : KDTree,
    node : Int,
    depth : Int,
    min_bounds : Array[Double],
    max_bounds : Array[Double],
    result : Array[KDPoint]
  ) -> Unit {
    if node < 0 {
      return
    }

    let point = tree.nodes[node].point

    // Check if point is in range
    let mut in_range = true
    for i = 0; i < tree.k; i = i + 1 {
      if point.get(i) < min_bounds[i] || point.get(i) > max_bounds[i] {
        in_range = false
        break
      }
    }
    if in_range {
      result.push(point)
    }

    let dim = depth % tree.k

    // Check if left subtree could contain points in range
    if point.get(dim) >= min_bounds[dim] {
      search(tree, tree.nodes[node].left, depth + 1, min_bounds, max_bounds, result)
    }

    // Check if right subtree could contain points in range
    if point.get(dim) <= max_bounds[dim] {
      search(tree, tree.nodes[node].right, depth + 1, min_bounds, max_bounds, result)
    }
  }

  search(self, self.root, 0, min_bounds, max_bounds, result)
  result
}

///|
fn KDTree::size(self : KDTree) -> Int {
  self.nodes.length()
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "kd_tree build" {
  let points : Array[KDPoint] = [
    KDPoint::new([2.0, 3.0]),
    KDPoint::new([5.0, 4.0]),
    KDPoint::new([9.0, 6.0]),
    KDPoint::new([4.0, 7.0]),
    KDPoint::new([8.0, 1.0]),
    KDPoint::new([7.0, 2.0]),
  ]

  let tree = KDTree::build(points)
  inspect(tree.size(), content="6")
}

///|
test "kd_tree nearest neighbor" {
  let points : Array[KDPoint] = [
    KDPoint::new([2.0, 3.0]),
    KDPoint::new([5.0, 4.0]),
    KDPoint::new([9.0, 6.0]),
  ]

  let tree = KDTree::build(points)
  let query = KDPoint::new([5.5, 4.5])

  match tree.nearest_neighbor(query) {
    Some(p) => {
      // Closest should be (5, 4)
      inspect(p.get(0), content="5")
      inspect(p.get(1), content="4")
    }
    None => fail("Expected to find nearest neighbor")
  }
}

///|
test "kd_tree empty" {
  let points : Array[KDPoint] = []
  let tree = KDTree::build(points)

  inspect(tree.size(), content="0")
  inspect(tree.nearest_neighbor(KDPoint::new([0.0, 0.0])) is None, content="true")
}

///|
test "kd_tree k_nearest" {
  let points : Array[KDPoint] = [
    KDPoint::new([1.0, 1.0]),
    KDPoint::new([2.0, 2.0]),
    KDPoint::new([3.0, 3.0]),
    KDPoint::new([4.0, 4.0]),
    KDPoint::new([5.0, 5.0]),
  ]

  let tree = KDTree::build(points)
  let query = KDPoint::new([2.5, 2.5])

  let nearest = tree.k_nearest(query, 3)
  inspect(nearest.length(), content="3")
}

///|
test "kd_tree range query" {
  let points : Array[KDPoint] = [
    KDPoint::new([1.0, 1.0]),
    KDPoint::new([2.0, 2.0]),
    KDPoint::new([3.0, 3.0]),
    KDPoint::new([5.0, 5.0]),
    KDPoint::new([8.0, 8.0]),
  ]

  let tree = KDTree::build(points)
  let result = tree.range_query([1.5, 1.5], [4.0, 4.0])

  // Should find (2,2) and (3,3)
  inspect(result.length(), content="2")
}

///|
test "kd_tree single point" {
  let points : Array[KDPoint] = [KDPoint::new([5.0, 5.0])]

  let tree = KDTree::build(points)
  let query = KDPoint::new([0.0, 0.0])

  match tree.nearest_neighbor(query) {
    Some(p) => {
      inspect(p.get(0), content="5")
      inspect(p.get(1), content="5")
    }
    None => fail("Expected to find point")
  }
}

///|
test "kd_tree 3d" {
  let points : Array[KDPoint] = [
    KDPoint::new([1.0, 2.0, 3.0]),
    KDPoint::new([4.0, 5.0, 6.0]),
    KDPoint::new([7.0, 8.0, 9.0]),
  ]

  let tree = KDTree::build(points)
  inspect(tree.size(), content="3")
  inspect(tree.k, content="3")
}

///|
test "kd_point distance" {
  let p1 = KDPoint::new([0.0, 0.0])
  let p2 = KDPoint::new([3.0, 4.0])

  inspect(p1.distance_sq(p2), content="25") // 3² + 4² = 25
}
