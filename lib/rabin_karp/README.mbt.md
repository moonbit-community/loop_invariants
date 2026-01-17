# Rabin–Karp (Rolling Hash String Matching)

This package implements **Rabin–Karp**, a fast string matching algorithm based
on **rolling hashes**.

It is great when:

- you want a **simple** string search,
- you have **many patterns**,
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

We treat a string like a number in base `b`:

```
hash(s[0..m-1]) =
  s0 * b^(m-1) + s1 * b^(m-2) + ... + s(m-1)
```

Rolling update (slide by 1):

```
new_hash = (old_hash - s[i] * b^(m-1)) * b + s[i+m]
```

Example (base 10):

```
hash("123") = 1*100 + 2*10 + 3 = 123
hash("234") = (123 - 1*100)*10 + 4 = 234
```

---

## 3. Small step‑by‑step example

Text: `"aabab"`
Pattern: `"ab"`

Let base = 31, ASCII chars.

```
hash("ab") = 97*31 + 98 = 3105
```

Window hashes:

```
i=0: "aa" -> 97*31 + 97 = 3104
i=1: "ab" -> 3105  -> match (verify characters)
i=2: "ba" -> 98*31 + 97 = 3135
i=3: "ab" -> 3105  -> match
```

Matches at positions [1, 3].

---

## 4. Why verification is needed

Hashes can collide:

```
hash("ab") == hash("cd")   // possible with unlucky hash
```

So we **always verify** characters when hashes match.

This makes the algorithm **correct**, with expected O(n) time.

---

## 5. API overview

From `pkg.generated.mbti`:

- `rabin_karp_search(text, pattern) -> Array[Int]`
- `rabin_karp_count(text, pattern) -> Int`
- `rabin_karp_multi(text, patterns) -> Array[(Int, Int)]`

`rabin_karp_multi` returns `(pattern_index, position)` pairs.

---

## 6. Example usage

```mbt check
///|
test "rabin karp search" {
  let matches = @rabin_karp.rabin_karp_search("abababab", "aba")
  inspect(matches, content="[0, 2, 4]")
}
```

```mbt check
///|
test "rabin karp count" {
  inspect(@rabin_karp.rabin_karp_count("aaaa", "aa"), content="3")
}
```

```mbt check
///|
test "rabin karp multi" {
  let patterns = ["aba", "bab", "ab"]
  let hits = @rabin_karp.rabin_karp_multi("ababab", patterns)
  inspect(hits, content="[(0, 0), (1, 1), (0, 2), (1, 3), (2, 0), (2, 2), (2, 4)]")
}
```

---

## 7. Diagram: sliding window

```
text:    a b a b a b
index:   0 1 2 3 4 5
pattern: a b a

window 0: [a b a]  -> match
window 1:   [b a b]
window 2:     [a b a]  -> match
window 3:       [b a b]
```

---

## 8. Multiple pattern search (why Rabin–Karp shines)

If you have many patterns, hashing makes it cheap to compare all of them:

```
patterns = {P0, P1, P2}
For each window in text:
  compare hash(window) with all pattern hashes
  if match, verify
```

This is often simpler than building a complex automaton.

---

## 9. Complexity

```
Expected: O(n + m)
Worst:    O(nm) if every hash collides (very unlikely)
```

With verification, correctness is guaranteed.

---

## 10. Practical tips

1. Use a large modulus (or 64‑bit hash) to reduce collisions.
2. Precompute `b^(m-1)` for rolling.
3. Always verify when hashes match.
4. For case‑insensitive search, normalize the text and pattern first.

---

## 11. Summary

- Rabin–Karp uses rolling hashes for fast window checks.
- Hash equality is a **filter**, not proof.
- Verification makes it exact.
- Great for multiple patterns or quick substring searches.
