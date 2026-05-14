// ============================================================================
// HOPCROFT'S DFA MINIMIZATION  -  Hopcroft 1971
// ============================================================================
//
// PROBLEM
//
// Given a deterministic finite automaton (DFA) over alphabet size `k`
// with `n` states, produce the **minimal** equivalent DFA -- i.e. the
// DFA with the fewest states that accepts the same language. The
// minimum is unique up to isomorphism (Myhill-Nerode).
//
// THE IDEA
//
// Two states `p`, `q` are equivalent iff for every input string `w`,
// `delta*(p, w)` is accepting iff `delta*(q, w)` is. Hopcroft's
// algorithm computes the coarsest such partition by *refinement*:
//
//   1. Start with two blocks: accepting (F) and non-accepting (Q \ F).
//   2. Maintain a worklist `W` of (block, symbol) pairs to refine by.
//   3. While W not empty:
//        Pop (A, c). For every other block B, partition B into:
//          B1 = { q in B : delta(q, c) in A }
//          B2 = { q in B : delta(q, c) not in A }
//        If both nonempty, replace B with {B1, B2} in the partition,
//        and update W (Hopcroft's trick: add the smaller of B1, B2 to
//        the worklist instead of both, which is what gets O(n log n)).
//
// COMPLEXITY
//
//   O(k * n * log n) where k is the alphabet size. The log n comes
//   from the fact that each state can be in the "smaller half" of a
//   split at most log n times -- the same telescoping argument that
//   gives small-to-large merging O(n log n) on trees.
//
// THE INVARIANT
//
//   "Two states p, q are in the same block iff they cannot yet be
//    distinguished by any string considered so far."
//
//   After termination, "considered so far" covers all strings, so
//   the partition is exactly the Myhill-Nerode equivalence.
//
// THIS PACKAGE
//
//   - `minimize(n, k, transitions, accepting) -> Array[Int]` returns
//     a map `state -> block id`, where block ids are in [0, m) with
//     `m = number of blocks in the minimal DFA`.
//   - States are integers in [0, n).
//   - `transitions[s][c]` gives the next state from `s` on symbol `c`.
//   - The start state is implicit (state 0). Unreachable states are
//     not pruned by `minimize` itself; the caller may pre-filter.

