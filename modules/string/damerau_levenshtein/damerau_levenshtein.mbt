// ============================================================================
// DAMERAU-LEVENSHTEIN DISTANCE  -  Damerau 1964
// ============================================================================
//
// PROBLEM
//
// The Damerau-Levenshtein distance extends Levenshtein's edit distance
// by allowing a **transposition of two adjacent characters** as a
// single unit-cost operation. Distinct from the *optimal string
// alignment* (OSA) distance which forbids reordering a character that
// has already been touched.
//
// Two flavours are widely used:
//
//   - **Restricted (OSA) edit distance**: a substring's transpositions
//     do not commute -- each character can be part of at most one
//     transposition. The O(n*m) DP is the same as Levenshtein with one
//     extra recurrence branch.
//
//   - **True Damerau-Levenshtein**: allows any number of transpositions,
//     even involving characters edited earlier. Requires
//     O(n*m + sigma) DP with an alphabet of size sigma.
//
// THIS PACKAGE implements the **restricted (OSA)** form, which is
// the variant most often called "Damerau-Levenshtein" in practice.
//
// THE DP
//
//   d[i][j] = OSA distance between a[0..i) and b[0..j)
//   d[i][0] = i,  d[0][j] = j
//   d[i][j] = min(
//       d[i-1][j] + 1,                  -- delete a[i-1]
//       d[i][j-1] + 1,                  -- insert b[j-1]
//       d[i-1][j-1] + (a[i-1] != b[j-1])  -- substitute
//   )
//   if i >= 2 && j >= 2 && a[i-1] == b[j-2] && a[i-2] == b[j-1]:
//       d[i][j] = min(d[i][j], d[i-2][j-2] + 1)   -- transpose
//
// COMPLEXITY
//
//   Time : O(n * m)
//   Space: O(n * m) -- a 3-row rolling window suffices but adds clutter
//
// THE INVARIANT
//
//   "After processing cell (i, j), d[i'][j'] equals the OSA distance
//    of a[0..i') and b[0..j') for every (i', j') with i' <= i and
//    j' <= j."

///|
fn min3(a : Int, b : Int, c : Int) -> Int {
  let ab = if a < b { a } else { b }
  if ab < c {
    ab
  } else {
    c
  }
}

///|
/// Restricted Damerau-Levenshtein (OSA) distance between `a` and `b`,
/// each given as an `Array[Int]` of code points.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // "abcd" -> "acbd" needs only one transposition (b<->c).
///   let a = "abcd".to_array().map(c => c.to_int())
///   let b = "acbd".to_array().map(c => c.to_int())
///   @debug.assert_eq(@damerau_levenshtein.distance(a, b), 1)
/// }
/// ```
pub fn distance(a : Array[Int], b : Array[Int]) -> Int {
  let n = a.length()
  let m = b.length()
  if n == 0 {
    return m
  }
  if m == 0 {
    return n
  }
  let d = Array::makei(n + 1, _ => Array::make(m + 1, 0))
  for i in 0..<=n {
    d[i][0] = i
  }
  for j in 0..<=m {
    d[0][j] = j
  }
  for i in 1..<=n {
    for j in 1..<=m {
      let cost = if a[i - 1] == b[j - 1] { 0 } else { 1 }
      let best = min3(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost)
      d[i][j] = best
      if i >= 2 && j >= 2 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1] {
        let trans = d[i - 2][j - 2] + 1
        if trans < d[i][j] {
          d[i][j] = trans
        }
      }
    }
  }
  d[n][m]
}

///|
fn s(str : String) -> Array[Int] {
  let r : Array[Int] = []
  for c in str {
    r.push(c.to_int())
  }
  r
}

///|
test "damerau classic example" {
  // ca -> ac is one transposition (OSA = 1).
  @debug.assert_eq(distance(s("ca"), s("ac")), 1)
  // Under restricted (OSA) "ca" -> "abc" costs 3: no aligned transposition
  // is possible, so we delete + insert + insert (or substitute).
  @debug.assert_eq(distance(s("ca"), s("abc")), 3)
}

///|
test "damerau simple transposition" {
  // ab -> ba is 1 (one transposition).
  @debug.assert_eq(distance(s("ab"), s("ba")), 1)
  // abcd -> acbd is 1.
  @debug.assert_eq(distance(s("abcd"), s("acbd")), 1)
}

///|
test "damerau equal to levenshtein when no transposition helps" {
  // For these pairs no transposition helps -- result equals standard
  // edit distance.
  @debug.assert_eq(distance(s("kitten"), s("sitting")), 3)
  @debug.assert_eq(distance(s("Saturday"), s("Sunday")), 3)
}

///|
test "damerau identical" {
  @debug.assert_eq(distance(s("hello"), s("hello")), 0)
}

///|
test "damerau empty" {
  @debug.assert_eq(distance([], s("abc")), 3)
  @debug.assert_eq(distance(s("abc"), []), 3)
  @debug.assert_eq(distance([], []), 0)
}

///|
test "damerau no overlap" {
  @debug.assert_eq(distance(s("abc"), s("xyz")), 3)
}

///|
test "damerau symmetric for sets with single transposition" {
  let pairs : ReadOnlyArray[(String, String)] = [
    ("abc", "acb"),
    ("listen", "silent"),
    ("abcd", "badc"),
  ]
  for p in pairs {
    let a = s(p.0)
    let b = s(p.1)
    @debug.assert_eq(distance(a, b), distance(b, a))
  }
}

///|
test "damerau triangle-ish inequality" {
  // OSA does not strictly satisfy the triangle inequality, but here we
  // check d(a, c) <= d(a, b) + d(b, c) holds on a chosen example.
  let a = s("kitten")
  let b = s("sitting")
  let c = s("sittin")
  let lhs = distance(a, c)
  let rhs = distance(a, b) + distance(b, c)
  @debug.assert_eq(lhs <= rhs, true)
}
