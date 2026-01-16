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
  sorted.sort_by_key(e => e.2)
  let dsu = dsu_make(n)
  let mut total = 0
  let mut used = 0
  for edge in sorted {
    let (u, v, w) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      if dsu_union(dsu, u, v) {
        total = total + w
        used = used + 1
      }
    }
  }
  if used == n - 1 {
    Some(total)
  } else {
    None
  }
}
