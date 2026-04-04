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

Insert `#` separators between characters and at both ends:

```
Original:    a  b  b  a
Index:       0  1  2  3

Transformed: #  a  #  b  #  b  #  a  #
Index:       0  1  2  3  4  5  6  7  8
             ^     ^     ^     ^     ^
             |     |     |     |     |
          sentinel  |    center      sentinel
                 original chars at odd positions
```

Every character from the original sits at an **odd** index; sentinels sit at
**even** indices. Now every palindrome in the transformed string has odd length
with a unique center, so a single radius array covers all cases.

- Even palindrome "bb" becomes "#b#b#" centered at index 4
- Odd palindrome "aba" becomes "#a#b#a#" centered at index 3

### Sentinel placement detail

```
Original "abba"  (n=4, transformed length = 2*4+1 = 9)

position:  0  1  2  3  4  5  6  7  8
           #  a  #  b  #  b  #  a  #
           ^           ^           ^
           left       center      right
         sentinel    (even pos)  sentinel
```

The `#` character never appears in normal text, so it cannot cause a false
match across the sentinel boundary.

## 6. Radii definition in the transformed string

Let `P[i]` be the **radius** at center `i` in the transformed string:

- A radius of 0 means only the center character matches (degenerate palindrome)
- A radius of k means the palindrome spans `[i-k, i+k]` in the transformed string

Example for `"cbbd"`:

```
Transformed:  #  c  #  b  #  b  #  d  #
Index:         0  1  2  3  4  5  6  7  8
P[i]:          0  1  0  1  2  1  0  1  0
                                ^
                           max radius=2 here
                           corresponds to "bb" in original
```

The maximum radius is 2 at center 4, which corresponds to "bb".

### Mapping radius to original length

In the transformed string, a radius of `r` corresponds to:

```
original length = r
```

This is why `longest_palindrome_len` can be read directly from the max radius.

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

### Quick sanity check

```
odd length = 2 * d1[i] - 1
even length = 2 * d2[i]
```

So for "abba":
- odd lengths = 1
- even length at center 2 = 2 * 2 = 4

## 8. The mirror property (the key speedup)

Suppose we already have a palindrome centered at `c` with right boundary `r`.
For every position `i` strictly inside `[c-(r-c), r]`, there is a **mirror**
position `i' = 2*c - i` on the other side of `c`.

```
  palindrome centered at c, extending to r on the right
  --------------------------------------------------------
              c
  ... # a # b # a # b # a # ...
      |     |     |     |
      l     i'    c    i     r
            |<----|---->|
             symmetric about c
```

Because the big palindrome is symmetric:

```
P[i] >= min(P[i'], r - i)
```

This gives a lower bound on the radius at `i` without any character
comparisons.  We only need to expand past `r` when the mirror palindrome
reaches the boundary. Since `r` only ever moves rightward, the total number
of expansions over all centers is linear.

### Why the mirror bound is safe

If `i` is inside the current palindrome `[l, r]` (where `l = 2*c - r`):

```
mirror = 2*c - i    (i' in the diagram above)
```

Two cases:

```
Case A: P[mirror] < r - i
        The mirror palindrome fits entirely inside [l, r].
        By symmetry, P[i] = P[mirror].  No expansion needed.

        ... [ l ... [i'-P[i'] ... i' ... i'+P[i']] ... c ... i ... r ] ...
                     |<-- safe copy, no new comparisons -->|

Case B: P[mirror] >= r - i
        The mirror palindrome touches or goes past l.
        We know P[i] >= r - i, but must expand starting at r+1.
```

In either case we start with the guaranteed lower bound and only compare new
characters beyond `r`.

## 9. Step-by-step walkthrough: "aabaa"

We trace the full Manacher scan on the transformed string.

```
Original:    a  a  b  a  a
Transformed: #  a  #  a  #  b  #  a  #  a  #
Index:       0  1  2  3  4  5  6  7  8  9  10
```

Initial state: `c = 0`, `r = 0`, all `P[i] = 0`.

