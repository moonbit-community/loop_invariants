///|
test "dial shortest paths small" {
  let g = @dial_shortest_path.Graph::new(5, 3)
  g.add_edge(0, 1, 1)
  g.add_edge(0, 2, 2)
  g.add_edge(1, 2, 1)
  g.add_edge(1, 3, 3)
  g.add_edge(2, 3, 1)
  g.add_edge(3, 4, 0)
  let dist = @dial_shortest_path.dial_shortest_paths(g, 0)
  inspect(dist, content="[0, 1, 2, 3, 3]")
}

///|
test "dial shortest paths undirected" {
  let g = @dial_shortest_path.Graph::new(4, 2)
  g.add_undirected_edge(0, 1, 0)
  g.add_undirected_edge(1, 2, 2)
  g.add_undirected_edge(0, 2, 2)
  g.add_undirected_edge(2, 3, 1)
  let dist = @dial_shortest_path.dial_shortest_paths(g, 0)
  inspect(dist, content="[0, 0, 2, 3]")
}
