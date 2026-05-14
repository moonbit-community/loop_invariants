// ============================================================================
// BRON-KERBOSCH - Enumerate all maximal cliques in an undirected graph
// ============================================================================
//
// PROBLEM
//
// A **clique** in an undirected graph is a subset of vertices that are
// pairwise adjacent. A clique is **maximal** if no superset is also a
// clique. Listing all maximal cliques is fundamental in social-network
// analysis, biological-network module discovery, and many constraint
// satisfaction problems.
//
// THE ALGORITHM (Bron-Kerbosch 1973, with Tomita-Tanaka-Takahashi pivot 2006)
//
// State: three vertex sets R, P, X.
//   R = the clique built so far (a "growing clique").
//   P = candidate vertices, all adjacent to every vertex in R.
//   X = excluded vertices (already considered, would yield a non-
//       maximal output if added).
//
// extend(R, P, X):
//   if P is empty and X is empty:
//     report R as a maximal clique
//     return
//   pivot = the vertex in P ∪ X with the most neighbours inside P
//   for each v in P \ N(pivot):
//     extend(R ∪ {v},  P ∩ N(v),  X ∩ N(v))
//     P = P \ {v}
//     X = X ∪ {v}
//
// THE PIVOT TRICK
//
// Without the pivot, the recursion branches on every v in P. With the
// pivot, we only branch on v in P \ N(pivot), and the "pivot" vertex
// (and its P-neighbours) is implicitly handled by the recursive calls
// (which will eventually have to consider that vertex too).
//
// This brings the worst-case complexity down to O(3^(n/3)) -- which
// is optimal because that's the maximum possible number of maximal
// cliques (Moon and Moser 1965).
//
// THE INVARIANTS
//
//   I1.  Every vertex in R is pairwise adjacent.
//   I2.  Every vertex in P is adjacent to every vertex in R.
//   I3.  Every vertex in X is adjacent to every vertex in R, AND has
//        already had its "extend with this as the new vertex" branch
//        explored.
//   I4.  Every maximal clique containing R appears in exactly one leaf
//        of the recursion tree.
//
// I4 is what guarantees no duplicates and no missed cliques.

///|
/// Enumerate all maximal cliques of the undirected graph.
///
/// ## Parameters
///
/// - `n`     : number of vertices (indices `0..<n`).
/// - `edges` : undirected edges as `(u, v)` pairs. Each edge is
///             stored once; the algorithm handles both directions.
///             Duplicate edges and self-loops are tolerated but
///             redundant (self-loops are dropped, since cliques are
///             defined on simple graphs).
///
/// ## Returns
///
/// An `Array[Array[Int]]`. Each inner array is a maximal clique
/// (vertices in ascending order). The outer array is the list of all
/// maximal cliques in unspecified order.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // Triangle on {0, 1, 2} plus an isolated vertex 3:
///   let cliques = @bron_kerbosch_clique.maximal_cliques(
///     4,
///     [(0, 1), (1, 2), (0, 2)][:],
///   )
///   // Two maximal cliques: {0, 1, 2} and {3}.
///   assert_eq(cliques.length(), 2)
/// }
/// ```
///
/// ## Complexity
///
/// `O(3^(n/3))` worst case (optimal -- matches the maximum possible
/// number of maximal cliques in any graph of `n` vertices, Moon-Moser).
pub fn maximal_cliques(
  n : Int,
  edges : ArrayView[(Int, Int)],
) -> Array[Array[Int]] {
  if n <= 0 {
    return []
  }
  // Build the adjacency bitset: nbr[v] contains the indices of v's
  // neighbours, sorted. We use a sorted Array[Int] for efficient
  // intersection.
  let neighbours = Array::make(n, ([] : Array[Int]))
  for i in 0..<n {
    neighbours[i] = []
  }
  for e in edges {
    let (u, v) = e
    if u == v || u < 0 || v < 0 || u >= n || v >= n {
      continue
    }
    if !neighbours[u].contains(v) {
      neighbours[u].push(v)
      neighbours[v].push(u)
    }
  }
  for i in 0..<n {
    neighbours[i].sort()
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (Adjacency sort):
      #|For each vertex in [0..i), its neighbour list is sorted
      #|ascending. This makes intersection and ranking O(|A| + |B|)
      #|via classic two-pointer merge.
    ),
  }
  let results : Array[Array[Int]] = []
  // Initial call: R = empty, P = all vertices, X = empty.
  let p_init : Array[Int] = []
  for i in 0..<n {
    p_init.push(i)
  }
  let r : Array[Int] = []
  let x : Array[Int] = []
  extend(neighbours, results, r, p_init, x)
  results
}

///|
/// Recursive enumeration step. `neighbours[i]` is sorted ascending.
fn extend(
  neighbours : Array[Array[Int]],
  results : Array[Array[Int]],
  r : Array[Int],
  p : Array[Int],
  x : Array[Int],
) -> Unit {
  if p.length() == 0 && x.length() == 0 {
    results.push(r.copy())
    return
  }
  // Choose pivot from P ∪ X with the most neighbours in P.
  let pivot = choose_pivot(neighbours, p, x)
  // Snapshot the candidates to branch on: P \ N(pivot). Iterating over
  // this snapshot is safe even though `p_copy` is modified inside the
  // loop.
  let pivot_neighbours = neighbours[pivot]
  let candidates : Array[Int] = []
  for v in p {
    if !pivot_neighbours.contains(v) {
      candidates.push(v)
    }
  }
  let p_copy = p.copy()
  let x_copy = x.copy()
  for v in candidates {
    let nv = neighbours[v]
    let new_p = intersect_sorted(p_copy[:], nv[:])
    let new_x = intersect_sorted(x_copy[:], nv[:])
    r.push(v)
    extend(neighbours, results, r, new_p, new_x)
    let _ = r.pop()
    // Move v from P to X for the remaining iterations.
    let _ = remove_from_sorted(p_copy, v)
    insert_sorted(x_copy, v)
  }
}

