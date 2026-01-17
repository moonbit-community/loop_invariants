// ============================================================================
// PRUFER CODE - Tree <-> Sequence Bijection
// ============================================================================
//
// A Prufer code uniquely represents a labeled tree with n vertices using a
// sequence of length n-2. Encoding removes the smallest leaf repeatedly; decoding
// reconstructs the tree by reversing this process.
//
// PROPERTIES:
// - Each vertex appears in the code exactly (deg[v] - 1) times.
// - Leaves (degree 1) never appear in the remaining suffix of the code.
//
// INVARIANTS (encoding):
// 1. The heap contains exactly the current leaves of the remaining tree.
// 2. The degrees array matches the remaining graph.
// 3. After k steps, the prefix of the code has length k and k leaves are removed.
//
// INVARIANTS (decoding):
// 1. degree[v] starts at 1 + count(v in code) and decreases as edges are added.
// 2. The heap always contains vertices with degree 1 not yet used as leaves.
// 3. After k steps, k edges are added and the remaining degrees are valid.
//
// TIME COMPLEXITY: O(n log n)
// SPACE COMPLEXITY: O(n)

///|
priv struct MinHeap {
  data : Array[Int]
}

///|
fn MinHeap::new() -> MinHeap {
  { data: [] }
}

///|
fn MinHeap::push(self : MinHeap, x : Int) -> Unit {
  self.data.push(x)
  let mut i = self.data.length() - 1
  while i > 0 {
    let p = (i - 1) / 2
    if self.data[i] < self.data[p] {
      let tmp = self.data[i]
      self.data[i] = self.data[p]
      self.data[p] = tmp
      i = p
    } else {
      break
    }
  }
}

///|
fn MinHeap::pop(self : MinHeap) -> Int? {
  let n = self.data.length()
  if n == 0 {
    return None
  }
  let result = self.data[0]
  let last = match self.data.pop() {
    Some(v) => v
    None => return Some(result)
  }
  if self.data.length() > 0 {
    self.data[0] = last
    let mut i = 0
    let len = self.data.length()
    for {
      let left = 2 * i + 1
      let right = 2 * i + 2
      let mut smallest = i
      if left < len && self.data[left] < self.data[smallest] {
        smallest = left
      }
      if right < len && self.data[right] < self.data[smallest] {
        smallest = right
      }
      if smallest == i {
        break
      }
      let tmp = self.data[i]
      self.data[i] = self.data[smallest]
      self.data[smallest] = tmp
      i = smallest
    } where {
      invariant: i >= 0 && i < len,
      reasoning: (
        #|INVARIANT (heapify down):
        #|All nodes outside the path from root to i satisfy heap order.
        #|MAINTENANCE:
        #|Swap with the smallest child when needed to restore min-heap property.
        #|TERMINATION:
        #|When smallest == i, the heap property holds for the entire array.
      ),
    }
  }
  Some(result)
}

///|
fn build_adj(n : Int) -> Array[Array[Int]] {
  Array::makei(n, _ => [])
}

///|
fn normalize_edge(u : Int, v : Int) -> (Int, Int) {
  if u < v {
    (u, v)
  } else {
    (v, u)
  }
}

///|
fn build_tree(
  n : Int,
  edges : ArrayView[(Int, Int)],
) -> (Array[Array[Int]], Array[Int])? {
  if n <= 0 {
    return None
  }
  if edges.length() != n - 1 {
    return None
  }
  let adj = build_adj(n)
  let deg = Array::make(n, 0)
  let seen : Map[Int64, Bool] = {}
  let n64 = n.to_int64()
  for edge in edges {
    let (u, v) = edge
    if u < 0 || v < 0 || u >= n || v >= n || u == v {
      return None
    }
    let (a, b) = normalize_edge(u, v)
    let key = a.to_int64() * n64 + b.to_int64()
    if seen.contains(key) {
      return None
    }
    seen[key] = true
    adj[u].push(v)
    adj[v].push(u)
    deg[u] = deg[u] + 1
    deg[v] = deg[v] + 1
  }

  // Check connectivity with BFS
  let seen_nodes = Array::make(n, false)
  let queue : Array[Int] = [0]
  seen_nodes[0] = true
  for idx = 0; idx < queue.length(); idx = idx + 1 {
    let u = queue[idx]
    for v in adj[u] {
      if not(seen_nodes[v]) {
        seen_nodes[v] = true
        queue.push(v)
      }
    }
  } where {
    invariant: idx >= 0 && idx <= queue.length(),
    reasoning: (
      #|INVARIANT (BFS):
      #|Vertices in queue[0..idx) are processed; seen_nodes marks all reached
      #|vertices so far.
      #|MAINTENANCE:
      #|Expand queue[idx] and enqueue unseen neighbors.
      #|TERMINATION:
      #|At idx = queue.length(), all reachable vertices are marked.
    ),
  }
  for v in 0..<n {
    if not(seen_nodes[v]) {
      return None
    }
  }
  Some((adj, deg))
}

