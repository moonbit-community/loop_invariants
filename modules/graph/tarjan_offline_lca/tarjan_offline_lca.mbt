// ============================================================================
// TARJAN'S OFFLINE LCA - All LCA queries in O((N + Q) * alpha(N))
// ============================================================================
//
// Given a tree and a fixed batch of `(u, v)` queries, this algorithm answers
// every Lowest Common Ancestor query in near-linear total time using a
// single DFS coupled with a disjoint-set union (DSU). It is "offline" in
// the sense that all queries must be known up front -- the answers are
// produced together at the end of the DFS, not one at a time.
//
// KEY INSIGHT: While the DFS is descending into a node `u`, the in-progress
// path from the root to `u` is exactly the set of ancestors of `u`. As we
// finish each subtree rooted at a child `c`, we *union* `c` with `u` in the
// DSU and record `ancestor[find(u)] = u`. The DSU's `find` then maps any
// node already finished beneath `u` back to its "lowest still-open"
// ancestor -- which is the LCA whenever we later finish processing the
// other endpoint of a query.
//
//   ancestor[root_of(set)] = the highest still-open ancestor of every
//                            finished node in that set
//
// PROCEDURE (textbook recursion):
//
//   dfs(u):
//     color[u] = GRAY                 // entering subtree at u
//     ancestor[u] = u
//     for c in children(u):
//       dfs(c)
//       union(u, c); ancestor[find(u)] = u
//     color[u] = BLACK                // finished subtree at u
//     for each pending query (u, v) with color[v] == BLACK:
//       answer = ancestor[find(v)]
//
// Queries are stored at *both* endpoints. The first endpoint to turn BLACK
// has nothing to answer (the other endpoint is still GRAY or WHITE); the
// second endpoint to turn BLACK finds its peer in the BLACK set and reads
// out the LCA via `find`.
//
// This implementation uses an iterative DFS so the main loop carries a
// stated `proof_invariant`: at every point the gray-colored nodes form
// exactly the in-progress root-to-current path, and every black-colored
// node has a finished subtree whose DSU root has been linked correctly
// into its parent's still-open ancestor chain.
//
// TIME COMPLEXITY : O((N + Q) * alpha(N))  with path-compressing DSU
// SPACE COMPLEXITY: O(N + Q)

///|
/// White = not yet entered; Gray = on the live DFS path (subtree
/// in progress); Black = subtree fully finished.
priv enum Color {
  White
  Gray
  Black
} derive(Eq)

///|
fn dsu_find(parent : Array[Int], x : Int) -> Int {
  // Two-pass find with path compression. The loop walks up to the root,
  // then a second loop snaps every node on the path to point directly
  // at the root, giving the inverse-Ackermann amortized bound when
  // combined with union-by-rank.
  let root = for cur = x {
    let p = parent[cur]
    if p == cur {
      break cur
    } else {
      continue p
    }
  } where {
    proof_invariant: cur >= 0,
    proof_reasoning: (
      #|INVARIANT (Walk to representative):
      #|cur is a valid node index; following `parent` strictly decreases
      #|depth in the DSU forest until reaching a self-loop at the root.
      #|TERMINATION:
      #|DSU forests are acyclic, so the chain reaches a root in finitely
      #|many steps.
    ),
  }
  for cur = x {
    if parent[cur] == cur {
      break ()
    } else {
      let next = parent[cur]
      parent[cur] = root
      continue next
    }
  } where {
    proof_invariant: cur >= 0,
    proof_reasoning: (
      #|INVARIANT (Path compression pass):
      #|cur ranges over the original path from x up to root; we rewrite
      #|each parent[cur] to point directly at root, which preserves
      #|reachability and shortens future finds.
      #|TERMINATION:
      #|Stops when cur is the root.
    ),
  }
  root
}

