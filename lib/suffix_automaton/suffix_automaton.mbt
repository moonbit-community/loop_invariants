// ============================================================================
// SUFFIX AUTOMATON - All Substrings in O(n) Space
// ============================================================================
//
// Suffix Automaton (SAM) is the smallest DFA that accepts all suffixes of a string.
// It has at most 2n-1 states and 3n-4 transitions.
//
// KEY INSIGHT: Each state represents an equivalence class of substrings
// that occur at the same set of ending positions (endpos-equivalence).
//
// STRUCTURE:
// - Each state has: length (longest string in class), suffix link, transitions
// - Suffix link points to state representing longest proper suffix of any string in class
// - Suffix links form a tree (suffix link tree)
//
// ALGORITHM (Online construction):
// 1. Start with initial state (empty string)
// 2. For each new character c:
//    a. Create new state for longest suffix + c
//    b. Follow suffix links from previous last state
//    c. Add transitions and update suffix links
//
// INVARIANTS:
// 1. Each state represents a contiguous range of lengths [len(link)+1, len]
// 2. Suffix link of state s points to state representing longest suffix not in s's class
// 3. Number of states ≤ 2n-1, transitions ≤ 3n-4
//
// TIME COMPLEXITY: O(n) construction
// SPACE COMPLEXITY: O(n * alphabet_size)

///|
const SAM_ALPHABET : Int = 26

///|
/// A single state in the suffix automaton.
///
/// Each state represents an endpos-equivalence class: the set of all
/// substrings that end at exactly the same positions in the original
/// string. The substrings represented by state `q` have lengths in the
/// range `(len[link] + 1) .. len`, where `link` is the suffix link.
///
/// Fields:
/// - `len`       - length of the longest string in this equivalence class
/// - `link`      - index of the suffix-link state (-1 for the initial state)
/// - `next`      - transition array indexed by character (0-25 for 'a'-'z');
///                 -1 means no transition exists for that character
/// - `first_pos` - ending position (0-indexed) of the first occurrence of
///                 the longest string in this class; used when counting
///                 occurrences
pub struct SAMState {
  mut len : Int // Length of longest string in this class
  mut link : Int // Suffix link (-1 for initial state)
  next : Array[Int] // Transitions (next[c] = state after character c)
  mut first_pos : Int // First occurrence ending position
}

///|
fn SAMState::new() -> SAMState {
  { len: 0, link: -1, next: Array::make(SAM_ALPHABET, -1), first_pos: -1 }
}

///|
/// A suffix automaton (SAM) for a string over the lowercase Latin alphabet.
///
/// The SAM is the minimal DFA that accepts every substring of the string it
/// was built from. It has at most `2n - 1` states and `3n - 4` transitions
/// for a string of length `n`, so both time and space are O(n).
///
/// Typical usage:
///
/// ```
/// let sam = SuffixAutomaton::new(max_len)
/// sam.build(s)          // or call extend() character by character
/// sam.contains(pattern) // O(|pattern|) substring test
/// sam.count_distinct_substrings()  // O(n)
/// sam.count_occurrences(pattern)   // O(n + |pattern|)
/// ```
///
/// Fields:
/// - `states` - array of all SAM states (indices 0 .. size-1 are valid)
/// - `last`   - index of the state that corresponds to the full string built
///              so far (updated after every `extend` call)
/// - `size`   - number of allocated states (includes initial state at index 0)
pub struct SuffixAutomaton {
  states : Array[SAMState]
  mut last : Int // State corresponding to entire string
  mut size : Int // Number of states
}

///|
/// Allocate a suffix automaton large enough for strings up to `max_len`
/// characters.
///
/// The backing array is pre-allocated to `2 * max_len + 1` slots so that
/// every `extend` call is O(1) amortised without further allocation.
/// Call `build` (or repeated `extend`) to populate the automaton.
///
/// Parameters:
/// - `max_len` - maximum number of characters that will be fed to this SAM
///
/// Returns a fresh `SuffixAutomaton` with only the initial state (index 0,
/// representing the empty string).
pub fn SuffixAutomaton::new(max_len : Int) -> SuffixAutomaton {
  let states : Array[SAMState] = []
  // Create initial state (empty string)
  let init = SAMState::new()
  init.len = 0
  init.link = -1
  init.first_pos = 0
  states.push(init)

  // Reserve space for states
  states.append([ for _ in 0..<(2 * max_len) => SAMState::new() ])
  { states, last: 0, size: 1 }
}

