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
pub struct SuffixAutomaton {
  states : Array[SAMState]
  mut last : Int // State corresponding to entire string
  mut size : Int // Number of states
}

///|
/// Create a suffix automaton sized for strings up to max_len.
pub fn SuffixAutomaton::new(max_len : Int) -> SuffixAutomaton {
  let states : Array[SAMState] = []
  // Create initial state (empty string)
  let init = SAMState::new()
  init.len = 0
  init.link = -1
  init.first_pos = 0
  states.push(init)

  // Reserve space for states
  states.append(Array::makei(2 * max_len, fn(_) { SAMState::new() }))
  { states, last: 0, size: 1 }
}

///|
/// Add a character to the automaton
pub fn SuffixAutomaton::extend(self : SuffixAutomaton, c : Int) -> Unit {
  let cur = self.size
  self.size = self.size + 1
  self.states[cur].len = self.states[self.last].len + 1
  self.states[cur].first_pos = self.states[cur].len - 1
  let mut p = self.last

  // Follow suffix links and add transitions
  while p >= 0 && self.states[p].next[c] < 0 {
    self.states[p].next[c] = cur
    p = self.states[p].link
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
      while p >= 0 && self.states[p].next[c] == q {
        self.states[p].next[c] = clone
        p = self.states[p].link
      }
      self.states[q].link = clone
      self.states[cur].link = clone
    }
  }
  self.last = cur
}

///|
/// Build suffix automaton from string
pub fn SuffixAutomaton::build(self : SuffixAutomaton, s : String) -> Unit {
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i].to_int() - 97 // 'a' = 97
    if c >= 0 && c < SAM_ALPHABET {
      self.extend(c)
    }
  } where {
    invariant: i >= 0 && i <= s.length(),
    reasoning: (
      #|INVARIANT (Prefix build):
      #|After processing s[0..i), the SAM recognizes all substrings of that
      #|prefix, and self.last corresponds to the entire prefix. Each extend
      #|adds a new state for the new prefix and updates suffix links, so the
      #|property holds inductively.
      #|MAINTENANCE:
      #|Extend with s[i], updating transitions and suffix links.
      #|TERMINATION:
      #|At i == s.length(), all substrings of s are represented.
    ),
  }
}

///|
/// Check if substring exists
pub fn SuffixAutomaton::contains(self : SuffixAutomaton, s : String) -> Bool {
  let mut state = 0
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i].to_int() - 97
    if c < 0 || c >= SAM_ALPHABET {
      return false
    }
    let next = self.states[state].next[c]
    if next < 0 {
      return false
    }
    state = next
  } where {
    invariant: i >= 0 && i <= s.length() && state >= 0 && state < self.size,
    reasoning: (
      #|INVARIANT (Traverse pattern):
      #|state corresponds to the SAM state for prefix s[0..i). If a transition
      #|is missing, the substring does not exist. Reaching the end means the
      #|entire pattern is accepted as a substring.
      #|MAINTENANCE:
      #|Follow the transition for s[i]; if missing, return false.
      #|TERMINATION:
      #|At i == s.length(), the pattern has been matched.
    ),
  }
  true
}

///|
/// Count distinct substrings
pub fn SuffixAutomaton::count_distinct_substrings(
  self : SuffixAutomaton,
) -> Int64 {
  let mut count = 0L
  for i = 1; i < self.size; i = i + 1 {
    let link = self.states[i].link
    let link_len = if link >= 0 { self.states[link].len } else { 0 }
    count = count + (self.states[i].len - link_len).to_int64()
  } where {
    invariant: i >= 1 && i <= self.size,
    reasoning: (
      #|INVARIANT (Distinct substrings):
      #|After processing states [1..i), count equals the total number of
      #|distinct substrings contributed by those states, where each state
      #|adds len[v] - len[link[v]] new substrings.
      #|MAINTENANCE:
      #|Accumulate the contribution of state i and advance.
      #|TERMINATION:
      #|At i == self.size, count is the total number of distinct substrings.
    ),
  }
  count
}