///|
fn dsu_union(parent : Array[Int], rank : Array[Int], a : Int, b : Int) -> Unit {
  // Union by rank. Used exclusively to merge a finished child set into
  // its parent's set; the parent's representative is then re-tagged as
  // the highest still-open ancestor via `ancestor[find(u)] = u`.
  let ra = dsu_find(parent, a)
  let rb = dsu_find(parent, b)
  if ra == rb {
    return
  }
  if rank[ra] < rank[rb] {
    parent[ra] = rb
  } else if rank[ra] > rank[rb] {
    parent[rb] = ra
  } else {
    parent[rb] = ra
    rank[ra] = rank[ra] + 1
  }
}

///|
/// Answer a batch of Lowest Common Ancestor queries on a rooted tree.
///
/// All queries are answered together in a single DFS that runs the DSU
/// "small to large" merge of finished subtrees, achieving a total cost of
/// `O((N + Q) * alpha(N))` where `alpha` is the inverse Ackermann
/// function. This is asymptotically faster than `Q` independent
/// `O(log N)` binary-lifting queries when `Q` is large.
///
/// ## Parameters
///
/// - `n`       : number of nodes; the tree spans the indices `0 .. n-1`.
/// - `adj`     : undirected adjacency list. `adj[u]` enumerates the
///               neighbours of `u`. The DFS picks the orientation away from
///               `root` automatically; callers do not need to remove the
///               back-edge to the parent themselves.
/// - `root`    : index of the root node; must satisfy `0 <= root < n` when
///               `n > 0`.
/// - `queries` : array of `(u, v)` pairs to answer. The answer for the
///               query at index `i` is written to position `i` of the
///               returned array.
///
/// ## Returns
///
/// An `Array[Int]` of length `queries.length()` whose `i`-th entry is the
/// LCA of `queries[i]` under the root `root`. A query mentioning an
/// out-of-range endpoint, or two endpoints with no common ancestor under
/// `root` (which cannot happen when the input really is a tree), receives
/// the sentinel `-1`.
///
/// ## Edge cases
///
/// - `queries[i] = (u, u)` returns `u` (any node is its own ancestor).
/// - When `n = 0` or `queries` is empty, the returned array is empty.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   //        0
///   //       / \
///   //      1   2
///   //     / \
///   //    3   4
///   let adj : Array[Array[Int]] = [[1, 2], [0, 3, 4], [0], [1], [1]]
///   let queries : ReadOnlyArray[(Int, Int)] = [(3, 4), (3, 2), (4, 2), (1, 1)]
///   let ans = @tarjan_offline_lca.tarjan_offline_lca(5, adj[:], 0, queries[:])
///   assert_eq(ans, [1, 0, 0, 1])
/// }
/// ```
///
/// ## Complexity
///
/// `O((N + Q) * alpha(N))` time and `O(N + Q)` space.
pub fn tarjan_offline_lca(
  n : Int,
  adj : ArrayView[Array[Int]],
  root : Int,
  queries : ArrayView[(Int, Int)],
) -> Array[Int] {
  let q = queries.length()
  let answers = Array::make(q, -1)
  if n <= 0 || q == 0 {
    return answers
  }
  if root < 0 || root >= n {
    return answers
  }

  // Group queries by both endpoints. `query_at[u]` enumerates the indices
  // of queries that involve `u`, paired with the *other* endpoint.
  let query_at : Array[Array[(Int, Int)]] = Array::make(n, [])
  for i in 0..<n {
    query_at[i] = []
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (Adjacency bucket init):
      #|Indices [0..i) have fresh empty per-node query lists.
      #|MAINTENANCE:
      #|Allocate one more empty bucket and advance i.
      #|TERMINATION:
      #|At i = n every node has its own bucket.
    ),
  }
  for i in 0..<q {
    let (u, v) = queries[i]
    if u < 0 || u >= n || v < 0 || v >= n {
      continue
    }
    if u == v {
      answers[i] = u
      continue
    }
    query_at[u].push((i, v))
    query_at[v].push((i, u))
  } where {
    proof_invariant: i >= 0 && i <= q,
    proof_reasoning: (
      #|INVARIANT (Query indexing):
      #|For every accepted query in [0..i), both endpoints' buckets
      #|contain a (query_index, other_endpoint) pair so the DFS can find
      #|them when processing either side.
      #|MAINTENANCE:
      #|Out-of-range pairs are skipped; self-queries are answered
      #|directly; valid pairs are appended to both endpoints' lists.
      #|TERMINATION:
      #|At i = q all queries are either short-circuited or indexed.
    ),
  }

  // DSU and per-node bookkeeping.
  let parent = Array::make(n, 0)
  let rank = Array::make(n, 0)
  for i in 0..<n {
    parent[i] = i
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (DSU init):
      #|Every node in [0..i) is its own DSU root with rank 0.
      #|MAINTENANCE:
      #|Set parent[i] = i.
      #|TERMINATION:
      #|At i = n the DSU is a forest of singletons.
    ),
  }
  let color : Array[Color] = Array::make(n, White)
  let ancestor = Array::make(n, -1)

  // Iterative DFS. Each stack frame is a triple `(u, parent_in_tree,
  // child_iter)` where `child_iter` is the next index into `adj[u]` to
  // examine. The first visit to a node paints it Gray and sets
  // `ancestor[u] = u`; popping a node paints it Black and runs the
  // query-answering pass for that endpoint.
  let stack : Array[(Int, Int, Int)] = []
  color[root] = Gray
  ancestor[root] = root
  stack.push((root, -1, 0))
  while stack.length() > 0 {
    let top = stack.length() - 1
    let (u, p, i) = stack[top]
    if i < adj[u].length() {
      stack[top] = (u, p, i + 1)
      let v = adj[u][i]
      if v == p || color[v] != White {
        continue
      }
      color[v] = Gray
      ancestor[v] = v
      stack.push((v, u, 0))
    } else {
      // Finished subtree at u. The order below is load-bearing:
      //
      //   1. Mark u BLACK.
      //   2. Resolve queries while `ancestor[find(u)] == u` still holds,
      //      so a query (u, descendant) sees `u` as the open ancestor.
      //   3. Merge u into the parent's set and re-tag the representative
      //      with the parent (the new still-open ancestor of the group).
      //
      // Doing the merge before answering would shift the ancestor entry
      // of u's group up to the parent, breaking queries (u, descendant).
      stack.pop() |> ignore
      color[u] = Black
      for entry in query_at[u] {
        let (qi, w) = entry
        if color[w] == Black {
          answers[qi] = ancestor[dsu_find(parent, w)]
        }
      }
      if p >= 0 {
        dsu_union(parent, rank, u, p)
        ancestor[dsu_find(parent, p)] = p
      }
    }
  }
  answers
}