```
i=0  (#)  c=0, r=0, i >= r -> start with P[0]=0
          Expand: t[-1] out of bounds -> stop
          P[0] = 0   r still 0

i=1  (a)  i >= r -> start with P[1]=0
          Expand: t[0]='#' == t[2]='#' -> P[1]=1
                  t[-1] out of bounds -> stop
          P[1] = 1   update c=1, r=2

     State:  c=1, r=2
     #  a  #  a  #  b  #  a  #  a  #
     0  1  2  3  4  5  6  7  8  9  10
        [c=1   r=2]

i=2  (#)  i=2 <= r=2 -> mirror = 2*1-2 = 0
          P[mirror]=P[0]=0, r-i=0 -> P[2] = min(0,0) = 0
          Expand: t[1]='a' != t[3]='a' ... wait both 'a': match -> P[2]=1
                  t[0]='#' != t[4]='#': match -> P[2]=2
                  t[-1] out of bounds -> stop
          P[2] = 2   update c=2, r=4

     State:  c=2, r=4
     #  a  #  a  #  b  #  a  #  a  #
     0  1  2  3  4  5  6  7  8  9  10
        [      c=2      r=4]

i=3  (a)  i=3 <= r=4 -> mirror = 2*2-3 = 1
          P[mirror]=P[1]=1, r-i=1 -> P[3] = min(1,1) = 1
          Expand: t[1]='a' vs t[5]='b' -> mismatch -> stop
          P[3] = 1   c and r unchanged

i=4  (#)  i=4 <= r=4 -> mirror = 2*2-4 = 0
          P[mirror]=P[0]=0, r-i=0 -> P[4] = min(0,0) = 0
          Expand: t[3]='a' vs t[5]='b' -> mismatch -> stop
          P[4] = 0   c and r unchanged

i=5  (b)  i=5 > r=4 -> start with P[5]=0
          Expand: t[4]='#' == t[6]='#' -> P[5]=1
                  t[3]='a' == t[7]='a' -> P[5]=2
                  t[2]='#' == t[8]='#' -> P[5]=3
                  t[1]='a' == t[9]='a' -> P[5]=4
                  t[0]='#' == t[10]='#' -> P[5]=5
                  t[-1] out of bounds -> stop
          P[5] = 5   update c=5, r=10

     State:  c=5, r=10
     #  a  #  a  #  b  #  a  #  a  #
     0  1  2  3  4  5  6  7  8  9  10
     [              c=5              r=10]
                                      ^-- rightmost boundary

i=6  (#)  i=6 <= r=10 -> mirror = 2*5-6 = 4
          P[mirror]=P[4]=0, r-i=4 -> P[6] = min(0,4) = 0
          Expand: t[5]='b' vs t[7]='a' -> mismatch -> stop
          P[6] = 0   c and r unchanged (mirror copy was sufficient)

i=7  (a)  i=7 <= r=10 -> mirror = 2*5-7 = 3
          P[mirror]=P[3]=1, r-i=3 -> P[7] = min(1,3) = 1
          Expand: t[5]='b' vs t[9]='a' -> mismatch -> stop
          P[7] = 1   c and r unchanged (mirror copy was sufficient)

i=8  (#)  i=8 <= r=10 -> mirror = 2*5-8 = 2
          P[mirror]=P[2]=2, r-i=2 -> P[8] = min(2,2) = 2
          Expand: t[5]='b' vs t[11] out of bounds -> stop
          P[8] = 2   c and r unchanged (boundary was reached)

i=9  (a)  i=9 <= r=10 -> mirror = 2*5-9 = 1
          P[mirror]=P[1]=1, r-i=1 -> P[9] = min(1,1) = 1
          Expand: t[7]='a' vs t[11] out of bounds -> stop
          P[9] = 1   c and r unchanged

i=10 (#)  i=10 <= r=10 -> mirror = 2*5-10 = 0
          P[mirror]=P[0]=0, r-i=0 -> P[10] = min(0,0) = 0
          Expand: t[9]='a' vs t[11] out of bounds -> stop
          P[10] = 0
```

Final radii array:

```
Transformed: #  a  #  a  #  b  #  a  #  a  #
Index:        0  1  2  3  4  5  6  7  8  9  10
P[i]:         0  1  2  1  0  5  0  1  2  1  0
                              ^
                        P[5]=5 is the max
```

Maximum radius = 5 at center 5.

```
start = (5 - 5) / 2 = 0
length = 5
substring = s[0..5] = "aabaa"
```

The entire string "aabaa" is a palindrome, as expected.

### Where mirror reuse saved work

At `i=6,7,8,9,10` we were inside the big palindrome `[0..10]` centered at 5.
For each of those positions we immediately had a lower bound from the mirror,
avoiding redundant character-by-character expansion.

## 10. Walkthrough example: "cbbd"

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

## 11. Converting back to original indices

If you know `(center, radius)` in the transformed string:

```
start = (center - radius) / 2
length = radius
```

This is exactly how `longest_palindrome` maps the answer back.

### Example conversion

```
center = 4, radius = 2  (from transformed string)
start = (4 - 2) / 2 = 1
length = 2
substring = s[1..3] = "bb"
```

## 12. Counting palindromes from radii

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

### Another quick check: "abba"

Palindromes:

```
"a","b","b","a","bb","abba" -> 6
```

`count_palindromes("abba")` should be 6.

## 13. Example usage (runnable)

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

## 14. Common pitfalls

- Confusing odd and even palindromes
- Forgetting that `d1[i]` is a radius, not a length
- Assuming the longest palindrome is unique (it is not in general)
- Using this for grapheme clusters; MoonBit strings are UTF-16 code units

## 15. Complexity

```
Time:  O(n)
Space: O(n)
```

Each position extends the right boundary at most once, so the total work is
linear.

## 16. When to use Manacher

- You need **all** palindrome radii in linear time
- You need longest palindromic substring fast
- You want to count palindromic substrings efficiently

If `n` is small or code simplicity matters more than performance, a quadratic
center-expansion might be simpler to implement. Otherwise Manacher is the
standard choice.

## 17. API summary

This package provides:

- `longest_palindrome(s)` -> longest palindromic substring
- `longest_palindrome_len(s)` -> length only
- `count_palindromes(s)` -> total count
- `manacher_radii(s)` -> `(d1, d2)` arrays for odd/even centers
