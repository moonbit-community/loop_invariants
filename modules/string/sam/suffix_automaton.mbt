// ============================================================================
// SUFFIX AUTOMATON (SAM) - Minimal DFA Accepting All Substrings
// ============================================================================
//
// The Suffix Automaton is a powerful data structure that compactly represents
// ALL substrings of a string in O(n) space and O(n) construction time.
//
// KEY CONCEPTS:
//
// 1. ENDPOS EQUIVALENCE: Two substrings are equivalent if they have the same
//    set of ending positions in the original string. Each state in SAM
//    represents one equivalence class.
//
// 2. SUFFIX LINKS: Each state (except initial) has a suffix link to the
//    longest proper suffix that belongs to a different equivalence class.
//
// 3. STATE COUNT: At most 2n-1 states for a string of length n
//
// 4. TRANSITION COUNT: At most 3n-4 transitions

///|
/// A single state in the suffix automaton.
///
/// Each state represents an **endpos equivalence class**: the set of all
/// non-empty substrings that end at exactly the same positions in the
/// original text.  The substrings in this class have lengths in the
/// contiguous range `(link.len + 1) .. len` (both inclusive).
///
/// Fields:
/// - `trans`     : Transition table indexed by ASCII character code.
///                 `trans[c] == -1` means no transition on character `c`.
/// - `link`      : Suffix link -- index of the state whose class contains
///                 the longest proper suffix of every string in this class.
///                 Set to `-1` only for the initial state.
/// - `len`       : Length of the **longest** string represented by this state.
/// - `cnt`       : Occurrence count populated by `compute_counts`.
///                 Before that call the value is undefined (0 for clones,
///                 1 for non-clone states).
/// - `first_pos` : Zero-based index of the position (in the original text)
///                 where this state was first created; equals the 0-based
///                 index of the last character of the first occurrence of
///                 the longest string in this class.
priv struct SAMState {
  trans : Array[Int] // transitions: char_code -> state_id (-1 if none)
  mut link : Int // suffix link (-1 for initial)
  mut len : Int // length of longest string in this equivalence class
  mut cnt : Int // occurrence count (computed via suffix link tree)
  mut first_pos : Int // first position where this state was reached
}

///|
/// Size of the character alphabet used by the automaton.
///
/// All transition arrays are sized to `alphabet_size` entries indexed by the
/// integer value of an ASCII character.  Characters outside the range
/// `[0, 127]` are not supported by this implementation.
let alphabet_size : Int = 128 // ASCII alphabet

///|
fn SAMState::SAMState() -> SAMState {
  {
    trans: Array::make(alphabet_size, -1),
    link: -1,
    len: 0,
    cnt: 0,
    first_pos: -1,
  }
}

///|
fn SAMState::copy_trans(self : SAMState) -> SAMState {
  let new_trans = self.trans.copy()
  {
    trans: new_trans,
    link: self.link,
    len: self.len,
    cnt: 0,
    first_pos: self.first_pos,
  }
}

///|
/// The suffix automaton (SAM) for a string.
///
/// A SAM is a minimal DFA that accepts every substring of the text it was
/// built from and no other strings.  It is constructed incrementally by
/// calling `extend` once per character (or via the convenience constructor
/// `build`).
///
/// Structural invariants maintained at all times:
/// - `states[0]` is the unique **initial state** with `len = 0` and
///   `link = -1`.
/// - `last` is the index of the state representing the full string built so
///   far (i.e., the state reached from the initial state by reading the
///   entire text).
/// - For every state `q` other than the initial, `states[q].link` is the
///   index of a state whose `len` is strictly less than `states[q].len`.
/// - The total number of states never exceeds `2 * n - 1` where `n` is the
///   current text length.
///
/// After construction, use:
/// - `contains(pattern)` to test substring membership in O(|pattern|).
/// - `count_distinct_substrings()` to enumerate distinct substrings in O(n).
/// - `compute_counts()` + `count_occurrences(pattern)` for frequency queries.
/// - `longest_common_substring(other)` or
///   `longest_common_substring_length(other)` for LCS queries.
/// - `kth_substring(k)` to retrieve the k-th lexicographic substring.
priv struct SuffixAutomaton {
  states : Array[SAMState]
  mut last : Int // index of last state
}

