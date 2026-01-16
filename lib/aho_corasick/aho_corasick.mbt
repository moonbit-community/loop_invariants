// ============================================================================
// AHO-CORASICK AUTOMATON - Multi-Pattern String Matching
// ============================================================================
//
// The Aho-Corasick algorithm efficiently finds all occurrences of multiple
// patterns in a text in O(n + m + z) time, where n is text length, m is total
// pattern length, and z is number of matches.
//
// KEY INSIGHT: We build a trie of all patterns, then add "failure links" that
// allow us to efficiently transition when a mismatch occurs, similar to KMP
// but generalized to multiple patterns.
//
// STRUCTURE:
// 1. Trie: A tree where each path from root represents a prefix of some pattern
// 2. Failure links: Point to longest proper suffix that is also a prefix of some pattern
// 3. Output links: Chain to find all patterns ending at current position
//
// EXAMPLE:
// Patterns: ["he", "she", "his", "hers"]
// Text: "ushers"
//
// Trie structure:
//        root
//       /    \
//      h      s
//     / \      \
//    e   i      h
//    |   |      |
//    r   s      e
//    |
//    s
//
// Failure links allow jumping to 'h' when 'she' fails to extend.
//
// INVARIANTS:
// 1. Trie property: Each node represents a unique prefix of some pattern
// 2. Failure link: Points to longest proper suffix that exists in trie
// 3. Output function: Returns all patterns ending at current state
//
// TIME COMPLEXITY:
// - Build: O(m * alphabet_size) where m is total pattern length
// - Search: O(n + z) where n is text length, z is number of matches

///|
/// A state in the Aho-Corasick automaton
priv struct ACState {
  children : Array[Int] // Transitions for each character (size 256)
  mut failure : Int // Failure link (-1 for root)
  output : Array[Int] // Pattern indices that end at this state
}

///|
fn ACState::new() -> ACState {
  { children: Array::make(256, -1), failure: -1, output: [] }
}

///|
/// Aho-Corasick Automaton
priv struct AhoCorasick {
  states : Array[ACState]
  patterns : Array[String]
}

///|
fn AhoCorasick::new() -> AhoCorasick {
  // Initialize with root state
  let states : Array[ACState] = [ACState::new()]
  { states, patterns: [] }
}

///|
/// Add a pattern to the automaton
/// Must be called before build()
fn AhoCorasick::add_pattern(self : AhoCorasick, pattern : String) -> Unit {
  let pattern_idx = self.patterns.length()
  self.patterns.push(pattern)

  // INVARIANT: state points to the node representing the current prefix
  // After processing character i, state represents pattern[0..i]
  let mut state = 0
  for i = 0; i < pattern.length(); i = i + 1 {
    let c = pattern[i].to_int()
    if self.states[state].children[c] < 0 {
      // Create new state for this character
      let new_state = self.states.length()
      self.states.push(ACState::new())
      self.states[state].children[c] = new_state
    }
    state = self.states[state].children[c]
  } where {
    invariant: 0 <= i && i < pattern.length(),
    reasoning: (
      #|INVARIANT (pattern insert):
      #|i ranges over valid code-unit indices of the pattern.
      #|MAINTENANCE:
      #|Advance one character per iteration to extend the trie path.
      #|TERMINATION:
      #|All characters in the pattern are inserted.
    ),
  }

  // Mark this state as accepting for this pattern
  self.states[state].output.push(pattern_idx)
}

