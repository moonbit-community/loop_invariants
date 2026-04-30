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
/// A directed edge in the flow network.
///
/// Each call to `add_edge` inserts one forward `Edge` and one reverse `Edge`
/// (with capacity 0) into the adjacency list. The reverse edge is used to
/// represent residual capacity so that previously pushed flow can be cancelled.
///
/// The residual capacity of an edge is `cap - flow`. For forward edges this
/// equals the unused capacity; for reverse edges it equals the flow that was
/// pushed on the corresponding forward edge and can therefore be pulled back.
///
/// Fields:
/// - `to`   -- index of the destination vertex
/// - `cap`  -- capacity of this edge (0 for reverse edges)
/// - `flow` -- current flow through this edge (may be negative for reverse
///             edges, encoding the cancellation of forward flow)
/// - `rev`  -- index of the reverse edge in `adj[to]`
pub struct Edge {
  to : Int
  cap : Int64
  mut flow : Int64
  rev : Int
}

///|
/// Push-relabel max flow structure.
///
/// Stores the flow network together with all working state needed by the
/// push-relabel algorithm. A single `PushRelabel` object can be reused for
/// multiple `max_flow` calls; all mutable state is reset at the start of each
/// call while the edge topology (adjacencies and capacities) is preserved.
///
/// Fields:
/// - `n`         -- number of vertices (vertices are numbered `0..n-1`)
/// - `adj`       -- adjacency list; `adj[u]` holds all edges leaving `u`,
///                  including reverse edges
/// - `height`    -- height label for each vertex; guides the direction of
///                  pushes (flow moves from higher to lower)
/// - `excess`    -- excess flow at each vertex; non-source, non-sink vertices
///                  must drain their excess to zero before the algorithm ends
/// - `next_edge` -- current-arc index for each vertex; enables the discharge
///                  procedure to resume scanning from where it left off rather
///                  than restarting from edge 0 after every relabel
/// - `in_active` -- whether a vertex is already present in the active queue,
///                  preventing duplicate enqueuing
pub struct PushRelabel {
  n : Int
  adj : Array[Array[Edge]]
  height : Array[Int]
  excess : Array[Int64]
  next_edge : Array[Int]
  in_active : Array[Bool]
}