///|
/// Build an adjacency list from an undirected edge list. Helper used by
/// tests; not part of the public algorithm.
fn build_adj(n : Int, edges : ArrayView[(Int, Int)]) -> Array[Array[Int]] {
  let adj : Array[Array[Int]] = Array::make(n, [])
  for i in 0..<n {
    adj[i] = []
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT:
      #|Adjacency buckets [0..i) are initialised to empty lists.
      #|TERMINATION:
      #|At i = n every node has its own bucket.
    ),
  }
  for e in edges {
    let (u, v) = e
    adj[u].push(v)
    adj[v].push(u)
  }
  adj
}

///|
test "tarjan offline lca tiny tree" {
  //        0
  //       / \
  //      1   2
  //     / \
  //    3   4
  let edges : ReadOnlyArray[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4)]
  let adj = build_adj(5, edges[:])
  let queries : ReadOnlyArray[(Int, Int)] = [(3, 4), (3, 2), (4, 2), (1, 1)]
  let ans = tarjan_offline_lca(5, adj[:], 0, queries[:])
  assert_eq(ans[0], 1) // lca(3, 4)
  assert_eq(ans[1], 0) // lca(3, 2)
  assert_eq(ans[2], 0) // lca(4, 2)
  assert_eq(ans[3], 1) // lca(1, 1)
}

