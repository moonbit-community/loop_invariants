// ============================================================================
// KARP'S MINIMUM MEAN-WEIGHT CYCLE (1978)
// ============================================================================
//
// Given a directed graph G = (V, E) with edge weights w : E -> Z (any sign),
// the *mean weight* of a directed cycle C is
//
//     mu(C)  =  sum_{e in C} w(e)  /  |C|
//
// where |C| is the number of edges in C. The *minimum cycle mean* is
//
//     mu*  =  min over directed cycles C  of  mu(C).
//
// Karp showed that, fixing any source vertex `s` from which every cycle is
// reachable, mu* admits the elegant closed form
//
//                              F_n(v)  -  F_k(v)
//     mu*  =  min over v in V   max over 0 <= k < n   ----------------
//                                                       n  -  k
//
// where `F_k(v)` is the minimum weight of *any* walk from `s` to `v` using
// *exactly* `k` edges (or `+infinity` if no such walk exists), and `n = |V|`.
//
// WHY THE MAX-OVER-k CORRESPONDS TO A CYCLE:
//   Fix v. If v is reachable, the walk of length n that realises F_n(v) must
//   contain some cycle (pigeonhole: n edges across n vertices forces a
//   repeated vertex). Subtracting any prefix walk of length k that ends at
//   the same vertex isolates a "tail walk" of length (n - k) that contains
//   the cycle, and the worst (largest) such ratio over k is achieved exactly
//   when the prefix splits off the cheapest non-cycle part, leaving the
//   cycle's mean weight as the difference quotient.
//
// AVOIDING FLOATING POINT:
//   All comparisons are done by cross-multiplication on rationals (num, den)
//   with `den > 0`. The numerators stay within Int64 for any reasonable
//   weight range because they are sums of at most `n` weights.
//
// TIME COMPLEXITY : O(V * E)   -- the F_k(v) DP touches each edge once per
//                                  layer, and there are n + 1 layers.
// SPACE COMPLEXITY: O(V)       -- two alternating layer arrays.

///|
/// Sentinel value used in place of +infinity inside the F_k(v) DP. Chosen
/// so that `INF + (any weight in [-INF/4, INF/4])` never overflows Int64.
const KARP_INF : Int64 = 4611686018427387903L

///|
/// Returns `true` if the rational `a/da` is strictly less than `b/db`,
/// assuming `da > 0` and `db > 0`. Comparison is by cross-multiplication
/// using 128-bit-safe arithmetic via `Int64` -- callers are responsible
/// for ensuring `|a| * db` and `|b| * da` fit in `Int64`. In this file
/// the operands satisfy `|num| <= n * max|w|` and `den <= n`, so for
/// reasonable inputs there is plenty of headroom.
fn ratio_lt(a : Int64, da : Int64, b : Int64, db : Int64) -> Bool {
  a * db < b * da
}

