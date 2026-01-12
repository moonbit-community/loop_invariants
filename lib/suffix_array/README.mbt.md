# Suffix Array

## Overview

A **Suffix Array** is a sorted array of all suffixes of a string. Combined with
an **LCP (Longest Common Prefix) array**, it enables powerful string operations.

## What is a Suffix Array?

For string "banana", the suffixes are:

```
Index  Suffix
  0    banana
  1    anana
  2    nana
  3    ana
  4    na
  5    a
```

Sorted alphabetically:

```
Rank  Suffix    Original Index
  0   a         5
  1   ana       3
  2   anana     1
  3   banana    0
  4   na        4
  5   nana      2

Suffix Array: SA = [5, 3, 1, 0, 4, 2]
```

## The LCP Array

The LCP array stores the **longest common prefix** between adjacent suffixes
in the sorted order:

```
Rank  Suffix    LCP with previous
  0   a         -
  1   ana       1  (shares "a" with "a")
  2   anana     3  (shares "ana" with "ana")
  3   banana    0  (shares nothing with "anana")
  4   na        0  (shares nothing with "banana")
  5   nana      2  (shares "na" with "na")

LCP Array: [0, 1, 3, 0, 0, 2]
```

## Visual: How Binary Search Works

To find pattern "ana" in "banana":

```
Suffix Array (sorted):
  [0] a        <- "a" < "ana"
  [1] ana      <- "ana" = "ana" MATCH!
  [2] anana    <- "ana" prefix of "anana" MATCH!
  [3] banana   <- "banana" > "ana"
  [4] na       <- "na" > "ana"
  [5] nana     <- "nana" > "ana"

Binary search finds range [1, 2]
Positions in original: SA[1]=3, SA[2]=1 → matches at indices 1 and 3
```

## Construction: Prefix Doubling

We build the suffix array by sorting suffixes by longer and longer prefixes:

```
Step 0 (k=1): Sort by first 1 character
  Suffixes by first char: a(5), a(3), a(1), b(0), n(4), n(2)
  Ranks: [b=0, a=1, n=2, a=1, n=2, a=1]

Step 1 (k=2): Sort by first 2 characters
  Compare pairs (rank[i], rank[i+1])
  "ba" > "an" > "na" etc.

Step 2 (k=4): Sort by first 4 characters
  ...continue until all ranks unique

Result: SA = [5, 3, 1, 0, 4, 2]
```

## LCP Construction: Kasai's Algorithm

Key insight: If we know `LCP(SA[i], SA[i-1]) = h`, then
`LCP(SA[rank[i+1]], SA[rank[i+1]-1]) >= h - 1`.

This allows O(n) construction by processing suffixes in text order.

## Use Cases

### 1. Pattern Matching
Find all occurrences of a pattern in O(m log n) time:

```mbt check
///|
test "pattern matching" {
  let sa = @suffix_array.SuffixArray::new("mississippi")
  inspect(sa.find_all("issi"), content="[1, 4]")
  inspect(sa.count("ss"), content="2")
}
```

### 2. Longest Repeated Substring
The longest repeated substring corresponds to the maximum LCP value:

```mbt check
///|
test "longest repeated substring" {
  let sa = @suffix_array.SuffixArray::new("banana")
  inspect(sa.longest_repeated_substring(), content="ana")
  let sa2 = @suffix_array.SuffixArray::new("abcabc")
  inspect(sa2.longest_repeated_substring(), content="abc")
}
```

### 3. Count Distinct Substrings
Total substrings minus LCP overlaps:

```
Formula: n(n+1)/2 - sum(LCP)

For "banana" (n=6):
  Total substrings = 6*7/2 = 21
  Sum of LCP = 0+1+3+0+0+2 = 6
  Distinct = 21 - 6 = 15
```

```mbt check
///|
test "distinct substrings" {
  let sa = @suffix_array.SuffixArray::new("banana")
  inspect(sa.count_distinct_substrings(), content="15")
}
```

### 4. Lexicographically Sorted Suffixes
Access suffixes in sorted order:

```mbt check
///|
test "sorted suffixes" {
  let sa = @suffix_array.SuffixArray::new("banana")
  inspect(sa.get_suffix(0), content="a")
  inspect(sa.get_suffix(1), content="ana")
  inspect(sa.get_suffix(3), content="banana")
}
```

## Common Applications

1. **Genome Analysis**: Find repeated sequences in DNA
2. **Data Compression**: Burrows-Wheeler Transform uses suffix arrays
3. **Plagiarism Detection**: Find common substrings between documents
4. **Search Engines**: Index text for fast substring queries
5. **Text Editors**: Fast find/replace operations

## Complexity Analysis

| Operation            | Time          | Space |
|----------------------|---------------|-------|
| Build SA             | O(n log² n)   | O(n)  |
| Build LCP (Kasai)    | O(n)          | O(n)  |
| Search pattern       | O(m log n)    | O(1)  |
| Longest repeated     | O(n)          | O(1)  |
| Count distinct       | O(n)          | O(1)  |

## Comparison with Other String Structures

| Structure      | Build    | Pattern Search | Space | Use Case |
|----------------|----------|----------------|-------|----------|
| Suffix Array   | O(n lg²n)| O(m log n)     | O(n)  | General  |
| Suffix Tree    | O(n)     | O(m)           | O(n)* | Complex queries |
| KMP            | O(m)     | O(n)           | O(m)  | Single pattern |
| Rabin-Karp     | O(n+m)   | O(n+m)         | O(1)  | Multiple patterns |

*Suffix trees have larger constant factors

## Advanced: Using LCP for Range Minimum Queries

With the LCP array, you can answer "longest common prefix of any two suffixes"
using Range Minimum Query (RMQ):

```
LCP(suffix[i], suffix[j]) = min(LCP[rank[i]+1 ... rank[j]])
```

This enables O(1) LCP queries after O(n) preprocessing with sparse tables.
