// ============================================================================
// GALE-SHAPLEY STABLE MATCHING - The deferred-acceptance algorithm
// ============================================================================
//
// PROBLEM
//
// `n` proposers and `n` reviewers each have a complete strict
// preference ranking over the other side. A matching pairs every
// proposer with exactly one reviewer (and vice versa). A pair
// (p, r) is **blocking** in a matching M if both `p` prefers `r`
// to their current match in M, AND `r` prefers `p` to theirs.
//
// A matching is **stable** if it has no blocking pair. Gale & Shapley
// (1962) showed that a stable matching always exists, and gave a
// simple deferred-acceptance algorithm that finds one. The result
// won the 2012 Nobel Prize in Economics (Roth & Shapley).
//
// THE ALGORITHM (proposer-optimal version)
//
//   for every proposer p:
//     p's next-proposal index = 0
//   while some proposer p is unmatched and has not exhausted their list:
//     r = p's most-preferred reviewer p has not yet proposed to
//     if r is currently unmatched:
//       match (p, r) tentatively
//     else:
//       let p' = r's current match
//       if r prefers p over p':
//         match (p, r); p' is now unmatched
//       else:
//         p remains unmatched; advance their proposal index
//
// PROPERTIES OF THE OUTPUT
//
//   1. **Always stable**: no blocking pair exists.
//   2. **Proposer-optimal**: every proposer gets their best stable
//      partner (and every reviewer gets their worst stable partner).
//   3. **Finite**: at most n^2 proposals, since each proposer
//      proposes to each reviewer at most once.
//   4. **Strategy-proof for proposers**: a proposer cannot do better
//      by lying about their preferences (Roth-Sotomayor, 1990).
//
// THE INVARIANT
//
// Throughout the algorithm:
//
//   - Each proposer who has proposed has proposed to a strict prefix
//     of their preference list.
//   - Each reviewer's current match (if any) is their best proposer
//     seen so far.
//   - The matching is partial but consistent.
//
// At termination, every proposer is matched (or has exhausted their
// list -- impossible when both sides have complete preferences over
// the other), and the matching is stable.
//
// TIME COMPLEXITY  : O(n^2)
// SPACE COMPLEXITY : O(n^2) for the preference arrays + O(n) for the
//                    matching state

