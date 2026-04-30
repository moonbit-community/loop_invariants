# String Hashing (Polynomial Rolling Hash)

This package provides **string hashing** helpers for fast substring comparison
and pattern matching.  It builds polynomial rolling hash tables in O(n) and
answers every substring hash query in O(1).

---

## 1. Big picture (beginner friendly)

Turn a string into a number by treating each character as a digit in a
polynomial evaluated at a fixed base `B`:

```
hash("abc") = 'a'*B^2 + 'b'*B^1 + 'c'*B^0
```

Character values start at 1 (`'a'=1, 'b'=2, ...`) so a leading `'a'` never
disappears into a zero term.  A large prime modulus `p` keeps the numbers
manageable.

With a precomputed **prefix hash table** you can extract the hash of any
substring in O(1) instead of re-scanning the characters.

---

## 2. Polynomial hash formula (ASCII diagram)

```
String:    s[0]      s[1]      s[2]    ...   s[n-1]

           +------+  +------+  +------+      +------+
           | s[0] |  | s[1] |  | s[2] |  ... |s[n-1]|
           +--+---+  +--+---+  +--+---+      +--+---+
              |         |         |              |
          * B^(n-1)  * B^(n-2)  * B^(n-3)    * B^0
              |         |         |              |
              +----+----+---------+----  ...  ---+
                   |
               sum mod p
                   |
           hash(s[0..n-1])
```

Each character contributes a term `s[i] * B^(n-1-i)`.  All terms are summed
modulo a large prime `p = 10^9 + 7`.

---

## 3. Building the prefix hash table

A **prefix hash** `prefix[i]` stores the hash of the first `i` characters.
The recurrence is:

```
prefix[0] = 0
prefix[i] = prefix[i-1] * B + s[i-1]   (mod p)
```

Simultaneously, a **power table** stores `powers[i] = B^i mod p`:

```
powers[0] = 1
powers[i] = powers[i-1] * B            (mod p)
```

Step-by-step for `s = "abcd"`, `B = 31`, `p = 10^9 + 7`
(character values: `a=1, b=2, c=3, d=4`):

```
i    s[i-1]   prefix[i]                         powers[i]
---  -------  ----------------------------------------  ----------
0    (none)   0                                         1
1    a = 1    0 * 31 + 1           =     1              31
2    b = 2    1 * 31 + 2           =    33              961
3    c = 3   33 * 31 + 3           =  1026              29791
4    d = 4   1026 * 31 + 4         = 31810              923521
```

---

## 4. Extracting any substring hash in O(1)

The key observation is:

```
prefix[r] = prefix[l] * B^(r-l) + hash(s[l..r))
```

Rearranging gives the O(1) query formula (exclusive end `r`):

```
hash(s[l..r)) = (prefix[r] - prefix[l] * powers[r-l] + p) mod p
```

The `+ p` before the outer `mod` prevents negative values from the
subtraction.

### Visual: extract hash of "bc" from "abcd" (positions 1..3, exclusive end)

```
prefix array:
  index:  [0]   [1]   [2]   [3]   [4]
  value:    0     1    33  1026  31810
                  ^               ^
                  |               |
                 l=1            r=3   (substring s[1..3) = "bc")

hash("bc") = (prefix[3] - prefix[1] * powers[2] + p) mod p
           = (1026       - 1        * 961        + p) mod p
           = 65
```

Verify directly: `2*31 + 3 = 65` -- correct.

---

## 5. Sliding window for pattern matching

To find a pattern of length `m` inside a text of length `n`, slide a window
of width `m` across the text and compare hashes in O(1) per step:

```
text:    a  b  a  b  a  b  a  b
index:   0  1  2  3  4  5  6  7

pattern = "aba"  (length m = 3)
target hash H = hash("aba")

window i=0: text[0..3) = "aba"  -> hash = H  -> match at 0
window i=1: text[1..4) = "bab"  -> hash != H -> skip
window i=2: text[2..5) = "aba"  -> hash = H  -> match at 2
window i=3: text[3..6) = "bab"  -> hash != H -> skip
window i=4: text[4..7) = "aba"  -> hash = H  -> match at 4
window i=5: text[5..8) = "bab"  -> hash != H -> skip
```

Result positions: `[0, 2, 4]`

Each window check is O(1) (a single prefix-table lookup), giving O(n + m)
overall.

---

## 6. Double hashing for collision resistance

