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
  let _ = for i = self.data.length() - 1 {
    if i <= 0 {
      break ()
    }
    let p = (i - 1) / 2
    if self.data[i] < self.data[p] {
      let tmp = self.data[i]
      self.data[i] = self.data[p]
      self.data[p] = tmp
      continue p
    } else {
      break ()
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
    let len = self.data.length()
    let _ = for i = 0 {
      let left = 2 * i + 1
      let right = 2 * i + 2
      let smallest = if left < len && self.data[left] < self.data[i] {
        left
      } else {
        i
      }
      let smallest = if right < len && self.data[right] < self.data[smallest] {
        right
      } else {
        smallest
      }
      if smallest == i {
        break ()
      }
      let tmp = self.data[i]
      self.data[i] = self.data[smallest]
      self.data[smallest] = tmp
      continue smallest
    } where {
      proof_invariant: i >= 0 && i < len,
      proof_reasoning: (
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
  [
    for _ in 0..<n => []
  ]
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
      if !seen_nodes[v] {
        seen_nodes[v] = true
        queue.push(v)
      }
    }
  } where {
    proof_invariant: idx >= 0 && idx <= queue.length(),
    proof_reasoning: (
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
    if !seen_nodes[v] {
      return None
    }
  }
  Some((adj, deg))
}

///|
/// Encode a labeled tree on `n` vertices (labeled `0..n-1`) into its Prufer
/// sequence.
///
/// The Prufer sequence has length `n - 2` and uniquely identifies the tree.
/// Trees with `n <= 2` have an empty sequence.
///
/// **Algorithm** (O(n log n) with a min-heap):
/// 1. Build an adjacency list and degree array from `edges`.
/// 2. Initialize a min-heap with all leaves (degree-1 vertices).
/// 3. Repeat `n - 2` times:
///    a. Pop the smallest leaf `u` from the heap.
///    b. Append `u`'s unique remaining neighbor to the code.
///    c. Decrement that neighbor's degree; if it becomes 1, push it as a leaf.
///
/// Returns `None` when:
/// - `n <= 0`
/// - `edges.length() != n - 1` (wrong number of edges for a tree)
/// - An edge vertex is out of range `[0, n)`
/// - Duplicate edges or self-loops are present
/// - The graph is not connected (i.e., not actually a tree)
///
/// # Example
///
/// ```
/// // Path 0-1-2-3 encodes to [1, 2]
/// let code = prufer_encode(4, [(0,1),(1,2),(2,3)][:]).unwrap()
/// // code == [1, 2]
/// ```
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
  for v in 0..<n {
    if deg[v] == 1 {
      heap.push(v)
    }
  } where {
    proof_invariant: v >= 0 && v <= n,
    proof_reasoning: (
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
  for step in 0..<(n - 2) {
    let leaf = match heap.pop() {
      Some(v) => v
      None => return None
    }
    let idx = for idx = next_idx[leaf] {
      if idx < adj[leaf].length() && deg[adj[leaf][idx]] == 0 {
        continue idx + 1
      } else {
        break idx
      }
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
    proof_invariant: step >= 0 && step <= n - 2,
    proof_reasoning: (
      #|INVARIANT (encode steps):
      #|After step iterations, code has length step and exactly step leaves
      #|have been removed from the tree.
      #|MAINTENANCE:
      #|Pop the smallest leaf, record its neighbor, and update degrees.
      #|TERMINATION:
      #|At step = n-2, the Prufer code is complete.
    ),
    proof_invariant: code.length() == step,
    proof_reasoning: (
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
/// Decode a Prufer sequence into a labeled tree, returned as an edge list.
///
/// Given a code of length `m`, the reconstructed tree has `n = m + 2` vertices
/// labeled `0..n-1` and exactly `n - 1` edges.
///
/// **Algorithm** (O(n log n) with a min-heap):
/// 1. Compute `degree[v] = 1 + count(v in code)` for each vertex `v`.
/// 2. Initialize a min-heap with all vertices whose degree is 1 (leaves).
/// 3. For each value `v` in the code:
///    a. Pop the smallest leaf `u` from the heap.
///    b. Add edge `(u, v)`.
///    c. Decrement `degree[v]`; if it becomes 1, push `v` onto the heap.
/// 4. Connect the two remaining vertices with the final edge.
///
/// Returns `None` when:
/// - Any code value is outside `[0, n)` where `n = code.length() + 2`
/// - The heap underflows (indicates a malformed sequence)
///
/// # Example
///
/// ```
/// // [1, 2] decodes to the path 0-1-2-3
/// let edges = prufer_decode([1, 2][:]).unwrap()
/// // edges contain (0,1), (1,2), (2,3) in some order
/// ```
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
  for v in 0..<n {
    if deg[v] == 1 {
      heap.push(v)
    }
  } where {
    proof_invariant: v >= 0 && v <= n,
    proof_reasoning: (
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
