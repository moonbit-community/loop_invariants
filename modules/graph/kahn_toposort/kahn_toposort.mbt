// ============================================================================
// KAHN'S TOPOLOGICAL SORT  -  Kahn 1962
// ============================================================================
//
// PROBLEM
//
// Linearise the vertices of a directed acyclic graph (DAG) so that
// every edge goes from earlier to later. The repository already has a
// DFS-based toposort in `graph/topological_sort_dfs`; this package
// implements the **BFS / queue-based** alternative, which has a few
// practical advantages:
//
//   - Detects cycles naturally: if the queue empties before all
//     vertices are emitted, the rest are on a cycle.
//   - Easy to make **lexicographic** (use a priority queue keyed by
//     vertex id) -- we expose a flag.
//   - Iterative, never recurses, so no stack-overflow risk.
//
// THE ALGORITHM
//
//   compute in_degree[v] for every v
//   enqueue every vertex with in_degree == 0
//   while queue not empty:
//     pop u; output u
//     for each edge u -> v:
//       in_degree[v] -= 1
//       if in_degree[v] == 0:
//         enqueue v
//
// COMPLEXITY
//
//   Time : O(V + E)
//   Space: O(V) for the in-degree array and queue
//
// THE INVARIANT
//
//   "At every step, the queue contains exactly the vertices whose
//    remaining in-degree (after removing previously-output vertices'
//    out-edges) is zero. The output sequence is a valid topological
//    prefix."

///|
/// Result of running Kahn's algorithm.
///
/// - `order`     : a topological ordering of `n` vertices. Empty when
///                 the input has a cycle that prevents linearisation.
/// - `has_cycle` : `true` iff a cycle was detected (in which case
///                 `order.length() < n` and the contents are partial).
pub(all) struct KahnResult {
  order : Array[Int]
  has_cycle : Bool
}

///|
/// Standard Kahn's algorithm, vanilla FIFO queue order.
///
/// `adj[u]` is the list of successors of `u`. `n` is the vertex count.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // 0 -> 1, 0 -> 2, 1 -> 3, 2 -> 3
///   let adj = [[1, 2], [3], [3], []]
///   let r = @kahn_toposort.toposort(4, adj)
///   @debug.assert_eq(r.has_cycle, false)
/// }
/// ```
pub fn toposort(n : Int, adj : Array[Array[Int]]) -> KahnResult {
  let in_deg = Array::make(n, 0)
  for u in 0..<n {
    for v in adj[u] {
      if v >= 0 && v < n {
        in_deg[v] = in_deg[v] + 1
      }
    }
  }
  let queue : Array[Int] = []
  for v in 0..<n {
    if in_deg[v] == 0 {
      queue.push(v)
    }
  }
  let order : Array[Int] = []
  let mut head = 0
  while head < queue.length() {
    let u = queue[head]
    head = head + 1
    order.push(u)
    for v in adj[u] {
      if v < 0 || v >= n {
        continue
      }
      in_deg[v] = in_deg[v] - 1
      if in_deg[v] == 0 {
        queue.push(v)
      }
    }
  }
  { order, has_cycle: order.length() != n }
}

///|
/// Lexicographically smallest topological order: whenever multiple
/// vertices have in-degree 0, prefer the one with the smaller index.
///
/// Uses a binary min-heap; `O((V + E) log V)`.
pub fn lex_toposort(n : Int, adj : Array[Array[Int]]) -> KahnResult {
  let in_deg = Array::make(n, 0)
  for u in 0..<n {
    for v in adj[u] {
      if v >= 0 && v < n {
        in_deg[v] = in_deg[v] + 1
      }
    }
  }
  let heap = HeapInt::new()
  for v in 0..<n {
    if in_deg[v] == 0 {
      heap.push(v)
    }
  }
  let order : Array[Int] = []
  while !heap.is_empty() {
    let u = heap.pop().unwrap()
    order.push(u)
    for v in adj[u] {
      if v < 0 || v >= n {
        continue
      }
      in_deg[v] = in_deg[v] - 1
      if in_deg[v] == 0 {
        heap.push(v)
      }
    }
  }
  { order, has_cycle: order.length() != n }
}

///|
priv struct HeapInt {
  data : Array[Int]
}

///|
fn HeapInt::new() -> HeapInt {
  { data: [] }
}

///|
fn HeapInt::is_empty(self : HeapInt) -> Bool {
  self.data.length() == 0
}

