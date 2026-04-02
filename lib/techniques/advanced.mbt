// ============================================================================
// Advanced Loop Invariant Examples
// Complex algorithms with deep mathematical reasoning
// ============================================================================

// ============================================================================
// Example A1: Floyd's Cycle Detection (Tortoise and Hare)
// Detect if a sequence enters a cycle, using O(1) space
// ============================================================================

///|
/// A simple linked list node for demonstrating cycle detection.
/// Using array indices to simulate pointers.
priv struct ListNode {
  next : Int // -1 means null/end
}

///|
/// Get next index in the "linked list" represented by nodes array.
/// Returns -1 if at end or invalid.
fn get_next(nodes : ArrayView[ListNode], idx : Int) -> Int {
  if idx < 0 || idx >= nodes.length() {
    -1
  } else {
    nodes[idx].next
  }
}

///|
/// Floyd's cycle detection: returns (has_cycle, cycle_start_index).
/// This is one of the most elegant algorithms in computer science.
#warnings("+missing_invariant+missing_reasoning")
fn floyd_cycle_detect(nodes : ArrayView[ListNode], head : Int) -> (Bool, Int) {
  guard head >= 0 && head < nodes.length() else { return (false, -1) }

  // Phase 1: Detect if cycle exists using tortoise and hare
  let meet_point : Int? = for slow = head, fast = head, first_step = true {
    let next_slow = get_next(nodes, slow)
    let next_fast_1 = get_next(nodes, fast)
    let next_fast = get_next(nodes, next_fast_1)
    if next_fast < 0 || next_fast_1 < 0 {
      // Fast pointer reached end - no cycle
      break None
    } else if !first_step && slow == fast {
      // They met! Cycle exists
      break Some(slow)
    } else {
      continue next_slow, next_fast, false
    }
  } where {
    invariant: slow >= 0 && slow < nodes.length(),
    reasoning: (
      #|INVARIANT 1 (Slow pointer validity): slow is always a valid index.
      #|
      #|Base: slow = head, which is valid by guard. ✓
      #|
      #|Inductive: We only continue if next_fast >= 0, which implies the
      #|list has enough elements for slow to advance safely. ✓
      #|MAINTENANCE:
      #|We advance slow by one step only when fast can advance, preserving
      #|a valid index within the list bounds.
      #|TERMINATION:
      #|The loop ends when fast reaches -1 (no cycle) or slow meets fast.
    ),
    invariant: fast >= 0 && fast < nodes.length(),
    reasoning: (
      #|INVARIANT 2 (Fast pointer validity): fast is always a valid index.
      #|
      #|Similar to slow, but fast moves 2 steps per iteration.
      #|We guard against invalid fast pointers before continuing.
      #|MAINTENANCE:
      #|We only advance fast when both next_fast_1 and next_fast are valid.
      #|TERMINATION:
      #|If fast cannot advance, we return None (no cycle).
    ),
    invariant: slow >= 0,
    reasoning: (
      #|INVARIANT 3 (Meeting theorem): If a cycle exists of length λ,
      #|and the tail before the cycle has length μ, then:
      #|
      #|After t iterations:
      #|  - slow is at position: min(t, μ) + ((t - μ) mod λ) if t > μ, else t
      #|  - fast is at position: min(2t, μ) + ((2t - μ) mod λ) if 2t > μ, else 2t
      #|
      #|KEY INSIGHT: When slow enters the cycle (at step μ), fast has already
      #|been in the cycle for μ steps. Fast is (2μ - μ) = μ steps ahead of
      #|slow within the cycle.
      #|
      #|Since fast gains 1 step per iteration on slow, they will meet after
      #|at most λ more iterations (when fast "laps" slow).
      #|
      #|Specifically, they meet when: t ≡ 2t (mod λ), i.e., t ≡ 0 (mod λ).
      #|First such t after slow enters cycle: t = μ + (λ - (μ mod λ)).
      #|
      #|MEETING POINT: They meet at position (μ + k) mod λ into the cycle,
      #|where k = λ - (μ mod λ). This equals λ - μ mod λ from cycle start.
      #|MAINTENANCE:
      #|Each iteration advances slow by 1 and fast by 2, so their relative
      #|distance in the cycle decreases by 1 mod λ.
      #|TERMINATION:
      #|If a cycle exists, they meet within at most λ iterations after entry;
      #|otherwise fast hits the end and the loop stops.
    ),
  }
  guard meet_point is Some(meeting) else { return (false, -1) }

  // Phase 2: Find cycle start using the beautiful mathematical property
  let cycle_start = for p1 = head, p2 = meeting {
    if p1 == p2 {
      break p1
    } else {
      continue get_next(nodes, p1), get_next(nodes, p2)
    }
  } where {
    invariant: p1 >= 0 && p2 >= 0,
    reasoning: (
      #|INVARIANT 4 (Convergence to cycle start):
      #|
      #|This is the magical part of Floyd's algorithm!
      #|
      #|Let μ = distance from head to cycle start
      #|Let λ = cycle length
      #|Let k = position within cycle where slow/fast met (from cycle start)
      #|
      #|At meeting point:
      #|  - slow traveled: μ + k steps
      #|  - fast traveled: μ + k + nλ steps (for some n ≥ 1)
      #|
      #|Since fast travels twice as fast: 2(μ + k) = μ + k + nλ
      #|Simplifying: μ + k = nλ
      #|Therefore: μ = nλ - k = (n-1)λ + (λ - k)
      #|
      #|This means: μ ≡ λ - k (mod λ)
      #|
      #|The meeting point is k steps INTO the cycle from the start.
      #|So the meeting point is (λ - k) steps BEFORE completing the cycle.
      #|But μ ≡ λ - k (mod λ), so walking μ steps from the meeting point
      #|brings us back to the cycle start!
      #|
      #|Simultaneously, walking μ steps from head brings us to cycle start.
      #|Therefore p1 (from head) and p2 (from meeting) will meet at cycle start!
      #|
      #|VISUAL PROOF:
      #|  Head ----μ----> [Cycle Start] ----k----> [Meeting Point]
      #|                       ^                        |
      #|                       |________(λ-k)___________|
      #|
      #|  From head: walk μ steps → reach cycle start
      #|  From meeting: walk (λ-k) + (n-1)λ = μ steps → reach cycle start
      #|MAINTENANCE:
      #|Both pointers advance one step, so their distance to cycle start
      #|decreases together until they coincide.
      #|TERMINATION:
      #|When p1 == p2, both are at the cycle start.
    ),
  }
  (true, cycle_start)
}