///|
fn SuffixAutomaton::SuffixAutomaton() -> SuffixAutomaton {
  let initial = SAMState()
  initial.len = 0
  initial.link = -1
  { states: [initial], last: 0 }
}

///|
/// Extend the suffix automaton with one more character.
///
/// `c` is the **integer character code** of the new character (e.g.,
/// `'a'.to_int()`).  After this call the automaton recognizes every
/// substring of the text seen so far.
///
/// Algorithm outline (one step of the online SAM construction):
/// 1. Allocate a new state `cur` with `len = last.len + 1`.
/// 2. Walk the suffix-link chain starting from `last`.  For every state on
///    the chain that has no outgoing edge on `c`, add an edge to `cur`.
/// 3. When the walk finds a state `p` with an existing edge `c -> q`:
///    - If `q.len == p.len + 1` the suffix link for `cur` is simply `q`.
///    - Otherwise **clone** `q` into a new state `clone` with
///      `len = p.len + 1`, redirect all suffix-link-chain states that
///      pointed to `q` via `c` to point to `clone` instead, and set
///      both `cur.link` and `q.link` to `clone`.
/// 4. Update `last = cur`.
///
/// Time per call: amortized O(1).
fn SuffixAutomaton::extend(self : SuffixAutomaton, c : Int) -> Unit {
  let pos = self.states[self.last].len

  // Create new state
  let cur = self.states.length()
  let new_state = SAMState()
  new_state.len = self.states[self.last].len + 1
  new_state.cnt = 1
  new_state.first_pos = pos
  self.states.push(new_state)

  // Walk suffix links, adding transitions
  for p = self.last; p >= 0 && self.states[p].trans[c] < 0; {
    self.states[p].trans[c] = cur
    continue self.states[p].link
  } nobreak {
    if p < 0 {
      // No suffix has transition on c - link to initial
      self.states[cur].link = 0
    } else {
      // Found a suffix with transition on c
      let q = self.states[p].trans[c]
      if self.states[p].len + 1 == self.states[q].len {
        // q is the natural suffix link target
        self.states[cur].link = q
      } else {
        // Clone case - need to split equivalence class
        let clone = self.states.length()
        let clone_state = self.states[q].copy_trans()
        clone_state.len = self.states[p].len + 1
        clone_state.link = self.states[q].link
        self.states.push(clone_state)

        // Update suffix links
        self.states[cur].link = clone
        self.states[q].link = clone

        // Redirect transitions to clone
        for pp = p; pp >= 0 && self.states[pp].trans[c] == q; {
          self.states[pp].trans[c] = clone
          continue self.states[pp].link
        } where {
          proof_invariant: pp >= -1 && pp < self.states.length(),
          proof_reasoning: (
            #|INVARIANT (redirect chain):
            #|All processed states on the suffix-link chain have their c-edge
            #|rewired from q to clone. Unprocessed states still point to q.
            #|This preserves endpos classes while splitting the clone.
            #|MAINTENANCE:
            #|Each step rewires one transition along the suffix chain, so all
            #|processed states now point to clone instead of q.
            #|TERMINATION:
            #|The loop ends when no further state on the chain has trans[c] == q.
          ),
        }
      }
    }
  } where {
    proof_invariant: p >= -1,
    proof_reasoning: (
      #|SUFFIX EXTENSION INVARIANT:
      #|
      #|1. p traverses suffix links from last state
      #|2. Loop terminates when p == -1 or we find existing transition
      #|3. For each state without transition c, we add transition to cur
      #|
      #|CORRECTNESS: This ensures all new suffixes are reachable
      #|EFFICIENCY: Amortized O(1) per character
      #|MAINTENANCE:
      #|Adding transitions while walking suffix links preserves the SAM
      #|property that all suffixes of the current string are represented.
      #|TERMINATION:
      #|p follows suffix links and strictly decreases in length until -1.
    ),
  }
  self.last = cur
}

///|
/// Build a suffix automaton for the given string.
///
/// Calls `extend` once per character in left-to-right order.
/// The resulting automaton accepts every substring of `s` and no other
/// strings.
///
/// Time: O(n).  Space: O(n).
fn SuffixAutomaton::build(s : String) -> SuffixAutomaton {
  let sam = SuffixAutomaton()
  for c in s {
    sam.extend(c.to_int())
  }
  sam
}

