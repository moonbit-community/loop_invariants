# Manacher's Algorithm

## Overview

**Manacher's Algorithm** finds all palindromic substrings in linear time.
It computes the longest palindrome centered at each position, enabling
O(n) solution for the longest palindromic substring problem.

- **Time**: O(n)
- **Space**: O(n)

## The Problem

```
Input: "babad"

Naive approach: Check each center, expand → O(n²)

Manacher's insight: Reuse information from palindromes
we've already found!
```

## The Transformation

Handle both odd and even length palindromes uniformly by inserting separators:

```
Original: "abba"
Transform: "#a#b#b#a#"

Now every palindrome has odd length with a unique center:
- "bb" (even) becomes "#b#b#" centered at middle #
- "abba" (even) becomes "#a#b#b#a#" centered at middle #
```

## The Key Insight: Mirror Property

When inside a known palindrome, use symmetry to avoid redundant work:

```
Known palindrome centered at c with right edge r:

    |<------palindrome------>|
    |         c              |r
... # a # b # a # b # a # ...
        i'      c       i
        |<---->|<---->|
        mirror distances equal!

If i < r:
  - Mirror position i' = 2*c - i
  - P[i'] already computed
  - P[i] >= min(P[i'], r - i)
```

## Algorithm Walkthrough

```
String: "cbbd"
Transform: "#c#b#b#d#"
            0 1 2 3 4 5 6 7 8

P[i] = palindrome radius at center i

i=0: P[0] = 0 (#)
i=1: P[1] = 1 (#c# centered at c)
i=2: P[2] = 0 (c#b)
i=3: P[3] = 1 (#b#)
i=4: P[4] = 2 (#b#b# - this is "bb"!)
i=5: P[5] = 1 (#b#)
i=6: P[6] = 0 (b#d)
i=7: P[7] = 1 (#d#)
i=8: P[8] = 0 (#)

Maximum: P[4] = 2
Original palindrome length = P[4] = 2
Substring: "bb"
```

## Visual Example

```
String: "abacaba"
Transform: "#a#b#a#c#a#b#a#"

         |<----palindrome---->|
... # a # b # a # c # a # b # a # ...
         i'      c       i

When processing i:
- If i < r, check mirror i' = 2*c - i
- P[i'] tells us minimum radius at i
- Only expand beyond what we already know
```

## Why O(n)?

Each character comparison either:
1. **Reuses** known information (O(1))
2. **Extends** the right boundary r (at most n times total)

```
r only increases, never decreases
Total expansions across all centers ≤ n
Therefore total time = O(n)
```

## Example Usage

```mbt check
///|
test "manacher example" {
  inspect(@manacher.longest_palindrome("cbbd"), content="bb")
  inspect(@manacher.count_palindromes("aaa"), content="6")
  inspect(@manacher.longest_palindrome_len("abacaba"), content="7")
  let (d1, d2) = @manacher.manacher_radii("abba")
  inspect(d1, content="[1, 1, 1, 1]")
  inspect(d2, content="[0, 0, 2, 0]")
}
```

## Common Applications

### 1. Longest Palindromic Substring
```
The classic problem! Find longest palindrome in a string.
Example: "babad" → "bab" or "aba" (length 3)
```

### 2. Count Palindromic Substrings
```
Each center with radius r contributes (r+1)/2 palindromes.

"aaa": 6 palindromic substrings
  - "a" at positions 0, 1, 2 (3 substrings)
  - "aa" at positions 0-1, 1-2 (2 substrings)
  - "aaa" at position 0-2 (1 substring)
```

### 3. Palindrome Partitioning
```
Combined with DP for minimum cuts or counting partitions.
```

### 4. Longest Palindromic Prefix/Suffix
```
Special case queries answered in O(1) after preprocessing.
```

## Complexity Analysis

| Operation | Time | Space |
|-----------|------|-------|
| Build radii array | O(n) | O(n) |
| Longest palindrome | O(n) | O(n) |
| Count palindromes | O(n) | O(n) |
| Check if [l,r) is palindrome | O(1)* | - |

*After O(n) preprocessing.

## Manacher vs Other Approaches

| Method | Time | Space | Finds |
|--------|------|-------|-------|
| **Manacher** | O(n) | O(n) | All palindromes |
| Expand from center | O(n²) | O(1) | All palindromes |
| DP | O(n²) | O(n²) | All palindromes |
| Hashing | O(n log n) | O(n) | Specific queries |
| Suffix array + LCP | O(n) | O(n) | All palindromes |

**Choose Manacher when**: You need O(n) time for palindrome queries.

## The Algorithm States

```
Maintain: center c, right boundary r

For each position i:

Case 1: i >= r
  - Outside known palindrome
  - Expand naively

Case 2: i < r
  - Inside palindrome centered at c
  - Mirror position: i' = 2*c - i

  Case 2a: P[i'] < r - i
    - Mirror fits inside → P[i] = P[i']

  Case 2b: P[i'] >= r - i
    - Mirror reaches boundary
    - P[i] >= r - i, expand from there

Always: If expanded past r, update c = i, r = i + P[i]
```

## Converting Radii to Substrings

```
In transformed string:
  - Center at position i
  - Radius P[i]

Original substring:
  - Start: (i - P[i]) / 2
  - Length: P[i]

Example: Transform "#a#b#b#a#"
  Center i=4 (#), radius P[4]=4
  Original start = (4-4)/2 = 0
  Original length = 4
  Substring: "abba"
```

## Implementation Notes

- Use a sentinel (like #) that won't appear in input
- Integer division automatically handles the 2x scaling
- Edge cases: empty string, single character
- P[0] = 0 for the leading separator
