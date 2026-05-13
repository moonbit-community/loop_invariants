# Suffix Array (Beginner-Friendly Guide)

This package provides:

- `suffix_array(text)` - build the raw suffix array
- `lcp_array(text, sa)` - build the LCP array from an existing suffix array
- `SuffixArray` - precomputed index with pattern search and substring analytics

---

## 1. What is a suffix array?

A **suffix array** (SA) is an array of integers that gives the starting
positions of all suffixes of a string, sorted in lexicographic order.

### All suffixes of `"banana"`

```
Index  Suffix
─────  ──────
  0    banana
  1    anana
  2    nana
  3    ana
  4    na
  5    a
```

### Sorted lexicographically

```
Rank   Suffix    Start
────   ──────    ─────
  0    a           5
  1    ana         3
  2    anana       1
  3    banana      0
  4    na          4
  5    nana        2
```

### The suffix array records just the start positions in sorted order

```
SA = [ 5, 3, 1, 0, 4, 2 ]
       ↑  ↑  ↑  ↑  ↑  ↑
       a ana ana ban na  nana
         na  na
```

---

## 2. What is the LCP array?

LCP = **Longest Common Prefix** between adjacent suffixes in SA order.

```
SA rank   Suffix      LCP with previous
────────  ──────      ──────────────────
  0       a              0  (no previous)
  1       ana            1  ("a")
  2       anana          3  ("ana")
  3       banana         0
  4       na             0
  5       nana           2  ("na")
```

```
SA  = [5, 3, 1, 0, 4, 2]
LCP = [0, 1, 3, 0, 0, 2]
```

### Aligned view

```
        a
        ana
        anana
        banana
        na
        nana
LCP:  0  1  3  0  0  2

lcp(a,       ana)   = 1  → "a"
lcp(ana,   anana)   = 3  → "ana"
lcp(anana, banana)  = 0
lcp(banana,    na)  = 0
lcp(na,      nana)  = 2  → "na"
```

The maximum LCP value identifies the **longest repeated substring**.

---

## 3. Example usage (basic)

```mbt check
///|
test "suffix array helpers" {
  let sa = @suffix_array.suffix_array("banana")
  let lcp = @suffix_array.lcp_array("banana", sa)
  debug_inspect(sa, content="[5, 3, 1, 0, 4, 2]")
  debug_inspect(lcp, content="[0, 1, 3, 0, 0, 2]")
}
```

---

## 4. How suffix arrays are built: prefix doubling

The implementation uses the **prefix-doubling** (also called "DC3-free" or
"Manber-Myers") algorithm.  Time: O(n log^2 n).

### Intuition

Start by ranking suffixes by their first 1 character. Then repeatedly
double the comparison window, re-sorting by the pair
`(rank[i], rank[i+k])` until every suffix has a unique rank.

### Step-by-step for `"banana"` (n = 6)

```
Initial ranks (by char code):
  index:  0   1   2   3   4   5
  char:   b   a   n   a   n   a
  rank:  98  97 110  97 110  97

k=1 sort key = (rank[i], rank[i+1]):
  SA after sort: [5, 3, 1, 0, 4, 2]
  new ranks:      0   3   4   1   2   0

k=2 sort key = (rank[i], rank[i+2]):
  SA after sort: [5, 3, 1, 0, 4, 2]
  new ranks:      0   3   5   1   2   4

  All ranks unique → done.
```

Each doubling pass costs O(n log n) for the sort, and there are at most
O(log n) passes, giving O(n log^2 n) total.

---

## 5. Pattern matching via binary search

Because the suffix array is sorted, all occurrences of a pattern `p` form
a **contiguous block** of SA entries.  Two binary searches (lower bound and
upper bound) locate that block in O(m log n) time.

### Finding `"ana"` in `"banana"`

```
Sorted suffixes:       Pattern "ana":
  rank 0 → a           a < "ana"  ← below range
  rank 1 → ana         "ana" == prefix? YES  ← lo = 1
  rank 2 → anana       "ana" == prefix? YES
  rank 3 → banana      b > "ana"  ← above range  → hi = 2
  rank 4 → na
  rank 5 → nana

Match range: [lo=1, hi=2]  (inclusive)
SA[1] = 3, SA[2] = 1

"ana" found at text positions: 1, 3
```

```
text:  b a n a n a
idx:   0 1 2 3 4 5
           ↑   ↑
           1   3
```

### Binary search pseudocode

```
lo = first index i where  text[sa[i]:] >= pattern
hi = last  index i where  text[sa[i]:] starts with pattern

matches at sa[lo], sa[lo+1], ..., sa[hi]
```

`SuffixArray::search` returns this `[lo, hi]` range as `Some((lo, hi))`.

---

## 6. Using the SuffixArray helper

```mbt check
///|
test "suffix array search" {
  let sa = @suffix_array.SuffixArray("mississippi")
  debug_inspect(sa.find_all("issi"), content="[1, 4]")
  debug_inspect(sa.count("ss"), content="2")
}
```

---

## 7. Longest repeated substring

The longest repeated substring corresponds to the maximum value in the LCP
array. The substring is `text[sa[max_lcp_idx] : sa[max_lcp_idx] + max_lcp]`.

```
"banana":  max LCP = 3 at rank 2
           sa[2] = 1  →  text[1:4] = "ana"
```

```mbt check
///|
test "longest repeated substring" {
  let sa = @suffix_array.SuffixArray("banana")
  debug_inspect(
    sa.longest_repeated_substring(),
    content=(
      #|"ana"
    ),
  )
}
```

```mbt check
///|
test "longest repeated substring overlap" {
  let sa = @suffix_array.SuffixArray("aaaaa")
  debug_inspect(
    sa.longest_repeated_substring(),
    content=(
      #|"aaaa"
    ),
  )
}
```

---

## 8. Count distinct substrings

Every suffix of length L contributes L substrings, but the first `lcp[i]`
of them were already seen in the previous SA entry. Summing the savings:

```
distinct = n*(n+1)/2 - sum(lcp[1..n-1])
```

For `"banana"` (n = 6):

```
Total    = 6*7/2 = 21
LCP sum  = 1+3+0+0+2 = 6
Distinct = 21 - 6 = 15
```

```mbt check
///|
test "distinct substrings" {
  let sa = @suffix_array.SuffixArray("banana")
  debug_inspect(sa.count_distinct_substrings(), content="15")
}
```

---

## 9. Complexity summary

```
Operation              Time           Space
─────────────────────  ─────────────  ──────
Build SuffixArray      O(n log^2 n)   O(n)
Build LCP (Kasai)      O(n)           O(n)
Pattern search         O(m log n)     O(1)
find_all (k matches)   O(m log n +    O(k)
                         k log k)
longest_repeated       O(n)           O(n)
count_distinct         O(n)           O(1)
```

---

## 10. When to use suffix arrays

- Fast substring search with many queries on the same text
- Counting or enumerating repeated substrings
- Lexicographic suffix ordering (useful in BWT / compression)
- Counting distinct substrings

---

## 11. Summary

Suffix arrays + LCP provide a compact string index:

- sorted suffixes in O(n log^2 n),
- O(m log n) binary search for any pattern,
- O(n) LCP construction reveals all repeated substrings.