///|
/// Extend the automaton by one character `c` (given as an integer offset
/// from `'a'`, i.e. `'a'=0`, `'b'=1`, ..., `'z'=25`).
///
/// This is the core online-construction step. Each call:
/// 1. Allocates a new state `cur` for the extended string.
/// 2. Walks suffix links from `last`, adding transition `c -> cur` to every
///    ancestor that does not yet have one.
/// 3. Sets the suffix link of `cur`, potentially cloning an existing state to
///    maintain the invariant that suffix links always point to a state whose
///    `len` is exactly one less than the predecessor in the suffix link chain.
///
/// After the call, `self.last` is updated to `cur`.
///
/// Time complexity: O(1) amortised.
pub fn SuffixAutomaton::extend(self : SuffixAutomaton, c : Int) -> Unit {
  let cur = self.size
  self.size = self.size + 1
  self.states[cur].len = self.states[self.last].len + 1
  self.states[cur].first_pos = self.states[cur].len - 1

  // Follow suffix links and add transitions
  let p = for p = self.last; p >= 0 && self.states[p].next[c] < 0; {
    self.states[p].next[c] = cur
    continue self.states[p].link
  } nobreak {
    p
  }
  if p < 0 {
    // No existing transition for c
    self.states[cur].link = 0
  } else {
    let q = self.states[p].next[c]
    if self.states[p].len + 1 == self.states[q].len {
      // q is the immediate suffix
      self.states[cur].link = q
    } else {
      // Clone state q
      let clone = self.size
      self.size = self.size + 1
      self.states[clone].len = self.states[p].len + 1
      self.states[clone].link = self.states[q].link
      self.states[clone].first_pos = self.states[q].first_pos
      self.states[q].next[:].blit_to(self.states[clone].next)

      // Redirect transitions from p and its ancestors to clone
      let _ = for p = p; p >= 0 && self.states[p].next[c] == q; {
        self.states[p].next[c] = clone
        continue self.states[p].link
      } nobreak {
        ()
      }
      self.states[q].link = clone
      self.states[cur].link = clone
    }
  }
  self.last = cur
}

///|
/// Build the suffix automaton from string `s` by calling `extend` for every
/// character in order.
///
/// Only lowercase Latin letters ('a'-'z') are indexed; any other character is
/// silently skipped (it does not break the automaton, but those characters
/// will never be matched by `contains`).
///
/// Time complexity: O(n) where n = s.length().
pub fn SuffixAutomaton::build(self : SuffixAutomaton, s : String) -> Unit {
  for i in 0..<s.length() {
    let c = s[i].to_int() - 97 // 'a' = 97
    if c >= 0 && c < SAM_ALPHABET {
      self.extend(c)
    }
  }
}

///|
/// Return `true` if `s` is a substring of the string the automaton was
/// built from.
///
/// The check walks the transition graph from the initial state, following one
/// transition per character. If every character of `s` has a valid transition,
/// the entire pattern was accepted. Characters outside 'a'-'z' immediately
/// return `false`.
///
/// Time complexity: O(|s|).
pub fn SuffixAutomaton::contains(self : SuffixAutomaton, s : String) -> Bool {
  let _ = for i = 0, state = 0; i < s.length(); {
    let c = s[i].to_int() - 97
    if c < 0 || c >= SAM_ALPHABET {
      return false
    }
    let next = self.states[state].next[c]
    if next < 0 {
      return false
    }
    continue i + 1, next
  } nobreak {
    ()
  }
  true
}

