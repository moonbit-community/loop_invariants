// ============================================================================
// Challenge: Minimum Spanning Tree (Kruskal)
// ============================================================================

///|
struct DSU {
  parent : Array[Int]
  size : Array[Int]
} derive(Debug)

///|
fn dsu_make(n : Int) -> DSU {
  let parent = Array::makei(n, i => i)
  let size = Array::make(n, 1)
  { parent, size }
}

///|
fn dsu_find(dsu : DSU, x : Int) -> Int {
  for cur = x {
    let p = dsu.parent[cur]
    if p == cur {
      break cur
    } else {
      continue p
    }
  } where {
    proof_invariant: cur >= 0 && cur < dsu.parent.length(),
    proof_reasoning: (
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
pub fn mst_weight(n : Int, edges : ArrayView[(Int, Int, Int)]) -> Int? {
  if n <= 1 {
    return Some(0)
  }
  let sorted = edges.to_array()
  sorted.sort_by_key(e => e.2)
  let dsu = dsu_make(n)
  let (total, used) = for edge in sorted; total = 0, used = 0 {
    let (u, v, w) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      if dsu_union(dsu, u, v) {
        continue total + w, used + 1
      }
    }
    continue total, used
  } nobreak {
    (total, used)
  }
  if used == n - 1 {
    Some(total)
  } else {
    None
  }
}

///|
test "mst_weight" {
  let edges = [(0, 1, 1), (1, 2, 2), (0, 2, 4), (2, 3, 3), (1, 3, 5)]
  assert_eq(mst_weight(4, edges[:]), Some(6))
  assert_eq(mst_weight(4, [(0, 1, 1), (2, 3, 2)][:]), None)
}
