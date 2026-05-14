// ============================================================================
// BORUVKA'S MINIMUM SPANNING TREE  -  Boruvka 1926
// ============================================================================
//
// PROBLEM
//
// Given an undirected, connected, weighted graph with `n` vertices
// and `m` edges, find a spanning tree of minimum total edge weight.
//
// THE IDEA
//
// Boruvka 1926 (the very first MST algorithm) builds the MST one
// **phase** at a time:
//
//   1. Each connected component independently picks its
//      lightest outgoing edge ("cheapest edge to escape").
//   2. All chosen edges are added to the MST simultaneously.
//      Components connected by them merge into super-components.
//   3. Repeat until one component remains.
//
// After every phase, the number of components is at least halved
// (each phase merges every component with at least one neighbor), so
// the total number of phases is `O(log n)`.
//
// COMPLEXITY
//
//   Time  : O(m * log n) -- each phase scans every edge once.
//   Space : O(n + m)
//
// WHY IT'S INTERESTING
//
// Boruvka's per-component independence makes it the canonical
// **parallel-friendly** MST algorithm. Modern Filter-Boruvka and
// PRAM variants compute MSTs in O(log^2 n) time on PRAM and `O(m
// alpha(m, n))` time sequentially.
//
// THE INVARIANT
//
//   "After completing phase k, the set of chosen edges forms a
//    subgraph of some MST, and the number of components has at most
//    halved since the start of phase k."
//
//   Because each phase's "cheapest outgoing edge per component" is
//   in every MST (the cut property), all chosen edges are MST edges.

///|
/// Compute a minimum spanning tree of an undirected, connected, weighted graph.
///
/// - `n` is the number of vertices, labeled `[0, n)`.
/// - `edges[i] = (u, v, w)` is an undirected edge of weight `w` between
///   `u` and `v`. `u != v` is required.
/// - Returns a list of edge indices (positions in `edges`) whose
///   selection forms an MST, in the order they were added.
///
/// If the input graph is disconnected the result is a minimum spanning
/// **forest** (one MST per component).
///
/// ## Example
///
/// ```moonbit nocheck
/// let n = 4
/// let edges : Array[(Int, Int, Int)] = [
///   (0, 1, 1),
///   (1, 2, 4),
///   (0, 2, 2),
///   (2, 3, 3),
/// ]
/// @boruvka_mst.mst(n, edges)  // [0, 2, 3]
/// ```
pub fn mst(n : Int, edges : Array[(Int, Int, Int)]) -> Array[Int] {
  // Union-find with path compression and union by size.
  let parent = Array::makei(n, i => i)
  let size = Array::make(n, 1)
  fn find(x : Int) -> Int {
    let mut r = x
    while parent[r] != r {
      r = parent[r]
    }
    // Path compression.
    let mut cur = x
    while parent[cur] != r {
      let nxt = parent[cur]
      parent[cur] = r
      cur = nxt
    }
    r
  }

  fn union(x : Int, y : Int) -> Bool {
    let rx = find(x)
    let ry = find(y)
    if rx == ry {
      return false
    }
    if size[rx] < size[ry] {
      parent[rx] = ry
      size[ry] = size[ry] + size[rx]
    } else {
      parent[ry] = rx
      size[rx] = size[rx] + size[ry]
    }
    true
  }

  let chosen : Array[Int] = []
  let mut num_components = n
  // Phase loop.
  while num_components > 1 {
    // cheapest[c] = (edge index, weight) of cheapest outgoing edge of
    // component rooted at c, or (-1, +inf) if none.
    let cheapest_edge = Array::make(n, -1)
    let cheapest_wt = Array::make(n, 0)
    let has = Array::make(n, false)
    for ei in 0..<edges.length() {
      let (u, v, w) = edges[ei]
      let ru = find(u)
      let rv = find(v)
      if ru == rv {
        continue
      }
      if !has[ru] ||
        w < cheapest_wt[ru] ||
        (w == cheapest_wt[ru] && ei < cheapest_edge[ru]) {
        cheapest_edge[ru] = ei
        cheapest_wt[ru] = w
        has[ru] = true
      }
      if !has[rv] ||
        w < cheapest_wt[rv] ||
        (w == cheapest_wt[rv] && ei < cheapest_edge[rv]) {
        cheapest_edge[rv] = ei
        cheapest_wt[rv] = w
        has[rv] = true
      }
    }
    // Add cheapest edges; merge components.
    let mut added = 0
    for c in 0..<n {
      if has[c] && cheapest_edge[c] >= 0 {
        let ei = cheapest_edge[c]
        let (u, v, _) = edges[ei]
        if union(u, v) {
          chosen.push(ei)
          added = added + 1
          num_components = num_components - 1
        }
      }
    }
    if added == 0 {
      // Graph is disconnected; no more edges possible.
      break
    }
  }
  chosen
}