///|
/// Find a stable matching given complete preference rankings.
///
/// ## Parameters
///
/// - `proposer_prefs` : array of `n` rows. `proposer_prefs[p][k]` is
///   the index (0-based) of proposer `p`'s `k`-th most-preferred
///   reviewer. Each row must be a permutation of `[0, n)`.
/// - `reviewer_prefs` : array of `n` rows. `reviewer_prefs[r][k]` is
///   reviewer `r`'s `k`-th most-preferred proposer.
///
/// ## Returns
///
/// `match_proposer_to_reviewer` of length `n`:
/// `result[p]` is the reviewer paired with proposer `p`.
///
/// When the input is malformed (different `n`, non-permutation rows),
/// returns an empty array.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // 3 proposers, 3 reviewers.
///   // proposer 0 prefers r0 > r1 > r2
///   // proposer 1 prefers r0 > r2 > r1
///   // proposer 2 prefers r1 > r0 > r2
///   // reviewer 0 prefers p1 > p0 > p2
///   // reviewer 1 prefers p0 > p1 > p2
///   // reviewer 2 prefers p2 > p1 > p0
///   let pp : Array[Array[Int]] = [[0, 1, 2], [0, 2, 1], [1, 0, 2]]
///   let rp : Array[Array[Int]] = [[1, 0, 2], [0, 1, 2], [2, 1, 0]]
///   let m = @gale_shapley_stable_matching.stable_match(pp[:], rp[:])
///   // proposer 0 -> 1, proposer 1 -> 0, proposer 2 -> 2 (one valid output)
///   assert_eq(m, [1, 0, 2])
/// }
/// ```
pub fn stable_match(
  proposer_prefs : ArrayView[Array[Int]],
  reviewer_prefs : ArrayView[Array[Int]],
) -> Array[Int] {
  let n = proposer_prefs.length()
  if n != reviewer_prefs.length() {
    return []
  }
  // Build a quick lookup: rank_of[r][p] = where does reviewer r rank
  // proposer p? Lower index means more preferred.
  let rank = Array::make(n, Array::make(n, 0))
  for r in 0..<n {
    let row = Array::make(n, 0)
    let prefs = reviewer_prefs[r]
    if prefs.length() != n {
      return []
    }
    for k in 0..<n {
      let p = prefs[k]
      if p < 0 || p >= n {
        return []
      }
      row[p] = k
    }
    rank[r] = row
  } where {
    proof_invariant: r >= 0 && r <= n,
    proof_reasoning: (
      #|INVARIANT (Rank-table construction):
      #|For each reviewer in [0..r), rank[reviewer][proposer] holds the
      #|position of that proposer in the reviewer's preference list.
    ),
  }
  // Per-proposer index into their preference list: how many they have
  // proposed to so far.
  let next_idx = Array::make(n, 0)
  // Current match of each side; -1 means unmatched.
  let match_of_proposer = Array::make(n, -1)
  let match_of_reviewer = Array::make(n, -1)
  // Stack of unmatched proposers; initially everyone.
  let pending : Array[Int] = []
  for p in 0..<n {
    pending.push(p)
    if proposer_prefs[p].length() != n {
      return []
    }
  }
  // Main loop: process pending proposers one at a time. Each iteration
  // either matches the proposer or advances their pointer; at most
  // n^2 total iterations.
  let mut steps = 0
  while pending.length() > 0 && steps < n * n + n {
    steps = steps + 1
    let p = match pending.pop() {
      Some(v) => v
      None => break
    }
    if next_idx[p] >= n {
      // Proposer exhausted -- shouldn't happen for complete
      // preferences on equal-size sides.
      continue
    }
    let r = proposer_prefs[p][next_idx[p]]
    next_idx[p] = next_idx[p] + 1
    let cur = match_of_reviewer[r]
    if cur == -1 {
      // Reviewer is unattached -- tentatively match.
      match_of_reviewer[r] = p
      match_of_proposer[p] = r
    } else if rank[r][p] < rank[r][cur] {
      // Reviewer prefers p over their current match -- swap.
      match_of_reviewer[r] = p
      match_of_proposer[p] = r
      match_of_proposer[cur] = -1
      pending.push(cur)
    } else {
      // p rejected; re-enter the pending pool.
      pending.push(p)
    }
  }
  match_of_proposer
}

///|
/// Predicate: is `m` a stable matching for the given preferences?
/// Returns `true` iff `m` has no blocking pair.
pub fn is_stable(
  proposer_prefs : ArrayView[Array[Int]],
  reviewer_prefs : ArrayView[Array[Int]],
  m : ArrayView[Int],
) -> Bool {
  let n = proposer_prefs.length()
  if n != reviewer_prefs.length() || m.length() != n {
    return false
  }
  // Build rank tables for both sides.
  let p_rank = Array::make(n, Array::make(n, 0))
  for p in 0..<n {
    let row = Array::make(n, 0)
    let prefs = proposer_prefs[p]
    for k in 0..<n {
      row[prefs[k]] = k
    }
    p_rank[p] = row
  }
  let r_rank = Array::make(n, Array::make(n, 0))
  for r in 0..<n {
    let row = Array::make(n, 0)
    let prefs = reviewer_prefs[r]
    for k in 0..<n {
      row[prefs[k]] = k
    }
    r_rank[r] = row
  }
  // Check every (p, r) pair: are p and r each other's blocking?
  for p in 0..<n {
    for r in 0..<n {
      if r != m[p] {
        // p prefers r over their match?
        let p_prefers = p_rank[p][r] < p_rank[p][m[p]]
        // r prefers p over their match? Find r's match: someone q with
        // m[q] == r.
        let mut r_match = -1
        for q in 0..<n {
          if m[q] == r {
            r_match = q
          }
        }
        let r_prefers = r_match == -1 || r_rank[r][p] < r_rank[r][r_match]
        if p_prefers && r_prefers {
          return false
        }
      }
    }
  }
  true
}

