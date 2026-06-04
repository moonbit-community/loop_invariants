// ============================================================================
// UNROOTED TREE ISOMORPHISM  -  AHU canonical form
// ============================================================================
//
// PROBLEM
//
// Decide whether two unrooted trees are isomorphic. Trees are encoded
// as adjacency lists. The standard tool is the **AHU algorithm**
// (Aho, Hopcroft, Ullman, 1974) which produces a canonical string for
// each rooted tree by recursively sorting children's canonical strings.
//
// For **unrooted** trees, root each tree at its **centroid(s)** (one
// or two vertices on the longest path) and compare the resulting
// canonical strings.
//
// COMPLEXITY
//
//   Time : O(n^2) here; can be made O(n log n) with better hashing.
//   Space: O(n)
//
// THE INVARIANT
//
//   "Two rooted trees produce the same canonical string iff there is
//    a label-preserving isomorphism between them respecting roots."

///|
fn find_centroids(n : Int, adj : Array[Array[Int]]) -> Array[Int] {
  if n <= 1 {
    return Array::makei(n, i => i)
  }
  let deg = Array::makei(n, i => adj[i].length())
  // Iteratively peel leaves.
  let mut remaining = n
  let leaves : Array[Int] = []
  for i in 0..<n {
    if deg[i] <= 1 {
      leaves.push(i)
    }
  }
  while remaining > 2 {
    let new_leaves : Array[Int] = []
    for l in leaves {
      remaining = remaining - 1
      for nb in adj[l] {
        deg[nb] = deg[nb] - 1
        if deg[nb] == 1 {
          new_leaves.push(nb)
        }
      }
    }
    leaves.clear()
    for x in new_leaves {
      leaves.push(x)
    }
  }
  leaves
}

///|
fn canon(v : Int, parent : Int, adj : Array[Array[Int]]) -> String {
  let kids : Array[String] = []
  for u in adj[v] {
    if u != parent {
      kids.push(canon(u, v, adj))
    }
  }
  sort_strings(kids)
  let buf = StringBuilder::new()
  buf.write_char('(')
  for s in kids {
    buf.write_string(s)
  }
  buf.write_char(')')
  buf.to_string()
}

///|
fn sort_strings(arr : Array[String]) -> Unit {
  for i in 1..<arr.length() {
    let key = arr[i]
    let mut j = i - 1
    while j >= 0 && arr[j] > key {
      arr[j + 1] = arr[j]
      j = j - 1
    }
    arr[j + 1] = key
  }
}

///|
/// Canonical string representation of a *rooted* tree.
pub fn canonical_string(root : Int, n : Int, adj : Array[Array[Int]]) -> String {
  if n == 0 {
    return ""
  }
  canon(root, -1, adj)
}

///|
/// Canonical string for an *unrooted* tree: root at the centroid(s)
/// and take the lex-smaller string when there are two centroids.
pub fn unrooted_canonical(n : Int, adj : Array[Array[Int]]) -> String {
  if n == 0 {
    return ""
  }
  let centroids = find_centroids(n, adj)
  let mut best = canon(centroids[0], -1, adj)
  if centroids.length() > 1 {
    let other = canon(centroids[1], -1, adj)
    if other < best {
      best = other
    }
  }
  best
}

///|
/// `true` iff `adj1` and `adj2` describe isomorphic unrooted trees.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // Path 0-1-2 vs path 2-1-0 (same tree labelled differently).
///   let a = [[1], [0, 2], [1]]
///   let b = [[1], [0, 2], [1]]
///   @debug.assert_eq(@tree_isomorphism.is_isomorphic(3, a, 3, b), true)
/// }
/// ```
pub fn is_isomorphic(
  n1 : Int,
  adj1 : Array[Array[Int]],
  n2 : Int,
  adj2 : Array[Array[Int]],
) -> Bool {
  if n1 != n2 {
    return false
  }
  unrooted_canonical(n1, adj1) == unrooted_canonical(n2, adj2)
}

///|
test "iso same path" {
  let a : Array[Array[Int]] = [[1], [0, 2], [1]]
  let b : Array[Array[Int]] = [[1], [0, 2], [1]]
  @debug.assert_eq(is_isomorphic(3, a, 3, b), true)
}

///|
test "iso star vs path" {
  // Star with 4 leaves vs path of 5: not isomorphic.
  let star : Array[Array[Int]] = [[1, 2, 3, 4], [0], [0], [0], [0]]
  let path : Array[Array[Int]] = [[1], [0, 2], [1, 3], [2, 4], [3]]
  @debug.assert_eq(is_isomorphic(5, star, 5, path), false)
}

///|
test "iso same star different labels" {
  let s1 : Array[Array[Int]] = [[1, 2, 3], [0], [0], [0]]
  // Same star centered on vertex 2 instead.
  let s2 : Array[Array[Int]] = [[2], [2], [0, 1, 3], [2]]
  @debug.assert_eq(is_isomorphic(4, s1, 4, s2), true)
}

///|
test "iso different sizes" {
  let a : Array[Array[Int]] = [[1], [0]]
  let b : Array[Array[Int]] = [[1], [0, 2], [1]]
  @debug.assert_eq(is_isomorphic(2, a, 3, b), false)
}

///|
test "iso same binary tree" {
  // Tree rooted at 0: 0->1, 0->2, 1->3.
  let a : Array[Array[Int]] = [[1, 2], [0, 3], [0], [1]]
  // Re-labelled: 3->2, 3->4, 2->1.
  let b : Array[Array[Int]] = [[3], [2], [1, 3], [0, 2]]
  @debug.assert_eq(is_isomorphic(4, a, 4, b), true)
}

///|
test "iso single vertex / empty" {
  @debug.assert_eq(is_isomorphic(0, [], 0, []), true)
  @debug.assert_eq(is_isomorphic(1, [[]], 1, [[]]), true)
}

///|
test "iso caterpillar vs Y-shape" {
  // Caterpillar 0-1-2-3 with leaf 4 attached to 1.
  // Y-shape with three leaves emanating from the centre.
  let cat : Array[Array[Int]] = [[1], [0, 2, 4], [1, 3], [2], [1]]
  let y : Array[Array[Int]] = [[1], [0, 2, 3, 4], [1], [1], [1]]
  @debug.assert_eq(is_isomorphic(5, cat, 5, y), false)
}
