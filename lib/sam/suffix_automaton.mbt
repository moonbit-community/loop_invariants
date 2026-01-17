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
/// State in the suffix automaton
priv struct SAMState {
  trans : Array[Int] // transitions: char_code -> state_id (-1 if none)
  mut link : Int // suffix link (-1 for initial)
  mut len : Int // length of longest string in this equivalence class
  mut cnt : Int // occurrence count (computed via suffix link tree)
  mut first_pos : Int // first position where this state was reached
}

///|
let alphabet_size : Int = 128 // ASCII alphabet

///|
fn SAMState::new() -> SAMState {
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
/// Suffix Automaton data structure
priv struct SuffixAutomaton {
  states : Array[SAMState]
  mut last : Int // index of last state
}

///|
fn SuffixAutomaton::new() -> SuffixAutomaton {
  let initial = SAMState::new()
  initial.len = 0
  initial.link = -1
  { states: [initial], last: 0 }
}

///|
/// Extend the suffix automaton with a new character
/// This is the core algorithm that maintains all SAM invariants
fn SuffixAutomaton::extend(self : SuffixAutomaton, c : Int) -> Unit {
  let pos = self.states[self.last].len

  // Create new state
  let cur = self.states.length()
  let new_state = SAMState::new()
  new_state.len = self.states[self.last].len + 1
  new_state.cnt = 1
  new_state.first_pos = pos
  self.states.push(new_state)

  // Walk suffix links, adding transitions
  for p = self.last; p >= 0 && self.states[p].trans[c] < 0; {
    self.states[p].trans[c] = cur
    continue self.states[p].link
  } else {
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
          invariant: pp >= -1 && pp < self.states.length(),
          reasoning: (
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
    invariant: p >= -1,
    reasoning: (
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
/// Build suffix automaton from a string
fn SuffixAutomaton::build(s : String) -> SuffixAutomaton {
  let sam = SuffixAutomaton::new()
  for c in s {
    sam.extend(c.to_int())
  }
  sam
}

///|
/// Check if pattern is a substring of text using a suffix automaton.
pub fn contains_substring(text : String, pattern : String) -> Bool {
  SuffixAutomaton::build(text).contains(pattern)
}

///|
/// Count distinct substrings of text using a suffix automaton.
pub fn distinct_substrings_count(text : String) -> Int {
  SuffixAutomaton::build(text).count_distinct_substrings()
}

// ============================================================================
// SUBSTRING QUERIES
// ============================================================================

///|
/// Check if a pattern is a substring of the original text
/// Time: O(|pattern|)
fn SuffixAutomaton::contains(self : SuffixAutomaton, pattern : String) -> Bool {
  for state = 0, i = 0; i < pattern.length(); {
    let c = pattern[i].to_int()
    let next = self.states[state].trans[c]
    if next < 0 {
      break false
    } else {
      continue next, i + 1
    }
  } else {
    true
  } where {
    invariant: state >= 0 && state < self.states.length(),
    reasoning: (
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
/// Count distinct substrings (excluding empty string)
/// Time: O(n) after construction
fn SuffixAutomaton::count_distinct_substrings(self : SuffixAutomaton) -> Int {
  for i = 0, count = 0; i < self.states.length(); {
    let state = self.states[i]
    let link_len = if state.link >= 0 { self.states[state.link].len } else { 0 }
    continue i + 1, count + state.len - link_len
  } else {
    count
  } where {
    invariant: i >= 0 && count >= 0,
    reasoning: (
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
/// Compute occurrence counts for all states
fn SuffixAutomaton::compute_counts(self : SuffixAutomaton) -> Unit {
  let n = self.states.length()
  if n == 0 {
    return
  }

  // Topological sort by length (counting sort)
  let max_len = self.states[self.last].len
  let cnt_by_len : Array[Int] = Array::make(max_len + 1, 0)
  for i = 0; i < n; i = i + 1 {
    cnt_by_len[self.states[i].len] = cnt_by_len[self.states[i].len] + 1
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (count lengths):
      #|cnt_by_len holds counts for state lengths in [0, i).
      #|MAINTENANCE:
      #|Increment the bucket for state i's length.
      #|TERMINATION:
      #|At i = n, counts per length are complete.
    ),
  }
  for i = 1; i <= max_len; i = i + 1 {
    cnt_by_len[i] = cnt_by_len[i] + cnt_by_len[i - 1]
  } where {
    invariant: i >= 1 && i <= max_len + 1,
    reasoning: (
      #|INVARIANT (prefix sums):
      #|cnt_by_len[0..i) stores cumulative counts.
      #|MAINTENANCE:
      #|Accumulate cnt_by_len[i] with the previous prefix sum.
      #|TERMINATION:
      #|At i = max_len + 1, cnt_by_len holds cumulative counts for all lengths.
    ),
  }
  let sorted : Array[Int] = Array::make(n, 0)
  for i = 0; i < n; i = i + 1 {
    let len = self.states[i].len
    cnt_by_len[len] = cnt_by_len[len] - 1
    sorted[cnt_by_len[len]] = i
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (bucket sort):
      #|States in [0, i) have been placed into sorted by nondecreasing length.
      #|MAINTENANCE:
      #|Place state i into its bucket position using cnt_by_len.
      #|TERMINATION:
      #|At i = n, all states are sorted by length.
    ),
  }

  // Propagate counts (longest to shortest)
  for i in n >.. 0 {
    let state_idx = sorted[i]
    let link = self.states[state_idx].link
    if link >= 0 {
      self.states[link].cnt = self.states[link].cnt + self.states[state_idx].cnt
    }
  }
}

///|
/// Count occurrences of a pattern
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
  } else {
    self.states[state].cnt
  } where {
    invariant: state >= 0,
    reasoning: (
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
/// Find longest common substring length between original and another string
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
  } else {
    best_len
  } where {
    invariant: state >= 0 && cur_len >= 0 && best_len >= 0,
    reasoning: (
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
/// Helper to find suffix match when direct extension fails
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
  } else {
    (0, 0)
  } where {
    invariant: st >= -1,
    reasoning: (
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
/// Find the actual longest common substring
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
  } else {
    (best_len, best_end)
  } where {
    invariant: state >= 0 && cur_len >= 0 && i >= 0,
    reasoning: (
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
    for j = best_end - best_len; j < best_end; j = j + 1 {
      let ch = other[j].to_int()
      sb.write_char(ch.unsafe_to_char())
    } where {
      invariant: j >= best_end - best_len && j <= best_end,
      reasoning: (
        #|INVARIANT (build substring):
        #|sb contains other[best_end - best_len..j).
        #|MAINTENANCE:
        #|Append other[j] to extend the substring.
        #|TERMINATION:
        #|At j = best_end, sb holds the best substring.
      ),
    }
    sb.to_string()
  }
}

// ============================================================================
// K-TH LEXICOGRAPHICALLY SMALLEST SUBSTRING
// ============================================================================

///|
/// Compute path counts for k-th substring query
fn SuffixAutomaton::compute_path_counts(self : SuffixAutomaton) -> Array[Int64] {
  let n = self.states.length()
  let memo : Array[Int64] = Array::make(n, -1L)
  fn dfs(sam : SuffixAutomaton, state : Int, memo : Array[Int64]) -> Int64 {
    if memo[state] >= 0L {
      return memo[state]
    }
    let mut cnt : Int64 = 1L
    for c = 0; c < alphabet_size; c = c + 1 {
      let next = sam.states[state].trans[c]
      if next >= 0 {
        cnt = cnt + dfs(sam, next, memo)
      }
    } where {
      invariant: c >= 0 && c <= alphabet_size,
      reasoning: (
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
/// Helper: find next transition for k-th substring
/// Returns (next_state, next_remaining, char_to_add) or None if done
fn find_next_transition(
  sam : SuffixAutomaton,
  state : Int,
  remaining : Int64,
  path_cnt : Array[Int64],
) -> (Int, Int64, Int)? {
  let mut rem = remaining - 1L // Account for "stop here" option
  for c = 0; c < alphabet_size; c = c + 1 {
    let next = sam.states[state].trans[c]
    if next >= 0 {
      let cnt = path_cnt[next]
      if rem <= cnt {
        return Some((next, rem, c))
      } else {
        rem = rem - cnt
      }
    }
  } where {
    invariant: c >= 0 && c <= alphabet_size && rem >= 0L,
    reasoning: (
      #|INVARIANT (select transition):
      #|rem is the rank among substrings starting from transitions in [0, c).
      #|MAINTENANCE:
      #|Skip transitions by subtracting their counts until rem fits.
      #|TERMINATION:
      #|If no transition fits by c = alphabet_size, no substring matches rem.
    ),
  }
  None
}

///|
/// Find k-th lexicographically smallest substring (1-indexed)
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
    invariant: state >= 0 && remaining >= 0L,
    reasoning: (
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
  inspect(sam.states.length() <= 9, content="true")
}

///|
test "suffix automaton contains" {
  let sam = SuffixAutomaton::build("abracadabra")
  inspect(sam.contains("abra"), content="true")
  inspect(sam.contains("bra"), content="true")
  inspect(sam.contains("cad"), content="true")
  inspect(sam.contains("abracadabra"), content="true")
  inspect(sam.contains("a"), content="true")
  inspect(sam.contains(""), content="true")
  inspect(sam.contains("xyz"), content="false")
  inspect(sam.contains("abracadabrax"), content="false")
}

///|
test "suffix automaton count distinct" {
  // "aab": "", "a", "b", "aa", "ab", "aab" = 5 (excluding empty)
  let sam1 = SuffixAutomaton::build("aab")
  inspect(sam1.count_distinct_substrings(), content="5")

  // "aaa": "a", "aa", "aaa" = 3
  let sam3 = SuffixAutomaton::build("aaa")
  inspect(sam3.count_distinct_substrings(), content="3")
}

///|
test "suffix automaton occurrence count" {
  let sam = SuffixAutomaton::build("abracadabra")
  sam.compute_counts()
  inspect(sam.count_occurrences("a"), content="5")
  inspect(sam.count_occurrences("abra"), content="2")
  inspect(sam.count_occurrences("bra"), content="2")
  inspect(sam.count_occurrences("c"), content="1")
  inspect(sam.count_occurrences("xyz"), content="0")
}

///|
test "suffix automaton longest common substring" {
  let sam = SuffixAutomaton::build("abracadabra")
  let lcs1 = sam.longest_common_substring("cadaver")
  inspect(lcs1, content="cada")
  inspect(sam.longest_common_substring_length("cadaver"), content="4")
  let lcs2 = sam.longest_common_substring("abra")
  inspect(lcs2, content="abra")
  let lcs3 = sam.longest_common_substring("xyz")
  inspect(lcs3, content="")
}

///|
test "suffix automaton kth substring" {
  // "ab" substrings: "", "a", "ab", "b" (lex order)
  let sam = SuffixAutomaton::build("ab")
  inspect(sam.kth_substring(1L), content="Some(\"\")") // empty
  inspect(sam.kth_substring(2L), content="Some(\"a\")")
  inspect(sam.kth_substring(3L), content="Some(\"ab\")")
  inspect(sam.kth_substring(4L), content="Some(\"b\")")
  inspect(sam.kth_substring(5L), content="None")
}

///|
test "suffix automaton stress" {
  let sam = SuffixAutomaton::build("ababababab")

  // Should contain all substrings
  inspect(sam.contains("abab"), content="true")
  inspect(sam.contains("baba"), content="true")
  inspect(sam.contains("ababababab"), content="true")

  // Count should be correct
  sam.compute_counts()
  inspect(sam.count_occurrences("ab") > 0, content="true")
}

// ============================================================================
// SUFFIX AUTOMATON UTILITIES
// ============================================================================

///|
/// Get all distinct substrings (for debugging/testing small strings)
fn SuffixAutomaton::all_substrings(self : SuffixAutomaton) -> Array[String] {
  let result : Array[String] = []
  fn dfs(
    sam : SuffixAutomaton,
    state : Int,
    current : StringBuilder,
    result : Array[String],
  ) -> Unit {
    result.push(current.to_string())
    for c = 0; c < alphabet_size; c = c + 1 {
      let next = sam.states[state].trans[c]
      if next >= 0 {
        current.write_char(c.unsafe_to_char())
        dfs(sam, next, current, result)
        // Remove last character (backtrack)
        let s = current.to_string()
        current.reset()
        for i = 0; i < s.length() - 1; i = i + 1 {
          let ch = s[i].to_int()
          current.write_char(ch.unsafe_to_char())
        } where {
          invariant: i >= 0 && i <= s.length() - 1,
          reasoning: (
            #|INVARIANT (rebuild prefix):
            #|current contains the first i characters of s (excluding the last).
            #|MAINTENANCE:
            #|Append s[i] to rebuild the prefix.
            #|TERMINATION:
            #|At i = s.length() - 1, the prefix is fully rebuilt.
          ),
        }
      }
    } where {
      invariant: c >= 0 && c <= alphabet_size,
      reasoning: (
        #|INVARIANT (DFS transitions):
        #|All transitions for chars < c have been explored and backtracked.
        #|MAINTENANCE:
        #|Follow transition c, recurse, then backtrack.
        #|TERMINATION:
        #|At c = alphabet_size, all substrings from this state are generated.
      ),
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
  inspect(subs, content="[\"\", \"a\", \"b\", \"ab\"]")
}
