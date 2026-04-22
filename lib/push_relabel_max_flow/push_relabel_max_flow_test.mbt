///|
test "push-relabel max flow classic" {
  let pr = @push_relabel_max_flow.PushRelabel::new(6)
  pr.add_edge(0, 1, 16L)
  pr.add_edge(0, 2, 13L)
  pr.add_edge(1, 2, 10L)
  pr.add_edge(2, 1, 4L)
  pr.add_edge(1, 3, 12L)
  pr.add_edge(2, 4, 14L)
  pr.add_edge(3, 2, 9L)
  pr.add_edge(4, 3, 7L)
  pr.add_edge(3, 5, 20L)
  pr.add_edge(4, 5, 4L)
  let flow = pr.max_flow(0, 5)
  inspect(flow, content="23")
}

///|
test "push-relabel small network" {
  let pr = @push_relabel_max_flow.PushRelabel::new(4)
  pr.add_edge(0, 1, 5L)
  pr.add_edge(0, 2, 3L)
  pr.add_edge(1, 2, 1L)
  pr.add_edge(1, 3, 4L)
  pr.add_edge(2, 3, 2L)
  let flow = pr.max_flow(0, 3)
  inspect(flow, content="6")
}
