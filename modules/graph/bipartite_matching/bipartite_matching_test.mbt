// ============================================================================
// BIPARTITE MATCHING - Blackbox Tests
// ============================================================================

///|
test "hungarian basic perfect matching" {
  // Perfect matching possible: 3x3 bipartite graph
  let graph = BipartiteGraph::BipartiteGraph(3, 3)
  graph.add_edge(0, 0)
  graph.add_edge(0, 1)
  graph.add_edge(1, 0)
  graph.add_edge(1, 2)
  graph.add_edge(2, 1)
  graph.add_edge(2, 2)
  let matcher = graph.hungarian()
  inspect(matcher.max_matching(), content="3")
  inspect(matcher.get_matching().length(), content="3")
}

///|
test "hungarian imperfect" {
  // 3 left vertices, 2 right vertices - can only match 2
  let graph = BipartiteGraph::BipartiteGraph(3, 2)
  graph.add_edge(0, 0)
  graph.add_edge(1, 0)
  graph.add_edge(2, 1)
  let matcher = graph.hungarian()
  inspect(matcher.max_matching(), content="2")
}

///|
test "hopcroft_karp basic" {
  let graph = BipartiteGraph::BipartiteGraph(3, 3)
  graph.add_edge(0, 0)
  graph.add_edge(0, 1)
  graph.add_edge(1, 0)
  graph.add_edge(1, 2)
  graph.add_edge(2, 1)
  graph.add_edge(2, 2)
  let matcher = graph.hopcroft_karp()
  inspect(matcher.max_matching(), content="3")
  inspect(matcher.get_matching().length(), content="3")
}

///|
test "hopcroft_karp larger" {
  let graph = BipartiteGraph::BipartiteGraph(4, 4)
  graph
  ..add_edge(0, 0)
  ..add_edge(0, 1)
  ..add_edge(1, 1)
  ..add_edge(1, 2)
  ..add_edge(2, 2)
  ..add_edge(2, 3)
  ..add_edge(3, 0)
  .add_edge(3, 3)
  let matcher = graph.hopcroft_karp()
  inspect(matcher.max_matching(), content="4")
  inspect(matcher.get_matching().length(), content="4")
}

///|
test "empty graph" {
  let graph = BipartiteGraph::BipartiteGraph(2, 2)
  inspect(graph.hungarian().max_matching(), content="0")
  let graph2 = BipartiteGraph::BipartiteGraph(2, 2)
  inspect(graph2.hopcroft_karp().max_matching(), content="0")
}

///|
test "single edge" {
  let graph = BipartiteGraph::BipartiteGraph(1, 1)
  graph.add_edge(0, 0)
  inspect(graph.hungarian().max_matching(), content="1")
}

///|
test "algorithms agree" {
  let graph1 = BipartiteGraph::BipartiteGraph(4, 4)
  let graph2 = BipartiteGraph::BipartiteGraph(4, 4)
  let edges = [(0, 0), (0, 1), (1, 0), (1, 2), (2, 1), (2, 2), (3, 3)]
  for edge in edges {
    graph1.add_edge(edge.0, edge.1)
    graph2.add_edge(edge.0, edge.1)
  }
  let hungarian_result = graph1.hungarian().max_matching()
  let hk_result = graph2.hopcroft_karp().max_matching()
  inspect(hungarian_result == hk_result, content="true")
  inspect(hungarian_result, content="4")
}

///|
test "min_vertex_cover" {
  let graph = BipartiteGraph::BipartiteGraph(3, 3)
  graph.add_edge(0, 0)
  graph.add_edge(0, 1)
  graph.add_edge(1, 1)
  graph.add_edge(2, 2)
  let matcher = graph.hopcroft_karp()
  let matching_size = matcher.max_matching()
  let (left, right) = matcher.min_vertex_cover()
  // Vertex cover size should equal max matching size (König's theorem)
  let cover_size = left.length() + right.length()
  inspect(cover_size == matching_size, content="true")
}

///|
test "min_vertex_cover covers all edges" {
  let graph = BipartiteGraph::BipartiteGraph(3, 3)
  let edges : Array[(Int, Int)] = [(0, 0), (0, 1), (1, 1), (2, 2)]
  for edge in edges {
    graph.add_edge(edge.0, edge.1)
  }
  let matcher = graph.hopcroft_karp()
  let _ = matcher.max_matching()
  let (left_cover, right_cover) = matcher.min_vertex_cover()
  // Verify every edge is covered (has at least one endpoint in cover)
  let left_set : Array[Bool] = Array::make(3, false)
  let right_set : Array[Bool] = Array::make(3, false)
  for u in left_cover {
    left_set[u] = true
  }
  for v in right_cover {
    right_set[v] = true
  }
  let all_covered = edges
    .iter()
    .all(fn(edge) {
      let (u, v) = edge
      left_set[u] || right_set[v]
    })
  inspect(all_covered, content="true")
}
