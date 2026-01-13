///|
test "gomory-hu tree matches min cuts" {
  let n = 4
  let undirected : Array[(Int, Int, Int64)] = [
    (0, 1, 3L),
    (1, 2, 2L),
    (2, 3, 4L),
    (0, 3, 1L),
    (0, 2, 2L),
  ]
  let directed : Array[(Int, Int, Int64)] = []
  for idx = 0; idx < undirected.length(); idx = idx + 1 {
    let (u, v, cap) = undirected[idx]
    directed.push((u, v, cap))
    directed.push((v, u, cap))
  } where {
    invariant: idx >= 0 && idx <= undirected.length(),
    reasoning: (
      #|INVARIANT (edge expansion):
      #|Edges in undirected[0..idx) have been expanded in both directions.
      #|MAINTENANCE:
      #|Expand edge idx into two directed edges.
      #|TERMINATION:
      #|At idx = len, all edges are expanded.
    ),
  }
  let tree = @gomory_hu_tree.gomory_hu_tree(n, undirected[:])
  for u in 0..<n {
    for v in (u + 1)..<n {
      let result = @min_cut_st.min_cut_st(n, directed[:], u, v).unwrap()
      let tree_cut = tree.min_cut(u, v)
      assert_eq(tree_cut, result.value)
    }
  }
}
