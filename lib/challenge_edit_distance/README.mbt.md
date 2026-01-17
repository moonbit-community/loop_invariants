# Challenge: Edit Distance (Levenshtein)

Edit distance is the minimum number of edits to transform one string into
another, using:

- insert a character
- delete a character
- substitute a character

Each operation costs 1. Matching characters cost 0.

## Problem statement

Given two strings `a` and `b`, compute the minimum number of edits required to
change `a` into `b`.

## DP definition

Let:

```
dp[i][j] = minimum edits to transform a[0..i) into b[0..j)
```

Transitions:

```
if a[i-1] == b[j-1]: cost = 0 else cost = 1

 dp[i][j] = min(
   dp[i-1][j] + 1,      // delete
   dp[i][j-1] + 1,      // insert
   dp[i-1][j-1] + cost  // substitute or match
 )
```

Base cases:

- `dp[i][0] = i` (delete all i characters)
- `dp[0][j] = j` (insert all j characters)

## Diagram: small DP table

Example: `a = "ab"`, `b = "ac"`

```
      ''  a  c
   +------------
'' | 0  1  2
 a | 1  0  1
 b | 2  1  1
```

Answer is `dp[2][2] = 1` (substitute b -> c).

## Examples

### Example 1: classic example

```mbt check
///|
test "edit distance basic" {
  let a : Array[Char] = ['k', 'i', 't', 't', 'e', 'n']
  let b : Array[Char] = ['s', 'i', 't', 't', 'i', 'n', 'g']
  let dist = @challenge_edit_distance.edit_distance(a[:], b[:])
  inspect(dist, content="3")
}
```

### Example 2: short words

```mbt check
///|
test "edit distance short" {
  let a : Array[Char] = ['f', 'l', 'a', 'w']
  let b : Array[Char] = ['l', 'a', 'w', 'n']
  let dist = @challenge_edit_distance.edit_distance(a[:], b[:])
  inspect(dist, content="2")
}
```

### Example 3: empty string

```mbt check
///|
test "edit distance empty" {
  let a : Array[Char] = []
  let b : Array[Char] = ['a', 'b', 'c']
  let dist = @challenge_edit_distance.edit_distance(a[:], b[:])
  inspect(dist, content="3")
}
```

### Example 4: longer words

```mbt check
///|
test "edit distance longer" {
  let a : Array[Char] = ['i', 'n', 't', 'e', 'n', 't', 'i', 'o', 'n']
  let b : Array[Char] = ['e', 'x', 'e', 'c', 'u', 't', 'i', 'o', 'n']
  let dist = @challenge_edit_distance.edit_distance(a[:], b[:])
  inspect(dist, content="5")
}
```

## Complexity

Let `m = len(a)`, `n = len(b)`:

- Time: O(m * n)
- Space: O(m * n) in this implementation

## Practical notes and pitfalls

- Edit distance is symmetric: dist(a, b) == dist(b, a).
- This version uses a full DP table; a rolling-row optimization can reduce
  space to O(min(m, n)).
- When characters are equal, substitution cost is 0.

## When to use it

Use edit distance when you need a precise measure of string similarity,
spelling correction, or approximate matching.
