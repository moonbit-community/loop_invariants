# Minimum Cyclic Rotation (Booth's Algorithm)

This package finds the **lexicographically smallest rotation** of a string.
It uses **Booth's algorithm**, which runs in O(n) time and O(n) space.

If you imagine the string written on a ring, you can cut the ring at any
position to read a rotation. The minimum cyclic rotation is the cut that gives
the smallest string in dictionary order.

## 1. Problem statement

Given a string `s` of length `n`, there are exactly `n` rotations.  Rotation
`i` is formed by taking the substring `s[i..n)` followed by `s[0..i)`.

```
s = "baca"   (n = 4)

 index | rotation | characters
-------+----------+------------
     0 | rot(0)   | b a c a
     1 | rot(1)   | a c a b
     2 | rot(2)   | c a b a
     3 | rot(3)   | a b a c   <-- lexicographic minimum
```

The minimum cyclic rotation is `"abac"` (start index `3`).

If there are ties (e.g. `"abab"`), the algorithm returns the **smallest start
index** among all minimal rotations.

## 2. Visualizing rotations as a ring

```
String on a ring:

       b (0)
      /     \
  a (3)     a (1)
      \     /
       c (2)

Cutting the ring at each index produces one rotation:

  cut at 0:  b | a c a   -->  b a c a
  cut at 1:  a | c a b   -->  a c a b
  cut at 2:  c | a b a   -->  c a b a
  cut at 3:  a | b a c   -->  a b a c   (smallest)
```

## 3. What this package provides

From `pkg.generated.mbti`:

- `min_cyclic_rotation(s : String) -> String`
- `min_cyclic_rotation_index(s : String) -> Int`

Behavior on edge cases:

- Empty string: rotation is `""`, index is `0`.
- Single character: rotation is the same character, index is `0`.

## 4. All rotations of "caaab" (five-character example)

```
s = "caaab"   (n = 5)

 index | rotation  | characters
-------+-----------+------------
     0 | rot(0)    | c a a a b
     1 | rot(1)    | a a a b c   <-- lexicographic minimum
     2 | rot(2)    | a a b c a
     3 | rot(3)    | a b c a a
     4 | rot(4)    | b c a a a

Lexicographic comparison:
  rot(1) = "aaabc"
  rot(2) = "aabca"   "aab..." > "aaa..."
  rot(3) = "abcaa"   "ab..."  > "aa..."
  rot(4) = "bcaaa"   "b..."   > "a..."
  rot(0) = "caaab"   "c..."   > "b..."

Winner: index 1
```

## 5. Why Booth's algorithm works (intuition)

The naive approach compares all n rotations and takes O(n^2) time in the worst
case.  Booth's algorithm maintains two candidate rotation starts, `i` and `j`,
and a common-prefix length `k`:

- Compare `s[(i+k) mod n]` against `s[(j+k) mod n]` in the doubled string.
- As long as characters are equal, extend `k` by one.
- On a mismatch:
  - If `s[i+k] > s[j+k]`, then rotations `i, i+1, ..., i+k` are all at least
    as bad as `j`.  Skip them by jumping `i` to `i+k+1`.
  - If `s[i+k] < s[j+k]`, symmetrically skip `j, j+1, ..., j+k`.

Each index from `0` to `n-1` is "eliminated" at most once, so the total number
of comparisons is O(n).

```
Skip diagram:

  i: [ i --- i+k ]  mismatch here (s[i+k] > s[j+k])
  j: [ j --- j+k ]

  All rotations starting in i..i+k are dominated by j.
  Jump: i := i + k + 1
        k := 0
```

## 6. Full Booth's algorithm walkthrough: "baca"

The algorithm operates on the doubled string `"bacabaca"` to handle wraparound
without modulo arithmetic.

```
s = "baca",  doubled = "b a c a b a c a"
                         0 1 2 3 4 5 6 7

State: (i, j, k)  --  compare doubled[i+k] vs doubled[j+k]

Step | i  j  k | doubled[i+k]  doubled[j+k] | outcome
-----+---------+---------------------------------+----------------------------
  1  | 0  1  0 |     b (0)   vs   a (1)      | b > a => i is worse
     |         |                              | next_i = 0+0+1 = 1, but 1 <= j=1
     |         |                              | so next_i = j+1 = 2
     |         |                              | i := 2, k := 0
     |         |                              |
  2  | 2  1  0 |     c (2)   vs   a (1)      | c > a => i is worse
     |         |                              | next_i = 2+0+1 = 3
     |         |                              | i := 3, k := 0
     |         |                              |
  3  | 3  1  0 |     a (3)   vs   a (1)      | equal => extend prefix
     |         |                              | k := 1
     |         |                              |
  4  | 3  1  1 |     b (4)   vs   c (2)      | b < c => j is worse
     |         |                              | next_j = 1+1+1 = 3, but 3 <= i=3
     |         |                              | so next_j = i+1 = 4
     |         |                              | j := 4, k := 0
     |         |                              |
  5  | 3  4  0 |     j=4 >= n=4              | loop exits: break (i=3, j=4)

Termination: i=3, j=4; since j >= n, the winner is i = 3.

Result: min_cyclic_rotation_index("baca") = 3
        min_cyclic_rotation("baca")       = "abac"
```

## 7. Full walkthrough: "caaab"

