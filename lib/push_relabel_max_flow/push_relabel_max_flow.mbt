// ============================================================================
// PUSH-RELABEL (PRE-FLOW) MAX FLOW
// ============================================================================
//
// Push-relabel maintains a preflow and vertex heights. Excess flow is pushed
// along admissible edges (height[u] = height[v] + 1). When no admissible edge
// remains, we relabel u to the smallest height that enables progress.
//
// KEY INVARIANTS:
// - Capacity constraints: 0 <= flow(e) <= cap(e)
// - Skew symmetry via reverse edges
// - Preflow: all non-source vertices can have excess >= 0
// - Height labels: for any residual edge (u,v), height[u] <= height[v] + 1
//
// When no active vertices remain, the preflow is a feasible max flow.
//
// TIME COMPLEXITY: O(V^2 E) worst-case (faster in practice)
// SPACE COMPLEXITY: O(V + E)

///|
pub struct Edge {
  to : Int
  cap : Int64
  mut flow : Int64
  rev : Int
}

///|
/// Push-relabel max flow structure.
pub struct PushRelabel {
  n : Int
  adj : Array[Array[Edge]]
  height : Array[Int]
  excess : Array[Int64]
  next_edge : Array[Int]
  in_active : Array[Bool]
}

///|
/// Create a push-relabel flow network with n vertices.
pub fn PushRelabel::new(n : Int) -> PushRelabel {
  let adj : Array[Array[Edge]] = Array::makei(n, _ => [])
  {
    n,
    adj,
    height: Array::make(n, 0),
    excess: Array::make(n, 0L),
    next_edge: Array::make(n, 0),
    in_active: Array::make(n, false),
  }
}

///|
/// Add a directed edge u -> v with capacity cap.
pub fn PushRelabel::add_edge(
  self : PushRelabel,
  u : Int,
  v : Int,
  cap : Int64,
) -> Unit {
  let rev_u = self.adj[v].length()
  let rev_v = self.adj[u].length()
  self.adj[u].push({ to: v, cap, flow: 0L, rev: rev_u })
  self.adj[v].push({ to: u, cap: 0L, flow: 0L, rev: rev_v })
}

///|
/// Add an undirected edge (u, v) with capacity cap in both directions.
pub fn PushRelabel::add_undirected_edge(
  self : PushRelabel,
  u : Int,
  v : Int,
  cap : Int64,
) -> Unit {
  let rev_u = self.adj[v].length()
  let rev_v = self.adj[u].length()
  self.adj[u].push({ to: v, cap, flow: 0L, rev: rev_u })
  self.adj[v].push({ to: u, cap, flow: 0L, rev: rev_v })
}

