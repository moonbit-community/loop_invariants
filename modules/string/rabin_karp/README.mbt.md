# Rabin-Karp (Rolling Hash String Matching)

This package implements **Rabin-Karp**, a fast string matching algorithm based
on **rolling hashes**.

It is great when:

- you want a **simple** string search,
- you have **many patterns** of the same or different lengths,
- or you want fast approximate checks before verifying characters.

---

## 1. Big idea (beginner friendly)

Instead of comparing strings character by character every time, compare their
**hashes**.

```
pattern = "aba"
text    = "acababa"

hash("aba") = H

Slide a window of length 3:
  "aca" -> hash != H
  "cab" -> hash != H
  "aba" -> hash == H  -> verify characters -> match!
```

The rolling hash lets us update the hash in O(1) time when the window slides.

---

## 2. Rolling hash formula

We treat a string like a polynomial evaluated at `base`:

```
hash(s[0..m-1]) =
  s[0] * b^(m-1) + s[1] * b^(m-2) + ... + s[m-1] * b^0
```

### Sliding window update

When the window moves one step to the right, only two characters change: the
leftmost character leaves and a new rightmost character enters.

```
  Before:  hash( s[i .. i+m-1] )
  After:   hash( s[i+1 .. i+m] )

  Formula:
    new_hash = (old_hash - s[i] * b^(m-1)) * b + s[i+m]
```

### ASCII diagram of one roll step

```
  text:     ... | s[i] | s[i+1] | s[i+2] | ... | s[i+m-1] | s[i+m] | ...
                  ^                                           ^
                  |  leaving window                          |  entering window
                  |                                          |
  old_hash = s[i]*b^(m-1) + s[i+1]*b^(m-2) + ... + s[i+m-1]*b^0

  Step 1 - remove s[i]:
    (old_hash - s[i] * b^(m-1))
    = s[i+1]*b^(m-2) + ... + s[i+m-1]*b^0  * (after subtracting, divide implicit)

  Step 2 - shift left by one power (multiply by b):
    * b  =>  s[i+1]*b^(m-1) + ... + s[i+m-1]*b^1

  Step 3 - add s[i+m]:
    + s[i+m]  =>  s[i+1]*b^(m-1) + ... + s[i+m-1]*b^1 + s[i+m]*b^0
               =  hash( s[i+1..i+m] )
```

### Concrete example (base 10 for clarity)

```
hash("123") = 1*100 + 2*10 + 3 = 123
hash("234") = (123 - 1*100) * 10 + 4
            = 23 * 10 + 4
            = 234
```

---

## 3. Small step-by-step example

Text: `"aabab"`
Pattern: `"ab"`

Let base = 31.  Characters are mapped: `'a'` -> 1, `'b'` -> 2, ...

```
hash("ab") = 1*31 + 2 = 33
```

Window hashes:

```
i=0: "aa" -> 1*31 + 1 = 32          (no match)
i=1: "ab" -> 1*31 + 2 = 33  == 33   -> verify -> match at 1
i=2: "ba" -> 2*31 + 1 = 63          (no match)
i=3: "ab" -> 1*31 + 2 = 33  == 33   -> verify -> match at 3
```

Matches at positions `[1, 3]`.

---

## 4. Why verification is needed

Hashes can collide:

```
hash("ab") == hash("cd")   // possible with an unlucky hash
```

So we **always verify** characters when hashes match.

This makes the algorithm **correct**, with expected O(n + m) time.

---

## 5. Diagram: full sliding window scan

```
text:     a  c  a  b  a  b  a
index:    0  1  2  3  4  5  6
          +--+--+
window 0: [a  c  a]    hash != pattern_hash
             +--+--+
window 1:    [c  a  b]  hash != pattern_hash
                +--+--+
window 2:       [a  b  a]  hash == pattern_hash -> verify -> MATCH at 2
                   +--+--+
window 3:          [b  a  b]  hash != pattern_hash
                      +--+--+
window 4:             [a  b  a]  hash == pattern_hash -> verify -> MATCH at 4
```

Each window shift costs O(1) due to the rolling formula.

---

## 6. Comparison with KMP

