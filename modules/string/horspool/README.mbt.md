# Boyer-Moore-Horspool Search

## Overview

**Horspool's algorithm** (1980) is a simplification of full Boyer-Moore
that keeps only the **bad-character shift rule**. It is short, easy to
get right, and in practice often as fast as the full algorithm on
natural-language text and binary data thanks to large average shifts.

| Phase | Time | Space |
|---|---|---|
| Pre-processing | `O(m + σ)` | `O(σ)` (`σ` = alphabet size) |
| Search (worst) | `O(n · m)` | `O(σ)` |
| Search (avg) | `O(n / m)` | `O(σ)` |

For comparison, KMP runs in `O(n)` worst case but with a smaller average
shift — Horspool is usually the speed winner in practice.

---

## The bad-character shift

Pre-compute, for each character `c`,

```
shift[c] = m − 1 − (rightmost index of c in p[0..m-2])
shift[c] = m                if c is not in p[0..m-2]
```

The pattern's *last* character is intentionally **excluded** from the
table: if a comparison ends in mismatch at `t[i+m-1]`, the shift is
based on `t[i+m-1]`, and including the last position would only give a
trivial shift of `0`.

To search, align `p` with `t[i .. i+m-1]` and compare *right-to-left*.
On a full match, record `i` and slide forward by `1` for overlapping
semantics. On mismatch, slide forward by `shift[t[i+m-1]]`.

---

## The invariant

> After processing window position `i`:
> - `shift` is exactly the bad-character table of `p`, and
> - every match starting in `[0, i)` has been emitted.

The slide rule is a sufficient condition for skipping `≥ 1` positions
without losing a match — informally, the next alignment must put some
copy of `t[i+m-1]` from `p[0..m-2]` at index `i + m - 1`, which forces
the new `i` to be at most `i + shift[t[i+m-1]]`.

---

## API

```
pub fn find_all(text : Array[Int], pattern : Array[Int]) -> Array[Int]
pub fn find_first(text : Array[Int], pattern : Array[Int]) -> Int?
```

Both inputs are `Array[Int]` of code points. Use any UTF-8 / UTF-16
decoder to feed in non-ASCII strings — the alphabet is internally
folded mod `2^16`, comfortably above standard 8-bit text and BMP
Unicode code units.

`find_all` returns starts of **all overlapping** matches, in order.
For non-overlapping matches, advance by `m` instead of `1` on the
caller side or filter the returned array.

---

## Tests and examples

```mbt check
///|
test "horspool finds repeated pattern" {
  let to_arr = fn(s : String) {
    let r : Array[Int] = []
    for c in s {
      r.push(c.to_int())
    }
    r
  }
  // 'the' occurs at positions 0 and 31.
  let result = @horspool.find_all(
    to_arr("the quick brown fox jumps over the lazy dog"),
    to_arr("the"),
  )
  debug_inspect(result, content="[0, 31]")
}
```

```mbt check
///|
test "horspool first vs none" {
  let to_arr = fn(s : String) {
    let r : Array[Int] = []
    for c in s {
      r.push(c.to_int())
    }
    r
  }
  debug_inspect(
    @horspool.find_first(to_arr("abc"), to_arr("c")),
    content="Some(2)",
  )
  debug_inspect(
    @horspool.find_first(to_arr("abc"), to_arr("z")),
    content="None",
  )
}
```

---

## Use cases

- **Search-and-replace** in editors, where the average case dominates.
- **`grep`-like utilities** on plain text — Horspool is the basis of
  GNU `grep`'s `--fixed-strings` fast path.
- **Binary-file scanning** — small patterns over large files benefit
  most from the average `O(n/m)` complexity.

---

## Pitfalls

- **Worst case is quadratic.** Pathological patterns like
  `aaaaaa...aab` on text `aaaaaaa...aaa` hit `O(nm)`. Use **Boyer-Moore
  with the good-suffix rule** or **KMP** when the worst case matters.
- **Alphabet folding.** Code points outside `[0, 2^16)` share table
  slots. This stays correct (a wrong-character mismatch just yields a
  smaller-than-ideal shift) but loses some speed on huge-alphabet text.
- **Empty pattern** returns no matches by convention; some libraries
  return `[0, 1, ..., n]` instead.

---

## Related concepts

```
Boyer-Moore             full algorithm with bad-char + good-suffix rules
Horspool's variant      this; keeps only bad-char (simpler & fast in practice)
Sunday's variant        uses t[i + m] instead of t[i + m - 1]
KMP                     O(n) worst case but smaller average shift
Aho-Corasick            multi-pattern matching with suffix automaton
```
