// ============================================================================
// STOER-WAGNER MIN CUT - Tests
// ============================================================================

///|
/// Helper function to verify cut weight.
///
/// Computes actual weight of edges crossing the cut.
fn cut_weight(
  n : Int,
  edges : ArrayView[(Int, Int, Int64)],
  cut : Array[Int],
) -> Int64 {
  let in_cut = Array::make(n, false)
  for v in cut {
    if v >= 0 && v < n {
      in_cut[v] = true
    }
  }
  let total = for edge in edges; total = 0L {
    let (u, v, w) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      if in_cut[u] != in_cut[v] {
        continue total + w
      }
    }
    continue total
  } nobreak {
    total
  }
  total
}

///|
/// Test min cut on a cycle graph.
///
/// GRAPH:
/// ```
///   0 ---1--- 1
///   |         |
///   1         1
///   |         |
///   3 ---1--- 2
///
///   Edges: (0,1,1), (1,2,1), (2,3,1), (3,0,1)
/// ```
///
/// MIN CUT:
/// ```
///   Any single vertex vs the rest has cut weight 2.
///   Example: cut = {0}, crossing edges: 0-1 and 0-3
/// ```
test "stoer wagner cycle" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 1L),
    (1, 2, 1L),
    (2, 3, 1L),
    (3, 0, 1L),
  ]
  let result = stoer_wagner_min_cut(4, edges[:]).unwrap()
  inspect(result.weight, content="2")
  // Verify the cut is actually valid
  inspect(cut_weight(4, edges[:], result.cut), content="2")
}

///|
/// Test on disconnected graph (cut weight = 0).
///
/// When the graph is disconnected, the min cut has weight 0.
test "stoer wagner disconnected" {
  let edges : Array[(Int, Int, Int64)] = []
  let result = stoer_wagner_min_cut(3, edges[:]).unwrap()
  inspect(result.weight, content="0")
}

///|
/// Test with single vertex (no valid cut exists).
test "stoer wagner n1" {
  let edges : Array[(Int, Int, Int64)] = []
  guard stoer_wagner_min_cut(1, edges[:]) is None else { fail("expected None") }
}

///|
/// Test on a complete graph K4.
///
/// GRAPH:
/// ```
///   All pairs connected with weight 1.
///   6 edges total.
/// ```
///
/// MIN CUT:
/// ```
///   Separating one vertex: cut weight = 3 (3 edges to other vertices)
/// ```
test "stoer wagner complete k4" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 1L),
    (0, 2, 1L),
    (0, 3, 1L),
    (1, 2, 1L),
    (1, 3, 1L),
    (2, 3, 1L),
  ]
  let result = stoer_wagner_min_cut(4, edges[:]).unwrap()
  inspect(result.weight, content="3")
  inspect(cut_weight(4, edges[:], result.cut), content="3")
}

///|
/// Test with weighted edges.
///
/// GRAPH:
/// ```
///   0 ---10--- 1
///   |          |
///   1          1
///   |          |
///   2 ---10--- 3
/// ```
///
/// MIN CUT:
/// ```
///   Cut {0,2} vs {1,3}: weight = 1 + 1 = 2
///   Better than cutting {0} vs rest: 10 + 1 = 11
/// ```
test "stoer wagner weighted" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 10L),
    (0, 2, 1L),
    (1, 3, 1L),
    (2, 3, 10L),
  ]
  let result = stoer_wagner_min_cut(4, edges[:]).unwrap()
  inspect(result.weight, content="2")
}

///|
/// Test with two vertices.
test "stoer wagner two vertices" {
  let edges : Array[(Int, Int, Int64)] = [(0, 1, 5L)]
  let result = stoer_wagner_min_cut(2, edges[:]).unwrap()
  inspect(result.weight, content="5")
  inspect(result.cut.length(), content="1")
}

///|
/// Test with parallel edges.
///
/// Parallel edges should be summed.
test "stoer wagner parallel edges" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 2L),
    (0, 1, 3L), // Same edge, different weight
    (1, 2, 1L),
  ]
  let result = stoer_wagner_min_cut(3, edges[:]).unwrap()

  // Cut {2} has weight 1, better than cut {0} with weight 5
  inspect(result.weight, content="1")
}
