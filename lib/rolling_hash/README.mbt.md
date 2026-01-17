# Rolling Hash (Polynomial Hashing)

This package provides **rolling hash** utilities for fast substring matching,
including Rabin–Karp pattern search helpers.

Rolling hashes let you compare substrings in **O(1)** after **O(n)** preprocessing.

---

## 1. Big picture (beginner friendly)

We treat a string as a number in base `b`:

```
hash(s) = s[0]*b^(n-1) + s[1]*b^(n-2) + ... + s[n-1]
```

If we precompute prefix hashes, we can get any substring hash in O(1).

This is the key trick behind Rabin–Karp and many string algorithms.

---

## 2. A tiny numeric example

String `"abcd"` with base 31, mod 1e9+7:

```
values: a=1, b=2, c=3, d=4

prefix[0] = 0
prefix[1] = 1
prefix[2] = 1*31 + 2 = 33
prefix[3] = 33*31 + 3 = 1026
prefix[4] = 1026*31 + 4 = 31810
```

Hash of `"bc"` (indices 1..2):

```
hash("bc") = prefix[3] - prefix[1] * 31^2
           = 1026 - 1*961
           = 65

Check directly: 2*31 + 3 = 65 ✓
```

---

## 2b. Off-by-one clarity (substring ranges)

This README uses half-open ranges `[l, r)`:

```
"abcd"
 index: 0 1 2 3

substring[1, 3) = "bc"
```

So `r` is not included.

---

## 3. Visual sliding window

```
text:    a b c d e f
index:   0 1 2 3 4 5

window length = 3

window 0: [a b c]
window 1:   [b c d]
window 2:     [c d e]
window 3:       [d e f]
```

Rolling update formula:

```
new_hash = (old_hash - left_char * b^(m-1)) * b + new_char
```

So each slide is O(1).

---

## 4. Rabin–Karp pattern matching

Example:

```
text    = "aabcaabxaab"
pattern = "aab"

hash(pattern) = H
slide window:
  i=0 -> "aab" -> hash = H -> match
  i=4 -> "aab" -> hash = H -> match
  i=8 -> "aab" -> hash = H -> match
```

Matches at [0, 4, 8].

---

## 4b. Double hashing intuition

Two different strings can collide under one modulus.  
Using two moduli makes collision probability extremely small:

```
P(collision) ≈ 1 / MOD1 + 1 / MOD2
```

This package uses single hashing, so it is recommended to **verify**
matches when collisions matter.

---

## 5. Example usage (public API)

```mbt check
///|
test "rolling hash pattern search" {
  let hits = @rolling_hash.find_pattern_rabin_karp("aabcaabxaab", "aab")
  inspect(hits, content="[0, 4, 8]")
  inspect(
    @rolling_hash.count_pattern_rabin_karp("mississippi", "issi"),
    content="2",
  )
}
```

---

## 5b. Another example: overlapping matches

```mbt check
///|
test "rolling hash overlapping" {
  let hits = @rolling_hash.find_pattern_rabin_karp("aaaaa", "aa")
  // Overlaps allowed: positions 0,1,2,3
  inspect(hits, content="[0, 1, 2, 3]")
}
```

---

## 6. Why collisions exist (and how to handle them)

A hash is not a perfect fingerprint. Different strings can share the same hash.

Solutions:

1. **Verify** with direct string comparison when hashes match.
2. **Double hashing** (two moduli) to reduce probability.

Collision probability is about `1 / MOD` for random strings.

---

## 7. Common applications

1. **Pattern matching** (Rabin–Karp)
2. **Longest common substring** (binary search + hashes)
3. **Palindrome checks** (compare forward and reverse hashes)
4. **Fast substring equality queries**
5. **Distinct substring counting**

---

## 8. Complexity

```
Precompute prefix hashes: O(n)
Substring hash query:     O(1)
Pattern search:           O(n + m) expected
```

---

## 9. Practical tips

1. Use a large prime modulus.
2. Base should be larger than alphabet size (31 or 37 for lowercase).
3. Precompute powers of base.
4. If hash difference is negative, add MOD.
5. For security‑critical uses, always verify matches.

### Common beginner mistake

Forgetting to normalize substring hashes to the same power of `b`:

```
hash(l, r) = prefix[r] - prefix[l] * b^(r-l)
```

If you skip the multiplication, different positions won't compare correctly.

---

## 10. Summary

Rolling hash gives a fast way to compare substrings:

- O(1) substring hashes,
- O(n + m) expected pattern matching,
- great building block for many string algorithms.
