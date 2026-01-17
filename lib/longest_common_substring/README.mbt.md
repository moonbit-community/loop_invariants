# Longest Common Substring (DP)

## 1. Problem statement (what we want)

Given two strings `a` and `b`, find the longest **contiguous** substring that
appears in **both** strings.

- If multiple substrings tie for the maximum length, this implementation keeps
  the first one it discovers while scanning rows left to right.
- If there is no common substring, the answer is the empty string with length 0.

This package returns both the substring itself and its length.

## 2. Substring vs subsequence (do not mix these up)

A **substring** is contiguous. A **subsequence** can skip characters.

Example:

```
String A:  a b c d e f
String B:  z b c d f

Common subsequence (can skip): "bcdf" (length 4)
Common substring  (contiguous): "bcd" (length 3)
```

The key rule for longest common substring is:

- Match: extend the diagonal (previous match).
- Mismatch: reset to 0 (contiguity is broken).

## 3. Naive idea (why we do DP)

A brute-force approach tries every pair of start positions and extends while
characters match. That is often O(n * m * L) where L is the length of the match.
For long strings, this is too slow.

Dynamic programming reduces the work to O(n * m).

## 4. DP idea: longest common suffix ending here

Define:

```
dp[i][j] = length of the longest common suffix
           of a[0..i) and b[0..j)
           that ends exactly at a[i-1] and b[j-1]
```

Recurrence:

```
if a[i-1] == b[j-1]:
  dp[i][j] = dp[i-1][j-1] + 1
else:
  dp[i][j] = 0
```

The answer is the maximum value in the DP table.

Why this works:

- `dp[i-1][j-1]` is the best suffix ending one step diagonally up-left.
- If the current characters match, we can extend that suffix by 1.
- If they do not match, the common suffix ending here is forced to 0.

## 5. Match grid: diagonals are the only places that grow

Think of a grid where rows are characters of `a`, columns are characters of `b`.
A match places an `X`, and only diagonals of `X` can grow into longer substrings.

```
a = "ababa"
b = "baba"

      b   a   b   a
    +---+---+---+---+
a |  . | X | . | X |
    +---+---+---+---+
b |  X | . | X | . |
    +---+---+---+---+
a |  . | X | . | X |
    +---+---+---+---+
b |  X | . | X | . |
    +---+---+---+---+
a |  . | X | . | X |
    +---+---+---+---+

A contiguous substring corresponds to a diagonal streak of Xs.
```

## 6. Concrete DP table example

Example strings:

```
a = "abab"
b = "baba"
```

DP table (rows = `a`, columns = `b`):

```
        ""  b  a  b  a
    ""   0  0  0  0  0
     a   0  0  1  0  1
     b   0  1  0  2  0
     a   0  0  2  0  3  <-- maximum = 3
     b   0  1  0  3  0
```

Maximum length is 3, ending at `a[3]`, so the substring is `"aba"`.

## 7. Walkthrough: "banana" vs "ananas"

We compute row by row. A few highlights:

- When `a[i-1]` and `b[j-1]` do not match, the cell is 0.
- When they match, the value is the diagonal + 1.

Selected steps:

```
Row for a[1] = 'a':
  b[0] = 'a' -> dp = 1
  b[1] = 'n' -> dp = 0
  b[2] = 'a' -> dp = 1

Row for a[2] = 'n':
  b[1] = 'n' -> dp = 2 (extends "a" to "an")
  b[3] = 'n' -> dp = 2

Row for a[5] = 'a':
  b[4] = 'a' -> dp = 5 ("anana")
```

The maximum value 5 gives substring "anana".

## 8. Space optimization (rolling rows)

The recurrence only depends on `dp[i-1][j-1]`, so we do not need the full table.
We keep two rows:

```
prev_row: dp for i-1
curr_row: dp for i
```

After finishing a row, we swap and clear `curr_row`.

This reduces space from O(n * m) to O(m).

## 9. Reconstructing the substring

While filling the table we track:

- `best_len`: maximum length seen so far
- `best_end`: the index in `a` where that maximum ends (1-based in the DP loop)

After the DP ends:

```
start = best_end - best_len
substring = a[start : best_end]
```

Example:

```
a = "banana"
best_len = 5
best_end = 6
substring = a[1:6] = "anana"
```

If `best_len` stays 0, the answer is the empty string.

## 10. MoonBit details (strings and indices)

MoonBit `String` is UTF-16. Indexing like `s[i]` accesses a code unit.
The DP uses those code units directly. If you need substring logic over full
Unicode grapheme clusters, you would need a different representation.

This implementation constructs the output substring with a `StringBuilder`
so the result is a fresh `String`.

## 11. Worked examples (runnable)

```mbt check
///|
test "lcs banana ananas" {
  let result = @longest_common_substring.longest_common_substring(
    "banana", "ananas",
  )
  inspect(result.substring, content="anana")
  inspect(result.length, content="5")
}
```

```mbt check
///|
test "lcs no common substring" {
  let result = @longest_common_substring.longest_common_substring("abc", "xyz")
  inspect(result.substring, content="")
  inspect(result.length, content="0")
}
```

```mbt check
///|
test "lcs identical strings" {
  let result = @longest_common_substring.longest_common_substring(
    "hello", "hello",
  )
  inspect(result.substring, content="hello")
  inspect(result.length, content="5")
}
```

```mbt check
///|
test "lcs inside a longer word" {
  let result = @longest_common_substring.longest_common_substring(
    "mississippi", "sipp",
  )
  inspect(result.substring, content="sipp")
  inspect(result.length, content="4")
}
```

```mbt check
///|
test "lcs short overlap" {
  let result = @longest_common_substring.longest_common_substring(
    "xyzab", "tabc",
  )
  inspect(result.substring, content="ab")
  inspect(result.length, content="2")
}
```

## 12. Common pitfalls

- Confusing substring with subsequence.
- Forgetting to reset to 0 on mismatches.
- Mixing index bases (`dp` is 1-based, strings are 0-based).
- Expecting a specific answer when there are multiple longest substrings.

## 13. Complexity and when to use this

```
Time:  O(n * m)
Space: O(m)
```

Use this DP when:

- You need the actual longest contiguous match.
- Input sizes are moderate (O(n * m) is acceptable).

For very large inputs, suffix automaton or suffix array methods can be faster,
but they are more complex to implement.
