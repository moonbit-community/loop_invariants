///|
fn edges_of_path(path : Array[Int]) -> Array[(Int, Int)] {
  let edges : Array[(Int, Int)] = []
  for i in 0..<(path.length() - 1) {
    edges.push((path[i], path[i + 1]))
  } where {
    proof_invariant: i >= 0 && i + 1 <= path.length(),
    proof_reasoning: (
      #|INVARIANT (edges of path):
      #|edges contains path edges for indices in [0, i).
      #|MAINTENANCE:
      #|Add edge (path[i], path[i+1]) to edges.
      #|TERMINATION:
      #|At i + 1 == len, all path edges are collected.
    ),
  }
  edges
}

///|
fn edge_weight(edges : Array[(Int, Int, Int64)], u : Int, v : Int) -> Int64? {
  for i in 0..<edges.length() {
    let (a, b, c) = edges[i]
    if a == u && b == v {
      return Some(c)
    }
  } where {
    proof_invariant: i >= 0 && i <= edges.length(),
    proof_reasoning: (
      #|INVARIANT (edge lookup):
      #|edges[0..i) have been checked for the pair (u, v).
      #|MAINTENANCE:
      #|Compare edge i with (u, v) and record its weight if found.
      #|TERMINATION:
      #|At i = len, the edge has either been found or is absent.
    ),
  }
  None
}

///|
fn path_cost(path : Array[Int], edges : Array[(Int, Int, Int64)]) -> Int64? {
  let total = for i = 0, total = 0L; i + 1 < path.length(); {
    let u = path[i]
    let v = path[i + 1]
    match edge_weight(edges, u, v) {
      None => return None
      Some(w) => continue i + 1, total + w
    }
  } nobreak {
    total
  } where {
    proof_invariant: i >= 0 && i + 1 <= path.length() && total >= 0L,
    proof_reasoning: (
      #|INVARIANT (path cost):
      #|total equals the sum of edge weights along path[0..i].
      #|MAINTENANCE:
      #|Add the weight of the next edge in the path.
      #|TERMINATION:
      #|At i + 1 == len, total is the full path cost.
    ),
  }
  Some(total)
}

///|
test "suurballe disjoint paths basic" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 1L),
    (1, 4, 1L),
    (0, 2, 1L),
    (2, 4, 1L),
    (0, 3, 2L),
    (3, 4, 0L),
  ]
  let result = @suurballe_disjoint_paths.suurballe_disjoint_paths(
    5,
    edges[:],
    0,
    4,
  )
  match result {
    None => fail("expected two paths")
    Some((p1, p2)) => {
      let e1 = edges_of_path(p1)
      let e2 = edges_of_path(p2)
      for i in 0..<e1.length() {
        for j in 0..<e2.length() {
          assert_true(e1[i] != e2[j])
        } where {
          proof_invariant: j >= 0 && j <= e2.length(),
          proof_reasoning: (
            #|INVARIANT (pairwise check):
            #|e1[i] has been compared against e2[0..j).
            #|MAINTENANCE:
            #|Compare e1[i] with e2[j].
            #|TERMINATION:
            #|At j = len, e1[i] is disjoint from all edges in e2.
          ),
        }
      } where {
        proof_invariant: i >= 0 && i <= e1.length(),
        proof_reasoning: (
          #|INVARIANT (edge-disjoint check):
          #|Edges e1[0..i) have been checked against all edges in e2.
          #|MAINTENANCE:
          #|Compare e1[i] with every edge in e2.
          #|TERMINATION:
          #|At i = len, all edge pairs are verified disjoint.
        ),
      }
      let cost1 = path_cost(p1, edges)
      let cost2 = path_cost(p2, edges)
      guard cost1 is Some(c1) else { fail("missing edge for p1") }
      guard cost2 is Some(c2) else { fail("missing edge for p2") }
      inspect(c1 + c2, content="4")
    }
  }
}

///|
test "suurballe no disjoint paths" {
  let edges : Array[(Int, Int, Int64)] = [(0, 1, 1L), (1, 2, 1L), (2, 3, 1L)]
  let result = @suurballe_disjoint_paths.suurballe_disjoint_paths(
    4,
    edges[:],
    0,
    3,
  )
  inspect(result is None, content="true")
}
