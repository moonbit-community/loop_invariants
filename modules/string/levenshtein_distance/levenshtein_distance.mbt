// ============================================================================
// LEVENSHTEIN DISTANCE  -  Wagner-Fischer 1974
// ============================================================================
//
// PROBLEM
//
// Given two sequences `a` of length `n` and `b` of length `m`, find
// the minimum number of single-character **insertions**, **deletions**,
// and **substitutions** to transform `a` into `b`.
//
// Levenshtein distance is the standard string-edit metric. It differs
// from Myers diff (which counts only insertions and deletions) by
// allowing substitutions at unit cost.
//
// THE DP
//
// Let `d[i][j]` = Levenshtein distance between `a[0..i)` and `b[0..j)`.
// Base cases:  d[i][0] = i,  d[0][j] = j.
//
// Recurrence:  d[i][j] = d[i-1][j-1]                     if a[i-1] == b[j-1]
//                       min(  d[i-1][j]   + 1,           (delete a[i-1])
//                             d[i][j-1]   + 1,           (insert b[j-1])
//                             d[i-1][j-1] + 1   )        (substitute)  otherwise
//
// COMPLEXITY
//
//   Time  : O(n * m)
//   Space : O(min(n, m)) using the classical two-rolling-row trick.
//
// THE INVARIANT
//
//   "After processing row i of the DP, the row d[i] is the edit
//    distance between the i-prefix of a and every prefix of b."
//
// This package returns just the distance; for the actual edit script
// see `string/myers_diff`.

///|
/// Levenshtein distance between two `Int` arrays. Use unit weights for
/// insert/delete/substitute.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   @debug.assert_eq(@levenshtein_distance.distance([1, 2, 3], [1, 4, 3]), 1)
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
  // Two-row rolling DP.
  let mut prev = Array::makei(m + 1, i => i)
  let mut cur = Array::make(m + 1, 0)
  for i in 1..<=n {
    cur[0] = i
    for j in 1..<=m {
      let cost = if a[i - 1] == b[j - 1] { 0 } else { 1 }
      let del = prev[j] + 1
      let ins = cur[j - 1] + 1
      let sub = prev[j - 1] + cost
      let mut best = del
      if ins < best {
        best = ins
      }
      if sub < best {
        best = sub
      }
      cur[j] = best
    }
    let tmp = prev
    prev = cur
    cur = tmp
  }
  prev[m]
}

///|
/// Levenshtein distance with custom unit costs.
///
/// - `cost_insert` -- cost of inserting one character into `a`
/// - `cost_delete` -- cost of deleting one character from `a`
/// - `cost_subst`  -- cost of substituting one character (0 when the chars match)
///
/// All costs must be non-negative.
pub fn distance_weighted(
  a : Array[Int],
  b : Array[Int],
  cost_insert~ : Int,
  cost_delete~ : Int,
  cost_subst~ : Int,
) -> Int {
  let n = a.length()
  let m = b.length()
  if n == 0 {
    return m * cost_insert
  }
  if m == 0 {
    return n * cost_delete
  }
  let mut prev = Array::makei(m + 1, j => j * cost_insert)
  let mut cur = Array::make(m + 1, 0)
  for i in 1..<=n {
    cur[0] = i * cost_delete
    for j in 1..<=m {
      let scost = if a[i - 1] == b[j - 1] { 0 } else { cost_subst }
      let del = prev[j] + cost_delete
      let ins = cur[j - 1] + cost_insert
      let sub = prev[j - 1] + scost
      let mut best = del
      if ins < best {
        best = ins
      }
      if sub < best {
        best = sub
      }
      cur[j] = best
    }
    let tmp = prev
    prev = cur
    cur = tmp
  }
  prev[m]
}

///|
test "levenshtein empty" {
  @debug.assert_eq(distance([], []), 0)
  @debug.assert_eq(distance([1, 2, 3], []), 3)
  @debug.assert_eq(distance([], [1, 2, 3]), 3)
}

///|
test "levenshtein identical" {
  @debug.assert_eq(distance([1, 2, 3], [1, 2, 3]), 0)
}

///|
test "levenshtein single substitution" {
  @debug.assert_eq(distance([1, 2, 3], [1, 4, 3]), 1)
}

///|
test "levenshtein kitten sitting" {
  // Classic example: kitten -> sitting has distance 3.
  //   kitten -> sitten (substitute k->s)
  //   sitten -> sittin (substitute e->i)
  //   sittin -> sitting (insert g)
  let kitten = [
    'k'.to_int(),
    'i'.to_int(),
    't'.to_int(),
    't'.to_int(),
    'e'.to_int(),
    'n'.to_int(),
  ]
  let sitting = [
    's'.to_int(),
    'i'.to_int(),
    't'.to_int(),
    't'.to_int(),
    'i'.to_int(),
    'n'.to_int(),
    'g'.to_int(),
  ]
  @debug.assert_eq(distance(kitten, sitting), 3)
}

///|
test "levenshtein no overlap" {
  @debug.assert_eq(distance([1, 2, 3], [4, 5, 6]), 3)
}

///|
test "levenshtein prefix" {
  // Inserting suffix should cost = length of suffix.
  @debug.assert_eq(distance([1, 2, 3], [1, 2, 3, 4, 5]), 2)
}

///|
test "levenshtein symmetric" {
  // L(a, b) == L(b, a) since insert and delete are dual.
  let a = [1, 2, 3, 4, 5]
  let b = [1, 3, 5, 7]
  @debug.assert_eq(distance(a, b), distance(b, a))
}

///|
test "levenshtein weighted insert costs more" {
  // Substitute-only path: kit -> cat needs 2 substitutions.
  // Insert+delete path: 3 inserts (cat) + 3 deletes (kit) = 6 unit, or
  // less under default unit costs.
  let kit = ['k'.to_int(), 'i'.to_int(), 't'.to_int()]
  let cat = ['c'.to_int(), 'a'.to_int(), 't'.to_int()]
  // Under default unit costs: 2 substitutions.
  @debug.assert_eq(distance(kit, cat), 2)
  // With expensive substitution (cost 5): 2 deletes + 2 inserts = 4 cheaper.
  @debug.assert_eq(
    distance_weighted(kit, cat, cost_insert=1, cost_delete=1, cost_subst=5),
    4,
  )
}

///|
test "levenshtein triangle inequality sanity" {
  // L(a, c) <= L(a, b) + L(b, c)
  let a = [1, 2, 3, 4]
  let b = [1, 3, 5]
  let c = [2, 4, 6, 8]
  let lac = distance(a, c)
  let lab = distance(a, b)
  let lbc = distance(b, c)
  @debug.assert_eq(lac <= lab + lbc, true)
}
