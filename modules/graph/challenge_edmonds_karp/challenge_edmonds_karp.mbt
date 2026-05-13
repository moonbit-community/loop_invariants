// ============================================================================
// Challenge: Max Flow (Edmonds-Karp)
// BFS augmenting paths on residual graph
// ============================================================================

///|
const INF : Int = 0x3fffffff

///|
struct Edge {
  to : Int
  rev : Int
  cap : Int
} derive(Debug)

///|
/// A directed flow network represented as adjacency lists with paired
/// forward/reverse edges for residual graph traversal.
///
/// Each forward edge `u -> v` with capacity `c` is stored together with a
/// reverse edge `v -> u` of initial capacity `0`; the indices into the
/// neighbour lists are cross-linked so that augmenting along an edge can
/// adjust both its remaining and reverse capacities in `O(1)`. This is the
/// shape consumed by the Edmonds-Karp routine `max_flow`, which repeatedly
/// runs BFS on the residual graph in `O(V * E^2)` total.
///
/// Construct with `make(n)`, add edges with `add_edge`, then call `max_flow`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let g = make(4)
///   add_edge(g, 0, 1, 3)
///   add_edge(g, 0, 2, 2)
///   add_edge(g, 1, 3, 2)
///   add_edge(g, 2, 3, 4)
///   @debug.assert_eq(max_flow(g, 0, 3), 5)
/// }
/// ```
pub struct FlowGraph {
  adj : Array[Array[Edge]]
} derive(Debug)

///|
/// Create a flow graph with n vertices.
pub fn make(n : Int) -> FlowGraph {
  { adj: [ for _ in 0..<n => [] ] }
}

///|
/// Add a directed edge (u -> v) with capacity cap.
pub fn add_edge(g : FlowGraph, u : Int, v : Int, cap : Int) -> Unit {
  let n = g.adj.length()
  if u < 0 || u >= n || v < 0 || v >= n || cap < 0 {
    return
  }
  let rev_u = g.adj[v].length()
  let rev_v = g.adj[u].length()
  g.adj[u].push({ to: v, rev: rev_u, cap })
  g.adj[v].push({ to: u, rev: rev_v, cap: 0 })
}

///|
fn min2(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
/// Compute max flow from s to t.
pub fn max_flow(g : FlowGraph, s : Int, t : Int) -> Int {
  let n = g.adj.length()
  if s < 0 || s >= n || t < 0 || t >= n {
    return 0
  }
  let edge_count = for neighbors in g.adj; edge_count = 0 {
    continue edge_count + neighbors.length()
  } nobreak {
    edge_count
  }
  let limit = n * edge_count + 1
  for iter = 0, flow = 0; iter < limit; {
    let parent : Array[(Int, Int)] = Array::make(n, (-1, -1))
    let queue : Array[Int] = []
    queue.push(s)
    parent[s] = (s, -1)
    for head = 0; head < queue.length(); head = head + 1 {
      let u = queue[head]
      let neighbors = g.adj[u]
      for j in 0..<neighbors.length() {
        let e = neighbors[j]
        if e.cap > 0 && parent[e.to].0 == -1 {
          parent[e.to] = (u, j)
          queue.push(e.to)
        }
      }
    } where {
      proof_invariant: head >= 0 && head <= queue.length(),
      proof_reasoning: (
        #|INVARIANT (BFS frontier):
        #|parent marks the BFS tree of reachable nodes from s.
        #|MAINTENANCE:
        #|Expand one node and enqueue its residual neighbors.
        #|TERMINATION:
        #|At head = queue.length(), BFS is complete.
      ),
    }
    if parent[t].0 == -1 {
      break flow
    }
    let aug = for cur = t, best = INF {
      if cur == s {
        break best
      } else {
        let (pu, ei) = parent[cur]
        let e = g.adj[pu][ei]
        continue pu, min2(best, e.cap)
      }
    } where {
      proof_invariant: best > 0 && best <= INF,
      proof_reasoning: (
        #|INVARIANT (Bottleneck):
        #|best is the minimum residual capacity on the path from cur to t.
        #|MAINTENANCE:
        #|Move to parent and tighten best with the edge capacity.
        #|TERMINATION:
        #|At cur = s, best is the path bottleneck.
      ),
    }
    for cur = t {
      if cur == s {
        break
      } else {
        let (pu, ei) = parent[cur]
        let e = g.adj[pu][ei]
        g.adj[pu][ei] = { to: e.to, rev: e.rev, cap: e.cap - aug }
        let rev = e.rev
        let back = g.adj[cur][rev]
        g.adj[cur][rev] = { to: back.to, rev: back.rev, cap: back.cap + aug }
        continue pu
      }
    } where {
      proof_invariant: cur >= 0 && cur < n,
      proof_reasoning: (
        #|INVARIANT (Augment path):
        #|All edges from cur to t have been updated with augment flow.
        #|MAINTENANCE:
        #|Decrease forward capacity and increase reverse capacity.
        #|TERMINATION:
        #|When cur reaches s, the augmentation is complete.
      ),
    }
    continue iter + 1, flow + aug
  } nobreak {
    flow
  } where {
    proof_invariant: iter >= 0 && iter <= limit,
    proof_invariant: flow >= 0,
    proof_reasoning: (
      #|INVARIANT (Flow augmentation):
      #|flow equals the total amount sent from s to t so far.
      #|MAINTENANCE:
      #|Each BFS finds a shortest augmenting path and adds its bottleneck.
      #|TERMINATION:
      #|When no path remains (or after the Edmonds-Karp bound), flow is final.
    ),
  }
}
