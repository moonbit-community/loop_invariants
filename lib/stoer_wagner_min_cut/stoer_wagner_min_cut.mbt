// ============================================================================
// STOER-WAGNER GLOBAL MIN CUT - Undirected Weighted Graphs
// ============================================================================
//
// The Stoer-Wagner algorithm finds the minimum s-t cut over all pairs,
// yielding the global minimum cut in an undirected graph with non-negative
// edge weights.
//
// IDEA:
// - Repeatedly run a "maximum adjacency" search to build a set A.
// - The last vertex added (t) defines a cut of weight w[t].
// - Contract t into the previous vertex (s) and repeat.
//
// INVARIANTS:
// 1. The adjacency matrix represents weights between current supernodes.
// 2. Each phase returns a valid s-t cut in the contracted graph.
// 3. The best cut across all phases is the global min cut.
//
// TIME COMPLEXITY: O(V^3)
// SPACE COMPLEXITY: O(V^2)

///|
const INF64 : Int64 = 4611686018427387903L

///|
pub(all) struct MinCutResult {
  weight : Int64
  cut : Array[Int] // One side of the minimum cut (original vertices)
}

///|
fn select_max_vertex(
  alive : Array[Bool],
  added : Array[Bool],
  w : Array[Int64],
) -> Int {
  let mut sel = -1
  let mut best = -1L
  for v in 0..<w.length() {
    if alive[v] && not(added[v]) {
      if sel == -1 || w[v] > best {
        sel = v
        best = w[v]
      }
    }
  }
  sel
}

///|
fn append_members(target : Array[Int], source : Array[Int]) -> Unit {
  for v in source {
    target.push(v)
  }
}

///|
/// Compute the global minimum cut using Stoer-Wagner.
/// Returns None if n <= 1 (no cut exists).
///
/// NOTE: Edge weights should be non-negative.
pub fn stoer_wagner_min_cut(
  n : Int,
  edges : ArrayView[(Int, Int, Int64)],
) -> MinCutResult? {
  if n <= 1 {
    return None
  }

  // Build adjacency matrix (sum parallel edges).
  let adj : Array[Array[Int64]] = Array::makei(n, fn(_) { Array::make(n, 0L) })
  for i = 0; i < edges.length(); i = i + 1 {
    let (u, v, w) = edges[i]
    if u >= 0 && u < n && v >= 0 && v < n && u != v {
      adj[u][v] = adj[u][v] + w
      adj[v][u] = adj[v][u] + w
    }
  } where {
    invariant: i >= 0 && i <= edges.length(),
    reasoning: (
      #|INVARIANT (adjacency accumulation):
      #|For every processed edge index < i, its weight has been added to the
      #|adjacency matrix. For any u,v, adj[u][v] equals the total weight of all
      #|processed edges between u and v, and adj remains symmetric.
      #|MAINTENANCE:
      #|For each valid undirected edge, we add its weight to both adj[u][v] and
      #|adj[v][u], preserving symmetry and cumulative totals.
      #|TERMINATION:
      #|At i = edges.length(), all edges are represented in adj.
    ),
  }
  let alive = Array::make(n, true)
  let members : Array[Array[Int]] = Array::makei(n, fn(i) { [i] })
  let mut alive_count = n
  let mut best_weight = INF64
  let mut best_cut : Array[Int] = []

  // Repeat maximum adjacency search and contract.
  for phase = 0; phase < n - 1; phase = phase + 1 {
    if alive_count <= 1 {
      break
    }
    let added = Array::make(n, false)
    let w = Array::make(n, 0L)
    let mut prev = -1
    for iter = 0; iter < alive_count; iter = iter + 1 {
      let sel = select_max_vertex(alive, added, w)
      if sel < 0 {
        break
      }
      added[sel] = true
      if iter == alive_count - 1 {
        let cut_weight = w[sel]
        if cut_weight < best_weight {
          best_weight = cut_weight
          best_cut = members[sel]
        }
        if prev >= 0 {
          // Contract sel into prev.
          for v in 0..<n {
            if alive[v] && v != prev && v != sel {
              adj[prev][v] = adj[prev][v] + adj[sel][v]
              adj[v][prev] = adj[prev][v]
            }
          }
          append_members(members[prev], members[sel])
        }
        alive[sel] = false
        alive_count = alive_count - 1
        break
      }
      for v in 0..<n {
        if alive[v] && not(added[v]) {
          w[v] = w[v] + adj[sel][v]
        }
      }
      prev = sel
    } where {
      invariant: iter >= 0 && iter <= alive_count,
      reasoning: (
        #|INVARIANT (maximum adjacency search):
        #|Let A = {v | added[v]} be the set of selected vertices. At the start of
        #|each iteration, |A| = iter and A contains only alive vertices.
        #|For any alive vertex x not in A, w[x] equals the total edge weight from
        #|x to A. The variable prev is the most recently added vertex, or -1 when
        #|A is empty (iter = 0).
        #|MAINTENANCE:
        #|We pick the alive vertex with maximum w, add it to A, then add its
        #|incident weights to w for all remaining vertices. This preserves the
        #|definition of w for the next iteration.
        #|TERMINATION:
        #|When iter = alive_count - 1, the last selected vertex t defines a cut
        #|between t and A whose weight is w[t]. This is a valid phase cut.
      ),
    }
  } where {
    invariant: phase >= 0 && phase <= n - 1 && alive_count >= 1,
    reasoning: (
      #|INVARIANT (contraction phases):
      #|Alive vertices represent current supernodes; each original vertex appears
      #|in exactly one members[u] for an alive u. For any alive u != v, adj[u][v]
      #|equals the total weight between members[u] and members[v].
      #|best_weight is the minimum cut weight seen so far, and best_cut is the
      #|corresponding side in original vertex indices.
      #|MAINTENANCE:
      #|Each phase finds a valid cut via maximum adjacency search, then contracts
      #|the last vertex into the previous one, preserving supernode partitions
      #|and edge weights between them.
      #|TERMINATION:
      #|After n-1 phases, only one supernode remains and the global min cut has
      #|been encountered among the phase cuts.
    ),
  }
  if best_weight == INF64 {
    None
  } else {
    Some({ weight: best_weight, cut: best_cut })
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
fn cut_weight(
  n : Int,
  edges : ArrayView[(Int, Int, Int64)],
  cut : Array[Int],
) -> Int64 {
  let in_cut = Array::make(n, false)
  for v in cut {
    if v >= 0 && v < n {
      in_cut[v] = true
    }
  }
  let mut total = 0L
  for edge in edges {
    let (u, v, w) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      if in_cut[u] != in_cut[v] {
        total = total + w
      }
    }
  }
  total
}

///|
test "stoer wagner cycle" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 1L),
    (1, 2, 1L),
    (2, 3, 1L),
    (3, 0, 1L),
  ]
  let result = stoer_wagner_min_cut(4, edges[:]).unwrap()
  inspect(result.weight, content="2")
  inspect(cut_weight(4, edges[:], result.cut), content="2")
}

///|
test "stoer wagner disconnected" {
  let edges : Array[(Int, Int, Int64)] = []
  let result = stoer_wagner_min_cut(3, edges[:]).unwrap()
  inspect(result.weight, content="0")
}

///|
test "stoer wagner n1" {
  let edges : Array[(Int, Int, Int64)] = []
  guard stoer_wagner_min_cut(1, edges[:]) is None else { fail("expected None") }
}