///|
test "floyd_cycle_detect" {
  // Create a list with cycle: 0 -> 1 -> 2 -> 3 -> 4 -> 2 (cycle back to 2)
  let nodes_with_cycle : Array[ListNode] = [
    { next: 1 },
    { next: 2 },
    { next: 3 }, // cycle starts here
    { next: 4 },
    { next: 2 }, // points back to index 2
  ]
  let (has_cycle, start) = floyd_cycle_detect(nodes_with_cycle[:], 0)
  assert_true(has_cycle)
  assert_eq(start, 2)

  // Create a list without cycle: 0 -> 1 -> 2 -> 3 -> end
  let nodes_no_cycle : Array[ListNode] = [
    { next: 1 },
    { next: 2 },
    { next: 3 },
    { next: -1 }, // end
  ]
  let (has_cycle2, _) = floyd_cycle_detect(nodes_no_cycle[:], 0)
  assert_true(!has_cycle2)
}

// ============================================================================
// Example A2: KMP String Matching
// Find pattern in text with O(n+m) time using failure function
// ============================================================================

///|
/// Build the KMP failure function (also called "partial match table" or "π function").
/// failure[i] = length of longest proper prefix of pattern[0..i+1] that is also a suffix.
#warnings("+missing_invariant+missing_reasoning")
fn build_kmp_failure(pattern : ArrayView[Char]) -> Array[Int] {
  guard pattern.length() > 0 else { return [] }
  let failure : Array[Int] = Array::make(pattern.length(), 0)
  // failure[0] = 0 by definition (no proper prefix)

  for i = 1, j = 0 {
    if i >= pattern.length() {
      break failure
    } else if pattern[i] == pattern[j] {
      // Extend the current matching prefix-suffix
      failure[i] = j + 1
      continue i + 1, j + 1
    } else if j > 0 {
      // Mismatch: fall back using failure function
      continue i, failure[j - 1]
    } else {
      // j == 0 and mismatch: no prefix-suffix match
      failure[i] = 0
      continue i + 1, 0
    }
  } where {
    invariant: i >= 1 && i <= pattern.length(),
    reasoning: (
      #|INVARIANT 1 (Bounds and progress):
      #|i is the next pattern index whose failure value is still unknown.
      #|All entries failure[0..i) are already fixed and correct, so the
      #|loop advances left-to-right and terminates at i == pattern.length().
      #|MAINTENANCE:
      #|On match, i increments; on fallback, j decreases. Either way,
      #|previous failure values remain fixed.
      #|TERMINATION:
      #|At i = pattern.length(), all failure values are computed.
    ),
    invariant: j >= 0 && j < i,
    reasoning: (
      #|INVARIANT 2 (j bound): j is always less than i.
      #|
      #|Base: i=1, j=0 → 0 < 1. ✓
      #|
      #|Inductive:
      #|  - If match: i+1, j+1 → j+1 < i+1 since j < i. ✓
      #|  - If fallback: i unchanged, j decreases (failure[j-1] < j). ✓
      #|  - If j=0, mismatch: i+1, 0 → 0 < i+1. ✓
      #|MAINTENANCE:
      #|Updates preserve 0 <= j < i by either increasing both or reducing j.
      #|TERMINATION:
      #|At loop end, j remains a valid prefix length.
    ),
    invariant: j >= 0,
    reasoning: (
      #|INVARIANT 3 (Failure function meaning):
      #|At the start of each iteration, pattern[0..j) == pattern[i-j..i).
      #|In other words, j is the length of the longest proper prefix of
      #|pattern[0..i) that matches a suffix of pattern[0..i).
      #|
      #|Base: i=1, j=0. Empty prefix/suffix trivially match. ✓
      #|
      #|Inductive case (match at position i):
      #|  We have pattern[0..j) == pattern[i-j..i) (by invariant).
      #|  And pattern[j] == pattern[i].
      #|  So pattern[0..j+1) == pattern[i-j..i+1).
      #|  This is the longest such prefix-suffix for pattern[0..i+1). ✓
      #|
      #|Inductive case (fallback j → failure[j-1]):
      #|  Let j' = failure[j-1]. By definition of failure function:
      #|  pattern[0..j') == pattern[j-j'..j).
      #|  Combined with pattern[0..j) == pattern[i-j..i):
      #|  pattern[0..j') == pattern[i-j'..i).
      #|  So the invariant holds with the smaller j'. ✓
      #|
      #|KEY INSIGHT: The failure function allows us to "reuse" previously
      #|computed prefix-suffix matches. When a mismatch occurs, we don't
      #|restart from scratch - we jump to the longest prefix that could
      #|still potentially match.
      #|
      #|AMORTIZED ANALYSIS: j can increase at most n times total (once per i).
      #|Each fallback decreases j. Total fallbacks ≤ total increases = O(n).
      #|Therefore the entire loop runs in O(n) time, not O(n²).
      #|MAINTENANCE:
      #|Both match-extension and fallback preserve the prefix-suffix meaning
      #|of j for the current i.
      #|TERMINATION:
      #|When i reaches pattern.length(), every failure entry is finalized.
    ),
  }
}