///|
/// Convenience: compute the total weight of the MST.
pub fn mst_weight(n : Int, edges : Array[(Int, Int, Int)]) -> Int {
  let chosen = mst(n, edges)
  let mut total = 0
  for ei in chosen {
    let (_, _, w) = edges[ei]
    total = total + w
  }
  total
}

///|
test "boruvka triangle" {
  // Triangle with weights 1, 2, 3. MST drops the heaviest (3), total = 3.
  let edges = [(0, 1, 1), (1, 2, 2), (0, 2, 3)]
  @debug.assert_eq(mst_weight(3, edges), 3)
  @debug.assert_eq(mst(3, edges).length(), 2)
}

///|
test "boruvka single vertex" {
  // n=1, no edges; MST is trivial empty.
  @debug.assert_eq(mst(1, []).length(), 0)
}

///|
test "boruvka two vertices" {
  let edges = [(0, 1, 5)]
  @debug.assert_eq(mst_weight(2, edges), 5)
}

///|
test "boruvka small example" {
  // 4 vertices, 5 edges:
  //   0 - 1 (1)
  //   0 - 2 (2)
  //   1 - 2 (3)
  //   1 - 3 (4)
  //   2 - 3 (5)
  // MST = {0-1, 0-2, 1-3} with weight 1 + 2 + 4 = 7
  let edges = [(0, 1, 1), (0, 2, 2), (1, 2, 3), (1, 3, 4), (2, 3, 5)]
  @debug.assert_eq(mst_weight(4, edges), 7)
}

///|
test "boruvka cross-validates with Kruskal" {
  // Run a naive Kruskal: sort edges by weight, greedily add if no cycle.
  fn kruskal(n : Int, edges : Array[(Int, Int, Int)]) -> Int {
    let indexed : Array[(Int, Int, Int, Int)] = []
    for i in 0..<edges.length() {
      let (u, v, w) = edges[i]
      indexed.push((w, u, v, i))
    }
    indexed.sort_by(fn(a, b) {
      let (wa, _, _, _) = a
      let (wb, _, _, _) = b
      wa.compare(wb)
    })
    let parent = Array::makei(n, i => i)
    fn find(x : Int) -> Int {
      let mut r = x
      while parent[r] != r {
        r = parent[r]
      }
      r
    }

    let mut total = 0
    for e in indexed {
      let (w, u, v, _) = e
      let ru = find(u)
      let rv = find(v)
      if ru != rv {
        parent[ru] = rv
        total = total + w
      }
    }
    total
  }

  let tests : Array[(Int, Array[(Int, Int, Int)])] = [
    (1, []),
    (2, [(0, 1, 7)]),
    (3, [(0, 1, 1), (1, 2, 2), (0, 2, 3)]),
    (
      5,
      [
        (0, 1, 2),
        (0, 2, 3),
        (1, 2, 1),
        (1, 3, 4),
        (2, 4, 5),
        (3, 4, 6),
        (0, 3, 7),
      ],
    ),
    (4, [(0, 1, 10), (0, 2, 6), (0, 3, 5), (1, 3, 15), (2, 3, 4)]),
  ]
  for t in tests {
    let (n, edges) = t
    @debug.assert_eq(mst_weight(n, edges), kruskal(n, edges))
  }
}

///|
test "boruvka disconnected graph" {
  // Two components: {0, 1} and {2, 3}. MSF has two edges, weight 1 + 3 = 4.
  let edges = [(0, 1, 1), (2, 3, 3)]
  @debug.assert_eq(mst_weight(4, edges), 4)
  @debug.assert_eq(mst(4, edges).length(), 2)
}

///|
test "boruvka parallel edges" {
  // Multiple edges between same vertices; MST picks the cheapest.
  let edges = [(0, 1, 10), (0, 1, 5), (0, 1, 7)]
  @debug.assert_eq(mst_weight(2, edges), 5)
}