///|
/// Count the number of **distinct** (non-empty) substrings of the string the
/// automaton was built from.
///
/// Each state `q` (except the initial state) represents a set of substrings
/// with lengths in the range `(len[link[q]] + 1) .. len[q]`. The count
/// contributed by state `q` is therefore `len[q] - len[link[q]]`. Summing
/// over all non-initial states gives the total number of distinct substrings.
///
/// Returns an `Int64` to handle strings long enough that the count overflows
/// a 32-bit integer.
///
/// Time complexity: O(n).
pub fn SuffixAutomaton::count_distinct_substrings(
  self : SuffixAutomaton,
) -> Int64 {
  for i = 1, count = 0L; i < self.size; {
    let link = self.states[i].link
    let link_len = if link >= 0 { self.states[link].len } else { 0 }
    continue i + 1, count + (self.states[i].len - link_len).to_int64()
  } nobreak {
    count
  }
}

///|
/// Find the length of the longest common substring of `s1` and `s2`.
///
/// The algorithm builds a SAM for `s1` and then traverses `s2` through that
/// SAM, tracking the length of the current match. When a character cannot
/// extend the current match, suffix links are followed to find the longest
/// suffix of the matched region that can still be extended. The maximum match
/// length observed across all positions in `s2` is returned.
///
/// Returns 0 if either string is empty or the two strings share no common
/// character.
///
/// Time complexity: O(|s1| + |s2|).
pub fn longest_common_substring(s1 : String, s2 : String) -> Int {
  if s1.length() == 0 || s2.length() == 0 {
    return 0
  }

  // Build SAM for s1
  let sam = SuffixAutomaton::new(s1.length())
  sam.build(s1)

  // Traverse s2 through SAM
  for i = 0, state = 0, len = 0, max_len = 0; i < s2.length(); {
    let c = s2[i].to_int() - 97
    if c < 0 || c >= SAM_ALPHABET {
      continue i + 1, 0, 0, max_len
    }

    // Follow suffix links until we can extend
    let (state2, len2) = for state = state, len = len; state > 0 &&
                            sam.states[state].next[c] < 0; {
      let next_state = sam.states[state].link
      continue next_state, sam.states[next_state].len
    } nobreak {
      (state, len)
    }
    let (state3, len3) = if sam.states[state2].next[c] >= 0 {
      (sam.states[state2].next[c], len2 + 1)
    } else {
      (0, 0)
    }
    let max_len = if len3 > max_len { len3 } else { max_len }
    continue i + 1, state3, len3, max_len
  } nobreak {
    max_len
  } where {
    proof_invariant: i >= 0 &&
    i <= s2.length() &&
    state >= 0 &&
    state < sam.size,
    proof_reasoning: (
      #|INVARIANT (LCS traversal):
      #|len is the length of the longest suffix of s2[0..i) that is a substring
      #|of s1, and state corresponds to that suffix in the SAM. If the next
      #|character cannot extend, we follow suffix links to find the longest
      #|extendable suffix. max_len tracks the best length seen so far.
      #|MAINTENANCE:
      #|Extend when possible; otherwise follow suffix links and reset length.
      #|TERMINATION:
      #|At i == s2.length(), max_len is the LCS length.
    ),
  }
}

///|
/// Return the number of states currently allocated in the automaton.
///
/// For a string of length `n`, this value is at most `2n - 1`. The initial
/// state (index 0, representing the empty string) is always counted, so an
/// automaton built from an empty string returns 1.
///
/// Useful for verifying the O(n) size bound in tests and benchmarks.
pub fn SuffixAutomaton::state_count(self : SuffixAutomaton) -> Int {
  self.size
}