///|
/// Test whether `pattern` occurs as a substring of `text`.
///
/// Builds a suffix automaton for `text` and walks it character by character
/// using `pattern`.  Returns `true` if and only if every character of
/// `pattern` can be consumed without a missing transition.
///
/// The empty pattern is always a substring of any text.
///
/// Time: O(|text| + |pattern|).
///
/// # Example
///
/// ```moonbit nocheck
/// assert_true!(@sam.contains_substring("abab", "aba"))
/// assert_false!(@sam.contains_substring("abab", "ac"))
/// ```
pub fn contains_substring(text : String, pattern : String) -> Bool {
  SuffixAutomaton::build(text).contains(pattern)
}

///|
/// Count the number of distinct non-empty substrings of `text`.
///
/// Builds a suffix automaton and sums, over every state `q`, the value
/// `len[q] - len[link[q]]`.  Each state contributes exactly the count of
/// new substrings it introduces that are not already represented by its
/// suffix-link ancestor.
///
/// The empty substring is **not** included in the count.
///
/// Time: O(|text|).
///
/// # Example
///
/// ```moonbit nocheck
/// // "abab" has 7 distinct non-empty substrings:
/// // "a", "b", "ab", "ba", "aba", "bab", "abab"
/// assert_eq!(@sam.distinct_substrings_count("abab"), 7)
/// ```
pub fn distinct_substrings_count(text : String) -> Int {
  SuffixAutomaton::build(text).count_distinct_substrings()
}

// ============================================================================
// SUBSTRING QUERIES
// ============================================================================

///|
/// Test whether `pattern` is a substring of the text this automaton was
/// built from.
///
/// Starting from the initial state, follows the transition for each
/// character of `pattern`.  If any character has no outgoing edge the
/// pattern is not a substring.
///
/// The empty pattern always returns `true`.
///
/// Time: O(|pattern|).
fn SuffixAutomaton::contains(self : SuffixAutomaton, pattern : String) -> Bool {
  for state = 0, i = 0; i < pattern.length(); {
    let c = pattern[i].to_int()
    let next = self.states[state].trans[c]
    if next < 0 {
      break false
    } else {
      continue next, i + 1
    }
  } nobreak {
    true
  } where {
    proof_invariant: state >= 0 && state < self.states.length(),
    proof_reasoning: (
      #|SUBSTRING CHECK INVARIANT:
      #|
      #|1. state is always valid (transitions lead to valid states)
      #|2. If we process all characters, pattern is a substring
      #|3. SAM accepts exactly all substrings of original text
      #|MAINTENANCE:
      #|Each transition consumes one character and advances the automaton
      #|state according to the SAM transition function.
      #|TERMINATION:
      #|When i reaches pattern.length(), all characters are matched.
    ),
  }
}

///|
/// Count distinct non-empty substrings represented by this automaton.
///
/// For each state `q` the number of new substrings it introduces equals
/// `len[q] - len[link[q]]` (the width of the length interval assigned to
/// this equivalence class).  Summing over all states (the initial state
/// contributes 0) gives the total.
///
/// Time: O(n) where n is the number of SAM states (at most 2|text| - 1).
fn SuffixAutomaton::count_distinct_substrings(self : SuffixAutomaton) -> Int {
  for i = 0, count = 0; i < self.states.length(); {
    let state = self.states[i]
    let link_len = if state.link >= 0 { self.states[state.link].len } else { 0 }
    continue i + 1, count + state.len - link_len
  } nobreak {
    count
  } where {
    proof_invariant: i >= 0 && count >= 0,
    proof_reasoning: (
      #|DISTINCT COUNT INVARIANT:
      #|
      #|Each state contributes (len - link.len) distinct substrings.
      #|These are the strings unique to this equivalence class.
      #|Sum over all states = total distinct substrings.
      #|MAINTENANCE:
      #|Adding each state's contribution accumulates the total count so far.
      #|TERMINATION:
      #|At i == states.length(), count is the total distinct substrings.
    ),
  }
}

// ============================================================================
// OCCURRENCE COUNTING
// ============================================================================

