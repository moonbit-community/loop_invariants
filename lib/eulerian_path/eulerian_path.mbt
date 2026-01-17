// ============================================================================
// EULERIAN PATH/CIRCUIT - Hierholzer's Algorithm
// ============================================================================
//
// An Eulerian path visits every edge exactly once.
// An Eulerian circuit is an Eulerian path that starts and ends at the same node.
//
// DIRECTED GRAPH CONDITIONS:
// - At most one vertex has out = in + 1 (start)
// - At most one vertex has in = out + 1 (end)
// - All other vertices satisfy in = out
// - All vertices with nonzero degree are connected in the underlying undirected graph
//
// UNDIRECTED GRAPH CONDITIONS:
// - 0 or 2 vertices have odd degree
// - All vertices with nonzero degree are connected
//
// ALGORITHM (Hierholzer):
// Walk edges until stuck, then backtrack. The backtracking order yields
// the Eulerian path in reverse.
//
// INVARIANTS:
// 1. Each edge is used at most once (tracked by pointer or used[])
// 2. Stack is a valid trail; path contains vertices whose outgoing edges are exhausted
// 3. When the stack empties, path length equals E + 1 if a solution exists
//
// TIME COMPLEXITY: O(V + E)
// SPACE COMPLEXITY: O(V + E)

///|
fn build_adj_lists(n : Int) -> Array[Array[Int]] {
  Array::makei(n, _ => [])
}

///|
fn is_connected_undirected(
  n : Int,
  adj : Array[Array[Int]],
  has_degree : Array[Bool],
  start : Int,
) -> Bool {
  let seen = Array::make(n, false)
  let stack : Array[Int] = []
  stack.push(start)
  seen[start] = true
  for idx = 0; idx < stack.length(); idx = idx + 1 {
    let u = stack[idx]
    for v in adj[u] {
      if not(seen[v]) {
        seen[v] = true
        stack.push(v)
      }
    }
  } where {
    invariant: idx >= 0 && idx <= stack.length(),
    reasoning: (
      #|INVARIANT (DFS reachability):
      #|Vertices in stack[0..idx) are processed; seen marks all vertices
      #|reachable from start discovered so far.
      #|MAINTENANCE:
      #|Expanding stack[idx] discovers new neighbors and marks them seen.
      #|TERMINATION:
      #|When idx reaches stack.length(), all reachable vertices are visited.
    ),
  }
  for i in 0..<n {
    if has_degree[i] && not(seen[i]) {
      return false
    }
  }
  true
}

///|
/// Eulerian path for a directed graph. Returns None if no Eulerian path exists.
/// If edges is empty, returns Some([]).
pub fn eulerian_path_directed(
  n : Int,
  edges : ArrayView[(Int, Int)],
) -> Array[Int]? {
  if n <= 0 {
    return Some([])
  }
  if edges.length() == 0 {
    return Some([])
  }
  let adj = build_adj_lists(n)
  let undirected = build_adj_lists(n)
  let in_deg = Array::make(n, 0)
  let out_deg = Array::make(n, 0)
  let has_degree = Array::make(n, false)
  for edge in edges {
    let (u, v) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      adj[u].push(v)
      undirected[u].push(v)
      undirected[v].push(u)
      out_deg[u] = out_deg[u] + 1
      in_deg[v] = in_deg[v] + 1
      has_degree[u] = true
      has_degree[v] = true
    }
  }
  let mut start = -1
  let mut end = -1
  for v in 0..<n {
    let diff = out_deg[v] - in_deg[v]
    if diff == 1 {
      if start != -1 {
        return None
      }
      start = v
    } else if diff == -1 {
      if end != -1 {
        return None
      }
      end = v
    } else if diff != 0 {
      return None
    }
  }
  if start == -1 {
    // Eulerian circuit case: choose any vertex with outgoing edges
    for v in 0..<n {
      if out_deg[v] > 0 {
        start = v
        break
      }
    }
  }
  if start == -1 {
    return Some([])
  }
  if not(is_connected_undirected(n, undirected, has_degree, start)) {
    return None
  }
  if end != -1 && not(has_degree[end]) {
    return None
  }
  let next_index = Array::make(n, 0)
  let stack : Array[Int] = [start]
  let path : Array[Int] = []
  for {
    if stack.length() == 0 {
      break
    }
    let v = stack[stack.length() - 1]
    let idx = next_index[v]
    if idx < adj[v].length() {
      let to = adj[v][idx]
      next_index[v] = idx + 1
      stack.push(to)
    } else {
      path.push(v)
      let _ = stack.pop()

    }
  } where {
    invariant: path.length() + stack.length() >= 1,
    reasoning: (
      #|INVARIANT (Hierholzer stack):
      #|stack is a valid trail using only unused outgoing edges; path contains
      #|vertices whose outgoing edges are exhausted in the current traversal.
      #|MAINTENANCE:
      #|Advance along an unused edge when available; otherwise backtrack by
      #|moving the vertex to path.
      #|TERMINATION:
      #|When stack is empty, all reachable edges are exhausted and path is built.
    ),
    invariant: next_index.length() == n,
    reasoning: (
      #|INVARIANT (edge cursor):
      #|next_index[v] is the count of outgoing edges from v already consumed.
      #|MAINTENANCE:
      #|Increment cursor exactly once when an edge is used.
      #|TERMINATION:
      #|Ensures each edge is used at most once.
    ),
  }
  path.rev_in_place()
  if path.length() != edges.length() + 1 {
    None
  } else {
    Some(path)
  }
}