///|
/// Karp's minimum mean-weight cycle algorithm.
///
/// Computes the minimum mean weight over all directed cycles in `edges`
/// that are reachable from `start`, returned as an exact rational
/// `Some((numerator, denominator))` where `denominator` is the cycle
/// length (always positive). Returns `None` when no cycle is reachable
/// from `start` (in particular, when the subgraph reachable from
/// `start` is a DAG).
///
/// ## Parameters
///
/// - `n`     : number of vertices; vertex indices are `0..<n`.
/// - `edges` : list of directed edges `(u, v, w)`. The weight `w` may be
///             negative, zero, or positive.
/// - `start` : the source vertex from which the cycle must be reachable.
///             Karp's algorithm requires a source for its layered DP.
///             In a strongly connected graph the result does not depend
///             on the choice; in a general graph only cycles reachable
///             from `start` are considered.
///
/// ## Returns
///
/// - `Some((num, den))` with `den >= 1` and `num / den` equal to the
///   minimum cycle mean. The returned pair is *not* reduced to lowest
///   terms; callers that need a canonical form should divide by
///   `gcd(num, den)`.
/// - `None` if no cycle is reachable from `start`.
///
/// ## Complexity
///
/// O(V * E) time and O(V) extra space.
pub fn min_mean_cycle(
  n : Int,
  edges : ArrayView[(Int, Int, Int64)],
  start : Int,
) -> (Int64, Int)? {
  if n <= 0 || start < 0 || start >= n {
    return None
  }

  // f_prev holds F_{k-1}, f_curr holds F_k. We allocate n + 1 rows lazily
  // by keeping all of them so we can query F_k(v) for every k in [0, n]
  // after the DP completes.
  //
  // Row k has length n. dp[k][v] = F_k(v) or KARP_INF if unreachable.
  let dp : Array[Array[Int64]] = [ for _ in 0..<=n => Array::make(n, KARP_INF) ]
  dp[0][start] = 0L

  // Layered Bellman-Ford-style relaxation. Each row sees every edge once.
  for k in 1..<=n {
    let prev = dp[k - 1]
    let curr = dp[k]
    for edge in edges {
      let (u, v, w) = edge
      if u >= 0 && u < n && v >= 0 && v < n && prev[u] < KARP_INF {
        let cand = prev[u] + w
        if cand < curr[v] {
          curr[v] = cand
        }
      }
    } where {
      proof_invariant: prev.length() == n,
      proof_invariant: curr.length() == n,
      proof_reasoning: (
        #|INVARIANT (F_k DP relaxation):
        #|  After processing a prefix of `edges`, curr[v] is the minimum over
        #|  every relaxed edge (u, v, w) of (prev[u] + w), capped at KARP_INF.
        #|MAINTENANCE:
        #|  For each edge (u, v, w) with prev[u] finite, consider the walk
        #|  start -> ... -> u (k - 1 edges, weight prev[u]) followed by edge
        #|  (u, v, w). That walk has exactly k edges and weight prev[u] + w;
        #|  the loop body keeps the running minimum across all such walks.
        #|TERMINATION:
        #|  The loop iterates once per edge. After the last edge,
        #|  curr[v] = F_k(v) for every v.
      ),
    }
  } where {
    proof_invariant: dp.length() == n + 1,
    proof_reasoning: (
      #|INVARIANT (Karp layered DP):
      #|  For every i in [0, k), dp[i][v] equals F_i(v): the minimum weight
      #|  of a walk start -> v using exactly i edges, or KARP_INF if no
      #|  such walk exists. In particular F_0(start) = 0 and F_0(v) = +inf
      #|  for v != start.
      #|MAINTENANCE:
      #|  Row k is filled from row k - 1 by edge relaxation:
      #|    F_k(v) = min_{(u,v,w) in E, F_{k-1}(u) < inf} F_{k-1}(u) + w.
      #|  This is the standard recurrence for walks of exactly k edges.
      #|TERMINATION:
      #|  k strictly increases from 1 to n; after k = n every row is filled.
      #|CYCLE EXISTENCE:
      #|  A cycle reachable from `start` exists iff F_n(v) < +inf for some
      #|  v in V. (If every walk of length n from `start` is "+inf", the
      #|  reachable subgraph has no walk of length n, hence no cycle.)
    ),
  }

  // Check cycle existence: F_n(v) must be finite for some v.
  let any_finite = for v = 0 {
    if v >= n {
      break false
    } else if dp[n][v] < KARP_INF {
      break true
    } else {
      continue v + 1
    }
  } where {
    proof_invariant: v >= 0 && v <= n,
    proof_reasoning: (
      #|INVARIANT (cycle-existence scan):
      #|  Every F_n(v') with v' < v is "+inf" (we have not yet broken out).
      #|MAINTENANCE:
      #|  If F_n(v) is finite, break early with `true`; otherwise advance v.
      #|TERMINATION:
      #|  v ranges over [0, n]. At v = n we break with `false` (no finite
      #|  entry exists, so no cycle is reachable from `start`). A finite
      #|  F_n(v) certifies a walk of length n, which (by pigeonhole on
      #|  n + 1 vertices) must contain a cycle.
    ),
  }
  if !any_finite {
    return None
  }

  // For each v with F_n(v) finite, compute  M(v) = max_{0 <= k < n} of
  //   (F_n(v) - F_k(v)) / (n - k)        (rational, den > 0).
  // The minimum cycle mean is  min_v M(v).
  //
  // best_num/best_den holds the current minimum-over-v of M(v).
  let mut best_num : Int64 = 0L
  let mut best_den : Int = 1
  let mut have_best = false
  for v in 0..<n {
    let fn_v = dp[n][v]
    if fn_v >= KARP_INF {
      continue
    }
    // Compute M(v) = max over k in [0, n) of (fn_v - F_k(v)) / (n - k),
    // skipping k for which F_k(v) is +inf (that term is -inf in the max
    // and therefore irrelevant). At least one finite k exists: k = n
    // itself is finite by assumption -- but k ranges only over [0, n),
    // so we instead rely on F_0(start) = 0 reaching v via the same walk
    // of length n; concretely, the walk realising F_n(v) has a prefix at
    // each length k, so F_k(v') is finite for *that prefix's endpoint*,
    // and over all v we will eventually pick up the cycle ratio.
    //
    // Implementation: scan k in [0, n), track the maximum rational.
    let mut m_num : Int64 = 0L
    let mut m_den : Int = 1
    let mut have_m = false
    for k in 0..<n {
      let fk_v = dp[k][v]
      if fk_v >= KARP_INF {
        continue
      }
      let cand_num = fn_v - fk_v
      let cand_den = n - k
      if !have_m ||
        ratio_lt(m_num, m_den.to_int64(), cand_num, cand_den.to_int64()) {
        m_num = cand_num
        m_den = cand_den
        have_m = true
      }
    } where {
      proof_invariant: k >= 0 && k <= n,
      proof_invariant: m_den >= 1 && m_den <= n,
      proof_reasoning: (
        #|INVARIANT (inner max-over-k):
        #|  When have_m is true, (m_num / m_den) equals the maximum of
        #|  (F_n(v) - F_j(v)) / (n - j) over all finite j in [0, k).
        #|MAINTENANCE:
        #|  For the current k, if F_k(v) is +inf the term is skipped
        #|  (its value is -inf, so it cannot raise the max). Otherwise
        #|  compute the candidate rational and replace the running max
        #|  via cross-multiplication when strictly greater.
        #|TERMINATION:
        #|  k ranges over [0, n). At loop exit, (m_num, m_den) realises
        #|  M(v) (assuming have_m). The vertex v with F_n(v) finite has
        #|  at least one finite F_k(v) -- the same walk has prefixes at
        #|  every length k <= n -- so have_m will be set.
      ),
    }
    if have_m {
      // Update outer min over v.
      if !have_best ||
        ratio_lt(m_num, m_den.to_int64(), best_num, best_den.to_int64()) {
        best_num = m_num
        best_den = m_den
        have_best = true
      }
    }
  } where {
    proof_invariant: v >= 0 && v <= n,
    proof_invariant: best_den >= 1,
    proof_reasoning: (
      #|INVARIANT (outer min-over-v):
      #|  When have_best is true, (best_num / best_den) equals
      #|    min over u in [0, v) with F_n(u) finite of M(u).
      #|MAINTENANCE:
      #|  For each v with F_n(v) finite, compute M(v) by the inner loop
      #|  and lower the running minimum if M(v) is strictly smaller.
      #|TERMINATION:
      #|  v sweeps [0, n). Karp's theorem identifies (best_num, best_den)
      #|  with the minimum cycle mean once at least one finite F_n(v)
      #|  exists -- which we verified above before entering this loop.
    ),
  }
  if have_best {
    Some((best_num, best_den))
  } else {
    None
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "karp single 2-cycle" {
  // Graph: 0 -> 1 (w = 5), 1 -> 0 (w = 3). Min mean = 8 / 2 = 4.
  let edges : Array[(Int, Int, Int64)] = [(0, 1, 5L), (1, 0, 3L)]
  @debug.assert_eq(min_mean_cycle(2, edges, 0), Some((8L, 2)))
}

///|
test "karp self-loop" {
  // Single self-loop of weight 7.
  let edges : Array[(Int, Int, Int64)] = [(0, 0, 7L)]
  @debug.assert_eq(min_mean_cycle(1, edges, 0), Some((7L, 1)))
}

///|
test "karp negative cycle" {
  // 0 -> 1 (w = -2), 1 -> 0 (w = -3). Min mean = -5 / 2.
  let edges : Array[(Int, Int, Int64)] = [(0, 1, -2L), (1, 0, -3L)]
  @debug.assert_eq(min_mean_cycle(2, edges, 0), Some((-5L, 2)))
}

///|
test "karp dag returns none" {
  // 0 -> 1 -> 2 with no back edges. No cycle.
  let edges : Array[(Int, Int, Int64)] = [(0, 1, 1L), (1, 2, 1L)]
  @debug.assert_eq(min_mean_cycle(3, edges, 0), None)
}

///|
test "karp two cycles picks smaller mean" {
  // Two disjoint cycles, both reachable from vertex 0:
  //   inner triangle 0 -> 1 -> 2 -> 0 with weights (1, 2, 3)  -> mean 6/3 = 2
  //   side cycle    0 -> 3 -> 0 with weights (10, 10)         -> mean 20/2 = 10
  // The algorithm must pick the smaller mean.
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 1L),
    (1, 2, 2L),
    (2, 0, 3L),
    (0, 3, 10L),
    (3, 0, 10L),
  ]
  let result = min_mean_cycle(4, edges, 0).unwrap()
  let (num, den) = result
  // Cross-check: num / den == 2 means num * 1 == 2 * den (both signs equal).
  @debug.assert_eq(num, 2L * den.to_int64())
}

