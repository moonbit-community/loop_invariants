# Suffix Array (Beginner‑Friendly Guide)

This package provides:

- `suffix_array(text)`
- `lcp_array(text, sa)`
- `SuffixArray` helper type with search utilities

---

## 1. What is a suffix array?

Take every suffix of a string and sort them.

Example: `"banana"`

Suffixes:

```
Index  Suffix
0      banana
1      anana
2      nana
3      ana
4      na
5      a
```

Sorted:

```
Rank  Suffix    Index
0     a         5
1     ana       3
2     anana     1
3     banana    0
4     na        4
5     nana      2
```

Suffix array:

```
SA = [5, 3, 1, 0, 4, 2]
```

---

## 2. What is the LCP array?

LCP = **Longest Common Prefix** of adjacent suffixes in SA order.

For `"banana"`:

```
SA:   [5, 3, 1, 0, 4, 2]
Suffixes: a, ana, anana, banana, na, nana

LCP: [0, 1, 3, 0, 0, 2]
```

Explanation:

- LCP(ana, a) = 1
- LCP(anana, ana) = 3
- etc.

---

## 3. Example usage (basic)

```mbt check
///|
test "suffix array helpers" {
  let sa = @suffix_array.suffix_array("banana")
  let lcp = @suffix_array.lcp_array("banana", sa[:])
  inspect(sa, content="[5, 3, 1, 0, 4, 2]")
  inspect(lcp, content="[0, 1, 3, 0, 0, 2]")
}
```

---

## 4. Pattern search intuition

Because suffixes are sorted, you can binary‑search for a pattern.

Example: search `"ana"` in `"banana"`:

```
Suffixes (sorted):
0: a
1: ana
2: anana
3: banana
4: na
5: nana

"ana" appears at ranks 1 and 2.
Original indices: SA[1]=3, SA[2]=1.
```

---

## 5. Using the SuffixArray helper

```mbt check
///|
test "suffix array search" {
  let sa = @suffix_array.SuffixArray::new("mississippi")
  inspect(sa.find_all("issi"), content="[1, 4]")
  inspect(sa.count("ss"), content="2")
}
```

---

## 6. Longest repeated substring

The longest repeated substring is the maximum LCP.

```mbt check
///|
test "longest repeated substring" {
  let sa = @suffix_array.SuffixArray::new("banana")
  inspect(sa.longest_repeated_substring(), content="ana")
}
```

---

## 7. Count distinct substrings

Formula:

```
total substrings = n(n+1)/2
distinct = total - sum(LCP)
```

```mbt check
///|
test "distinct substrings" {
  let sa = @suffix_array.SuffixArray::new("banana")
  inspect(sa.count_distinct_substrings(), content="15")
}
```

---

## 8. Complexity

```
Build SA:   O(n log^2 n) (prefix doubling)
Build LCP:  O(n)
Search:     O(m log n)
```

---

## 9. When to use suffix arrays

Use them for:

- fast substring search,
- repeated substring queries,
- lexicographic suffix ordering,
- building compression tools (BWT).

---

## 10. Summary

Suffix arrays + LCP are a powerful, compact string index:

- sorted suffixes,
- binary search for patterns,
- LCP powers repeated substring queries.