///|
/// Create a push-relabel flow network with `n` vertices.
///
/// Vertices are numbered `0` to `n - 1`. No edges are present initially; add
/// them with `add_edge` or `add_undirected_edge` before calling `max_flow`.
///
/// Parameters:
/// - `n` -- number of vertices in the network
///
/// Example:
///
/// ```mbt nocheck
/// let pr = PushRelabel(4)
/// ```
pub fn PushRelabel::PushRelabel(n : Int) -> PushRelabel {
  let adj : Array[Array[Edge]] = [ for _ in 0..<n => [] ]
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
/// Add a directed edge `u -> v` with the given capacity.
///
/// A reverse edge `v -> u` with capacity 0 is also added automatically so
/// that the residual graph is always maintained. This reverse edge allows
/// previously pushed flow to be cancelled (pulled back) if a better routing
/// is found later.
///
/// Multiple edges between the same pair of vertices are allowed; each call
/// adds an independent pair of forward and reverse edges.
///
/// Parameters:
/// - `u`   -- source vertex of the edge (0-indexed)
/// - `v`   -- destination vertex of the edge (0-indexed)
/// - `cap` -- non-negative capacity of the edge
///
/// Example:
///
/// ```mbt nocheck
/// let pr = PushRelabel(3)
/// pr.add_edge(0, 1, 10L)
/// pr.add_edge(1, 2, 5L)
/// ```
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
/// Add an undirected edge between `u` and `v` with the given capacity in
/// both directions.
///
/// This is equivalent to calling `add_edge(u, v, cap)` and
/// `add_edge(v, u, cap)`, except that the two directions share a single pair
/// of adjacency-list entries and their reverse pointers are cross-linked, so
/// flow pushed in one direction automatically reduces the available capacity
/// in the other direction.
///
/// Use this for undirected networks (e.g. pipe networks, road networks) where
/// flow can travel in either direction along the same physical link.
///
/// Parameters:
/// - `u`   -- one endpoint of the undirected edge (0-indexed)
/// - `v`   -- other endpoint of the undirected edge (0-indexed)
/// - `cap` -- capacity in each direction
///
/// Example:
///
/// ```mbt nocheck
/// let pr = PushRelabel(4)
/// pr.add_undirected_edge(0, 1, 7L)
/// pr.add_undirected_edge(1, 3, 3L)
/// ```
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
/// Enqueue vertex `v` into the active list if it qualifies.
///
/// A vertex qualifies for enqueuing when all of the following hold:
/// - it is not the source or the sink,
/// - it has positive excess flow (`excess[v] > 0`),
/// - it is not already in the active list (`in_active[v]` is false).
///
/// The `in_active` flag prevents the same vertex from appearing in the active
/// list more than once at a time, which would cause it to be discharged
/// redundantly.
fn PushRelabel::enqueue(
  self : PushRelabel,
  v : Int,
  source : Int,
  sink : Int,
  active : Array[Int],
) -> Unit {
  if v != source && v != sink && self.excess[v] > 0L && !self.in_active[v] {
    active.push(v)
    self.in_active[v] = true
  }
}

///|
/// Push flow along edge `idx` out of vertex `u`.
///
/// Computes the amount to push as:
///
/// ```
/// delta = min(excess[u], residual(u, idx))
/// ```
///
/// Updates the flow on the forward edge and its reverse, adjusts the excess
/// of both endpoints, and enqueues the destination if it becomes active.
///
/// Does nothing when the edge is already saturated or `u` has no excess.
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
/// Raise the height label of vertex `u` so that at least one outgoing
/// residual edge becomes admissible.
///
/// Scans all outgoing edges of `u` with positive residual capacity and sets:
///
/// ```
/// height[u] = 1 + min{ height[v] | residual(u, v) > 0 }
/// ```
///
/// This is the smallest height that makes one outgoing edge admissible without
/// violating the height invariant for any other edge. If `u` has no outgoing
/// residual edges the height is not changed (the node is isolated in the
/// residual graph and its excess will eventually be pushed back to the source
/// by the surrounding algorithm).
fn PushRelabel::relabel(self : PushRelabel, u : Int) -> Unit {
  let min_height = for e in self.adj[u]; min_height = 1000000000 {
    if e.cap > e.flow && self.height[e.to] < min_height {
      continue self.height[e.to]
    }
    continue min_height
  } nobreak {
    min_height
  }
  if min_height < 1000000000 {
    self.height[u] = min_height + 1
  }
}

///|
/// Discharge vertex `u` until its excess reaches zero.
///
/// Repeatedly scans outgoing edges of `u` using the current-arc pointer
/// `next_edge[u]`:
///
/// - If the current edge is admissible (`residual > 0` and
///   `height[u] == height[v] + 1`), push flow along it.
/// - If the current edge is not admissible, advance `next_edge[u]` to try
///   the next edge.
/// - If all edges have been scanned without draining the excess, relabel `u`
///   and reset `next_edge[u]` to 0 to restart the scan at the new height.
///
/// Loop invariant: every edge before index `next_edge[u]` is non-admissible
/// under the current height of `u`.
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
    proof_invariant: steps >= 0 && self.excess[u] >= 0L,
    proof_reasoning: (
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
/// Compute the maximum flow from `source` to `sink`.
///
/// Resets all flow and height state, then runs the push-relabel algorithm:
///
/// 1. Set `height[source] = n` (source is above all other vertices).
/// 2. Saturate every edge out of `source`, creating initial excess at
///    neighbours and adding them to the active queue.
/// 3. Repeatedly dequeue an active vertex and discharge it until the queue
///    is empty.
///
/// When the queue empties, every non-source, non-sink vertex has zero excess,
/// so the preflow is a valid feasible flow. The height invariant then implies
/// no residual path from `source` to `sink` exists, hence the flow is maximum
/// (by the max-flow min-cut theorem).
///
/// The value returned is the total flow reaching `sink`, which equals the
/// maximum flow in the network.
///
/// This function resets all flow values before running, so calling it again
/// with different source/sink arguments on the same `PushRelabel` object
/// produces a fresh computation.
///
/// Parameters:
/// - `source` -- index of the source vertex (0-indexed)
/// - `sink`   -- index of the sink vertex (0-indexed)
///
/// Returns the maximum flow value from `source` to `sink`.
///
/// Example:
///
/// ```mbt nocheck
/// let pr = PushRelabel(4)
/// pr.add_edge(0, 1, 5L)
/// pr.add_edge(0, 2, 3L)
/// pr.add_edge(1, 3, 4L)
/// pr.add_edge(2, 3, 2L)
/// let flow = pr.max_flow(0, 3)
/// ```
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
  for i in 0..<self.adj[source].length() {
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
  }
  for steps = 0; active.length() > 0; steps = steps + 1 {
    match active.pop() {
      Some(u) => {
        self.in_active[u] = false
        self.discharge(u, active, source, sink)
      }
      None => break
    }
  } where {
    proof_invariant: steps >= 0 && active.length() >= 0,
    proof_reasoning: (
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