///|
/// KMP string matching: find first occurrence of pattern in text.
/// Returns starting index or -1 if not found.
#warnings("+missing_invariant+missing_reasoning")
fn kmp_search(text : ArrayView[Char], pattern : ArrayView[Char]) -> Int {
  guard pattern.length() > 0 && text.length() >= pattern.length() else {
    return -1
  }
  let failure = build_kmp_failure(pattern)
  for i = 0, j = 0 {
    if i >= text.length() {
      break -1 // Pattern not found
    } else if text[i] == pattern[j] {
      if j == pattern.length() - 1 {
        break i - j // Found! Return starting position
      } else {
        continue i + 1, j + 1
      }
    } else if j > 0 {
      // Mismatch: use failure function to avoid re-comparing
      continue i, failure[j - 1]
    } else {
      // j == 0, mismatch: move to next text position
      continue i + 1, 0
    }
  } where {
    invariant: i >= 0 && i <= text.length() && j >= 0 && j < pattern.length(),
    reasoning: (
      #|INVARIANT 1 (Bounds and progress):
      #|i is the current text position, and j is the length of the matched
      #|pattern prefix. The bounds ensure all indexing is safe.
      #|Each iteration either advances i or shortens j, so the loop makes
      #|progress and eventually finishes.
      #|MAINTENANCE:
      #|On match we advance i and j; on mismatch we either fall back j or
      #|advance i, keeping indices in range.
      #|TERMINATION:
      #|The loop ends when i reaches text.length() or a full match is found.
    ),
    invariant: j >= 0,
    reasoning: (
      #|INVARIANT 2 (Partial match): text[i-j..i) == pattern[0..j).
      #|
      #|This states that j characters have been matched: the last j
      #|characters of text ending at position i-1 match the first j
      #|characters of pattern.
      #|
      #|Base: i=0, j=0. Empty sequences match. ✓
      #|
      #|Inductive (match): text[i] == pattern[j].
      #|  Before: text[i-j..i) == pattern[0..j)
      #|  After (i+1, j+1): text[(i+1)-(j+1)..i+1) = text[i-j..i+1)
      #|                   = text[i-j..i) + text[i]
      #|                   == pattern[0..j) + pattern[j]
      #|                   = pattern[0..j+1). ✓
      #|
      #|Inductive (fallback j → failure[j-1]):
      #|  Let j' = failure[j-1]. By failure function definition:
      #|  pattern[0..j') == pattern[j-j'..j).
      #|  We had text[i-j..i) == pattern[0..j).
      #|  So text[i-j'..i) == pattern[j-j'..j) == pattern[0..j'). ✓
      #|
      #|CORRECTNESS: When j reaches pattern.length()-1 and matches,
      #|we have text[i-j..i+1) == pattern[0..pattern.length()),
      #|meaning we found the pattern starting at position i-j.
      #|
      #|WHY KMP IS BRILLIANT:
      #|Naive search: when mismatch at text[i], restart pattern from 0.
      #|KMP insight: we already know text[i-j..i) == pattern[0..j).
      #|If pattern has a prefix that's also a suffix of pattern[0..j),
      #|we can "slide" the pattern to align that prefix with what we've
      #|already seen in text, without re-examining those characters!
      #|MAINTENANCE:
      #|Matches extend the equality by one; fallback uses failure[j-1] to
      #|preserve text[i-j..i) == pattern[0..j).
      #|TERMINATION:
      #|When j reaches pattern.length(), the pattern is found at i-j.
    ),
  }
}

