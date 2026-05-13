# Z-Algorithm (Beginner-Friendly Guide)

The Z-algorithm computes, for each position `i`, how long the substring
starting at `i` matches the **prefix** of the string. This gives fast pattern
matching in **linear time**.

This package provides:

```
@z_algorithm.compute_z(s)
@z_algorithm.z_function(s)          // alias
@z_algorithm.find_pattern(text, pattern)
@z_algorithm.z_search(text, pattern) // alias
@z_algorithm.count_pattern(text, pattern)
```

---

## 1) What is the Z-array?

For a string `s`, `Z[i]` = length of the longest prefix match starting at `i`.

By convention `Z[0] = n` (the full string length).

**Example: `s = "aabcaab"`**

```
index:  0   1   2   3   4   5   6
char:   a   a   b   c   a   a   b
        |   |               |
        +---+               +-- Z[5]=1 ("a" matches prefix "a")
        |
        Z[0]=7  (whole string, by convention)

Z[1]=1  s[1..1] = "a"   == s[0..0] = "a"      match length 1
Z[2]=0  s[2..2] = "b"  !=  s[0..0] = "a"      no match
Z[3]=0  s[3..3] = "c"  !=  s[0..0] = "a"      no match
Z[4]=3  s[4..6] = "aab" == s[0..2] = "aab"    match length 3
Z[5]=1  s[5..5] = "a"   == s[0..0] = "a"      match length 1
Z[6]=0  s[6..6] = "b"  !=  s[0..0] = "a"      no match

Z = [7, 1, 0, 0, 3, 1, 0]
```

---

## 2) The Z-box idea (the trick that makes it O(n))

A naive implementation recomputes every Z-value from scratch.  The Z-algorithm
avoids this by maintaining a **Z-box**: the rightmost matching window `[l, r]`
found so far, where `s[l..r]` matches the prefix `s[0..r-l]`.

**Z-box visualization for `s = "aabcaab"` after processing `i=4`:**

```
index:  0   1   2   3   4   5   6
char:   a   a   b   c   a   a   b
                        [---l   r---]
                         Z-box = [4, 6]
                         s[4..6] == s[0..2] == "aab"
```

When we later process index `i=5` (which is inside the Z-box):

```
        0   1   2   3   4   5   6
        a   a   b   c   a   a   b
        ^   ^               ^
prefix: |   |               |
        0   k=1             i=5

        k = i - l = 5 - 4 = 1
        Z[k] = Z[1] = 1
        remaining in box = r - i + 1 = 6 - 5 + 1 = 2

        Z[k]=1 < remaining=2  -->  Z[5] = Z[1] = 1  (no extra comparison needed)
```

When we process `i=6` (also inside the box):

```
        k = i - l = 6 - 4 = 2
        Z[k] = Z[2] = 0
        Z[k]=0 < remaining=1  -->  Z[6] = 0  (reused directly)
```

**The key saving**: positions already matched inside the Z-box are never
re-examined.  The right boundary `r` only ever moves forward, so across the
entire string, at most `n` comparisons are made in total.

**When does the Z-box expand?** Only in two cases:

```
Case 1: i > r  (i is outside the Z-box)
        -- expand naively from i, update Z-box to [i, i+match-1]

Case 2: i <= r AND Z[k] >= r-i+1  (match would reach or exceed the Z-box edge)
        -- start comparing from r+1, extend Z-box right edge
```

In case 2a (`Z[k] < r-i+1`) the match stays strictly inside the box and we
copy `Z[i] = Z[k]` for free.

---

## 3) Step-by-step walkthrough for `s = "aabcaab"`