///|
test "tarjan offline lca linear chain" {
  // 0 - 1 - 2 - 3 - 4
  let edges : ReadOnlyArray[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
  let adj = build_adj(5, edges[:])
  let queries : ReadOnlyArray[(Int, Int)] = [(0, 4), (2, 4), (1, 3), (3, 0)]
  let ans = tarjan_offline_lca(5, adj[:], 0, queries[:])
  assert_eq(ans[0], 0)
  assert_eq(ans[1], 2)
  assert_eq(ans[2], 1)
  assert_eq(ans[3], 0)
}

///|
test "tarjan offline lca non-zero root" {
  // Same tree as the tiny example but rooted at 1:
  //
  //          1
  //         /|\
  //        3 4 0
  //              \
  //               2
  let edges : ReadOnlyArray[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4)]
  let adj = build_adj(5, edges[:])
  let queries : ReadOnlyArray[(Int, Int)] = [(3, 2), (4, 0), (3, 4)]
  let ans = tarjan_offline_lca(5, adj[:], 1, queries[:])
  assert_eq(ans[0], 1) // lca(3, 2) with root 1
  assert_eq(ans[1], 1) // lca(4, 0) with root 1
  assert_eq(ans[2], 1) // lca(3, 4) with root 1
}

///|
test "tarjan offline lca caterpillar deep paths" {
  // Tree rooted at 0:
  //
  //            0
  //           / \
  //          1   4
  //         /|
  //        2 5
  //       /|
  //      3 6
  //      |
  //      7
  //
  // Edges form a spine 0-1-2-3 plus four leaf legs 0-4, 1-5, 2-6, 3-7.
  let edges : ReadOnlyArray[(Int, Int)] = [
    (0, 1),
    (1, 2),
    (2, 3),
    (0, 4),
    (1, 5),
    (2, 6),
    (3, 7),
  ]
  let adj = build_adj(8, edges[:])
  let queries : ReadOnlyArray[(Int, Int)] = [
    (4, 5), //  side leg vs spine -> meet at 0
    (4, 7), //  side leg vs deep spine -> meet at 0
    (5, 6), //  cousins below 1 and 2 -> meet at 1
    (6, 7), //  cousin and deep nephew -> meet at 2
    (3, 7), //  ancestor of 7 directly
    (1, 5), //  parent and child
    (4, 4), //  self
  ]
  let ans = tarjan_offline_lca(8, adj[:], 0, queries[:])
  assert_eq(ans[0], 0)
  assert_eq(ans[1], 0)
  assert_eq(ans[2], 1)
  assert_eq(ans[3], 2)
  assert_eq(ans[4], 3)
  assert_eq(ans[5], 1)
  assert_eq(ans[6], 4)
}

///|
test "tarjan offline lca empty cases" {
  // No nodes, no queries.
  let empty_adj : ReadOnlyArray[Array[Int]] = []
  let empty_q : ReadOnlyArray[(Int, Int)] = []
  let ans0 = tarjan_offline_lca(0, empty_adj[:], 0, empty_q[:])
  assert_eq(ans0.length(), 0)

  // Single node, single self-query.
  let one_adj : Array[Array[Int]] = [[]]
  let one_q : ReadOnlyArray[(Int, Int)] = [(0, 0)]
  let ans1 = tarjan_offline_lca(1, one_adj[:], 0, one_q[:])
  assert_eq(ans1, [0])
}

///|
test "tarjan offline lca out-of-range query stays at sentinel" {
  let edges : ReadOnlyArray[(Int, Int)] = [(0, 1), (1, 2)]
  let adj = build_adj(3, edges[:])
  let queries : ReadOnlyArray[(Int, Int)] = [(0, 5), (-1, 1), (1, 2)]
  let ans = tarjan_offline_lca(3, adj[:], 0, queries[:])
  assert_eq(ans[0], -1) // invalid second endpoint
  assert_eq(ans[1], -1) // invalid first endpoint
  assert_eq(ans[2], 1) // valid query still answered
}