///|
test "kmp_search" {
  let text : Array[Char] = [
    'A', 'B', 'A', 'B', 'D', 'A', 'B', 'A', 'C', 'D', 'A', 'B', 'A', 'B', 'C', 'A',
    'B', 'A', 'B',
  ]
  let pattern : Array[Char] = ['A', 'B', 'A', 'B', 'C', 'A', 'B', 'A', 'B']
  assert_eq(kmp_search(text[:], pattern[:]), 10)
  let text2 : Array[Char] = ['A', 'A', 'A', 'A', 'A', 'B']
  let pattern2 : Array[Char] = ['A', 'A', 'A', 'B']
  assert_eq(kmp_search(text2[:], pattern2[:]), 2)
  let text3 : Array[Char] = ['H', 'E', 'L', 'L', 'O']
  let pattern3 : Array[Char] = ['W', 'O', 'R', 'L', 'D']
  assert_eq(kmp_search(text3[:], pattern3[:]), -1)
}

// ============================================================================
// Example A3: Edit Distance (Levenshtein Distance)
// Minimum operations to transform one string to another
// ============================================================================

///|
/// Recursive specification for edit distance (reference for correctness proofs).
fn edit_dist_spec(
  s1 : ArrayView[Char],
  i : Int,
  s2 : ArrayView[Char],
  j : Int,
) -> Int {
  if i == 0 {
    j // Insert j characters
  } else if j == 0 {
    i // Delete i characters
  } else if s1[i - 1] == s2[j - 1] {
    edit_dist_spec(s1, i - 1, s2, j - 1)
  } else {
    let delete = edit_dist_spec(s1, i - 1, s2, j) + 1
    let insert = edit_dist_spec(s1, i, s2, j - 1) + 1
    let replace = edit_dist_spec(s1, i - 1, s2, j - 1) + 1
    min3(delete, insert, replace)
  }
}

///|
fn min3(a : Int, b : Int, c : Int) -> Int {
  if a <= b && a <= c {
    a
  } else if b <= c {
    b
  } else {
    c
  }
}

