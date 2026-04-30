// ============================================================================
// LCT - Access Operation
// ============================================================================
//
// The access operation is THE fundamental operation of Link-Cut Trees.
// All other operations (find_root, cut, link, lca) are built on access.
//
// WHAT ACCESS DOES:
// ```
//   access(v) makes the path from v to the tree root into a single
//   preferred path, stored in one splay tree, with v at the root.
//
//   Before access(v):
//   - v might be on any preferred path (or be a path by itself)
//   - Path to root may cross multiple splay trees via path-parent
//
//   After access(v):
//   - Entire path from v to tree root is one preferred path
//   - v is the root of this splay tree
//   - v has no right child (v is the deepest on preferred path)
// ```
//
// VISUAL EXAMPLE:
// ```
//   Original tree:        Before access(5):       After access(5):
//
//        1                 Splay tree 1:              Splay tree:
//       /|\                    1                      1-2-4-5
//      2 3 4                  / \
//     /    |                 3   2              5 is root of splay,
//    5     6                                    no right child
//                          Splay tree 2:
//   access(5) will             4
//   change preferred          /
//   paths to include         6
//   path 1-2-5
//                          Splay tree 3:
//                              5
//
//   Path-parent: 5→2, 4→1 (or similar)
// ```
//
// ALGORITHM STEPS:
// ```
//   1. Splay v in its current splay tree
//   2. Detach v's right subtree (make them non-preferred)
//   3. Walk up path-parent chain:
//      a. Splay the path-parent node w
//      b. Detach w's current right subtree
//      c. Attach v's tree as w's right subtree
//      d. Splay v again (now in larger tree)
//   4. Repeat until path_parent is -1 (reached tree root)
// ```
//
// WHY IT WORKS:
// ```
//   Key insight: path_parent always points to an ancestor in original tree.
//
//   When we attach v's tree as w's right subtree:
//   - v is now "deeper" than w in the splay tree (right = deeper)
//   - This correctly represents that v is below w in original tree
//   - The entire path from v to w is now in one splay tree
//
//   After splaying v, it becomes the root, ready for the next splice.
// ```
//
// TIME COMPLEXITY:
// ```
//   Amortized O(log n) per access.
//
//   Analysis uses "preferred child" changes:
//   - Each access changes O(log n) preferred children amortized
//   - Each splay is O(log n) amortized
//   - Total: O(log n) amortized
// ```

///|
/// Access operation: Make path from v to root a single preferred path.
///
/// After access(v):
///   - Path from v to tree root is one continuous preferred path
///   - v is at the root of this path's splay tree
///   - v has no right child (deepest node on preferred path)
fn LinkCutTree::access(self : LinkCutTree, v : Int) -> Unit {
  // Step 1: Splay v in its current splay tree
  self.splay(v)

  // Step 2: Detach v's right subtree (descendants in preferred path)
  // These become non-preferred children
  if self.nodes[v].right >= 0 {
    // Right subtree gets path-parent pointing to v
    self.nodes[self.nodes[v].right].path_parent = v
    self.nodes[self.nodes[v].right].parent = -1
    self.nodes[v].right = -1
    self.push_up(v)
  }

  // Step 3: Walk up path-parent chain, splicing v's path into each tree
  for ; self.nodes[v].path_parent >= 0; {
    let w = self.nodes[v].path_parent

    // Splay w to root of its splay tree
    self.splay(w)

    // Detach w's current right subtree (it's no longer preferred)
    if self.nodes[w].right >= 0 {
      self.nodes[self.nodes[w].right].path_parent = w
      self.nodes[self.nodes[w].right].parent = -1
    }

    // Attach v's tree as w's right subtree (v is now on preferred path)
    self.nodes[w].right = v
    self.nodes[v].parent = w
    self.nodes[v].path_parent = -1
    self.push_up(w)

    // Splay v again (it's in a larger splay tree now)
    self.splay(v)
  } where {
    proof_invariant: v >= 0,
    proof_reasoning: (
      #|ACCESS INVARIANT:
      #|
      #|LOOP STATE:
      #|  - v is root of a splay tree containing part of path to tree root
      #|  - v.path_parent points to next ancestor (or -1 if done)
      #|  - v has no right child (we're building path bottom-up)
      #|
      #|EACH ITERATION:
      #|  1. w = v.path_parent is the next ancestor in original tree
      #|  2. Splay w brings it to root of its splay tree
      #|  3. Detach w's right subtree (old preferred path below w)
      #|  4. Attach v as w's right child (v is deeper than w)
      #|  5. Now v and w are in same splay tree, splay v to root
      #|
      #|CORRECTNESS:
      #|  After attaching v under w:
      #|  - The splay tree now contains path from v to w
      #|  - v's old path-parent link becomes a proper splay edge
      #|  - w's path-parent (if any) becomes v's new path-parent
      #|
      #|MAINTENANCE:
      #|  Each iteration extends the preferred path by one ancestor.
      #|  v.path_parent moves up the tree.
      #|
      #|TERMINATION:
      #|  When v.path_parent == -1, we've reached the tree root.
      #|  The entire root-to-v path is now one preferred path.
    ),
  }
}