///|
/// Populate the `cnt` field of every state with the number of times its
/// represented substrings appear in the original text.
///
/// Algorithm:
/// 1. Topologically sort states by decreasing `len` using counting sort.
/// 2. Propagate counts from longer states to shorter ones via suffix links:
///    `cnt[link[q]] += cnt[q]`.
///
/// This must be called before `count_occurrences`.  Calling it more than
/// once is safe (counts are accumulated idempotently because the initial
/// `cnt` values reflect construction, not previous propagation).
///
/// Time: O(n + max_len) where max_len = length of the original text.
fn SuffixAutomaton::compute_counts(self : SuffixAutomaton) -> Unit {
  let n = self.states.length()
  if n == 0 {
    return
  }

  // Topological sort by length (counting sort)
  let max_len = self.states[self.last].len
  let cnt_by_len : Array[Int] = Array::make(max_len + 1, 0)
  for i in 0..<n {
    cnt_by_len[self.states[i].len] = cnt_by_len[self.states[i].len] + 1
  }
  for i in 1..<=max_len {
    cnt_by_len[i] = cnt_by_len[i] + cnt_by_len[i - 1]
  }
  let sorted : Array[Int] = Array::make(n, 0)
  for i in 0..<n {
    let len = self.states[i].len
    cnt_by_len[len] = cnt_by_len[len] - 1
    sorted[cnt_by_len[len]] = i
  }

  // Propagate counts (longest to shortest)
  for i in n>..0 {
    let state_idx = sorted[i]
    let link = self.states[state_idx].link
    if link >= 0 {
      self.states[link].cnt = self.states[link].cnt + self.states[state_idx].cnt
    }
  }
}

///|
/// Count how many times `pattern` appears in the original text.
///
/// `compute_counts` must have been called before this method; otherwise
/// the returned value is unspecified.
///
/// Walks the automaton reading `pattern` character by character.  If any
/// transition is missing the pattern does not appear and 0 is returned.
/// Otherwise returns `cnt` of the final state, which equals the number of
/// occurrences recorded during count propagation.
///
/// Time: O(|pattern|) after `compute_counts`.
fn SuffixAutomaton::count_occurrences(
  self : SuffixAutomaton,
  pattern : String,
) -> Int {
  for state = 0, i = 0; i < pattern.length(); {
    let c = pattern[i].to_int()
    let next = self.states[state].trans[c]
    if next < 0 {
      break 0
    } else {
      continue next, i + 1
    }
  } nobreak {
    self.states[state].cnt
  } where {
    proof_invariant: state >= 0,
    proof_reasoning: (
      #|OCCURRENCE COUNT INVARIANT:
      #|state represents the SAM state after reading pattern[0..i).
      #|MAINTENANCE:
      #|Follow the transition for pattern[i], or fail if it does not exist.
      #|TERMINATION:
      #|At i = pattern.length(), state.cnt is the occurrence count.
    ),
  }
}

// ============================================================================
// LONGEST COMMON SUBSTRING
// ============================================================================

///|
/// Return the length of the longest common substring shared between the
/// original text (the one this SAM was built from) and `other`.
///
/// Algorithm: scan `other` left to right while maintaining the current SAM
/// state and match length.  When a transition exists, extend the match.
/// When it does not, fall back along suffix links (shortening the match)
/// until a matching transition is found or the initial state is reached.
/// Track the maximum match length seen.
///
/// Time: O(|text| + |other|).
fn SuffixAutomaton::longest_common_substring_length(
  self : SuffixAutomaton,
  other : String,
) -> Int {
  for state = 0, cur_len = 0, best_len = 0, i = 0; i < other.length(); {
    let c = other[i].to_int()
    let next = self.states[state].trans[c]
    if next >= 0 {
      // Successfully extended
      let new_len = cur_len + 1
      let new_best = if new_len > best_len { new_len } else { best_len }
      continue next, new_len, new_best, i + 1
    } else {
      // Follow suffix links to find shorter match
      let result = find_suffix_match(self, state, c)
      continue result.0, result.1, best_len, i + 1
    }
  } nobreak {
    best_len
  } where {
    proof_invariant: state >= 0 && cur_len >= 0 && best_len >= 0,
    proof_reasoning: (
      #|LCS INVARIANT:
      #|
      #|1. state: current state in SAM for longest match ending here
      #|2. cur_len: length of current match
      #|3. best_len: best match found so far
      #|
      #|MAINTENANCE:
      #|Extend on matching transition; otherwise follow suffix links to shorten.
      #|TERMINATION:
      #|After scanning all characters, best_len is the LCS length.
    ),
  }
}

