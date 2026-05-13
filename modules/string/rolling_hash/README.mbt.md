# Rolling Hash (Polynomial Hashing)

This package provides **rolling hash** utilities for fast substring matching,
including Rabin-Karp pattern search helpers.

Rolling hashes let you compare substrings in **O(1)** after **O(n)** preprocessing.

---

## 1. Big picture (beginner friendly)

We treat a string as a polynomial evaluated at base `b`:

```
hash(s[0..n-1]) = s[0]*b^(n-1) + s[1]*b^(n-2) + ... + s[n-1]*b^0
```

If we precompute prefix hashes, we can get any substring hash in O(1).

This is the key trick behind Rabin-Karp and many string algorithms.

---

## 2. Polynomial hash formula (ASCII diagram)

```
String:   s[0]   s[1]   s[2]  ...  s[n-1]

Weights:   b^(n-1)  b^(n-2)  b^(n-3)  ...   b^0

          +-------+  +-------+  +-------+        +-------+
          | s[0]  |  | s[1]  |  | s[2]  |  ...   |s[n-1] |
          +---+---+  +---+---+  +---+---+        +---+---+
              |          |          |                  |
          * b^(n-1)  * b^(n-2)  * b^(n-3)         * b^0
              |          |          |                  |
              +----------+----------+----  ...  -------+
                                    |
                                  sum mod p
                                    |
                               hash(s[0..n-1])
```

Each character is multiplied by a decreasing power of `b`, and everything
is summed modulo a large prime `p`.  Character values start at 1 (`'a'` = 1,
`'b'` = 2, ...) so that a leading `'a'` never disappears into a zero weight.

---

## 3. Prefix hashes and O(1) substring extraction

### How prefix hashes are built

```
String:        a    b    c    d
Index:         0    1    2    3

prefix[0] = 0
prefix[1] = a
prefix[2] = a*b  + c_b
prefix[3] = a*b^2 + c_b*b + c_c
prefix[4] = a*b^3 + c_b*b^2 + c_c*b + c_d
```

Where `c_x` is the numeric value of character `x`.

### Extracting a substring hash in O(1)

The key observation is that `prefix[r] = prefix[l] * b^(r-l) + hash(s[l..r-1])`.
Rearranging gives the O(1) query formula:

```
  prefix array (0-indexed length):
  +--------+--------+--------+--------+--------+
  | [0]=0  | [1]=ph1| [2]=ph2| [3]=ph3| [4]=ph4|
  +--------+--------+--------+--------+--------+
       ^                          ^
       |                          |
       l=1                        r+1=4    (substring s[1..3] = "bcd")

  hash(s[l..r]) = (prefix[r+1] - prefix[l] * b^(r-l+1)) mod p
               = (prefix[4]   - prefix[1]  * b^3       ) mod p
```

The multiplication by `b^(r-l+1)` "shifts" `prefix[l]` so its polynomial
weight aligns with the start of the substring, making the subtraction exact.

---

## 4. Step-by-step example: hash of "abc" and substring extraction

String `"abc"`, base `b = 31`, mod `p = 10^9 + 7`.
Character values: `a=1, b=2, c=3`.

### Step 1: build power table

```
pow[0] = 1
pow[1] = 31
pow[2] = 961
pow[3] = 29791
```

### Step 2: build prefix hashes

```
prefix[0] = 0
prefix[1] = 0 * 31 + 1           =   1        (just 'a')
prefix[2] = 1 * 31 + 2           =  33        ('a','b')
prefix[3] = 33 * 31 + 3          = 1026        ('a','b','c')
```

### Step 3: hash of the full string "abc"

```
hash("abc") = prefix[3] = 1026
```

Verify directly: `1*31^2 + 2*31 + 3 = 961 + 62 + 3 = 1026` -- correct.

### Step 4: extract hash of substring "bc" (indices 1..2, inclusive)

```
l = 1, r = 2, len = r - l + 1 = 2

hash("bc") = (prefix[3] - prefix[1] * pow[2] + p) mod p
           = (1026       - 1        * 961     + p) mod p
           = 65
```

Verify directly: `2*31 + 3 = 65` -- correct.

```
  prefix:  [0]   [1]   [2]   [3]
             0     1    33  1026
                   ^           ^
                   |           |
                  l=1        r+1=3

  hash("bc") = prefix[3] - prefix[1] * 31^2
             = 1026 - 961
             = 65
```

---

## 5. Off-by-one clarity (substring ranges)

This package uses **inclusive** ranges `[l, r]` in its API:

