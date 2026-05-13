// ============================================================================
// STOER-WAGNER MIN CUT - Tests
// ============================================================================

///|
/// Compute the actual weight of edges crossing a cut, for verification.
///
/// Given the vertex set on one side of the cut (`cut`), sums the weights of
/// all edges `(u, v, w)` where exactly one endpoint is in `cut`.
///
/// Parameters:
/// - `n`: total number of vertices (used for bounds checking).
/// - `edges`: all edges as `(u, v, weight)` triples.
/// - `cut`: the vertices on one side of the cut.
///
/// Returns the total crossing edge weight. Used in tests to confirm that
/// the weight reported by `@stoer_wagner_min_cut.stoer_wagner_min_cut` matches the actual cut.
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
/// Four-cycle with unit weights; any single-vertex cut has weight 2.
///
/// ```
///   0 ---1--- 1
///   |         |
///   1         1
///   |         |
///   3 ---1--- 2
/// ```
///
/// Minimum cut = 2: remove any vertex from the rest (two incident edges).
test "stoer wagner cycle" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 1L),
    (1, 2, 1L),
    (2, 3, 1L),
    (3, 0, 1L),
  ]
  let result = @stoer_wagner_min_cut.stoer_wagner_min_cut(4, edges).unwrap()
  debug_inspect(result.weight, content="2")
  // Verify the cut is actually valid
  debug_inspect(cut_weight(4, edges, result.cut), content="2")
}

///|
/// Disconnected graph: minimum cut weight is 0 because one component can be
/// isolated by removing no edges at all.
test "stoer wagner disconnected" {
  let edges : Array[(Int, Int, Int64)] = []
  let result = @stoer_wagner_min_cut.stoer_wagner_min_cut(3, edges).unwrap()
  debug_inspect(result.weight, content="0")
}

///|
/// Single vertex: no cut exists, so the function returns `None`.
test "stoer wagner n1" {
  let edges : Array[(Int, Int, Int64)] = []
  guard @stoer_wagner_min_cut.stoer_wagner_min_cut(1, edges) is None else {
    fail("expected None")
  }
}

///|
/// Complete graph K4 with unit weights; every vertex has degree 3.
///
/// ```
///   All 6 pairs connected, each edge weight 1.
///   Isolating any single vertex cuts 3 edges → min cut = 3.
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
  let result = @stoer_wagner_min_cut.stoer_wagner_min_cut(4, edges).unwrap()
  debug_inspect(result.weight, content="3")
  debug_inspect(cut_weight(4, edges, result.cut), content="3")
}

///|
/// Square with mixed weights; the cheapest cut splits the graph into two pairs.
///
/// ```
///   0 ---10--- 1
///   |          |
///   1          1
///   |          |
///   2 ---10--- 3
///
///   Cut {0,2} vs {1,3}: crossing edges 0-1 (w=10) and 2-3 (w=10)? No.
///   Actually cut {0,2} vs {1,3}: edges 0-1 (10) + 2-3 (10) = 20, not great.
///   Cut {0} vs {1,2,3}: edges 0-1 (10) + 0-2 (1) = 11.
///   Best cut: {1,3} vs {0,2}: edges 0-1 (10) + 0-2 (1) ... hmm.
///
///   Edges: (0,1,10), (0,2,1), (1,3,1), (2,3,10)
///   Cut {1,3} vs {0,2}: cross edges 0-1 (10) + 2-3 (10) = 20? No.
///   Cross edges for {1,3} vs {0,2}: 0-1 (10)? 0 in {0,2}, 1 in {1,3} → yes.
///                                    1-3 (1)? both in {1,3} → no.
///                                    0-2 (1)? both in {0,2} → no.
///                                    2-3 (10)? 2 in {0,2}, 3 in {1,3} → yes.
///   Total = 10 + 10 = 20.
///   Cut {0,1} vs {2,3}: 0-2 (1) + 1-3 (1) = 2. This is the min cut!
/// ```
///
/// Minimum cut = 2 (the two lightweight edges form the bottleneck).
test "stoer wagner weighted" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 10L),
    (0, 2, 1L),
    (1, 3, 1L),
    (2, 3, 10L),
  ]
  let result = @stoer_wagner_min_cut.stoer_wagner_min_cut(4, edges).unwrap()
  debug_inspect(result.weight, content="2")
}

///|
/// Two vertices with a single edge of weight 5.
///
/// The only possible cut is {0} vs {1}; cut weight = 5.
test "stoer wagner two vertices" {
  let edges : Array[(Int, Int, Int64)] = [(0, 1, 5L)]
  let result = @stoer_wagner_min_cut.stoer_wagner_min_cut(2, edges).unwrap()
  debug_inspect(result.weight, content="5")
  debug_inspect(result.cut.length(), content="1")
}

///|
/// Parallel edges between 0 and 1 are summed to give effective weight 5.
///
/// ```
///   0 ==2+3== 1 ---1--- 2
///   (parallel)
///
///   Effective graph:  0 --5-- 1 --1-- 2
///   Cut {2} vs {0,1}: weight = 1  (cheaper)
///   Cut {0} vs {1,2}: weight = 5
///   Min cut = 1.
/// ```
test "stoer wagner parallel edges" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 2L),
    (0, 1, 3L), // Same edge, different weight
    (1, 2, 1L),
  ]
  let result = @stoer_wagner_min_cut.stoer_wagner_min_cut(3, edges).unwrap()

  // Cut {2} has weight 1, better than cut {0} with weight 5
  debug_inspect(result.weight, content="1")
}
