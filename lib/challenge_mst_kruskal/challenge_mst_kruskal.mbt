// ============================================================================
// Challenge: Minimum Spanning Tree (Kruskal)
// ============================================================================

///|
struct DSU {
  parent : Array[Int]
  size : Array[Int]
} derive(Show)

///|
fn dsu_make(n : Int) -> DSU {
  let parent = Array::makei(n, i => i)
  let size = Array::make(n, 1)
  { parent, size }
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn dsu_find(dsu : DSU, x : Int) -> Int {
  for cur = x {
    let p = dsu.parent[cur]
    if p == cur {
      break cur
    } else {
      continue p
    }
  } where {
    invariant: cur >= 0 && cur < dsu.parent.length(),
    reasoning: (
      #|INVARIANT (DSU root walk):
      #|cur stays on the parent chain of x.
      #|MAINTENANCE:
      #|Move to parent until a root is found.
      #|TERMINATION:
      #|When parent[cur] = cur, cur is the set representative.
    ),
  }
}

///|
fn dsu_union(dsu : DSU, a : Int, b : Int) -> Bool {
  let ra = dsu_find(dsu, a)
  let rb = dsu_find(dsu, b)
  if ra == rb {
    false
  } else {
    let sa = dsu.size[ra]
    let sb = dsu.size[rb]
    if sa < sb {
      dsu.parent[ra] = rb
      dsu.size[rb] = sa + sb
    } else {
      dsu.parent[rb] = ra
      dsu.size[ra] = sa + sb
    }
    true
  }
}

///|
/// Return the MST total weight if the graph is connected; otherwise None.
#warnings("+missing_invariant+missing_reasoning")
pub fn mst_weight(n : Int, edges : ArrayView[(Int, Int, Int)]) -> Int? {
  if n <= 1 {
    return Some(0)
  }
  let sorted = edges.to_array()
  sorted.sort_by_key(fn(e) { e.2 })
  let dsu = dsu_make(n)
  let mut total = 0
  let mut used = 0
  let m = sorted.length()
  for i = 0; i < m; i = i + 1 {
    let (u, v, w) = sorted[i]
    if u >= 0 && u < n && v >= 0 && v < n {
      if dsu_union(dsu, u, v) {
        total = total + w
        used = used + 1
      }
    }
  } where {
    invariant: i >= 0 && i <= m,
    invariant: used >= 0 && used <= n - 1,
    reasoning: (
      #|INVARIANT (Kruskal scan):
      #|The selected edges form an acyclic forest of size used.
      #|total equals the sum of selected edge weights.
      #|MAINTENANCE:
      #|Add an edge only when it connects two different components.
      #|TERMINATION:
      #|After all edges, used == n-1 iff the graph is connected.
    ),
  }
  if used == n - 1 {
    Some(total)
  } else {
    None
  }
}

///|
test "mst_kruskal_basic" {
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 1),
    (1, 2, 2),
    (2, 3, 3),
    (0, 3, 10),
  ]
  assert_eq(mst_weight(4, edges[:]), Some(6))
}

///|
test "mst_kruskal_disconnected" {
  let edges : Array[(Int, Int, Int)] = [(0, 1, 1)]
  assert_eq(mst_weight(3, edges[:]), None)
}