Both Rabin-Karp and KMP run in O(n + m) expected time for a single pattern,
but they work in fundamentally different ways:

```
                KMP                          Rabin-Karp
                ---                          ----------
Preprocess:     Build failure table O(m)     Compute pattern hash O(m)
                (stores partial match info)  (a single integer)

Per character:  Follow failure links          Update rolling hash O(1)
                O(1) amortised               No backtracking needed

On candidate:   Guaranteed correct            Must verify characters
                (no false positives)         (hash collision possible)

Multiple        Requires Aho-Corasick        Group by length; one pass
patterns:       (separate automaton)         per distinct length

Worst case:     O(n + m) always              O(nm) if every hash collides
                                             (extremely unlikely in practice)

Best for:       One fixed pattern,           Many patterns, or when
                worst-case guarantees        simplicity is preferred
```

### When to choose Rabin-Karp over KMP

- You have multiple patterns of the same length and want a single scan.
- The set of patterns changes at runtime (no need to rebuild an automaton).
- You want a concise implementation with easy-to-understand invariants.

### When to choose KMP over Rabin-Karp

- You need a strict O(n + m) worst-case guarantee (no hash collisions).
- You are matching a single fixed pattern against many texts.
- You want to avoid the (small) risk of spurious hash hits.

---

## 7. Multiple pattern search (why Rabin-Karp shines)

If you have many patterns, group them by length.  Each distinct length
requires exactly one rolling hash pass:

```
patterns = {P0 (len 3), P1 (len 3), P2 (len 5)}

Pass for len=3:
  slide window of size 3 over text
  at each position: compare hash(window) with hash(P0) and hash(P1)
  if match, verify characters

Pass for len=5:
  slide window of size 5 over text
  at each position: compare hash(window) with hash(P2)
  if match, verify characters
```

Total cost: O(n * number_of_distinct_lengths + sum_of_pattern_lengths)

For KMP or Aho-Corasick, you would need to build a trie/automaton first.
Rabin-Karp requires no such preprocessing.

---

## 8. API overview

From `pkg.generated.mbti`:

- `rabin_karp_search(text, pattern) -> Array[Int]`
- `rabin_karp_count(text, pattern) -> Int`
- `rabin_karp_multi(text, patterns) -> Array[(Int, Int)]`

`rabin_karp_multi` returns `(pattern_index, position)` pairs.

---

## 9. Example usage

```mbt check
///|
test "rabin karp search" {
  let matches = @rabin_karp.rabin_karp_search("abababab", "aba")
  debug_inspect(matches, content="[0, 2, 4]")
}
```

```mbt check
///|
test "rabin karp count" {
  debug_inspect(@rabin_karp.rabin_karp_count("aaaa", "aa"), content="3")
}
```

```mbt check
///|
test "rabin karp multi" {
  let patterns = ["aba", "bab", "ab"]
  let hits = @rabin_karp.rabin_karp_multi("ababab", patterns)
  debug_inspect(
    hits,
    content="[(0, 0), (1, 1), (0, 2), (1, 3), (2, 0), (2, 2), (2, 4)]",
  )
}
```

---

## 10. Complexity

```
Expected: O(n + m) per pattern length
Worst:    O(nm)    if every hash collides (very unlikely with a good modulus)
```

With character verification, correctness is guaranteed regardless of
collisions.

---

## 11. Practical tips

1. Use a large prime modulus (this implementation uses 1_000_000_007) to
   reduce collision probability.
2. Precompute `b^(m-1) mod p` once per pattern length for the rolling update.
3. Always verify characters when hashes match; never trust the hash alone.
4. For case-insensitive search, normalize the text and pattern to the same
   case before passing them to the functions.
5. For binary or Unicode data, choose a base larger than the alphabet size to
   avoid trivial collisions.

---

## 12. Summary

- Rabin-Karp uses polynomial rolling hashes to slide a window across the text
  in O(1) per step.
- Hash equality is a **filter**, not proof; character verification makes it
  exact.
- It excels at multi-pattern search because all patterns of the same length
  can be checked in a single pass.
- KMP offers a strict O(n + m) worst case and no false positives; prefer it
  when those guarantees matter.