```
Initial state: l=0, r=0 (Z-box is empty, r < l conceptually)

i=1  outside box
     compare s[0] vs s[1]: 'a'=='a' -> match
     compare s[1] vs s[2]: 'a'!='b' -> stop
     Z[1]=1, update box: l=1, r=1

     s:  a  a  b  c  a  a  b
            [l=r=1]

i=2  outside box (i=2 > r=1)
     compare s[0] vs s[2]: 'a'!='b' -> stop
     Z[2]=0, box unchanged: l=1, r=1

i=3  outside box (i=3 > r=1)
     compare s[0] vs s[3]: 'a'!='c' -> stop
     Z[3]=0, box unchanged

i=4  outside box (i=4 > r=1)
     compare s[0] vs s[4]: 'a'=='a' -> match
     compare s[1] vs s[5]: 'a'=='a' -> match
     compare s[2] vs s[6]: 'b'=='b' -> match
     compare s[3] vs s[7]: out of bounds -> stop
     Z[4]=3, update box: l=4, r=6

     s:  a  a  b  c  a  a  b
                     [l=4  r=6]

i=5  INSIDE box (i=5 <= r=6)
     k = 5-4 = 1,  Z[k]=Z[1]=1,  remaining=6-5+1=2
     Z[1]=1 < 2  -->  Z[5]=1  (copied, no comparisons)

i=6  INSIDE box (i=6 <= r=6)
     k = 6-4 = 2,  Z[k]=Z[2]=0,  remaining=6-6+1=1
     Z[2]=0 < 1  -->  Z[6]=0  (copied, no comparisons)

Result: Z = [7, 1, 0, 0, 3, 1, 0]
```

---

## 4) Pattern matching with Z

To find a pattern `P` inside text `T`, build:

```
S = P + "$" + T
```

Compute Z on `S`.  
Any position `i > |P|` with `Z[i] == |P|` is a match in `T` at index `i - |P| - 1`.

**Example: find `"ab"` in `"ababab"`**

```
P = "ab"   (length 2)
T = "ababab"
S = "ab$ababab"
     01234567 8

Z-array of S:
  index:  0  1  2  3  4  5  6  7  8
  char:   a  b  $  a  b  a  b  a  b
  Z:      9  0  0  2  0  2  0  2  0
                   ^     ^     ^
                 Z[3]=2  Z[5]=2  Z[7]=2
                 all equal |P|=2

Text positions: i - |P| - 1
  i=3:  3 - 2 - 1 = 0
  i=5:  5 - 2 - 1 = 2
  i=7:  7 - 2 - 1 = 4

Matches at positions 0, 2, 4 in T.
```

The `"$"` separator ensures no Z-value in the text portion accidentally spans
across the boundary into the pattern.

---

## 5) Example usage

```mbt check
///|
test "z array and search" {
  let z = @z_algorithm.compute_z("aabcaab")
  debug_inspect(z, content="[7, 1, 0, 0, 3, 1, 0]")
  let hits = @z_algorithm.find_pattern("aabcaabxaab", "aab")
  debug_inspect(hits, content="[0, 4, 8]")
}
```

```mbt check
///|
test "z aliases" {
  let z2 = @z_algorithm.z_function("aaaaa")
  debug_inspect(z2, content="[5, 4, 3, 2, 1]")
  let hits2 = @z_algorithm.z_search("ababa", "aba")
  debug_inspect(hits2, content="[0, 2]")
}
```

```mbt check
///|
test "count pattern" {
  let cnt = @z_algorithm.count_pattern("aaaaa", "aa")
  debug_inspect(cnt, content="4") // overlaps allowed: "aa" at 0,1,2,3
}
```

---

## 6) Why it is O(n)

The right boundary `r` starts at 0 and only ever moves **right**.  
Every character comparison either:

- advances `r` by 1, or
- is avoided by reusing a cached `Z[k]` value.

Since `r` can increase at most `n` times, the total number of character
comparisons across all iterations is **O(n)**.  Building the concatenated
string for pattern matching is O(|P| + |T|), so the full search is also O(n).

```
r: 0 --> ... --> n-1      (monotonically non-decreasing)
      each step = one comparison  =>  O(n) total
```

---

## 7) Common applications

```
Pattern matching         -- find all occurrences of P in T
String borders           -- prefix that is also a suffix
String period detection  -- smallest repeating unit
Counting repeated prefixes
Palindrome detection (combined with reverse)
```

---

## 8) Z vs KMP

Both do pattern matching in O(n).

```
Z-algorithm:  maintains a "Z-box" window; reuses prefix comparisons
KMP:          maintains a failure/next array; reuses suffix-prefix links
```

Z is often simpler to implement and reason about; KMP avoids building a
concatenated string.

---

## 9) Common pitfalls

- Forgetting that `Z[0] = n` (full string, by convention).
- Off-by-one when converting a Z-array index back to a text index: `i - m - 1`.
- Not using a separator between pattern and text (risk of false matches spanning the boundary).
- Using an empty string as the pattern — handled gracefully by returning no matches.