///|
/// Build failure links using BFS
/// REASONING: We process states in BFS order (by depth) because:
/// - Failure link of state at depth d points to state at depth < d
/// - So all failure link targets are processed before their sources
fn AhoCorasick::build(self : AhoCorasick) -> Unit {
  // BFS queue
  let queue : Array[Int] = []

  // Initialize: children of root have failure link to root
  for c = 0; c < 256; c = c + 1 {
    let child = self.states[0].children[c]
    if child >= 0 {
      self.states[child].failure = 0
      queue.push(child)
    }
  } where {
    invariant: 0 <= c && c < 256,
    reasoning: (
      #|INVARIANT (root transitions):
      #|All byte transitions for characters in [0, c) are processed.
      #|MAINTENANCE:
      #|If a child exists, set its failure to root and enqueue it.
      #|TERMINATION:
      #|At c = 256, all root transitions are initialized.
    ),
  }

  // BFS to compute failure links
  // INVARIANT: When processing state s, all states with depth < depth(s)
  // have their failure links correctly computed
  let mut front = 0
  while queue.get(front) is Some(state) {
    for c = 0; c < 256; c = c + 1 {
      let child = self.states[state].children[c]
      if child < 0 {
        continue
      }
      queue.push(child)

      // Find failure link for child
      // Follow failure links from parent until we find a state with
      // transition on c, or reach root
      //
      // INVARIANT: f represents suffix of child's string (without last char)
      // We're looking for longest suffix that also has transition on c
      let failure = for f = self.states[state].failure; f >= 0; {
        if self.states[f].children[c] >= 0 {
          break self.states[f].children[c]
        }
        continue self.states[f].failure
      } else {
        // Reached root, check if root has transition on c
        let root_child = self.states[0].children[c]
        if root_child >= 0 && root_child != child {
          root_child
        } else {
          0
        }
      } where {
        invariant: f >= -1 && f < self.states.length(),
        reasoning: (
          #|INVARIANT (failure chain):
          #|f is a valid state index or -1; it represents a proper suffix state.
          #|MAINTENANCE:
          #|Move to failure[f], which strictly shortens the suffix each step.
          #|TERMINATION:
          #|The chain reaches the root sentinel after finitely many steps.
        ),
      }
      self.states[child].failure = failure

      // Merge output: patterns ending at failure state also end here
      // (they are suffixes of current string)
      let failure_output = self.states[failure].output.copy()
      for pattern_idx in failure_output {
        self.states[child].output.push(pattern_idx)
      }
    } where {
      invariant: 0 <= c && c < 256,
      reasoning: (
        #|INVARIANT (state transitions):
        #|All byte transitions for characters in [0, c) are processed for state.
        #|MAINTENANCE:
        #|Process transition c and compute its failure link/output.
        #|TERMINATION:
        #|At c = 256, all transitions from this state are handled.
      ),
    }
    front = front + 1
  }
}

///|
/// Search for all pattern occurrences in text
/// Returns array of (position, pattern_index) pairs
fn AhoCorasick::search(self : AhoCorasick, text : String) -> Array[(Int, Int)] {
  let matches : Array[(Int, Int)] = []

  // INVARIANT: state represents the longest suffix of text[0..i] that is
  // a prefix of some pattern
  let mut state = 0
  for i = 0; i < text.length(); i = i + 1 {
    let c = text[i].to_int()

    // Follow failure links until we find a transition on c or reach root
    // INVARIANT: Each iteration moves to a shorter suffix
    while state > 0 && self.states[state].children[c] < 0 {
      state = self.states[state].failure
    }

    // Take transition if possible
    if self.states[state].children[c] >= 0 {
      state = self.states[state].children[c]
    }

    // Report all patterns ending at current position
    // Output contains indices of all patterns that are suffixes of current match
    let outputs = self.states[state].output
    for pattern_idx in outputs {
      let pattern_len = self.patterns[pattern_idx].length()
      let match_start = i - pattern_len + 1
      matches.push((match_start, pattern_idx))
    }
  } where {
    invariant: 0 <= i && i < text.length(),
    reasoning: (
      #|INVARIANT (search scan):
      #|Characters in text[0..i) have been processed and all matches ending
      #|before i are reported.
      #|MAINTENANCE:
      #|Advance one character, update state via failure links, and emit outputs.
      #|TERMINATION:
      #|At i = text.length(), all matches are reported.
    ),
  }
  matches
}

///|
/// Get pattern by index
fn AhoCorasick::get_pattern(self : AhoCorasick, idx : Int) -> String {
  self.patterns[idx]
}