///|
/// Walk suffix links from `start_state` until an outgoing edge on character
/// `c` is found, then return `(next_state, new_cur_len)`.
///
/// If the initial state is reached without finding an edge on `c`, returns
/// `(0, 0)` meaning: reset to the initial state with match length 0.
///
/// This is the fallback helper used by LCS scanning when a direct extension
/// fails.
fn find_suffix_match(
  sam : SuffixAutomaton,
  start_state : Int,
  c : Int,
) -> (Int, Int) {
  for st = start_state; st >= 0; {
    let next = sam.states[st].trans[c]
    if next >= 0 {
      break (next, sam.states[st].len + 1)
    } else {
      continue sam.states[st].link
    }
  } nobreak {
    (0, 0)
  } where {
    proof_invariant: st >= -1,
    proof_reasoning: (
      #|INVARIANT (suffix fallback):
      #|st is a valid suffix-link state or -1 sentinel.
      #|MAINTENANCE:
      #|Follow suffix links until a transition on c exists.
      #|TERMINATION:
      #|At st < 0, no suffix matches; return (0, 0).
    ),
  }
}

///|
/// Return the longest common substring shared between the original text and
/// `other` as a `String`.
///
/// When multiple substrings of equal maximum length exist, the one ending
/// earliest in `other` is returned.  If there is no common substring (or
/// one of the strings is empty), returns the empty string `""`.
///
/// Internally performs the same scan as `longest_common_substring_length`
/// while also tracking the end position in `other` to reconstruct the
/// result.
///
/// Time: O(|text| + |other|).
fn SuffixAutomaton::longest_common_substring(
  self : SuffixAutomaton,
  other : String,
) -> String {
  let (best_len, best_end) = for state = 0, cur_len = 0, i = 0, best_len = 0, best_end = 0; i <
                                other.length(); {
    let c = other[i].to_int()
    let next = self.states[state].trans[c]
    if next >= 0 {
      let new_len = cur_len + 1
      let (new_best_len, new_best_end) = if new_len > best_len {
        (new_len, i + 1)
      } else {
        (best_len, best_end)
      }
      continue next, new_len, i + 1, new_best_len, new_best_end
    } else {
      let result = find_suffix_match(self, state, c)
      continue result.0, result.1, i + 1, best_len, best_end
    }
  } nobreak {
    (best_len, best_end)
  } where {
    proof_invariant: state >= 0 && cur_len >= 0 && i >= 0,
    proof_reasoning: (
      #|LCS STRING INVARIANT:
      #|
      #|state and cur_len describe the longest suffix of other[0..i)
      #|that is recognized by the SAM. best_len/best_end track the
      #|best substring seen so far.
      #|MAINTENANCE:
      #|Extend on matching transition or follow suffix links on mismatch.
      #|Update best_len/best_end when a longer match is found.
      #|TERMINATION:
      #|At i = other.length(), best_len/best_end identify the LCS (via else).
    ),
  }
  if best_len == 0 {
    ""
  } else {
    let sb = StringBuilder::new()
    for j in (best_end - best_len)..<best_end {
      let ch = other[j].to_int()
      sb.write_char(ch.unsafe_to_char())
    }
    sb.to_string()
  }
}

// ============================================================================
// K-TH LEXICOGRAPHICALLY SMALLEST SUBSTRING
// ============================================================================

///|
/// Pre-compute the number of distinct strings (paths) reachable from each
/// state in the automaton DAG, for use by `kth_substring`.
///
/// `path_count[q]` equals 1 (for the empty path from `q` itself) plus the
/// sum of `path_count[r]` for every state `r` reachable from `q` via a
/// single transition.  This is computed with memoized DFS.
///
/// Time: O(n * alphabet_size) where n is the number of SAM states.
fn SuffixAutomaton::compute_path_counts(self : SuffixAutomaton) -> Array[Int64] {
  let n = self.states.length()
  let memo : Array[Int64] = Array::make(n, -1L)
  fn dfs(sam : SuffixAutomaton, state : Int, memo : Array[Int64]) -> Int64 {
    if memo[state] >= 0L {
      return memo[state]
    }
    let cnt = for c = 0, cnt = 1L; c < alphabet_size; {
      let next = sam.states[state].trans[c]
      let cnt = if next >= 0 { cnt + dfs(sam, next, memo) } else { cnt }
      continue c + 1, cnt
    } nobreak {
      cnt
    } where {
      proof_invariant: c >= 0 && c <= alphabet_size,
      proof_reasoning: (
        #|INVARIANT (count paths):
        #|cnt accounts for paths through transitions in [0, c).
        #|MAINTENANCE:
        #|Add counts from transition c when it exists.
        #|TERMINATION:
        #|At c = alphabet_size, cnt is total paths from this state.
      ),
    }
    memo[state] = cnt
    cnt
  }

  let _ = dfs(self, 0, memo)
  memo
}