```
"abcd"
 index: 0 1 2 3

get_hash(1, 2)  -->  hash of "bc"   (positions 1 and 2 inclusive)
```

Internally, prefix arrays use a 1-indexed end (`prefix[r+1]`) to keep the
formula clean and to allow `prefix[0] = 0` as a sentinel.

---

## 6. Visual sliding window (Rabin-Karp pattern matching)

```
text:    a b c d e f
index:   0 1 2 3 4 5

window length = 3

window 0: [a b c] d e f
window 1:  a[b c d]e f
window 2:  a b[c d e]f
window 3:  a b c[d e f]
```

Each window hash is read directly from the prefix table in O(1) rather than
recomputing from scratch, giving O(n + m) expected search time.

---

## 7. Rabin-Karp pattern matching

Example:

```
text    = "aabcaabxaab"
pattern = "aab"

hash(pattern) = H

Check each window of length 3:
  i=0 -> text[0..2] = "aab" -> hash = H -> verify -> match at 0
  i=1 -> text[1..3] = "abc" -> hash != H
  i=2 -> text[2..4] = "bca" -> hash != H
  i=3 -> text[3..5] = "caa" -> hash != H
  i=4 -> text[4..6] = "aab" -> hash = H -> verify -> match at 4
  ...
  i=8 -> text[8..10]= "aab" -> hash = H -> verify -> match at 8
```

Matches at positions: `[0, 4, 8]`.

---

## 8. Double hashing intuition

Two different strings can collide under one modulus.
Using two independent (base, modulus) pairs makes collision probability
extremely small:

```
P(collision, single hash)  ~  1 / MOD          (~10^-9)
P(collision, double hash)  ~  1 / (MOD1*MOD2)  (~10^-18)
```

This package offers `DoubleRollingHash` (private) used by
`longest_common_substring` and `count_distinct_substrings`.
The public Rabin-Karp functions use single hashing and verify every hit
character-by-character to eliminate false positives.

---

## 9. Example usage (public API)

```mbt check
///|
test "rolling hash pattern search" {
  let hits = @rolling_hash.find_pattern_rabin_karp("aabcaabxaab", "aab")
  debug_inspect(hits, content="[0, 4, 8]")
  debug_inspect(
    @rolling_hash.count_pattern_rabin_karp("mississippi", "issi"),
    content="2",
  )
}
```

---

## 9b. Another example: overlapping matches

```mbt check
///|
test "rolling hash overlapping" {
  let hits = @rolling_hash.find_pattern_rabin_karp("aaaaa", "aa")
  // Overlaps allowed: positions 0,1,2,3
  debug_inspect(hits, content="[0, 1, 2, 3]")
}
```

---

## 10. Why collisions exist (and how to handle them)

A hash is not a perfect fingerprint.  Different strings can share the same
hash value under a finite modulus.

Solutions:

1. **Verify** with direct string comparison when hashes match (done by
   `find_pattern_rabin_karp`).
2. **Double hashing** (two independent moduli) to reduce probability to ~10^-18.

Collision probability for a random string pair is approximately `1 / MOD`.

---

## 11. Common applications

1. **Pattern matching** (Rabin-Karp)
2. **Longest common substring** (binary search + hashes)
3. **Palindrome checks** (compare forward and reverse hashes)
4. **Fast substring equality queries**
5. **Distinct substring counting**

---

## 12. Complexity

```
Precompute prefix hashes: O(n)
Substring hash query:     O(1)
Pattern search:           O(n + m) expected
Longest common substring: O((n + m) log(min(n, m)))
Count distinct substrings:O(n^2 log n)
```

---

## 13. Practical tips

1. Use a large prime modulus (this package uses 10^9 + 7).
2. Base should be larger than the alphabet size (31 for lowercase ASCII).
3. Precompute powers of base up to `n` (done in the constructor).
4. If the hash difference is negative, add MOD before taking mod again.
5. For security-critical uses, always verify matches character by character.

### Common beginner mistake

Forgetting to normalise the prefix hash to the same power of `b`:

```
hash(s[l..r]) = prefix[r+1] - prefix[l] * b^(r-l+1)
                                          ^^^^^^^^^^^
                                          must not be skipped!
```

Without the multiplication, `prefix[l]` is not aligned to the start of
the window and substrings at different positions will not compare correctly.

---

## 14. Summary

Rolling hash gives a fast way to compare substrings:

- O(1) substring hash queries after O(n) preprocessing,
- O(n + m) expected pattern matching (Rabin-Karp),
- great building block for many string algorithms.
