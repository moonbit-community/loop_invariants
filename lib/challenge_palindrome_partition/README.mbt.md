# Challenge: Palindrome Partition (Minimum Cuts)

We want to cut a string into the **fewest number of pieces** such that every
piece is a palindrome.

This package computes the **minimum number of cuts**.

---

## Problem restatement (plain words)

Given a string `s`, split it into substrings so that:

- every substring reads the same forward and backward (palindrome)
- the number of cuts between substrings is as small as possible

If the string itself is a palindrome, the answer is `0`.

---

## Example intuition

```
"aab" -> "aa" | "b"  (1 cut)
"ababa" -> "ababa"  (0 cuts)
"abc" -> "a" | "b" | "c"  (2 cuts)
```

---

## Two-step dynamic programming

We solve it in two stages:

### Step 1: Palindrome table

`pal[i][j] = true` if `s[i..j]` is a palindrome.

Recurrence:

- Base: all single characters are palindromes
- For length >= 2:
  - `s[i] == s[j]` and
  - either length is 2, or the inner substring `pal[i+1][j-1]` is true

That gives `O(n^2)` time and space.

### Step 2: Minimum cuts for prefixes

Let:

```
dp[i] = minimum cuts needed for s[0..i]
```

Then:

- If `pal[0][i]` is true, `dp[i] = 0` (whole prefix is a palindrome)
- Otherwise:

```
dp[i] = min over all j <= i with pal[j][i] = true of (dp[j-1] + 1)
```

That also costs `O(n^2)`.

---

## Visual example with "aab"

String: `a a b`
Indices: `0 1 2`

Palindrome table (T for true, F for false):

```
      j=0 j=1 j=2
 i=0   T   T   F
 i=1       T   F
 i=2           T
```

Explanation:

- `s[0..1] = "aa"` is a palindrome
- `s[0..2] = "aab"` is not

Now compute dp:

```
 i=0: pal[0][0] -> dp[0] = 0
 i=1: pal[0][1] -> dp[1] = 0
 i=2: pal[0][2] is false
      pal[1][2] is false
      pal[2][2] is true -> dp[2] = dp[1] + 1 = 1
```

Answer: 1 cut.

---

## Reference implementation

```mbt
///| pub fn min_palindrome_cuts(s : String) -> Int { ... }
```

The full code is in `challenge_palindrome_partition.mbt`.

---

## Tests and examples

### Small example

```mbt check
///|
test "palindrome partition example" {
  let cuts = @challenge_palindrome_partition.min_palindrome_cuts("aab")
  inspect(cuts, content="1")
}
```

### Already a palindrome

```mbt check
///|
test "palindrome partition no cuts" {
  let cuts = @challenge_palindrome_partition.min_palindrome_cuts("ababa")
  inspect(cuts, content="0")
}
```

### No multi-character palindromes

```mbt check
///|
test "palindrome partition all single" {
  let cuts = @challenge_palindrome_partition.min_palindrome_cuts("abc")
  inspect(cuts, content="2")
}
```

### Larger example

```mbt check
///|
test "palindrome partition banana" {
  let cuts = @challenge_palindrome_partition.min_palindrome_cuts("banana")
  inspect(cuts, content="1")
}
```

### Empty string

```mbt check
///|
test "palindrome partition empty" {
  let cuts = @challenge_palindrome_partition.min_palindrome_cuts("")
  inspect(cuts, content="0")
}
```

---

## Complexity

Let `n = s.length()`:

- Palindrome table: `O(n^2)` time, `O(n^2)` space
- DP for cuts: `O(n^2)` time
- Total: `O(n^2)` time and `O(n^2)` memory

---

## Takeaways

- Precompute palindromes so each substring check is `O(1)`.
- The minimum cuts problem reduces to a simple prefix DP.
- The answer is the fewest cuts needed to cover the string by palindromes.