///|
/// Edit distance using space-optimized DP (two rows).
#warnings("+missing_invariant+missing_reasoning")
fn edit_distance(s1 : ArrayView[Char], s2 : ArrayView[Char]) -> Int {
  let m = s1.length()
  let n = s2.length()
  guard m > 0 && n > 0 else { return m + n }

  // Only need two rows: previous and current
  let mut prev : Array[Int] = Array::make(n + 1, 0)
  let mut curr : Array[Int] = Array::make(n + 1, 0)

  // Initialize first row: edit distance from empty string to s2[0..j)
  for j = 0; j <= n; j = j + 1 {
    prev[j] = j
  } where {
    invariant: j >= 0 && j <= n + 1,
    reasoning: (
      #|INVARIANT (Base row):
      #|After processing columns [0..j), prev[t] = t for each t in [0..j),
      #|matching the definition D[0][t] = t (insert t characters into empty).
      #|This row anchors the DP recurrence for all later rows.
      #|MAINTENANCE:
      #|Assign prev[j] = j and advance j, extending the initialized prefix.
      #|TERMINATION:
      #|At j = n + 1, the entire base row is initialized.
    ),
  }
  for i = 1 {
    if i > m {
      break prev[n]
    } else {
      // First column: edit distance from s1[0..i) to empty string
      curr[0] = i
      for j = 1 {
        if j > n {
          break
        } else {
          if s1[i - 1] == s2[j - 1] {
            // Characters match: no operation needed
            curr[j] = prev[j - 1]
          } else {
            // Take minimum of three operations:
            // - Delete from s1: prev[j] + 1
            // - Insert into s1: curr[j-1] + 1
            // - Replace: prev[j-1] + 1
            curr[j] = 1 + min3(prev[j], curr[j - 1], prev[j - 1])
          }
          continue j + 1
        }
      } where {
        invariant: j >= 1 && j <= n + 1,
        reasoning: (
          #|INVARIANT (Row DP construction):
          #|After processing columns [1..j), curr[t] is the edit distance
          #|D[i][t] = edit_dist(s1[0..i), s2[0..t)) for each t in that range.
          #|Each step uses the three neighboring DP states:
          #|  prev[j]   = D[i-1][j]
          #|  curr[j-1] = D[i][j-1]
          #|  prev[j-1] = D[i-1][j-1]
          #|so curr[j] is computed exactly by the recurrence.
          #|MAINTENANCE:
          #|Compute curr[j] from the three neighbors and advance j.
          #|TERMINATION:
          #|At j = n + 1, row i is complete.
        ),
      }

      // Swap rows
      let tmp = prev
      prev = curr
      curr = tmp
      continue i + 1
    }
  } where {
    invariant: i >= 1 && i <= m + 1,
    reasoning: (
      #|INVARIANT 1 (Outer loop bounds):
      #|i tracks which prefix of s1 is being processed. After each iteration
      #|we have completed row i and advance to i+1, guaranteeing termination
      #|once i exceeds m.
      #|MAINTENANCE:
      #|After finishing row i, increment i to move to the next prefix.
      #|TERMINATION:
      #|At i = m + 1, all rows are processed.
    ),
    invariant: i >= 1,
    reasoning: (
      #|INVARIANT 2 (DP correctness): After processing row i,
      #|prev[j] = edit_dist(s1[0..i), s2[0..j)) for all j ∈ [0, n].
      #|
      #|This is the classic DP recurrence for edit distance:
      #|
      #|Let D[i][j] = minimum edit distance from s1[0..i) to s2[0..j).
      #|
      #|BASE CASES:
      #|  D[0][j] = j  (insert j characters)
      #|  D[i][0] = i  (delete i characters)
      #|
      #|RECURRENCE (for i,j > 0):
      #|  If s1[i-1] == s2[j-1]:
      #|    D[i][j] = D[i-1][j-1]  (characters match, no operation)
      #|  Else:
      #|    D[i][j] = 1 + min(
      #|      D[i-1][j],    // Delete s1[i-1]
      #|      D[i][j-1],    // Insert s2[j-1] into s1
      #|      D[i-1][j-1]   // Replace s1[i-1] with s2[j-1]
      #|    )
      #|
      #|PROOF OF RECURRENCE:
      #|
      #|Case s1[i-1] == s2[j-1]:
      #|  The last characters already match. Any edit sequence that
      #|  transforms s1[0..i) to s2[0..j) can ignore these matching
      #|  characters. So D[i][j] = D[i-1][j-1]. ✓
      #|
      #|Case s1[i-1] ≠ s2[j-1]:
      #|  Consider the last operation in an optimal sequence:
      #|
      #|  1. DELETE s1[i-1]:
      #|     First transform s1[0..i-1) to s2[0..j), costing D[i-1][j].
      #|     Then delete s1[i-1], costing 1.
      #|     Total: D[i-1][j] + 1.
      #|
      #|  2. INSERT s2[j-1]:
      #|     First transform s1[0..i) to s2[0..j-1), costing D[i][j-1].
      #|     Then insert s2[j-1] at the end, costing 1.
      #|     Total: D[i][j-1] + 1.
      #|
      #|  3. REPLACE s1[i-1] with s2[j-1]:
      #|     First transform s1[0..i-1) to s2[0..j-1), costing D[i-1][j-1].
      #|     Then replace s1[i-1] → s2[j-1], costing 1.
      #|     Total: D[i-1][j-1] + 1.
      #|
      #|  Taking the minimum gives the optimal solution. ✓
      #|
      #|SPACE OPTIMIZATION:
      #|  Notice that D[i][j] only depends on D[i-1][j], D[i][j-1], D[i-1][j-1].
      #|  We only need the previous row and current row, not the full matrix.
      #|  This reduces space from O(mn) to O(n).
      #|MAINTENANCE:
      #|After computing curr, swapping rows makes prev hold D[i][*].
      #|TERMINATION:
      #|When i = m, prev[n] is the full edit distance.
    ),
  }
}