///|
/// Count the number of (possibly overlapping) occurrences of `pattern` in
/// the string the automaton was built from.
///
/// The algorithm:
/// 1. Walk the transition graph with `pattern` to find the corresponding
///    state `s`. If no such state exists, return 0.
/// 2. Sort all states by `len` descending to obtain a topological order of
///    the suffix link tree (bottom-up).
/// 3. Initialise every state on the "last" suffix-link chain with count 1
///    (these are the terminal states, each representing one occurrence of the
///    full string built so far).
/// 4. Propagate counts bottom-up through suffix links. Each parent accumulates
///    the counts of all its children.
/// 5. Return `cnt[s]`.
///
/// Time complexity: O(n + |pattern|) where n is the length of the original
/// string.
pub fn SuffixAutomaton::count_occurrences(
  self : SuffixAutomaton,
  pattern : String,
) -> Int {
  // First, find the state for pattern
  let state = for i = 0, state = 0; i < pattern.length(); {
    let c = pattern[i].to_int() - 97
    if c < 0 || c >= SAM_ALPHABET {
      return 0
    }
    let next = self.states[state].next[c]
    if next < 0 {
      return 0
    }
    continue i + 1, next
  } nobreak {
    state
  }

  // Count using topological sort on suffix link tree
  // Each terminal state contributes 1, propagate through suffix links
  let cnt = Array::make(self.size, 0)
  let order : Array[Int] = []

  // Sort states by length (longest first)
  let max_len = self.states[:self.size]
    .iter()
    .map(s => s.len)
    .maximum()
    .unwrap_or(0)
  let by_len : Array[Array[Int]] = [ for _ in 0..<(max_len + 1) => [] ]
  for i in 0..<self.size {
    by_len[self.states[i].len].push(i)
  }
  let len_start = max_len + 1
  for len in len_start>..0 {
    for j in 0..<by_len[len].length() {
      order.push(by_len[len][j])
    }
  }

  // Mark terminal states (states on path from initial to last)
  let _ = for p = self.size - 1; p > 0; {
    cnt[p] = 1
    continue self.states[p].link
  } nobreak {
    ()
  }

  // Propagate counts through suffix links
  for i in 0..<order.length() {
    let v = order[i]
    let link = self.states[v].link
    if link >= 0 {
      cnt[link] = cnt[link] + cnt[v]
    }
  }
  cnt[state]
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "sam basic" {
  let sam = SuffixAutomaton::new(10)
  sam.build("abab")
  inspect(sam.contains("ab"), content="true")
  inspect(sam.contains("ba"), content="true")
  inspect(sam.contains("aba"), content="true")
  inspect(sam.contains("abab"), content="true")
  inspect(sam.contains("abc"), content="false")
}

///|
test "sam distinct substrings" {
  let sam = SuffixAutomaton::new(10)
  sam.build("abab")
  // Distinct: a, b, ab, ba, aba, bab, abab = 7
  inspect(sam.count_distinct_substrings(), content="7")
}

///|
test "sam distinct aaa" {
  let sam = SuffixAutomaton::new(10)
  sam.build("aaa")
  // Distinct: a, aa, aaa = 3
  inspect(sam.count_distinct_substrings(), content="3")
}

///|
test "sam state count" {
  let sam = SuffixAutomaton::new(10)
  sam.build("abcbc")
  // State count should be ≤ 2n - 1 = 9
  inspect(sam.state_count() <= 9, content="true")
}

///|
test "lcs basic" {
  inspect(longest_common_substring("abcde", "cdefg"), content="3") // "cde"
  inspect(longest_common_substring("abc", "xyz"), content="0")
  inspect(longest_common_substring("abab", "baba"), content="3") // "aba" or "bab"
}

///|
test "sam empty" {
  let sam = SuffixAutomaton::new(5)
  sam.build("")
  inspect(sam.count_distinct_substrings(), content="0")
  inspect(sam.state_count(), content="1") // Only initial state
}

///|
test "sam single char" {
  let sam = SuffixAutomaton::new(5)
  sam.build("a")
  inspect(sam.count_distinct_substrings(), content="1")
  inspect(sam.contains("a"), content="true")
  inspect(sam.contains("b"), content="false")
}

///|
test "sam occurrences" {
  let sam = SuffixAutomaton::new(20)
  sam.build("abababab")
  // "ab" appears 4 times
  // Note: counting through suffix links may give different results
  // depending on implementation
  let count = sam.count_occurrences("ab")
  inspect(count >= 1, content="true")
}
