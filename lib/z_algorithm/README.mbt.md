# Z-Algorithm

## Overview

The **Z-Algorithm** computes the Z-array in linear time, where `Z[i]` is the
length of the longest substring starting at position i that matches a prefix
of the string. This enables O(n) pattern matching.

- **Time**: O(n)
- **Space**: O(n)

## The Z-Array

```
String: a a b c a a b
Index:  0 1 2 3 4 5 6

Z-array:
Z[0] = 7  (entire string matches prefix - by definition)
Z[1] = 1  ("a" matches prefix "a")
Z[2] = 0  ("b" doesn't match "a")
Z[3] = 0  ("c" doesn't match "a")
Z[4] = 3  ("aab" matches prefix "aab")
Z[5] = 1  ("a" matches prefix "a")
Z[6] = 0  ("b" doesn't match "a")
```

## The Key Insight: Z-Box

Maintain a "Z-box" `[l, r]` where the substring `s[l..r]` matches the prefix `s[0..r-l]`.

```
String: a a b c a a b
              [-----]  Z-box when i=4
              l     r

If position i is inside the Z-box (i <= r):
  - Mirror position k = i - l tells us about s[i..]
  - s[i..] starts the same as s[k..] (within the Z-box)
  - We can reuse Z[k] to initialize Z[i]!
```

## Algorithm Walkthrough

```
String: a a b c a a b

i=1: Outside Z-box (r=0)
     Compare s[0..] with s[1..]
     "a" matches "a" → Z[1] = 1
     New Z-box: l=1, r=1

i=2: Outside Z-box (i > r)
     "b" ≠ "a" → Z[2] = 0

i=3: Outside Z-box
     "c" ≠ "a" → Z[3] = 0

i=4: Outside Z-box
     Compare: "aab" matches "aab" → Z[4] = 3
     New Z-box: l=4, r=6

i=5: Inside Z-box (l=4, r=6)
     k = 5 - 4 = 1
     Z[k] = Z[1] = 1
     Remaining in Z-box: r - i + 1 = 2
     Since Z[k] < remaining, Z[5] = Z[1] = 1

i=6: Inside Z-box
     k = 6 - 4 = 2
     Z[k] = Z[2] = 0
     Since Z[k] < remaining (1), Z[6] = 0

Result: [7, 1, 0, 0, 3, 1, 0]
```

## Pattern Matching

To find pattern P in text T, compute Z-array of `P + "$" + T`:

```
Pattern: "ab"
Text:    "ababab"
Concat:  "ab$ababab"

Z-array: [9, 0, 0, 2, 0, 2, 0, 2, 0]
                  ^     ^     ^
               indices where Z[i] = |P| = 2

Matches at positions: 0, 2, 4 in original text
(Subtract |P| + 1 from concatenated indices)
```

## Example Usage

```mbt check
///|
test "z algorithm example" {
  let z = @z_algorithm.compute_z("aabcaab")
  inspect(z, content="[7, 1, 0, 0, 3, 1, 0]")
  let hits = @z_algorithm.find_pattern("aabcaabxaab", "aab")
  inspect(hits, content="[0, 4, 8]")

  // Alias names are also available
  let z2 = @z_algorithm.z_function("aaaaa")
  inspect(z2, content="[5, 4, 3, 2, 1]")
  let hits2 = @z_algorithm.z_search("ababa", "aba")
  inspect(hits2, content="[0, 2]")
}
```

## Why O(n)?

The key insight is that `r` (right boundary of Z-box) only increases:

```
- When we expand past r, we do new comparisons
- Each comparison advances r by 1
- r goes from 0 to n-1 at most once
- Total comparisons ≤ n

Even though there's a while loop inside the for loop,
total work is bounded by n.
```

## Common Applications

### 1. Pattern Matching
```
Find all occurrences of pattern in text: O(n + m)
Faster than naive O(n*m) approach
```

### 2. Longest Prefix-Suffix (Border)
```
If Z[i] + i == n, then s[i..n-1] is both a prefix and suffix.
These are called "borders" of the string.

Example: "abcab"
Z = [5, 0, 0, 2, 0]
Z[3] + 3 = 2 + 3 = 5 = n
So "ab" is a border (prefix = suffix)
```

### 3. String Period
```
Period p means s[i] = s[i mod p] for all i.
Find smallest p where Z[p] >= n - p.

Example: "abab" has period 2
Z = [4, 0, 2, 0]
Z[2] = 2 >= 4 - 2 = 2 ✓
```

### 4. Counting Distinct Substrings
```
Combined with suffix arrays for advanced string algorithms.
```

## Z-Algorithm vs KMP

| Feature | Z-Algorithm | KMP |
|---------|-------------|-----|
| Builds | Z-array | Failure function |
| Concept | Prefix matching | Failure links |
| Pattern matching | O(n + m) | O(n + m) |
| Coding complexity | Simpler | More complex |
| Additional uses | Period, borders | Automaton |

**Choose Z-Algorithm when**: You want simple code for pattern matching.

## Complexity Analysis

| Operation | Time | Space |
|-----------|------|-------|
| Compute Z-array | O(n) | O(n) |
| Pattern search | O(n + m) | O(n + m) |
| Find all borders | O(n) | O(n) |
| String period | O(n) | O(n) |

## The Three Cases

```
Case 1: i > r (outside Z-box)
  - No information available
  - Expand naively from position 0

Case 2a: i <= r and Z[k] < r - i + 1
  - Mirror value fits entirely in Z-box
  - Z[i] = Z[k] (direct copy)

Case 2b: i <= r and Z[k] >= r - i + 1
  - Mirror value reaches or exceeds Z-box boundary
  - Start from r - i + 1, expand naively
```

## Implementation Notes

- Z[0] is defined as n (entire string)
- Use a sentinel character ($) for pattern matching
- Watch for integer types when computing mirror indices