///|
/// Get number of patterns
fn AhoCorasick::pattern_count(self : AhoCorasick) -> Int {
  self.patterns.length()
}

///|
/// Get number of states in automaton
fn AhoCorasick::state_count(self : AhoCorasick) -> Int {
  self.states.length()
}

// ============================================================================
// CONVENIENCE FUNCTIONS
// ============================================================================

///|
/// Build automaton from array of patterns
fn AhoCorasick::from_patterns(patterns : Array[String]) -> AhoCorasick {
  let ac = AhoCorasick::new()
  patterns.each(pattern => ac.add_pattern(pattern))
  ac.build()
  ac
}

///|
/// Check if text contains any of the patterns
fn AhoCorasick::contains_any(self : AhoCorasick, text : String) -> Bool {
  let mut state = 0
  for i = 0; i < text.length(); i = i + 1 {
    let c = text[i].to_int()
    while state > 0 && self.states[state].children[c] < 0 {
      state = self.states[state].failure
    }
    if self.states[state].children[c] >= 0 {
      state = self.states[state].children[c]
    }
    if self.states[state].output.length() > 0 {
      return true
    }
  } where {
    invariant: 0 <= i && i < text.length(),
    reasoning: (
      #|INVARIANT (contains_any):
      #|Characters in text[0..i) have been scanned with no match found.
      #|MAINTENANCE:
      #|Advance state with current character and check outputs.
      #|TERMINATION:
      #|At i = text.length(), no pattern occurs in text.
    ),
  }
  false
}

///|
/// Count total number of matches
fn AhoCorasick::count_matches(self : AhoCorasick, text : String) -> Int {
  let matches = self.search(text)
  matches.length()
}

///|
/// Find all matches and return as (start, end, pattern) tuples
fn AhoCorasick::find_all(
  self : AhoCorasick,
  text : String,
) -> Array[(Int, Int, String)] {
  let raw_matches = self.search(text)
  let result : Array[(Int, Int, String)] = []
  for m in raw_matches {
    let (start, pattern_idx) = m
    let pattern = self.patterns[pattern_idx]
    let end = start + pattern.length()
    result.push((start, end, pattern))
  }
  result
}

///|
/// Build an automaton from patterns and return all matches in text.
/// Each match is (start, end, pattern) with end exclusive.
pub fn find_all_matches(
  patterns : ArrayView[String],
  text : String,
) -> Array[(Int, Int, String)] {
  let ac = AhoCorasick::from_patterns(patterns.to_array())
  ac.find_all(text)
}