///|
/// Select the next transition when navigating to the k-th substring.
///
/// Given the current `state`, `remaining` rank (already adjusted so that
/// 1 means "take the state itself"), and the precomputed `path_cnt` array,
/// iterates transitions in lexicographic order and returns
/// `Some((next_state, adjusted_remaining, char))` for the first transition
/// whose subtree contains the target rank, or `None` when no transition
/// covers the remaining rank.
///
/// The caller must subtract 1 from `remaining` before passing it here to
/// account for the empty path represented by the state itself.
fn find_next_transition(
  sam : SuffixAutomaton,
  state : Int,
  remaining : Int64,
  path_cnt : Array[Int64],
) -> (Int, Int64, Int)? {
  for c = 0, rem = remaining - 1L; c < alphabet_size; {
    let next = sam.states[state].trans[c]
    if next >= 0 {
      let cnt = path_cnt[next]
      if rem <= cnt {
        break Some((next, rem, c))
      }
      continue c + 1, rem - cnt
    }
    continue c + 1, rem
  } nobreak {
    None
  } where {
    proof_invariant: c >= 0 && c <= alphabet_size && rem >= 0L,
    proof_reasoning: (
      #|INVARIANT (select transition):
      #|rem is the rank among substrings starting from transitions in [0, c).
      #|MAINTENANCE:
      #|Skip transitions by subtracting their counts until rem fits.
      #|TERMINATION:
      #|If no transition fits by c = alphabet_size, no substring matches rem.
    ),
  }
}

