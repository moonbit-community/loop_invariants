// ============================================================================
// KARGER MIN-CUT - Randomised edge contraction
// ============================================================================
//
// PROBLEM
//
// Given a connected undirected (multi-)graph, find a partition of its
// vertices into two non-empty sets `S, T` that minimises the number of
// edges crossing `S | T`.
//
// THE TRICK (Karger 1993)
//
// Repeatedly contract a uniformly random edge until only two
// "super-vertices" remain. The number of edges between those two
// super-vertices is the size of a cut. Each trial reports SOME cut;
// the minimum across all trials is, with high probability, the
// minimum cut.
//
// ANALYSIS
//
// Let `k` = size of the (unknown) minimum cut. After contracting one
// edge at random, the probability of contracting a min-cut edge is at
// most `k / E` where E is the current edge count. By a degree
// argument, `E >= n * k / 2`, so each contraction "survives" the
// min-cut with probability at least `1 - 2 / n`.
//
// Multiplying across n - 2 contractions:
//
//     Pr[ trial finds min cut ]
//     >=  (1 - 2/n) * (1 - 2/(n-1)) * ... * (1 - 2/3)
//     =   2 / (n * (n - 1))
//
// To boost this to high probability, run T independent trials. The
// failure probability is at most  (1 - 2 / (n(n-1)))^T. Choosing
// T = c * n^2 * log n iterations gives failure probability < 1 / n^c.
//
// TIME COMPLEXITY  : O(trials * n^2)  -- linear per contraction, n-2 contractions per trial
// SPACE COMPLEXITY : O(E + n)  -- DSU plus edge list

///|
/// A tiny LCG used to generate "random" edge indices deterministically
/// from the user seed. Quality sufficient for the uniform-pick
/// semantics Karger needs; statistical quality is not load-bearing.
fn karger_lcg(state : Int64) -> Int64 {
  state * 6364136223846793005L + 1442695040888963407L
}

///|
/// Draw a uniform Int in [0, n) from the LCG state. Updates `state`
/// in place by returning the new state alongside the index.
fn karger_next_index(state : Int64, n : Int) -> (Int, Int64) {
  let s = karger_lcg(state)
  let abs_s = if s < 0L { -s } else { s }
  let idx = (abs_s % n.to_int64()).to_int()
  (idx, s)
}

///|
/// DSU helpers, private to this package.
fn dsu_find(parent : Array[Int], x : Int) -> Int {
  let root = for cur = x {
    if parent[cur] == cur {
      break cur
    } else {
      continue parent[cur]
    }
  } where {
    proof_invariant: cur >= 0,
    proof_reasoning: (
      #|INVARIANT: cur is a valid node; the parent chain has no cycle
      #|so it terminates at the root.
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
      #|INVARIANT (Path compression):
      #|rewrite each cur's parent to point at root.
    ),
  }
  root
}

///|
fn dsu_union(parent : Array[Int], rank : Array[Int], a : Int, b : Int) -> Bool {
  let ra = dsu_find(parent, a)
  let rb = dsu_find(parent, b)
  if ra == rb {
    return false
  }
  if rank[ra] < rank[rb] {
    parent[ra] = rb
  } else if rank[ra] > rank[rb] {
    parent[rb] = ra
  } else {
    parent[rb] = ra
    rank[ra] = rank[ra] + 1
  }
  true
}

///|
/// Run a single Karger contraction trial. Returns the size of the cut
/// found in this run.
fn one_trial(
  n : Int,
  edges : ArrayView[(Int, Int)],
  initial_state : Int64,
) -> (Int, Int64) {
  let parent = Array::make(n, 0)
  let rank = Array::make(n, 0)
  for i in 0..<n {
    parent[i] = i
  }
  // Contract until two super-vertices remain. We pick a random edge
  // and union its endpoints; if they were already in the same set,
  // we ignore the pick.
  let result_state = for state = initial_state, components = n {
    if components <= 2 {
      break state
    }
    let (idx, next_state) = karger_next_index(state, edges.length())
    let (u, v) = edges[idx]
    if dsu_union(parent, rank, u, v) {
      continue next_state, components - 1
    } else {
      continue next_state, components
    }
  } where {
    proof_invariant: components >= 2 && components <= n,
    proof_reasoning: (
      #|INVARIANT (Karger contraction):
      #|At each step, `components` equals the number of distinct DSU
      #|roots, i.e. the number of super-vertices. A successful union
      #|reduces it by 1; ignored unions (same set) leave it unchanged.
      #|MAINTENANCE:
      #|Sample one edge; attempt to union; track count.
      #|TERMINATION:
      #|Each successful union strictly reduces components, bounded
      #|below by 2. The loop is also bounded by the edge count in
      #|practice: any "successful" union takes <= E iterations
      #|amortised.
    ),
  }
  // Count edges crossing between the two surviving super-vertices.
  let mut cut = 0
  for e in edges {
    let (u, v) = e
    if dsu_find(parent, u) != dsu_find(parent, v) {
      cut = cut + 1
    }
  }
  (cut, result_state)
}