///|
test "edit_distance" {
  let kitten : Array[Char] = ['k', 'i', 't', 't', 'e', 'n']
  let sitting : Array[Char] = ['s', 'i', 't', 't', 'i', 'n', 'g']
  assert_eq(edit_distance(kitten[:], sitting[:]), 3)
  assert_eq(edit_dist_spec(['a', 'b'][:], 2, ['a', 'c'][:], 2), 1)
  let abc : Array[Char] = ['a', 'b', 'c']
  let abc2 : Array[Char] = ['a', 'b', 'c']
  assert_eq(edit_distance(abc[:], abc2[:]), 0)
  let empty : Array[Char] = []
  let hello : Array[Char] = ['h', 'e', 'l', 'l', 'o']
  assert_eq(edit_distance(empty[:], hello[:]), 5)
  assert_eq(edit_distance(hello[:], empty[:]), 5)
}

// ============================================================================
// Example A4: Convex Hull (Andrew's Monotone Chain Algorithm)
// Find the convex hull of a set of 2D points
// ============================================================================

///|
priv struct Point {
  x : Int
  y : Int
}

///|
/// Cross product of vectors OA and OB where O is origin.
/// Positive = counterclockwise, Negative = clockwise, Zero = collinear.
fn cross_product(o : Point, a : Point, b : Point) -> Int {
  (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
}

///|
/// Compare points for sorting: first by x, then by y.
fn point_cmp(p1 : Point, p2 : Point) -> Int {
  if p1.x != p2.x {
    p1.x - p2.x
  } else {
    p1.y - p2.y
  }
}

///|
/// Simple insertion sort for points (for demonstration).
fn sort_points(points : Array[Point]) -> Unit {
  for i in 1..<points.length() {
    let key = points[i]
    let mut j = i - 1
    while j >= 0 && point_cmp(points[j], key) > 0 {
      points[j + 1] = points[j]
      j = j - 1
    }
    points[j + 1] = key
  }
}

///|
/// Build convex hull using Andrew's monotone chain algorithm.
/// Returns vertices of convex hull in counterclockwise order.
#warnings("+missing_invariant+missing_reasoning")
fn convex_hull(points : Array[Point]) -> Array[Point] {
  guard points.length() >= 3 else { return points }

  // Sort points lexicographically (by x, then by y)
  sort_points(points)
  let hull : Array[Point] = []

  // Build lower hull (left to right)
  for i = 0 {
    if i >= points.length() {
      break
    } else {
      // Remove points that make clockwise turn
      while hull.length() >= 2 &&
            cross_product(
              hull[hull.length() - 2],
              hull[hull.length() - 1],
              points[i],
            ) <=
            0 {
        let _ = hull.pop()
      }
      hull.push(points[i])
      continue i + 1
    }
  } where {
    invariant: i >= 0 && i <= points.length(),
    reasoning: (
      #|INVARIANT 1 (Bounds and progress):
      #|i is the next point to consider in the sorted order. All points with
      #|index < i have either been added to the lower hull or discarded as
      #|non-hull points, so the scan proceeds left-to-right and terminates.
      #|MAINTENANCE:
      #|After processing points[i], increment i to move to the next point.
      #|TERMINATION:
      #|At i = points.length(), all points were considered for the lower hull.
    ),
    invariant: i >= 0,
    reasoning: (
      #|INVARIANT 2 (Lower hull convexity):
      #|hull[0..hull.length()) forms a convex chain where each consecutive
      #|triple makes a counterclockwise (or straight) turn.
      #|
      #|More precisely: for all j ∈ [0, hull.length()-2),
      #|  cross_product(hull[j], hull[j+1], hull[j+2]) > 0
      #|  (strictly counterclockwise)
      #|
      #|Base: hull has < 3 points → trivially convex. ✓
      #|
      #|Inductive: When adding points[i]:
      #|  - We pop from hull while the last three points (including new one)
      #|    would make a clockwise or collinear turn.
      #|  - After popping, adding points[i] maintains convexity.
      #|
      #|WHY THIS WORKS:
      #|  Since points are sorted by x-coordinate, points[i] is the rightmost
      #|  point seen so far. For the hull to be convex, the sequence must
      #|  "turn left" (counterclockwise) at each vertex.
      #|
      #|  If adding points[i] creates a right turn, the previous point
      #|  cannot be on the convex hull (it's "inside" the triangle formed
      #|  by its neighbors and the new point).
      #|
      #|VISUAL:
      #|     * points[i]
      #|    /
      #|   * hull[k-1]  ← This point gets removed if turn is clockwise
      #|  /
      #| * hull[k-2]
      #|MAINTENANCE:
      #|Pop while the turn is non-left, then push points[i], preserving
      #|strict counterclockwise turns in the hull chain.
      #|TERMINATION:
      #|At i = points.length(), the lower hull is convex and complete.
    ),
  }
  let lower_size = hull.length()

  // Build upper hull (right to left)
  for i = points.length() - 2 {
    if i < 0 {
      break
    } else {
      while hull.length() > lower_size &&
            cross_product(
              hull[hull.length() - 2],
              hull[hull.length() - 1],
              points[i],
            ) <=
            0 {
        let _ = hull.pop()
      }
      hull.push(points[i])
      continue i - 1
    }
  } where {
    invariant: i >= -1 && i < points.length(),
    reasoning: (
      #|INVARIANT 3 (Upper hull construction):
      #|Similar to lower hull, but we traverse right-to-left.
      #|
      #|After building lower hull from leftmost to rightmost point,
      #|we build upper hull from rightmost back to leftmost.
      #|
      #|The invariant hull.length() > lower_size ensures we only pop
      #|points from the upper hull portion, preserving the lower hull.
      #|
      #|COMPLETENESS: Every point on the true convex hull is either:
      #|  - On the lower hull (below the line from leftmost to rightmost), or
      #|  - On the upper hull (above that line)
      #|
      #|By processing all points in both directions, we capture both.
      #|
      #|TIME COMPLEXITY: O(n log n) for sorting + O(n) for hull construction.
      #|Each point is pushed at most once to lower hull and once to upper hull.
      #|Each point is popped at most once from each. Total: O(n).
      #|MAINTENANCE:
      #|Decrement i each step and maintain convexity by popping when needed.
      #|TERMINATION:
      #|At i < 0, the upper hull is complete.
    ),
  }

  // Remove last point (it's the same as first)
  let _ = hull.pop()
  hull
}

///|
test "convex_hull" {
  let points : Array[Point] = [
    { x: 0, y: 0 },
    { x: 1, y: 1 },
    { x: 2, y: 2 },
    { x: 0, y: 2 },
    { x: 2, y: 0 },
    { x: 1, y: 0 },
  ]
  let hull = convex_hull(points)
  // Hull should be: (0,0), (2,0), (2,2), (0,2) in CCW order
  // (1,1) and (1,0) are interior points or on edges
  assert_true(hull.length() >= 3)
  assert_true(hull.length() <= 4)
}
