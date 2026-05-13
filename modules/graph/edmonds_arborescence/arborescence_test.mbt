// ============================================================================
// EDMONDS' ARBORESCENCE - Tests
// ============================================================================

///|
/// Test basic arborescence computation.
///
/// GRAPH:
/// ```
///   0 →(1)→ 1 →(1)→ 2 →(1)→ 3
///   │       │               ↑
///   └──(5)──┴──────(2)──────┘
///
///   Edges:
///     0→1 (weight 1)
///     0→2 (weight 5)
///     1→2 (weight 1)
///     1→3 (weight 2)
///     2→3 (weight 1)
/// ```
///
/// OPTIMAL ARBORESCENCE:
/// ```
///   0 → 1 → 2 → 3
///   Cost: 1 + 1 + 1 = 3
/// ```
test "arborescence basic" {
  let edges : Array[@edmonds_arborescence.Edge] = [
    { from: 0, to: 1, weight: 1L },
    { from: 0, to: 2, weight: 5L },
    { from: 1, to: 2, weight: 1L },
    { from: 1, to: 3, weight: 2L },
    { from: 2, to: 3, weight: 1L },
  ]
  let res = @edmonds_arborescence.min_arborescence(4, edges, 0).unwrap()
  inspect(res.cost, content="3")
  inspect(res.parent[0], content="-1") // root
  inspect(res.parent[1], content="0") // 0→1
  inspect(res.parent[2], content="1") // 1→2
  inspect(res.parent[3], content="2") // 2→3
}

///|
/// Test arborescence with a cycle that needs breaking.
///
/// GRAPH:
/// ```
///   0 →(1)→ 1 ←──(1)──→ 2 →(1)→ 3
///           │           ↑
///           └────(1)────┘
///           ↓
///   0 ─────(5)─────────────────→ 3
///
///   Edges:
///     0→1 (weight 1)
///     1→2 (weight 1)
///     2→1 (weight 1)  ← creates potential cycle with 1→2
///     2→3 (weight 1)
///     0→3 (weight 5)
/// ```
///
/// CYCLE HANDLING:
/// ```
///   Min incoming edges initially:
///     1: from 2 (cost 1) or from 0 (cost 1)
///     2: from 1 (cost 1)
///     3: from 2 (cost 1)
///
///   If we pick 2→1, we get cycle 1↔2.
///   Algorithm contracts this cycle and recurses.
/// ```
test "arborescence cycle" {
  let edges : Array[@edmonds_arborescence.Edge] = [
    { from: 0, to: 1, weight: 1L },
    { from: 1, to: 2, weight: 1L },
    { from: 2, to: 1, weight: 1L },
    { from: 2, to: 3, weight: 1L },
    { from: 0, to: 3, weight: 5L },
  ]
  let res = @edmonds_arborescence.min_arborescence(4, edges, 0).unwrap()

  // Optimal: 0→1→2→3 with cost 3
  inspect(res.cost, content="3")
}

///|
/// Test that unreachable vertices return None.
///
/// GRAPH:
/// ```
///   Component 1: 0 → 1
///   Component 2: 2 → 3  (disconnected)
///
///   Root = 0, but vertices 2 and 3 are unreachable.
/// ```
test "arborescence unreachable" {
  let edges : Array[@edmonds_arborescence.Edge] = [
    { from: 0, to: 1, weight: 1L },
    { from: 2, to: 3, weight: 1L },
  ]
  let res = @edmonds_arborescence.min_arborescence(4, edges, 0)
  inspect(res is None, content="true")
}

///|
/// Test with single vertex (trivial case).
test "arborescence single vertex" {
  let edges : Array[@edmonds_arborescence.Edge] = []
  let res = @edmonds_arborescence.min_arborescence(1, edges, 0).unwrap()
  inspect(res.cost, content="0")
  inspect(res.parent[0], content="-1")
}

///|
/// Test with invalid inputs.
test "arborescence invalid" {
  let edges : Array[@edmonds_arborescence.Edge] = [
    { from: 0, to: 1, weight: 1L },
  ]

  // Invalid root
  inspect(
    @edmonds_arborescence.min_arborescence(2, edges, -1) is None,
    content="true",
  )
  inspect(
    @edmonds_arborescence.min_arborescence(2, edges, 5) is None,
    content="true",
  )

  // Invalid n
  inspect(
    @edmonds_arborescence.min_arborescence(0, edges, 0) is None,
    content="true",
  )
  inspect(
    @edmonds_arborescence.min_arborescence(-1, edges, 0) is None,
    content="true",
  )
}

///|
/// Test with multiple paths to same vertex.
///
/// GRAPH:
/// ```
///        1
///       / \
///   0 →(1) (3)
///       \ /
///        2
///
///   Edges:
///     0→1 (weight 1)
///     0→2 (weight 2)
///     1→2 (weight 3)
/// ```
///
/// Should pick direct path 0→2 (cost 2) over 0→1→2 (cost 1+3=4)
test "arborescence path choice" {
  let edges : Array[@edmonds_arborescence.Edge] = [
    { from: 0, to: 1, weight: 1L },
    { from: 0, to: 2, weight: 2L },
    { from: 1, to: 2, weight: 3L },
  ]
  let res = @edmonds_arborescence.min_arborescence(3, edges, 0).unwrap()
  inspect(res.cost, content="3") // 1 + 2 = 3
  inspect(res.parent[1], content="0")
  inspect(res.parent[2], content="0") // Direct edge, not via 1
}