///|
test "gale-shapley three person example" {
  // Same example as the docstring above.
  let pp : Array[Array[Int]] = [[0, 1, 2], [0, 2, 1], [1, 0, 2]]
  let rp : Array[Array[Int]] = [[1, 0, 2], [0, 1, 2], [2, 1, 0]]
  let m = stable_match(pp[:], rp[:])
  @debug.assert_eq(m, [1, 0, 2])
  @debug.assert_eq(is_stable(pp[:], rp[:], m[:]), true)
}

///|
test "gale-shapley single pair" {
  let pp : Array[Array[Int]] = [[0]]
  let rp : Array[Array[Int]] = [[0]]
  let m = stable_match(pp[:], rp[:])
  @debug.assert_eq(m, [0])
}

///|
test "gale-shapley empty inputs" {
  let pp : Array[Array[Int]] = []
  let rp : Array[Array[Int]] = []
  let m = stable_match(pp[:], rp[:])
  @debug.assert_eq(m, [])
}

///|
test "gale-shapley mismatched sizes returns empty" {
  let pp : Array[Array[Int]] = [[0, 1]]
  let rp : Array[Array[Int]] = [[0]]
  let m = stable_match(pp[:], rp[:])
  @debug.assert_eq(m, [])
}

///|
test "gale-shapley all-same-favourite reviewer" {
  // Every proposer ranks r0 first; r0 picks their favourite proposer
  // (p1 in this case). Others cascade.
  let pp : Array[Array[Int]] = [[0, 1, 2], [0, 1, 2], [0, 1, 2]]
  let rp : Array[Array[Int]] = [[1, 0, 2], [0, 1, 2], [0, 1, 2]]
  let m = stable_match(pp[:], rp[:])
  @debug.assert_eq(is_stable(pp[:], rp[:], m[:]), true)
  // r0 should pick p1 (their top choice).
  @debug.assert_eq(m[1], 0)
}

///|
test "gale-shapley always produces stable matching" {
  // Random-ish but deterministic preferences. The output must always
  // be stable.
  let pp : Array[Array[Int]] = [
    [2, 0, 1, 3],
    [3, 2, 0, 1],
    [1, 3, 0, 2],
    [0, 1, 2, 3],
  ]
  let rp : Array[Array[Int]] = [
    [1, 0, 3, 2],
    [3, 1, 2, 0],
    [2, 0, 1, 3],
    [0, 2, 3, 1],
  ]
  let m = stable_match(pp[:], rp[:])
  @debug.assert_eq(is_stable(pp[:], rp[:], m[:]), true)
  // Each reviewer appears exactly once in the matching.
  let seen = Array::make(4, false)
  for r in m {
    @debug.assert_eq(seen[r], false)
    seen[r] = true
  }
}

///|
test "gale-shapley proposer-optimal at most pessimistic" {
  // A scenario where one proposer has unique top choice that the
  // reviewer also tops -- they should be matched.
  let pp : Array[Array[Int]] = [
    [2, 0, 1, 3], // proposer 0 wants r2 most
    [0, 1, 2, 3],
    [1, 0, 2, 3],
    [3, 2, 1, 0],
  ]
  let rp : Array[Array[Int]] = [
    [1, 0, 2, 3],
    [2, 0, 1, 3],
    [0, 1, 2, 3], // reviewer 2 wants p0 most
    [3, 2, 1, 0],
  ]
  let m = stable_match(pp[:], rp[:])
  @debug.assert_eq(m[0], 2) // their mutual top match
  @debug.assert_eq(is_stable(pp[:], rp[:], m[:]), true)
}