///|
/// Minimize a DFA. Returns an array `block_of` where `block_of[s]` is
/// the block id of state `s` in the minimal DFA. Block ids are
/// contiguous integers in `[0, m)` where `m` is the number of
/// equivalence classes.
///
/// ## Inputs
///
/// - `n`: number of states (must be >= 1).
/// - `k`: alphabet size (must be >= 1).
/// - `transitions`: an `n × k` matrix; `transitions[s][c]` is the
///   next state from `s` on input `c`. Every entry must be in `[0, n)`.
/// - `accepting`: a length-`n` boolean array; `accepting[s] = true`
///   iff `s` is an accepting state.
///
/// ## Example
///
/// ```moonbit nocheck
/// // Toy DFA: 3 states {0, 1, 2}, alphabet {0}, only 2 is accepting,
/// // transitions 0->1, 1->2, 2->2. States 0 and 1 are equivalent
/// // because they both need at least one more `0` to accept.
/// let bo = @hopcroft_dfa_minimization.minimize(3, 1, [[1], [2], [2]], [
///   false, false, true,
/// ])
/// // bo[0] == bo[1] != bo[2]
/// ```
pub fn minimize(
  n : Int,
  k : Int,
  transitions : Array[Array[Int]],
  accepting : Array[Bool],
) -> Array[Int] {
  // Trivial cases.
  if n <= 0 {
    return []
  }
  // Initial partition: {F, Q \ F}.
  let block_of = Array::make(n, 0)
  let mut block_count = 0
  let acc_block = 0
  let nonacc_block = 1
  let mut has_acc = false
  let mut has_nonacc = false
  for s in 0..<n {
    if accepting[s] {
      has_acc = true
    } else {
      has_nonacc = true
    }
  }
  // Assign initial blocks.
  if has_acc && has_nonacc {
    for s in 0..<n {
      block_of[s] = if accepting[s] { acc_block } else { nonacc_block }
    }
    block_count = 2
  } else {
    // Single initial block.
    block_count = 1
  }
  // Reverse-transition table: rev[c][t] = list of states s with
  // transitions[s][c] = t.
  let rev : Array[Array[Array[Int]]] = Array::makei(k, _ => {
    Array::makei(n, _ => [])
  })
  for s in 0..<n {
    for c in 0..<k {
      let t = transitions[s][c]
      rev[c][t].push(s)
    }
  }
  // Build initial worklist: for each character, add the smaller of
  // {F, Q\F}. (Standard Hopcroft optimization.)
  let in_worklist : Array[Array[Bool]] = Array::makei(block_count, _ => {
    Array::make(k, false)
  })
  let worklist : Array[(Int, Int)] = []
  if block_count == 2 {
    // Count members of each.
    let mut count_acc = 0
    for s in 0..<n {
      if accepting[s] {
        count_acc = count_acc + 1
      }
    }
    let smaller = if count_acc <= n - count_acc {
      acc_block
    } else {
      nonacc_block
    }
    for c in 0..<k {
      worklist.push((smaller, c))
      in_worklist[smaller][c] = true
    }
  }
  // Members lists for each block, kept up to date.
  let members : Array[Array[Int]] = Array::makei(block_count, _ => [])
  for s in 0..<n {
    members[block_of[s]].push(s)
  }
  // Main loop.
  while worklist.length() > 0 {
    let (a_block, c) = worklist.pop().unwrap()
    in_worklist[a_block][c] = false
    // Build X = { s : transitions[s][c] in A }.
    // We only need to consider blocks B whose intersection with X
    // is non-trivial. For each t in A, for each s in rev[c][t],
    // group by block_of[s].
    let touched : Array[Int] = []
    let by_block : @hashmap.HashMap[Int, Array[Int]] = HashMap([], capacity=16)
    for t in members[a_block] {
      for s in rev[c][t] {
        let b = block_of[s]
        match by_block.get(b) {
          Some(_) => ()
          None => {
            by_block[b] = []
            touched.push(b)
          }
        }
        by_block[b].push(s)
      }
    }
    // For each touched block B, split into (B intersect X) and (B \ X).
    for b in touched {
      let intersect = by_block.get(b).unwrap()
      // If |intersect| == |members[b]|, the block is wholly inside X;
      // no split.
      if intersect.length() == members[b].length() {
        continue
      }
      // Otherwise create a new block for `intersect`. Use whichever side
      // is smaller as the "new" block and put it on the worklist.
      let new_block_id = block_count
      block_count = block_count + 1
      members.push([])
      in_worklist.push(Array::make(k, false))
      // Move members of `intersect` from b to new_block_id.
      for s in intersect {
        block_of[s] = new_block_id
        members[new_block_id].push(s)
      }
      // Rebuild members[b] to exclude `intersect`.
      let kept : Array[Int] = []
      for s in members[b] {
        if block_of[s] == b {
          kept.push(s)
        }
      }
      members[b] = kept
      // Update worklist. For every character c', either the original
      // (b, c') is already there (in which case add (new_block_id, c')
      // too) OR add only the smaller half.
      for cc in 0..<k {
        if in_worklist[b][cc] {
          worklist.push((new_block_id, cc))
          in_worklist[new_block_id][cc] = true
        } else if members[b].length() <= members[new_block_id].length() {
          worklist.push((b, cc))
          in_worklist[b][cc] = true
        } else {
          worklist.push((new_block_id, cc))
          in_worklist[new_block_id][cc] = true
        }
      }
    }
  }
  // Normalize block ids to be contiguous in [0, m), in order of first
  // appearance from state 0 upward.
  let remap : @hashmap.HashMap[Int, Int] = HashMap([], capacity=16)
  let result = Array::make(n, 0)
  let mut next_id = 0
  for s in 0..<n {
    let b = block_of[s]
    match remap.get(b) {
      Some(id) => result[s] = id
      None => {
        remap[b] = next_id
        result[s] = next_id
        next_id = next_id + 1
      }
    }
  }
  result
}