///|
fn HeapInt::push(self : HeapInt, x : Int) -> Unit {
  self.data.push(x)
  let mut i = self.data.length() - 1
  while i > 0 {
    let p = (i - 1) / 2
    if self.data[i] < self.data[p] {
      let t = self.data[i]
      self.data[i] = self.data[p]
      self.data[p] = t
      i = p
    } else {
      break
    }
  }
}

///|
fn HeapInt::pop(self : HeapInt) -> Int? {
  let n = self.data.length()
  if n == 0 {
    return None
  }
  let top = self.data[0]
  let last = self.data[n - 1]
  self.data.pop() |> ignore
  if n > 1 {
    self.data[0] = last
    let m = self.data.length()
    let mut i = 0
    while true {
      let l = 2 * i + 1
      let r = 2 * i + 2
      let mut best = i
      if l < m && self.data[l] < self.data[best] {
        best = l
      }
      if r < m && self.data[r] < self.data[best] {
        best = r
      }
      if best == i {
        break
      }
      let t = self.data[i]
      self.data[i] = self.data[best]
      self.data[best] = t
      i = best
    }
  }
  Some(top)
}

///|
/// Verify a candidate ordering is topological: every edge `u -> v`
/// must have `position(u) < position(v)`.
fn is_topological(order : Array[Int], adj : Array[Array[Int]]) -> Bool {
  let n = adj.length()
  if order.length() != n {
    return false
  }
  let pos = Array::make(n, -1)
  for i in 0..<n {
    pos[order[i]] = i
  }
  for u in 0..<n {
    if pos[u] == -1 {
      return false
    }
    for v in adj[u] {
      if v < 0 || v >= n {
        continue
      }
      if pos[u] >= pos[v] {
        return false
      }
    }
  }
  true
}

///|
test "kahn basic dag" {
  let adj : Array[Array[Int]] = [[1, 2], [3], [3], []]
  let r = toposort(4, adj)
  @debug.assert_eq(r.has_cycle, false)
  @debug.assert_eq(is_topological(r.order, adj), true)
}

///|
test "kahn detects cycle" {
  // 0 -> 1 -> 2 -> 0
  let adj : Array[Array[Int]] = [[1], [2], [0]]
  let r = toposort(3, adj)
  @debug.assert_eq(r.has_cycle, true)
  @debug.assert_eq(r.order.length(), 0)
}

///|
test "kahn empty graph" {
  let r = toposort(0, [])
  @debug.assert_eq(r.has_cycle, false)
  @debug.assert_eq(r.order, [])
}

///|
test "kahn isolated vertices" {
  let r = toposort(3, [[], [], []])
  @debug.assert_eq(r.has_cycle, false)
  @debug.assert_eq(r.order.length(), 3)
}

///|
test "kahn lex_toposort smallest first" {
  // Multiple valid orderings; expect lexicographic smallest.
  let adj : Array[Array[Int]] = [[2], [2], [3, 4], [], []]
  let r = lex_toposort(5, adj)
  // 0 and 1 are roots; lex picks 0 first, then 1, then 2, then 3 < 4.
  @debug.assert_eq(r.order, [0, 1, 2, 3, 4])
}

///|
test "kahn longer dag" {
  // 0 -> 1, 0 -> 2, 1 -> 3, 2 -> 3, 3 -> 4, 3 -> 5
  let adj : Array[Array[Int]] = [[1, 2], [3], [3], [4, 5], [], []]
  let r = toposort(6, adj)
  @debug.assert_eq(r.has_cycle, false)
  @debug.assert_eq(is_topological(r.order, adj), true)
  // 0 must come before all others; 3 before 4 and 5.
  let pos = Array::make(6, -1)
  for i in 0..<6 {
    pos[r.order[i]] = i
  }
  @debug.assert_eq(pos[0], 0)
  @debug.assert_eq(pos[3] < pos[4], true)
  @debug.assert_eq(pos[3] < pos[5], true)
}

///|
test "kahn partial cycle still detects" {
  // {0 -> 1} acyclic chain, {2 -> 3 -> 2} cycle.
  let adj : Array[Array[Int]] = [[1], [], [3], [2]]
  let r = toposort(4, adj)
  @debug.assert_eq(r.has_cycle, true)
  // Only 0 and 1 should make it out.
  @debug.assert_eq(r.order.length(), 2)
}