///|
fn min_i64(a : Int64, b : Int64) -> Int64 {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn PushRelabel::enqueue(
  self : PushRelabel,
  v : Int,
  source : Int,
  sink : Int,
  active : Array[Int],
) -> Unit {
  if v != source && v != sink && self.excess[v] > 0L && not(self.in_active[v]) {
    active.push(v)
    self.in_active[v] = true
  }
}

///|
fn PushRelabel::push_edge(
  self : PushRelabel,
  u : Int,
  idx : Int,
  active : Array[Int],
  source : Int,
  sink : Int,
) -> Unit {
  let v = self.adj[u][idx].to
  let residual = self.adj[u][idx].cap - self.adj[u][idx].flow
  if residual <= 0L || self.excess[u] <= 0L {
    return
  }
  let delta = min_i64(self.excess[u], residual)
  self.adj[u][idx].flow = self.adj[u][idx].flow + delta
  let rev = self.adj[u][idx].rev
  self.adj[v][rev].flow = self.adj[v][rev].flow - delta
  self.excess[u] = self.excess[u] - delta
  self.excess[v] = self.excess[v] + delta
  self.enqueue(v, source, sink, active)
}

///|
fn PushRelabel::relabel(self : PushRelabel, u : Int) -> Unit {
  let mut min_height = 1000000000
  for e in self.adj[u] {
    if e.cap > e.flow && self.height[e.to] < min_height {
      min_height = self.height[e.to]
    }
  }
  if min_height < 1000000000 {
    self.height[u] = min_height + 1
  }
}

///|
fn PushRelabel::discharge(
  self : PushRelabel,
  u : Int,
  active : Array[Int],
  source : Int,
  sink : Int,
) -> Unit {
  for steps = 0; self.excess[u] > 0L; steps = steps + 1 {
    if self.next_edge[u] < self.adj[u].length() {
      let idx = self.next_edge[u]
      let v = self.adj[u][idx].to
      let residual = self.adj[u][idx].cap - self.adj[u][idx].flow
      if residual > 0L && self.height[u] == self.height[v] + 1 {
        self.push_edge(u, idx, active, source, sink)
      } else {
        self.next_edge[u] = self.next_edge[u] + 1
      }
    } else {
      self.relabel(u)
      self.next_edge[u] = 0
    }
  } where {
    invariant: steps >= 0 && self.excess[u] >= 0L,
    reasoning: (
      #|INVARIANT (discharge scan):
      #|Edges with index < next_edge[u] are known to be non-admissible under
      #|the current height: either saturated or height condition violated.
      #|MAINTENANCE:
      #|If an admissible residual edge exists, push reduces excess or saturates
      #|the edge. If none exist, relabel raises height[u] to enable progress and
      #|resets next_edge[u]. Heights only increase, so the process terminates.
      #|TERMINATION:
      #|When excess[u] becomes 0, u is fully discharged.
    ),
  }
}

///|
/// Compute max flow from source to sink.
pub fn PushRelabel::max_flow(
  self : PushRelabel,
  source : Int,
  sink : Int,
) -> Int64 {
  let n = self.n
  for i in 0..<n {
    self.height[i] = 0
    self.excess[i] = 0L
    self.next_edge[i] = 0
    self.in_active[i] = false
    for idx in 0..<self.adj[i].length() {
      self.adj[i][idx].flow = 0L
    }
  }
  self.height[source] = n
  let active : Array[Int] = []

  // Preflow: saturate edges out of source.
  for i = 0; i < self.adj[source].length(); i = i + 1 {
    let cap = self.adj[source][i].cap
    if cap > 0L {
      self.adj[source][i].flow = cap
      let v = self.adj[source][i].to
      let rev = self.adj[source][i].rev
      self.adj[v][rev].flow = self.adj[v][rev].flow - cap
      self.excess[v] = self.excess[v] + cap
      self.excess[source] = self.excess[source] - cap
      self.enqueue(v, source, sink, active)
    }
  } where {
    invariant: i >= 0 && i <= self.adj[source].length(),
    reasoning: (
      #|INVARIANT (preflow saturation):
      #|Edges out of source in [0, i) are fully saturated, contributing their
      #|capacity to excess at their head vertices. Source excess equals the
      #|negative of the total flow sent so far.
      #|MAINTENANCE:
      #|Saturate edge i and update excess values; newly active vertices are
      #|enqueued.
      #|TERMINATION:
      #|After all outgoing edges are processed, the preflow is initialized with
      #|height[source] = n and all other heights 0.
    ),
  }
  for steps = 0; active.length() > 0; steps = steps + 1 {
    let u = active.pop().unwrap()
    self.in_active[u] = false
    self.discharge(u, active, source, sink)
  } where {
    invariant: steps >= 0 && active.length() >= 0,
    reasoning: (
      #|INVARIANT (active vertices):
      #|Every vertex in active has positive excess and is neither source nor
      #|sink. Vertices not in active (except source/sink) have zero excess.
      #|MAINTENANCE:
      #|Discharging u removes its excess, while any neighbor that gains excess
      #|is enqueued. This preserves the invariant that all positive-excess
      #|vertices are eventually processed.
      #|TERMINATION:
      #|When active is empty, all non-source/sink vertices have zero excess, so
      #|the preflow is a valid flow. Height labels imply no residual s-t path,
      #|hence the flow is maximum.
    ),
  }
  self.excess[sink]
}