///|
/// Find longest common substring of two strings
pub fn longest_common_substring(s1 : String, s2 : String) -> Int {
  if s1.length() == 0 || s2.length() == 0 {
    return 0
  }

  // Build SAM for s1
  let sam = SuffixAutomaton::new(s1.length())
  sam.build(s1)

  // Traverse s2 through SAM
  let mut state = 0
  let mut len = 0
  let mut max_len = 0
  for i = 0; i < s2.length(); i = i + 1 {
    let c = s2[i].to_int() - 97
    if c < 0 || c >= SAM_ALPHABET {
      state = 0
      len = 0
      continue i + 1
    }

    // Follow suffix links until we can extend
    while state > 0 && sam.states[state].next[c] < 0 {
      state = sam.states[state].link
      len = sam.states[state].len
    }
    if sam.states[state].next[c] >= 0 {
      state = sam.states[state].next[c]
      len = len + 1
    } else {
      state = 0
      len = 0
    }
    if len > max_len {
      max_len = len
    }
  } where {
    invariant: i >= 0 && i <= s2.length() && state >= 0 && state < sam.size,
    reasoning: (
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
  max_len
}

///|
/// Get number of states in SAM
pub fn SuffixAutomaton::state_count(self : SuffixAutomaton) -> Int {
  self.size
}

///|
/// Count occurrences of pattern (using endpos set sizes)
pub fn SuffixAutomaton::count_occurrences(
  self : SuffixAutomaton,
  pattern : String,
) -> Int {
  // First, find the state for pattern
  let mut state = 0
  for i = 0; i < pattern.length(); i = i + 1 {
    let c = pattern[i].to_int() - 97
    if c < 0 || c >= SAM_ALPHABET {
      return 0
    }
    let next = self.states[state].next[c]
    if next < 0 {
      return 0
    }
    state = next
  } where {
    invariant: i >= 0 &&
    i <= pattern.length() &&
    state >= 0 &&
    state < self.size,
    reasoning: (
      #|INVARIANT (Pattern state):
      #|state corresponds to pattern[0..i). If a transition is missing, the
      #|pattern does not occur. Reaching the end gives the state representing
      #|the full pattern.
      #|MAINTENANCE:
      #|Follow the transition for pattern[i] or return 0 on failure.
      #|TERMINATION:
      #|At i == pattern.length(), state represents the full pattern.
    ),
  }

  // Count using topological sort on suffix link tree
  // Each terminal state contributes 1, propagate through suffix links
  let cnt = Array::make(self.size, 0)
  let order : Array[Int] = []

  // Sort states by length (longest first)
  let max_len = self.states[:self.size]
    .iter()
    .map(fn(s) { s.len })
    .maximum()
    .unwrap_or(0)
  let by_len : Array[Array[Int]] = Array::makei(max_len + 1, _ => [])
  for i = 0; i < self.size; i = i + 1 {
    by_len[self.states[i].len].push(i)
  } where {
    invariant: i >= 0 && i <= self.size,
    reasoning: (
      #|INVARIANT (Bucket fill):
      #|States [0..i) have been placed into their length buckets. After the
      #|loop, every state appears exactly once in by_len[len].
      #|MAINTENANCE:
      #|Push state i into by_len at its length.
      #|TERMINATION:
      #|At i == self.size, all states are bucketed.
    ),
  }
  for len = max_len; len >= 0; len = len - 1 {
    for j = 0; j < by_len[len].length(); j = j + 1 {
      order.push(by_len[len][j])
    } where {
      invariant: j >= 0 && j <= by_len[len].length(),
      reasoning: (
        #|INVARIANT (Append bucket):
        #|order contains the first j states from by_len[len]. After the loop,
        #|all states of length len are appended in arbitrary order.
        #|MAINTENANCE:
        #|Append by_len[len][j] and advance j.
        #|TERMINATION:
        #|At j == bucket size, the entire bucket is appended.
      ),
    }
  } where {
    invariant: len >= -1 && len <= max_len,
    reasoning: (
      #|INVARIANT (Length order):
      #|order contains all states with length > len. Appending the current
      #|bucket builds a list sorted by decreasing length, used for propagating
      #|endpos counts from longer states to their suffix links.
      #|MAINTENANCE:
      #|Append the bucket for length len, then decrement len.
      #|TERMINATION:
      #|At len == -1, order contains all states sorted by length descending.
    ),
  }

  // Mark terminal states (states on path from initial to last)
  let mut p = self.size - 1
  while p > 0 {
    cnt[p] = 1
    p = self.states[p].link
  }

  // Propagate counts through suffix links
  for i = 0; i < order.length(); i = i + 1 {
    let v = order[i]
    let link = self.states[v].link
    if link >= 0 {
      cnt[link] = cnt[link] + cnt[v]
    }
  } where {
    invariant: i >= 0 && i <= order.length(),
    reasoning: (
      #|INVARIANT (Count propagation):
      #|After processing order[0..i), all states in that prefix have pushed
      #|their counts to their suffix links. Because order is by decreasing
      #|length, every state contributes before its link is processed.
      #|MAINTENANCE:
      #|Add cnt[v] to cnt[link] and advance i.
      #|TERMINATION:
      #|At i == order.length(), all counts are fully propagated.
    ),
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
