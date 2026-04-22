// ============================================================================
// DINIC'S ALGORITHM - Tests
// ============================================================================

///|
/// Test basic flow network.
///
/// NETWORK:
/// ```
///   0 --3--> 1 --2--> 3
///    \              /
///     2           3
///      \        /
///       --> 2 --
///
///   Max flow = 4 (3 through path 0->1->3, saturated; 1+2 through 0->2->3)
///   Wait, actually 2 through 0->1->3 and 2 through 0->2->3 = 4
/// ```
test "dinic basic" {
  let dinic = Dinic::new(4)
  dinic.add_edge(0, 1, 3L)
  dinic.add_edge(0, 2, 2L)
  dinic.add_edge(1, 3, 2L)
  dinic.add_edge(2, 3, 3L)
  inspect(dinic.max_flow(0, 3), content="4")
}

///|
/// Test simple single edge.
test "dinic simple" {
  let dinic = Dinic::new(2)
  dinic.add_edge(0, 1, 5L)
  inspect(dinic.max_flow(0, 1), content="5")
  inspect(dinic.get_flow(0, 1), content="5")
}

///|
/// Test parallel edges (multiple edges between same vertices).
test "dinic parallel" {
  let dinic = Dinic::new(2)
  dinic.add_edge(0, 1, 3L)
  dinic.add_edge(0, 1, 2L)
  inspect(dinic.max_flow(0, 1), content="5")
}

///|
/// Test diamond network.
///
/// NETWORK:
/// ```
///   0 --10--> 1 --10--> 3
///    \                 /
///    10              10
///      \            /
///       --> 2 ------
///
///   Max flow = 20 (10 through each path)
/// ```
test "dinic diamond" {
  let dinic = Dinic::new(4)
  dinic.add_edge(0, 1, 10L)
  dinic.add_edge(0, 2, 10L)
  dinic.add_edge(1, 3, 10L)
  dinic.add_edge(2, 3, 10L)
  inspect(dinic.max_flow(0, 3), content="20")
}

///|
/// Test bottleneck edge.
///
/// NETWORK:
/// ```
///   0 --100--> 1 --1--> 2
///
///   Max flow = 1 (limited by bottleneck edge)
/// ```
test "dinic bottleneck" {
  let dinic = Dinic::new(3)
  dinic.add_edge(0, 1, 100L)
  dinic.add_edge(1, 2, 1L) // Bottleneck
  inspect(dinic.max_flow(0, 2), content="1")
}

///|
/// Test disconnected network (no path to sink).
test "dinic no path" {
  let dinic = Dinic::new(3)
  dinic.add_edge(0, 1, 5L)
  // No edge to vertex 2
  inspect(dinic.max_flow(0, 2), content="0")
}

///|
/// Test min cut computation.
test "dinic min cut" {
  let dinic = Dinic::new(4)
  dinic.add_edge(0, 1, 3L)
  dinic.add_edge(0, 2, 2L)
  dinic.add_edge(1, 3, 2L)
  dinic.add_edge(2, 3, 3L)
  let _ = dinic.max_flow(0, 3)
  let source_side = dinic.min_cut_source_side(0)
  // Source side should include source
  let has_source = source_side.contains(0)
  inspect(has_source, content="true")
}

///|
/// Test larger network (classic max flow example).
///
/// NETWORK:
/// ```
///   Classic Ford-Fulkerson example network.
///   Max flow = 23
/// ```
test "dinic larger" {
  let dinic = Dinic::new(6)
  dinic.add_edge(0, 1, 16L)
  dinic.add_edge(0, 2, 13L)
  dinic.add_edge(1, 2, 10L)
  dinic.add_edge(1, 3, 12L)
  dinic.add_edge(2, 1, 4L)
  dinic.add_edge(2, 4, 14L)
  dinic.add_edge(3, 2, 9L)
  dinic.add_edge(3, 5, 20L)
  dinic.add_edge(4, 3, 7L)
  dinic.add_edge(4, 5, 4L)
  inspect(dinic.max_flow(0, 5), content="23")
}

///|
/// Test reset functionality.
test "dinic reset" {
  let dinic = Dinic::new(2)
  dinic.add_edge(0, 1, 5L)
  inspect(dinic.max_flow(0, 1), content="5")
  dinic.reset()
  inspect(dinic.max_flow(0, 1), content="5")
}