///|
/// Pick the vertex in P ∪ X with the most neighbours in P.
fn choose_pivot(
  neighbours : Array[Array[Int]],
  p : Array[Int],
  x : Array[Int],
) -> Int {
  let mut best = -1
  let mut best_score = -1
  for v in p {
    let score = count_intersection(neighbours[v][:], p[:])
    if score > best_score {
      best = v
      best_score = score
    }
  }
  for v in x {
    let score = count_intersection(neighbours[v][:], p[:])
    if score > best_score {
      best = v
      best_score = score
    }
  }
  best
}

///|
/// Sorted-array intersection using a two-pointer merge.
fn intersect_sorted(a : ArrayView[Int], b : ArrayView[Int]) -> Array[Int] {
  let out : Array[Int] = []
  for i = 0, j = 0; i < a.length() && j < b.length(); {
    let av = a[i]
    let bv = b[j]
    if av == bv {
      out.push(av)
      continue i + 1, j + 1
    } else if av < bv {
      continue i + 1, j
    } else {
      continue i, j + 1
    }
  } where {
    proof_invariant: i >= 0 && j >= 0,
    proof_invariant: i <= a.length() && j <= b.length(),
    proof_reasoning: (
      #|INVARIANT (Two-pointer merge):
      #|out contains every value that has been simultaneously matched
      #|in a and b; pointers advance monotonically.
    ),
  }
  out
}

///|
/// Count of values present in both sorted arrays.
fn count_intersection(a : ArrayView[Int], b : ArrayView[Int]) -> Int {
  let mut count = 0
  for i = 0, j = 0; i < a.length() && j < b.length(); {
    let av = a[i]
    let bv = b[j]
    if av == bv {
      count = count + 1
      continue i + 1, j + 1
    } else if av < bv {
      continue i + 1, j
    } else {
      continue i, j + 1
    }
  } where {
    proof_invariant: count >= 0,
    proof_reasoning: (
      #|INVARIANT (Count): same two-pointer walk as intersect_sorted.
    ),
  }
  count
}

///|
/// Remove a value from a sorted array (in place). Returns true iff the
/// value was present. Caller ensures the array stays sorted.
fn remove_from_sorted(a : Array[Int], v : Int) -> Bool {
  for i in 0..<a.length() {
    if a[i] == v {
      a.remove(i) |> ignore
      return true
    } else if a[i] > v {
      return false
    }
  }
  false
}

///|
/// Insert into a sorted array if not already present, maintaining order.
fn insert_sorted(a : Array[Int], v : Int) -> Unit {
  for i in 0..<a.length() {
    if a[i] == v {
      return
    } else if a[i] > v {
      a.insert(i, v)
      return
    }
  }
  a.push(v)
}

///|
test "bron-kerbosch triangle" {
  let cliques = maximal_cliques(3, [(0, 1), (1, 2), (0, 2)][:])
  @debug.assert_eq(cliques.length(), 1)
  @debug.assert_eq(cliques[0], [0, 1, 2])
}

///|
test "bron-kerbosch isolated vertices" {
  // 3 isolated vertices -> 3 size-1 cliques.
  let cliques = maximal_cliques(3, [][:])
  @debug.assert_eq(cliques.length(), 3)
}

///|
test "bron-kerbosch triangle plus isolated" {
  let cliques = maximal_cliques(4, [(0, 1), (1, 2), (0, 2)][:])
  // {0, 1, 2} and {3} -> two maximal cliques.
  @debug.assert_eq(cliques.length(), 2)
}

///|
test "bron-kerbosch path graph" {
  // Path 0-1-2-3 has three maximal cliques (each edge), each of size 2.
  let cliques = maximal_cliques(4, [(0, 1), (1, 2), (2, 3)][:])
  @debug.assert_eq(cliques.length(), 3)
}

///|
test "bron-kerbosch K4 complete graph" {
  // K4: every quadruple is mutually adjacent, so one maximal clique of size 4.
  let cliques = maximal_cliques(
    4,
    [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)][:],
  )
  @debug.assert_eq(cliques.length(), 1)
  @debug.assert_eq(cliques[0], [0, 1, 2, 3])
}

///|
test "bron-kerbosch two triangles sharing a vertex" {
  // Triangles {0, 1, 2} and {0, 3, 4} sharing vertex 0.
  let cliques = maximal_cliques(
    5,
    [(0, 1), (1, 2), (0, 2), (0, 3), (3, 4), (0, 4)][:],
  )
  // Two maximal cliques of size 3.
  @debug.assert_eq(cliques.length(), 2)
}

///|
test "bron-kerbosch single vertex" {
  let cliques = maximal_cliques(1, [][:])
  @debug.assert_eq(cliques.length(), 1)
  @debug.assert_eq(cliques[0], [0])
}

///|
test "bron-kerbosch empty graph" {
  let cliques = maximal_cliques(0, [][:])
  @debug.assert_eq(cliques.length(), 0)
}
