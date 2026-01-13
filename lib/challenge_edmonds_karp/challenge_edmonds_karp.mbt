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
} derive(Show)

///|
pub struct FlowGraph {
  adj : Array[Array[Edge]]
} derive(Show)

///|
/// Create a flow graph with n vertices.
pub fn make(n : Int) -> FlowGraph {
  { adj: Array::makei(n, _ => []) }
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
  g.adj[u].push(Edge::{ to: v, rev: rev_u, cap })
  g.adj[v].push(Edge::{ to: u, rev: rev_v, cap: 0 })
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
#warnings("+missing_invariant+missing_reasoning")
pub fn max_flow(g : FlowGraph, s : Int, t : Int) -> Int {
  let n = g.adj.length()
  if s < 0 || s >= n || t < 0 || t >= n {
    return 0
  }
  let mut edge_count = 0
  for i = 0; i < n; i = i + 1 {
    edge_count = edge_count + g.adj[i].length()
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (Edge count):
      #|edge_count equals the sum of adj[0..i) lengths.
      #|MAINTENANCE:
      #|Accumulate adjacency sizes as we scan vertices.
      #|TERMINATION:
      #|At i = n, edge_count equals the total number of edges.
    ),
  }
  let limit = n * edge_count + 1
  let mut flow = 0
  for iter = 0; iter < limit; iter = iter + 1 {
    let parent : Array[(Int, Int)] = Array::make(n, (-1, -1))
    let queue : Array[Int] = []
    queue.push(s)
    parent[s] = (s, -1)
    for head = 0; head < queue.length(); head = head + 1 {
      let u = queue[head]
      let neighbors = g.adj[u]
      for j = 0; j < neighbors.length(); j = j + 1 {
        let e = neighbors[j]
        if e.cap > 0 && parent[e.to].0 == -1 {
          parent[e.to] = (u, j)
          queue.push(e.to)
        }
      } where {
        invariant: j >= 0 && j <= neighbors.length(),
        reasoning: (
          #|INVARIANT (BFS edges):
          #|All neighbors[0..j) have been checked for residual capacity.
          #|MAINTENANCE:
          #|Record parent for newly discovered nodes.
          #|TERMINATION:
          #|At j = deg(u), all outgoing residual edges are processed.
        ),
      }
    } where {
      invariant: head >= 0 && head <= queue.length(),
      reasoning: (
        #|INVARIANT (BFS frontier):
        #|parent marks the BFS tree of reachable nodes from s.
        #|MAINTENANCE:
        #|Expand one node and enqueue its residual neighbors.
        #|TERMINATION:
        #|At head = queue.length(), BFS is complete.
      ),
    }
    if parent[t].0 == -1 {
      break
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
      invariant: best > 0 && best <= INF,
      reasoning: (
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
        g.adj[pu][ei] = Edge::{ to: e.to, rev: e.rev, cap: e.cap - aug }
        let rev = e.rev
        let back = g.adj[cur][rev]
        g.adj[cur][rev] = Edge::{
          to: back.to,
          rev: back.rev,
          cap: back.cap + aug,
        }
        continue pu
      }
    } where {
      invariant: cur >= 0 && cur < n,
      reasoning: (
        #|INVARIANT (Augment path):
        #|All edges from cur to t have been updated with augment flow.
        #|MAINTENANCE:
        #|Decrease forward capacity and increase reverse capacity.
        #|TERMINATION:
        #|When cur reaches s, the augmentation is complete.
      ),
    }
    flow = flow + aug
  } where {
    invariant: iter >= 0 && iter <= limit,
    invariant: flow >= 0,
    reasoning: (
      #|INVARIANT (Flow augmentation):
      #|flow equals the total amount sent from s to t so far.
      #|MAINTENANCE:
      #|Each BFS finds a shortest augmenting path and adds its bottleneck.
      #|TERMINATION:
      #|When no path remains (or after the Edmonds-Karp bound), flow is final.
    ),
  }
  flow
}