///|
/// Number of distinct blocks (equivalence classes) in the output of
/// `minimize`.
pub fn block_count_of(block_of : Array[Int]) -> Int {
  let mut m = 0
  for b in block_of {
    if b + 1 > m {
      m = b + 1
    }
  }
  m
}

///|
test "hopcroft trivial single block" {
  let bo = minimize(1, 1, [[0]], [false])
  @debug.assert_eq(bo, [0])
  @debug.assert_eq(block_count_of(bo), 1)
}

///|
test "hopcroft accepts vs non-accepts" {
  // Two-state DFA: 0 -> 0 on '0', 0 -> 1 on '0'; only 1 is accepting.
  // (Just one symbol; states 0 and 1 are NOT equivalent since one is
  // accepting and the other is not.)
  let bo = minimize(2, 1, [[1], [1]], [false, true])
  @debug.assert_eq(block_count_of(bo), 2)
  @debug.assert_eq(bo[0] != bo[1], true)
}

///|
test "hopcroft merges chain to single accepting" {
  // 3-state chain: 0 -> 1 -> 2 -> 2, only 2 accepting.
  // States 0 and 1 are distinguishable: from 0, need at least 2 zeros;
  // from 1, need at least 1. So they are NOT equivalent.
  let bo = minimize(3, 1, [[1], [2], [2]], [false, false, true])
  @debug.assert_eq(block_count_of(bo), 3)
}

///|
test "hopcroft equivalent states get merged" {
  // 4-state DFA, alphabet {a, b}.
  //   0 --a--> 1, 0 --b--> 2
  //   1 --a--> 3, 1 --b--> 3
  //   2 --a--> 3, 2 --b--> 3
  //   3 --a--> 3, 3 --b--> 3
  // Only 3 is accepting. States 1 and 2 are equivalent (both lead to
  // accept after one step). 0 needs two steps. 3 is final.
  let bo = minimize(4, 2, [[1, 2], [3, 3], [3, 3], [3, 3]], [
    false, false, false, true,
  ])
  // Three classes: {0}, {1, 2}, {3}.
  @debug.assert_eq(block_count_of(bo), 3)
  @debug.assert_eq(bo[1], bo[2])
  @debug.assert_eq(bo[0] != bo[1], true)
  @debug.assert_eq(bo[3] != bo[1], true)
}

///|
test "hopcroft all states equivalent" {
  // DFA where every state goes to itself; no accepting states.
  let bo = minimize(5, 1, [[0], [1], [2], [3], [4]], [
    false, false, false, false, false,
  ])
  @debug.assert_eq(block_count_of(bo), 1)
}

///|
test "hopcroft already minimal" {
  // Strings over {a, b} ending in 'ab'. 3 states.
  //   0: just saw something other than 'a' (or nothing)
  //   1: just saw 'a'
  //   2: just saw "ab" -- accepting
  // delta:
  //   0 --a--> 1, 0 --b--> 0
  //   1 --a--> 1, 1 --b--> 2
  //   2 --a--> 1, 2 --b--> 0
  let bo = minimize(3, 2, [[1, 0], [1, 2], [1, 0]], [false, false, true])
  // Already minimal: 3 blocks.
  @debug.assert_eq(block_count_of(bo), 3)
}

///|
test "hopcroft two equivalent accept states" {
  // 3 states: 0 -> 1 on '0'; 1 -> 1; 2 -> 1; 1 and 2 both accepting.
  // (1 and 2 only differ in starting state; behave identically.)
  let bo = minimize(3, 1, [[1], [1], [1]], [false, true, true])
  // 1 and 2 merge.
  @debug.assert_eq(bo[1], bo[2])
  @debug.assert_eq(block_count_of(bo), 2)
}

///|
test "hopcroft block count helper" {
  @debug.assert_eq(block_count_of([0, 1, 2, 1, 0]), 3)
  @debug.assert_eq(block_count_of([0]), 1)
  @debug.assert_eq(block_count_of([]), 0)
}