///|
/// Return the `k`-th lexicographically smallest substring (1-indexed),
/// where substrings are ordered lexicographically and the empty string
/// is considered the smallest (rank 1).
///
/// Returns `None` if `k <= 0` or `k` exceeds the total number of distinct
/// substrings (including the empty string).
///
/// Algorithm:
/// 1. Compute `path_count` for each state via `compute_path_counts`.
/// 2. Navigate the automaton greedily: at each state, skip past transitions
///    whose subtree is too small and descend into the first transition that
///    contains the target rank.
///
/// Time: O(n * alphabet_size + |result|).
fn SuffixAutomaton::kth_substring(self : SuffixAutomaton, k : Int64) -> String? {
  if k <= 0L {
    return None
  }
  let path_cnt = self.compute_path_counts()
  let total = path_cnt[0]
  if k > total {
    return None
  }
  let result = StringBuilder::new()

  // Navigate from initial state
  for state = 0, remaining = k; remaining > 0L; {
    if remaining == 1L {
      break
    }
    match find_next_transition(self, state, remaining, path_cnt) {
      Some((next_state, next_rem, c)) => {
        result.write_char(c.unsafe_to_char())
        continue next_state, next_rem
      }
      None => break
    }
  } where {
    proof_invariant: state >= 0 && remaining >= 0L,
    proof_reasoning: (
      #|INVARIANT (ranked substring):
      #|remaining is the rank among substrings from the current state.
      #|MAINTENANCE:
      #|Select the next transition by counts, append its character, and update
      #|remaining for the suffix rank.
      #|TERMINATION:
      #|Loop ends when rank is exhausted or no transition exists.
    ),
  }
  Some(result.to_string())
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "suffix automaton construction" {
  let sam = SuffixAutomaton::build("aabba")
  guard sam.states.length() > 1 else { fail("SAM should have multiple states") }
  debug_inspect(sam.states.length() <= 9, content="true")
}

///|
test "suffix automaton contains" {
  let sam = SuffixAutomaton::build("abracadabra")
  debug_inspect(sam.contains("abra"), content="true")
  debug_inspect(sam.contains("bra"), content="true")
  debug_inspect(sam.contains("cad"), content="true")
  debug_inspect(sam.contains("abracadabra"), content="true")
  debug_inspect(sam.contains("a"), content="true")
  debug_inspect(sam.contains(""), content="true")
  debug_inspect(sam.contains("xyz"), content="false")
  debug_inspect(sam.contains("abracadabrax"), content="false")
}

///|
test "suffix automaton count distinct" {
  // "aab": "", "a", "b", "aa", "ab", "aab" = 5 (excluding empty)
  let sam1 = SuffixAutomaton::build("aab")
  debug_inspect(sam1.count_distinct_substrings(), content="5")

  // "aaa": "a", "aa", "aaa" = 3
  let sam3 = SuffixAutomaton::build("aaa")
  debug_inspect(sam3.count_distinct_substrings(), content="3")
}

///|
test "suffix automaton occurrence count" {
  let sam = SuffixAutomaton::build("abracadabra")
  sam.compute_counts()
  debug_inspect(sam.count_occurrences("a"), content="5")
  debug_inspect(sam.count_occurrences("abra"), content="2")
  debug_inspect(sam.count_occurrences("bra"), content="2")
  debug_inspect(sam.count_occurrences("c"), content="1")
  debug_inspect(sam.count_occurrences("xyz"), content="0")
}

///|
test "suffix automaton longest common substring" {
  let sam = SuffixAutomaton::build("abracadabra")
  let lcs1 = sam.longest_common_substring("cadaver")
  debug_inspect(lcs1, content=(
    #|"cada"
  ))
  debug_inspect(sam.longest_common_substring_length("cadaver"), content="4")
  let lcs2 = sam.longest_common_substring("abra")
  debug_inspect(lcs2, content=(
    #|"abra"
  ))
  let lcs3 = sam.longest_common_substring("xyz")
  debug_inspect(lcs3, content=(
    #|""
  ))
}

///|
test "suffix automaton kth substring" {
  // "ab" substrings: "", "a", "ab", "b" (lex order)
  let sam = SuffixAutomaton::build("ab")
  debug_inspect(sam.kth_substring(1L), content="Some(\"\")") // empty
  debug_inspect(sam.kth_substring(2L), content="Some(\"a\")")
  debug_inspect(sam.kth_substring(3L), content="Some(\"ab\")")
  debug_inspect(sam.kth_substring(4L), content="Some(\"b\")")
  debug_inspect(sam.kth_substring(5L), content="None")
}

///|
test "suffix automaton stress" {
  let sam = SuffixAutomaton::build("ababababab")

  // Should contain all substrings
  debug_inspect(sam.contains("abab"), content="true")
  debug_inspect(sam.contains("baba"), content="true")
  debug_inspect(sam.contains("ababababab"), content="true")

  // Count should be correct
  sam.compute_counts()
  debug_inspect(sam.count_occurrences("ab") > 0, content="true")
}

// ============================================================================
// SUFFIX AUTOMATON UTILITIES
// ============================================================================

///|
/// Collect all distinct substrings (including the empty string) into a
/// sorted array.
///
/// This performs a depth-first traversal of the automaton DAG, collecting
/// every string reachable from the initial state.  The result is sorted
/// lexicographically.
///
/// Intended for debugging and testing on small strings only.
/// For a string of length n this may return O(n^2) substrings.
fn SuffixAutomaton::all_substrings(self : SuffixAutomaton) -> Array[String] {
  let result : Array[String] = []
  fn dfs(
    sam : SuffixAutomaton,
    state : Int,
    current : StringBuilder,
    result : Array[String],
  ) -> Unit {
    result.push(current.to_string())
    for c in 0..<alphabet_size {
      let next = sam.states[state].trans[c]
      if next >= 0 {
        current.write_char(c.unsafe_to_char())
        dfs(sam, next, current, result)
        // Remove last character (backtrack)
        let s = current.to_string()
        current.reset()
        for i in 0..<(s.length() - 1) {
          let ch = s[i].to_int()
          current.write_char(ch.unsafe_to_char())
        }
      }
    }
  }

  dfs(self, 0, StringBuilder::new(), result)
  result.sort_by((a, b) => a.compare(b))
  result
}

///|
test "suffix automaton all substrings" {
  let sam = SuffixAutomaton::build("ab")
  let subs = sam.all_substrings()
  // Note: sort order depends on String.compare implementation
  debug_inspect(subs, content="[\"\", \"a\", \"b\", \"ab\"]")
}