///|
/// Encode a tree into a Prufer sequence. Returns None if input is not a tree.
pub fn prufer_encode(n : Int, edges : ArrayView[(Int, Int)]) -> Array[Int]? {
  if n <= 0 {
    return None
  }
  if n <= 2 {
    if edges.length() == n - 1 {
      return Some([])
    } else {
      return None
    }
  }
  let (adj, deg) = match build_tree(n, edges) {
    None => return None
    Some(pair) => pair
  }
  let heap = MinHeap::new()
  for v = 0; v < n; v = v + 1 {
    if deg[v] == 1 {
      heap.push(v)
    }
  } where {
    invariant: v >= 0 && v <= n,
    reasoning: (
      #|INVARIANT (leaf init):
      #|heap contains exactly the leaves among vertices in [0..v).
      #|MAINTENANCE:
      #|Insert v if its degree is 1.
      #|TERMINATION:
      #|At v = n, heap holds all initial leaves.
    ),
  }
  let next_idx = Array::make(n, 0)
  let code : Array[Int] = []
  for step = 0; step < n - 2; step = step + 1 {
    let leaf = match heap.pop() {
      Some(v) => v
      None => return None
    }
    let mut idx = next_idx[leaf]
    while idx < adj[leaf].length() && deg[adj[leaf][idx]] == 0 {
      idx = idx + 1
    }
    if idx >= adj[leaf].length() {
      return None
    }
    next_idx[leaf] = idx
    let v = adj[leaf][idx]
    code.push(v)
    deg[leaf] = 0
    deg[v] = deg[v] - 1
    if deg[v] == 1 {
      heap.push(v)
    }
  } where {
    invariant: step >= 0 && step <= n - 2,
    reasoning: (
      #|INVARIANT (encode steps):
      #|After step iterations, code has length step and exactly step leaves
      #|have been removed from the tree.
      #|MAINTENANCE:
      #|Pop the smallest leaf, record its neighbor, and update degrees.
      #|TERMINATION:
      #|At step = n-2, the Prufer code is complete.
    ),
    invariant: code.length() == step,
    reasoning: (
      #|INVARIANT (code length):
      #|code length equals the number of processed leaves.
      #|MAINTENANCE:
      #|Each iteration appends exactly one vertex to code.
      #|TERMINATION:
      #|At step = n-2, code length is n-2.
    ),
  }
  Some(code)
}

///|
/// Decode a Prufer sequence into a tree (edge list).
/// Returns None if the sequence contains invalid vertex IDs.
pub fn prufer_decode(code : ArrayView[Int]) -> Array[(Int, Int)]? {
  let n = code.length() + 2
  if n < 2 {
    return None
  }
  let deg = Array::make(n, 1)
  for v in code {
    if v < 0 || v >= n {
      return None
    }
    deg[v] = deg[v] + 1
  }
  let heap = MinHeap::new()
  for v = 0; v < n; v = v + 1 {
    if deg[v] == 1 {
      heap.push(v)
    }
  } where {
    invariant: v >= 0 && v <= n,
    reasoning: (
      #|INVARIANT (leaf init):
      #|heap contains all current leaves among vertices in [0..v).
      #|MAINTENANCE:
      #|Insert v if deg[v] == 1.
      #|TERMINATION:
      #|At v = n, heap holds all initial leaves.
    ),
  }
  let edges : Array[(Int, Int)] = []
  for v in code {
    let leaf = match heap.pop() {
      Some(x) => x
      None => return None
    }
    edges.push((leaf, v))
    deg[leaf] = 0
    deg[v] = deg[v] - 1
    if deg[v] == 1 {
      heap.push(v)
    }
  }
  let u = match heap.pop() {
    Some(x) => x
    None => return None
  }
  let v = match heap.pop() {
    Some(x) => x
    None => return None
  }
  edges.push((u, v))
  Some(edges)
}

// ============================================================================
// TEST HELPERS
// ============================================================================

///|
fn normalize_edges(edges : Array[(Int, Int)]) -> Array[(Int, Int)] {
  let result : Array[(Int, Int)] = []
  for e in edges {
    let (u, v) = e
    if u < v {
      result.push((u, v))
    } else {
      result.push((v, u))
    }
  }
  result.sort_by((a, b) => if a.0 != b.0 { a.0 - b.0 } else { a.1 - b.1 })
  result
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "prufer encode path" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
  let code = prufer_encode(4, edges[:]).unwrap()
  inspect(code, content="[1, 2]")
}

///|
test "prufer encode star" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
  let code = prufer_encode(5, edges[:]).unwrap()
  inspect(code, content="[0, 0, 0]")
}

///|
test "prufer decode star" {
  let code : Array[Int] = [0, 0, 0]
  let edges = prufer_decode(code[:]).unwrap()
  let norm = normalize_edges(edges)
  inspect(norm, content="[(0, 1), (0, 2), (0, 3), (0, 4)]")
}

///|
test "prufer roundtrip" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (1, 3), (3, 4)]
  let code = prufer_encode(5, edges[:]).unwrap()
  let edges2 = prufer_decode(code[:]).unwrap()
  let code2 = prufer_encode(5, edges2[:]).unwrap()
  inspect(code2, content="[1, 1, 3]")
}

///|
test "prufer invalid" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2)]
  inspect(prufer_encode(4, edges[:]), content="None")
  let code : Array[Int] = [0, 4]
  inspect(prufer_decode(code[:]), content="None")
}