///|
/// Karger's randomised min-cut. Repeats `trials` independent
/// contraction runs and returns the smallest cut found.
///
/// ## Parameters
///
/// - `n`       : number of vertices.
/// - `edges`   : undirected edges as `(u, v)` pairs. Multi-edges
///               (parallel) are allowed and meaningful -- they make
///               the corresponding cut "harder."
/// - `trials`  : how many independent contraction runs to do. For
///               high-probability correctness, choose
///               `trials = ceil(n*(n-1)/2 * ln(n))`.
/// - `seed`    : deterministic seed; runs with the same seed produce
///               identical results.
///
/// ## Returns
///
/// The smallest cut size found across all trials. Returns `Int::MAX`
/// when `n <= 1` (no cut exists) or `0` when the graph has no edges
/// (the "cut" between any partition is empty).
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // 4-cycle: min cut size is 2.
///   let edges : ReadOnlyArray[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
///   let answer = @karger_min_cut.karger_min_cut(4, edges[:], 50, seed=1L)
///   assert_eq(answer, 2)
/// }
/// ```
///
/// ## Complexity
///
/// Time `O(trials * (n + E))`, space `O(n + E)`.
pub fn karger_min_cut(
  n : Int,
  edges : ArrayView[(Int, Int)],
  trials : Int,
  seed~ : Int64,
) -> Int {
  if n <= 1 {
    return @int.MAX_VALUE
  }
  if edges.length() == 0 {
    return 0
  }
  let mut best = @int.MAX_VALUE
  for t = 0, state = seed; t < trials; {
    let (cut, next_state) = one_trial(n, edges, state)
    if cut < best {
      best = cut
    }
    continue t + 1, next_state
  } where {
    proof_invariant: t >= 0 && t <= trials,
    proof_invariant: best >= 0,
    proof_reasoning: (
      #|INVARIANT (Trial minimum):
      #|`best` is the minimum cut size observed across trials [0..t).
      #|MAINTENANCE:
      #|Run one contraction trial; lower `best` if the new cut is smaller.
      #|TERMINATION:
      #|t increases by 1 each iteration, bounded by `trials`.
    ),
  }
  best
}

///|
test "karger 4-cycle has min cut 2" {
  // 4-cycle: each vertex has degree 2, so min cut is 2.
  let edges : ReadOnlyArray[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
  let cut = karger_min_cut(4, edges[:], 50, seed=1L)
  @debug.assert_eq(cut, 2)
}

///|
test "karger triangle has min cut 2" {
  let edges : ReadOnlyArray[(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
  let cut = karger_min_cut(3, edges[:], 30, seed=42L)
  @debug.assert_eq(cut, 2)
}

///|
test "karger bridge edge has min cut 1" {
  // Two triangles connected by a single bridge edge: min cut = 1.
  let edges : ReadOnlyArray[(Int, Int)] = [
    (0, 1),
    (1, 2),
    (2, 0), // triangle on {0, 1, 2}
    (3, 4),
    (4, 5),
    (5, 3), // triangle on {3, 4, 5}
    (2, 3), // bridge
  ]
  let cut = karger_min_cut(6, edges[:], 200, seed=7L)
  @debug.assert_eq(cut, 1)
}

///|
test "karger complete graph K4 has min cut 3" {
  // K4: every vertex degree 3, min cut = 3.
  let edges : ReadOnlyArray[(Int, Int)] = [
    (0, 1),
    (0, 2),
    (0, 3),
    (1, 2),
    (1, 3),
    (2, 3),
  ]
  let cut = karger_min_cut(4, edges[:], 100, seed=99L)
  @debug.assert_eq(cut, 3)
}

///|
test "karger double-edge bridge has min cut 2" {
  // Two triangles connected by two parallel bridge edges.
  let edges : ReadOnlyArray[(Int, Int)] = [
    (0, 1),
    (1, 2),
    (2, 0), // left triangle
    (3, 4),
    (4, 5),
    (5, 3), // right triangle
    (2, 3),
    (2, 3), // double bridge
  ]
  let cut = karger_min_cut(6, edges[:], 200, seed=11L)
  @debug.assert_eq(cut, 2)
}

///|
test "karger single edge" {
  let edges : ReadOnlyArray[(Int, Int)] = [(0, 1)]
  let cut = karger_min_cut(2, edges[:], 10, seed=1L)
  @debug.assert_eq(cut, 1)
}

///|
test "karger edge cases" {
  // n = 0 or 1 has no proper cut; we return Int::MAX.
  let empty : ReadOnlyArray[(Int, Int)] = []
  @debug.assert_eq(karger_min_cut(0, empty[:], 5, seed=1L), @int.MAX_VALUE)
  @debug.assert_eq(karger_min_cut(1, empty[:], 5, seed=1L), @int.MAX_VALUE)
  // n >= 2 but no edges: cut is 0.
  @debug.assert_eq(karger_min_cut(3, empty[:], 5, seed=1L), 0)
}

///|
test "karger deterministic for same seed" {
  let edges : ReadOnlyArray[(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3)]
  let c1 = karger_min_cut(4, edges[:], 20, seed=1234L)
  let c2 = karger_min_cut(4, edges[:], 20, seed=1234L)
  @debug.assert_eq(c1, c2)
}