///|
/// Eulerian path for an undirected graph. Returns None if no Eulerian path exists.
/// If edges is empty, returns Some([]).
pub fn eulerian_path_undirected(
  n : Int,
  edges : ArrayView[(Int, Int)],
) -> Array[Int]? {
  if n <= 0 {
    return Some([])
  }
  if edges.length() == 0 {
    return Some([])
  }
  let adj = build_adj_lists(n)
  let deg = Array::make(n, 0)
  let has_degree = Array::make(n, false)
  for i, edge in edges {
    let (u, v) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      adj[u].push(i)
      adj[v].push(i)
      deg[u] = deg[u] + 1
      deg[v] = deg[v] + 1
      has_degree[u] = true
      has_degree[v] = true
    }
  }
  let odd : Array[Int] = []
  for v in 0..<n {
    if deg[v] % 2 == 1 {
      odd.push(v)
    }
  }
  if odd.length() != 0 && odd.length() != 2 {
    return None
  }
  let mut start = -1
  if odd.length() == 2 {
    start = odd[0]
  } else {
    for v in 0..<n {
      if deg[v] > 0 {
        start = v
        break
      }
    }
  }
  if start == -1 {
    return Some([])
  }
  let undirected = build_adj_lists(n)
  for edge in edges {
    let (u, v) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      undirected[u].push(v)
      undirected[v].push(u)
    }
  }
  if not(is_connected_undirected(n, undirected, has_degree, start)) {
    return None
  }
  let used = Array::make(edges.length(), false)
  let cursor = Array::make(n, 0)
  let stack : Array[Int] = [start]
  let path : Array[Int] = []
  for {
    if stack.length() == 0 {
      break
    }
    let v = stack[stack.length() - 1]
    let idx = loop cursor[v] {
      i => {
        if i < adj[v].length() && used[adj[v][i]] {
          continue i + 1
        }
        break i
      }
    }
    cursor[v] = idx
    if idx < adj[v].length() {
      let e = adj[v][idx]
      if not(used[e]) {
        used[e] = true
        let (a, b) = edges[e]
        let next = if a == v { b } else { a }
        stack.push(next)
      }
    } else {
      path.push(v)
      let _ = stack.pop()

    }
  } where {
    invariant: path.length() + stack.length() >= 1,
    reasoning: (
      #|INVARIANT (Hierholzer undirected):
      #|stack is a valid trail using unused edges; path contains vertices whose
      #|incident edges are exhausted.
      #|MAINTENANCE:
      #|Consume one unused edge when available; otherwise backtrack to path.
      #|TERMINATION:
      #|When stack is empty, every reachable edge is consumed.
    ),
    invariant: cursor.length() == n && used.length() == edges.length(),
    reasoning: (
      #|INVARIANT (edge usage):
      #|used[e] is true iff edge e has been traversed once.
      #|MAINTENANCE:
      #|Mark used exactly once per traversal, never unmark.
      #|TERMINATION:
      #|Guarantees each edge is used at most once.
    ),
  }
  path.rev_in_place()
  if path.length() != edges.length() + 1 {
    None
  } else {
    Some(path)
  }
}

// ============================================================================
// TEST HELPERS
// ============================================================================

///|
fn consume_edge_directed(
  edges : ArrayView[(Int, Int)],
  used : Array[Bool],
  u : Int,
  v : Int,
) -> Bool {
  for i in 0..<edges.length() {
    if not(used[i]) {
      let (a, b) = edges[i]
      if a == u && b == v {
        used[i] = true
        return true
      }
    }
  }
  false
}

///|
fn consume_edge_undirected(
  edges : ArrayView[(Int, Int)],
  used : Array[Bool],
  u : Int,
  v : Int,
) -> Bool {
  for i in 0..<edges.length() {
    if not(used[i]) {
      let (a, b) = edges[i]
      if (a == u && b == v) || (a == v && b == u) {
        used[i] = true
        return true
      }
    }
  }
  false
}

///|
fn valid_path_directed(
  edges : ArrayView[(Int, Int)],
  path : Array[Int],
) -> Bool {
  if edges.length() == 0 {
    return path.length() == 0
  }
  if path.length() != edges.length() + 1 {
    return false
  }
  let used = Array::make(edges.length(), false)
  for i in 0..<(path.length() - 1) {
    if not(consume_edge_directed(edges, used, path[i], path[i + 1])) {
      return false
    }
  }
  true
}

///|
fn valid_path_undirected(
  edges : ArrayView[(Int, Int)],
  path : Array[Int],
) -> Bool {
  if edges.length() == 0 {
    return path.length() == 0
  }
  if path.length() != edges.length() + 1 {
    return false
  }
  let used = Array::make(edges.length(), false)
  for i in 0..<(path.length() - 1) {
    if not(consume_edge_undirected(edges, used, path[i], path[i + 1])) {
      return false
    }
  }
  true
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "eulerian directed path" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
  let path = eulerian_path_directed(3, edges[:]).unwrap()
  inspect(valid_path_directed(edges[:], path), content="true")
}

///|
test "eulerian directed chain" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2)]
  let path = eulerian_path_directed(3, edges[:]).unwrap()
  inspect(path, content="[0, 1, 2]")
}

///|
test "eulerian directed none" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2)]
  inspect(eulerian_path_directed(3, edges[:]), content="None")
}

///|
test "eulerian undirected circuit" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
  let path = eulerian_path_undirected(3, edges[:]).unwrap()
  inspect(valid_path_undirected(edges[:], path), content="true")
}

///|
test "eulerian undirected path" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2)]
  let path = eulerian_path_undirected(3, edges[:]).unwrap()
  inspect(path, content="[0, 1, 2]")
}

///|
test "eulerian undirected none" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
  inspect(eulerian_path_undirected(4, edges[:]), content="None")
}