Two different strings can share the same hash under a single modulus (a
**collision**).  Using two independent (base, modulus) pairs makes this
extremely unlikely:

```
Single hash:  P(collision) ~ 1 / (10^9 + 7)   ~ 10^-9
Double hash:  P(collision) ~ 1 / ((10^9+7) * (10^9+9))  ~ 10^-18
```

The package provides a private `DoubleHash` struct that computes both hashes
in a single pass and compares them as a pair `(h1, h2)`.

---

## 7. Longest common prefix via binary search

Given positions `i` and `j`, the length of the longest common prefix of the
two suffixes can be found in O(log n):

```
Binary search on length L:
  if hash(s[i..i+L)) == hash(s[j..j+L))  -> L is feasible, try longer
  else                                    -> L is too long, try shorter

Each hash comparison is O(1), so the total cost is O(log n).
```

---

## 8. Off-by-one reference

This package uses **half-open** (exclusive end) ranges internally:

```
s = "abcde"
      01234

get_hash(1, 4)  ->  hash of s[1..4) = "bcd"  (positions 1, 2, 3)
```

The prefix array has `n + 1` entries so that `prefix[0] = 0` acts as a
sentinel and `prefix[n]` covers the full string.

---

## 9. Example usage (public API)

```mbt check
///|
test "string hash example" {
  let hits = @string_hash.hash_pattern_match("abababab", "aba")
  inspect(hits, content="[0, 2, 4]")
}
```

---

## 10. Step-by-step: hash_pattern_match walk-through

Input: `text = "abababab"`, `pattern = "aba"`

**Step 1** -- build prefix table for text (shown compactly):

```
i    char  prefix[i+1]
0    a=1   1
1    b=2   33
2    a=1   1024
3    b=2   31746
4    a=1   983927
5    b=2   30501741
6    a=1   945554972
7    b=2   29312204134 mod p = ...
```

**Step 2** -- compute `target = hash("aba")`:

```
prefix for "aba":
  prefix[0] = 0
  prefix[1] = 1         ('a')
  prefix[2] = 33        ('ab')
  prefix[3] = 1024      ('aba')
target = 1024
```

**Step 3** -- slide window of length 3:

```
i=0: get_hash(0, 3) = 1024  == target  -> push 0
i=1: get_hash(1, 4) != 1024            -> skip
i=2: get_hash(2, 5) = 1024  == target  -> push 2
i=3: get_hash(3, 6) != 1024            -> skip
i=4: get_hash(4, 7) = 1024  == target  -> push 4
i=5: get_hash(5, 8) != 1024            -> skip
```

Result: `[0, 2, 4]`

---

## 11. Why collisions matter

Different strings can share the same hash value.  For
correctness-critical tasks:

- **Verify** by direct comparison when hashes match, or
- **Use double hashing** (`DoubleHash`) to reduce probability to ~10^-18.

---

## 12. Common applications

1. **Pattern matching** -- find all occurrences of a pattern in O(n + m).
2. **Distinct substring counting** -- count unique substrings of a fixed length.
3. **Longest common prefix** -- binary search + O(1) hash comparison.
4. **Palindrome detection** -- compare forward and reverse hashes.
5. **Lexicographic substring comparison** -- binary search for LCP, then
   compare the next character.

---

## 13. Complexity summary

```
Build prefix hash table:      O(n)
Substring hash query:         O(1)
Pattern search (n text, m pat): O(n + m) expected
Longest common prefix:        O(log n)
Count distinct (length k):    O(n) expected
```

---

## 14. Practical tips

1. Use a large prime modulus (`10^9 + 7` is used here).
2. The base must be larger than the alphabet size (31 > 26).
3. Precompute powers of the base up to `n` (done in the constructor).
4. Always add `MOD` before the final `mod` when subtracting prefix hashes.
5. For security-critical applications, verify character-by-character after
   every hash match.

### Common beginner mistake

Forgetting to align `prefix[l]` to the window start:

```
hash(s[l..r)) = prefix[r] - prefix[l] * powers[r-l]
                                        ^^^^^^^^^^^
                                        must not be skipped!
```

Without the multiplication, `prefix[l]` carries the wrong polynomial weight
and substrings at different positions will not compare correctly.

---

## 15. Summary

String hashing is a fast, practical tool:

- O(1) substring hash after O(n) preprocessing,
- O(n + m) pattern search,
- simple to implement and extend to double hashing.