```
s = "caaab",  n = 5
doubled = "c a a a b c a a a b"
            0 1 2 3 4 5 6 7 8 9

Step | i  j  k | doubled[i+k]  doubled[j+k] | outcome
-----+---------+-------------------------------+---------------------------
  1  | 0  1  0 |   c (0)  vs  a (1)          | c > a => skip i block
     |         |                              | next_i = 0+0+1 = 1, 1 <= j=1
     |         |                              | i := 2, k := 0
     |         |                              |
  2  | 2  1  0 |   a (2)  vs  a (1)          | equal
     |         |                              | k := 1
     |         |                              |
  3  | 2  1  1 |   a (3)  vs  a (2)          | equal
     |         |                              | k := 2
     |         |                              |
  4  | 2  1  2 |   b (4)  vs  a (3)          | b > a => skip i block
     |         |                              | next_i = 2+2+1 = 5 >= n
     |         |                              | i := 5, k := 0
     |         |                              |
  5  | 5  1  0 |   i=5 >= n=5                | loop exits: break (i=5, j=1)

Termination: i=5, j=1; since i >= n, the winner is j = 1.

Result: min_cyclic_rotation_index("caaab") = 1
        min_cyclic_rotation("caaab")       = "aaabc"
```

## 8. Loop invariant

```
At every iteration of the main loop, with state (i, j, k):

  I1: 0 <= i <= n
  I2: 0 <= j <= n
  I3: k >= 0
  I4: Every rotation start r < min(i, j) has already been shown to be
      strictly worse than either rotation i or rotation j.
  I5: The first k characters of rotation i and rotation j are identical,
      i.e. doubled[i..i+k) == doubled[j..j+k).

On mismatch at position k:
  - The losing candidate and all starts up to offset k are dominated.
  - They are eliminated in one step, maintaining I4.

Termination:
  - When i >= n or j >= n, one candidate has been fully scanned.
  - The remaining in-range candidate is the global minimum.
```

## 9. Example usage (basic)

```mbt check
///|
test "min rotation basic" {
  inspect(@minimum_cyclic_rotation.min_cyclic_rotation("baca"), content="abac")
  inspect(
    @minimum_cyclic_rotation.min_cyclic_rotation_index("baca"),
    content="3",
  )
}
```

## 10. Example: repeated patterns and ties

`"abab"` has two minimal rotations: `"abab"` (start 0) and `"abab"` (start 2).
The smallest index is `0`.

```mbt check
///|
test "min rotation repeated patterns" {
  inspect(@minimum_cyclic_rotation.min_cyclic_rotation("abab"), content="abab")
  inspect(
    @minimum_cyclic_rotation.min_cyclic_rotation_index("abab"),
    content="0",
  )
  inspect(@minimum_cyclic_rotation.min_cyclic_rotation("aaaa"), content="aaaa")
  inspect(
    @minimum_cyclic_rotation.min_cyclic_rotation_index("aaaa"),
    content="0",
  )
}
```

## 11. Example: a clear winner

```
s = "caaab"
rotations:
  0: caaab
  1: aaabc   <- minimum
  2: aabca
  3: abcaa
  4: bcaaa
```

```mbt check
///|
test "min rotation clear winner" {
  inspect(
    @minimum_cyclic_rotation.min_cyclic_rotation("caaab"),
    content="aaabc",
  )
  inspect(
    @minimum_cyclic_rotation.min_cyclic_rotation_index("caaab"),
    content="1",
  )
}
```

## 12. Example: canonicalizing cyclic strings (necklace view)

Two strings are rotations of each other iff their minimum rotations match.

```mbt check
///|
fn canon(s : String) -> String {
  @minimum_cyclic_rotation.min_cyclic_rotation(s)
}

///|
test "canonicalization by minimum rotation" {
  inspect(canon("abc"), content="abc")
  inspect(canon("bca"), content="abc")
  inspect(canon("acb"), content="acb")
}
```

## 13. Example: use the index to rotate parallel data

Sometimes you want the **index** so you can rotate other arrays the same way.

```mbt check
///|
fn[T] rotate_array(xs : ArrayView[T], start : Int) -> Array[T] {
  let n = xs.length()
  if n == 0 {
    Array::new()
  } else {
    let shift = start % n
    Array::makei(n, i => xs[(shift + i) % n])
  }
}

///|
test "rotate parallel data by min rotation index" {
  let s = "baca"
  let idx = @minimum_cyclic_rotation.min_cyclic_rotation_index(s)
  let weights : Array[Int] = [10, 20, 30, 40]
  let rotated = rotate_array(weights[:], idx)
  inspect(rotated, content="[40, 10, 20, 30]")
}
```

## 14. Complexity

```
Time:  O(n)   -- each candidate index is eliminated at most once
Space: O(n)   -- the doubled string "s + s"
```

## 15. Implementation notes

- The algorithm operates on `s + s` so that index arithmetic stays simple: no
  modulo is needed when reading `doubled[i + k]`.
- Lexicographic order follows the string's code unit order (UTF-16 / Unicode
  scalar values for ASCII-range input).
- When `i` would not advance past `j` after a skip, it is bumped to `j + 1` to
  preserve the invariant `i != j`.  The symmetric rule applies to `j`.
- The index result is stable for repeated patterns: it returns the smallest
  start index among all positions that achieve the minimum rotation.

## 16. Related tools

- **Duval's algorithm** (`duval_lyndon` package): Lyndon factorization, which
  can also be used to find the minimum rotation.
- **KMP on s+s** (`kmp` package): can test whether two strings are rotations of
  each other by searching for one inside the doubled version of the other.
- **Rolling hash** (`rolling_hash` package): approximate rotation check using
  polynomial hashing.
