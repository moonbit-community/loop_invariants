# Manacher's Algorithm (palindromes in O(n))

## 1. What problem does this solve?

A **palindrome** reads the same forward and backward.
This package focuses on **palindromic substrings** (contiguous).

Typical tasks:

- Longest palindromic substring
- Length of the longest palindrome
- Count of all palindromic substrings
- Radii arrays for all centers (odd and even)

Manacher's algorithm solves all of these in **linear time**.

## 2. Substring vs subsequence (quick reminder)

A substring is contiguous, a subsequence is not.
We only care about substrings here.

```
String:  a b a c
Substring palindrome: "aba" (positions 0..2)
Subsequence palindrome: "aac" (not contiguous) -> not our target
```

## 3. Why the naive approach is too slow

A naive solution expands around every possible center:

- There are O(n) centers
- Each expansion can cost O(n)

Total: **O(n^2)**.

Manacher reduces this to **O(n)** by reusing information from previously
found palindromes.

## 4. Odd vs even palindromes

Every palindrome is either:

- **Odd length**: has a center character
- **Even length**: center is between two characters

Example:

```
String: "abac"
Odd palindrome centered at index 1: "aba"

String: "abba"
Even palindrome centered between 1 and 2: "bb" and "abba"
```

Manacher handles both at once by transforming the string.

## 5. The transformation (make everything odd)

Insert separators between characters and at both ends:

```
Original:  a b b a
Index:     0 1 2 3

Transformed:  # a # b # b # a #
Index:         0 1 2 3 4 5 6 7 8
```

Now every palindrome in the transformed string has **odd length** with a
unique center.

- Even palindrome "bb" becomes "#b#b#" centered at index 4
- Odd palindrome "aba" becomes "#a#b#a#" centered at index 3

## 6. Radii definition in the transformed string

Let `P[i]` be the **radius** at center `i` in the transformed string:

- Radius counts how far we can expand while staying palindrome
- A radius of 0 means only the center matches

Example for `"cbbd"`:

```
Transformed:  # c # b # b # d #
Index:         0 1 2 3 4 5 6 7 8
P[i]:          0 1 0 1 2 1 0 1 0
```

The maximum radius is 2 at center 4, which corresponds to "bb".

## 7. Radii in the original string (d1 and d2)

This package exposes `manacher_radii` returning two arrays:

- `d1[i]`: radius of the longest **odd** palindrome centered at `i`
  - Length = `2 * d1[i] - 1`
- `d2[i]`: radius of the longest **even** palindrome centered between `i-1` and `i`
  - Length = `2 * d2[i]`

Example: `"abba"`

```
indices:  0 1 2 3
string:   a b b a

d1:       1 1 1 1   (all odd palindromes are just the single letter)
d2:       0 0 2 0   (center between 1 and 2 gives "bb" and "abba")
```

## 8. The mirror property (the key speedup)

Suppose we already have a palindrome centered at `c` with right boundary `r`.
If we are at position `i` **inside** that palindrome, there is a mirror
position `i'` on the other side:

```
         c
... # a # b # a # b # a # ...
        i'         i
            r
```

Because of symmetry:

```
P[i] >= min(P[i'], r - i)
```

This gives a strong lower bound without any comparisons.
We only expand past `r` if needed. The right boundary `r` only moves forward,
so total expansions across the whole scan are linear.

## 9. Walkthrough example: "cbbd"

```
Original:    c b b d
Transformed: # c # b # b # d #
Index:        0 1 2 3 4 5 6 7 8
P[i]:         0 1 0 1 2 1 0 1 0
```

Interpretation:

- Center 4 has radius 2 -> length 2 in original
- Start = (4 - 2) / 2 = 1
- Substring = s[1:3] = "bb"

## 10. Converting back to original indices

If you know `(center, radius)` in the transformed string:

```
start = (center - radius) / 2
length = radius
```

This is exactly how `longest_palindrome` maps the answer back.

## 11. Counting palindromes from radii

In the transformed string, each center contributes:

```
(r + 1) / 2
```

palindromes in the original string.

Example: `"aaa"`

Palindromic substrings:

- "a" at (0), (1), (2) -> 3
- "aa" at (0..1), (1..2) -> 2
- "aaa" at (0..2) -> 1

Total = 6.

## 12. Example usage (runnable)

```mbt check
///|
test "manacher basics" {
  inspect(@manacher.longest_palindrome("cbbd"), content="bb")
  inspect(@manacher.longest_palindrome("racecar"), content="racecar")
  inspect(@manacher.longest_palindrome_len("abacaba"), content="7")
}
```

```mbt check
///|
test "manacher counts" {
  inspect(@manacher.count_palindromes("aaa"), content="6")
  inspect(@manacher.count_palindromes("aaaa"), content="10")
}
```

```mbt check
///|
test "manacher radii arrays" {
  let (d1, d2) = @manacher.manacher_radii("abba")
  inspect(d1, content="[1, 1, 1, 1]")
  inspect(d2, content="[0, 0, 2, 0]")
}
```

```mbt check
///|
test "manacher unique longest" {
  inspect(@manacher.longest_palindrome("abaxyzzyxf"), content="xyzzyx")
  inspect(@manacher.longest_palindrome_len("abcdef"), content="1")
}
```

## 13. Common pitfalls

- Confusing odd and even palindromes
- Forgetting that `d1[i]` is a radius, not a length
- Assuming the longest palindrome is unique (it is not in general)
- Using this for grapheme clusters; MoonBit strings are UTF-16 code units

## 14. Complexity

```
Time:  O(n)
Space: O(n)
```

Each position extends the right boundary at most once, so the total work is
linear.

## 15. When to use Manacher

- You need **all** palindrome radii in linear time
- You need longest palindromic substring fast
- You want to count palindromic substrings efficiently

If `n` is small or code simplicity matters more than performance, a quadratic
center-expansion might be simpler to implement. Otherwise Manacher is the
standard choice.

## 16. API summary

This package provides:

- `longest_palindrome(s)` -> longest palindromic substring
- `longest_palindrome_len(s)` -> length only
- `count_palindromes(s)` -> total count
- `manacher_radii(s)` -> `(d1, d2)` arrays for odd/even centers
