// ============================================================================
// DYNAMIC FOREST - High-Level Interface
// ============================================================================
//
// DynamicForest provides a clean interface for dynamic connectivity:
//   - link(u, v): Add edge between u and v (fails if already connected)
//   - cut(u, v): Remove edge between u and v (fails if not connected)
//   - connected(u, v): Check if u and v are in same component
//
// This wraps LinkCutTree with safety checks for:
//   - Cycle prevention (can't link nodes in same tree)
//   - Edge verification (can't cut non-existent edge)
//
// USE CASES:
// ```
//   1. Dynamic graph connectivity
//      - Online queries: "are u and v connected?"
//      - Support adding/removing edges
//
//   2. Incremental minimum spanning tree
//      - Add edges in weight order
//      - Check if endpoints already connected
//
//   3. Network reliability
//      - Model network as tree
//      - Simulate link failures with cut
//      - Query connectivity after failures
// ```

///|
/// Dynamic forest supporting link/cut/connected queries.
pub(all) struct DynamicForest {
  lct : LinkCutTree
}

///|
/// Create a new dynamic forest with n isolated nodes.
pub fn DynamicForest::new(n : Int) -> DynamicForest {
  { lct: LinkCutTree::new(n) }
}

///|
/// Link u and v (add edge between them).
///
/// RETURNS:
///   - true: Edge added successfully
///   - false: u and v already connected (would create cycle)
pub fn DynamicForest::link(self : DynamicForest, u : Int, v : Int) -> Bool {
  // Check if already connected (would create cycle)
  if self.lct.connected(u, v) {
    return false
  }
  self.lct.link_as_root(u, v)
  true
}

///|
/// Cut edge between u and v.
///
/// RETURNS:
///   - true: Edge removed successfully
///   - false: u and v not connected (no edge to cut)
pub fn DynamicForest::cut(self : DynamicForest, u : Int, v : Int) -> Bool {
  // Check if connected
  if !self.lct.connected(u, v) {
    return false
  }
  self.lct.cut_edge(u, v)
  true
}

///|
/// Check if u and v are in the same tree.
pub fn DynamicForest::connected(self : DynamicForest, u : Int, v : Int) -> Bool {
  self.lct.connected(u, v)
}