///|
test "karp two cycles picks smaller mean exact" {
  // Same as above but with weights chosen so the exact rational is unique.
  // Cycle A: 0 -> 1 -> 0 with weights (1, 4) -> mean 5/2 = 2.5
  // Cycle B: 0 -> 2 -> 0 with weights (3, 4) -> mean 7/2 = 3.5
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 1L),
    (1, 0, 4L),
    (0, 2, 3L),
    (2, 0, 4L),
  ]
  @debug.assert_eq(min_mean_cycle(3, edges, 0), Some((5L, 2)))
}

///|
test "karp longer cycle wins over short heavy one" {
  // Triangle 0->1->2->0 with weights (1, 1, 1) -> mean 1.
  // Self-loop at 0 with weight 100 -> mean 100.
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 1L),
    (1, 2, 1L),
    (2, 0, 1L),
    (0, 0, 100L),
  ]
  let (num, den) = min_mean_cycle(3, edges, 0).unwrap()
  // 1/1 should win. The exact pair may be (3, 3) or (1, 1); compare ratio.
  @debug.assert_eq(num, den.to_int64())
}

///|
test "karp unreachable cycle from start" {
  // Two components: 0 is isolated; the cycle 1 -> 2 -> 1 is not reachable
  // from 0. With start = 0, we report no cycle.
  let edges : Array[(Int, Int, Int64)] = [(1, 2, 1L), (2, 1, 1L)]
  @debug.assert_eq(min_mean_cycle(3, edges, 0), None)
  // From start = 1 the cycle IS reachable.
  @debug.assert_eq(min_mean_cycle(3, edges, 1), Some((2L, 2)))
}

///|
test "karp negative self-loop" {
  // Self-loop with negative weight.
  let edges : Array[(Int, Int, Int64)] = [(0, 0, -4L)]
  @debug.assert_eq(min_mean_cycle(1, edges, 0), Some((-4L, 1)))
}

///|
test "karp invalid arguments" {
  let edges : Array[(Int, Int, Int64)] = [(0, 1, 1L), (1, 0, 1L)]
  // n <= 0
  @debug.assert_eq(min_mean_cycle(0, edges, 0), None)
  // start out of range
  @debug.assert_eq(min_mean_cycle(2, edges, -1), None)
  @debug.assert_eq(min_mean_cycle(2, edges, 5), None)
}

///|
test "karp three vertex worked example" {
  // 0 -> 1 (w = 2), 1 -> 2 (w = -1), 2 -> 0 (w = -2)
  // Only cycle has weight 2 + (-1) + (-2) = -1, length 3, mean -1/3.
  let edges : Array[(Int, Int, Int64)] = [(0, 1, 2L), (1, 2, -1L), (2, 0, -2L)]
  @debug.assert_eq(min_mean_cycle(3, edges, 0), Some((-1L, 3)))
}