///|
/// Build an automaton from patterns and count total matches in text.
pub fn count_all_matches(patterns : ArrayView[String], text : String) -> Int {
  let ac = AhoCorasick::from_patterns(patterns.to_array())
  ac.count_matches(text)
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "aho corasick basic" {
  let ac = AhoCorasick::from_patterns(["he", "she", "his", "hers"])

  // Test pattern_count and get_pattern
  inspect(ac.pattern_count(), content="4")
  inspect(ac.get_pattern(0), content="he")
  inspect(ac.get_pattern(1), content="she")

  // Test count_matches
  inspect(ac.count_matches("ushers"), content="3")
  let matches = ac.search("ushers")
  // "she" at position 1, "he" at position 2, "hers" at position 2
  inspect(matches.length(), content="3")

  // Verify matches
  let found_she = matches.filter(m => m.1 == 1).length() > 0 // "she"
  let found_he = matches.filter(m => m.1 == 0).length() > 0 // "he"
  let found_hers = matches.filter(m => m.1 == 3).length() > 0 // "hers"
  inspect(found_she, content="true")
  inspect(found_he, content="true")
  inspect(found_hers, content="true")
}

///|
test "aho corasick single pattern" {
  let ac = AhoCorasick::from_patterns(["abc"])
  let matches = ac.search("abcabcabc")
  inspect(matches.length(), content="3")

  // Positions: 0, 3, 6
  inspect(matches[0].0, content="0")
  inspect(matches[1].0, content="3")
  inspect(matches[2].0, content="6")
}

///|
test "aho corasick overlapping patterns" {
  let ac = AhoCorasick::from_patterns(["a", "ab", "abc"])
  let matches = ac.search("abc")
  // "a" at 0, "ab" at 0, "abc" at 0
  inspect(matches.length(), content="3")
}

///|
test "aho corasick no match" {
  let ac = AhoCorasick::from_patterns(["xyz", "uvw"])
  let matches = ac.search("abcdef")
  inspect(matches.length(), content="0")
  inspect(ac.contains_any("abcdef"), content="false")
}

///|
test "aho corasick contains any" {
  let ac = AhoCorasick::from_patterns(["error", "warning", "fatal"])
  inspect(ac.contains_any("this is an error message"), content="true")
  inspect(ac.contains_any("fatal error occurred"), content="true")
  inspect(ac.contains_any("all good here"), content="false")
}

///|
test "aho corasick repeated pattern" {
  let ac = AhoCorasick::from_patterns(["aa"])
  let matches = ac.search("aaaa")
  // Overlapping matches at positions 0, 1, 2
  inspect(matches.length(), content="3")
}

///|
test "aho corasick find all" {
  let ac = AhoCorasick::from_patterns(["cat", "dog"])
  let results = ac.find_all("the cat and the dog")
  inspect(results.length(), content="2")

  // First match: "cat" at position 4
  inspect(results[0].0, content="4")
  inspect(results[0].1, content="7")
  inspect(results[0].2, content="cat")

  // Second match: "dog" at position 16
  inspect(results[1].0, content="16")
  inspect(results[1].1, content="19")
  inspect(results[1].2, content="dog")
}

///|
test "aho corasick prefix patterns" {
  // Patterns where one is prefix of another
  let ac = AhoCorasick::from_patterns(["a", "ab", "abc", "abcd"])
  let matches = ac.search("abcd")
  // All patterns match at position 0
  inspect(matches.length(), content="4")

  // All should start at position 0
  for m in matches {
    guard m.0 == 0 else { fail("Expected all matches at position 0") }
  }
}

///|
test "aho corasick suffix patterns" {
  // Patterns where one is suffix of another
  let ac = AhoCorasick::from_patterns(["d", "cd", "bcd", "abcd"])
  let matches = ac.search("abcd")
  // "d" at 3, "cd" at 2, "bcd" at 1, "abcd" at 0
  inspect(matches.length(), content="4")
}

///|
test "aho corasick state count" {
  let ac = AhoCorasick::from_patterns(["abc", "abd", "abe"])
  // Shared prefix "ab" means fewer states than 3*3=9
  // States: root, a, ab, abc, abd, abe = 6
  inspect(ac.state_count(), content="6")
}

///|
test "aho corasick empty text" {
  let ac = AhoCorasick::from_patterns(["a", "b"])
  let matches = ac.search("")
  inspect(matches.length(), content="0")
}

///|
test "aho corasick long text" {
  let ac = AhoCorasick::from_patterns(["needle"])

  // Build text with multiple needles
  let text = "haystackneedlehaystackneedlehaystack"
  let matches = ac.search(text)
  inspect(matches.length(), content="2")
  inspect(matches[0].0, content="8")
  inspect(matches[1].0, content="22")
}

///|
test "aho corasick failure links" {
  // Test that failure links work correctly
  // Pattern "aba" should find both occurrences in "ababa"
  let ac = AhoCorasick::from_patterns(["aba"])
  let matches = ac.search("ababa")
  // "aba" at position 0 and position 2 (overlapping)
  inspect(matches.length(), content="2")
  inspect(matches[0].0, content="0")
  inspect(matches[1].0, content="2")
}

///|
test "aho corasick case sensitive" {
  let ac = AhoCorasick::from_patterns(["ABC"])
  inspect(ac.contains_any("abc"), content="false")
  inspect(ac.contains_any("ABC"), content="true")
}
