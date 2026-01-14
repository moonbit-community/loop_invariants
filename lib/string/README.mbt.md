# String Algorithms

## Overview

A collection of classic string algorithms for pattern matching, palindrome
detection, and sequence comparison. These algorithms form the foundation of
text processing and bioinformatics.

- **Longest Palindrome**: O(n) with Manacher's algorithm
- **LCS (Longest Common Subsequence)**: O(nm)
- **Pattern Matching**: O(n + m) with KMP/Z-algorithm

## Core Idea

- Precompute **prefix/suffix relationships** to avoid rescanning text.
- Use **linear-time scans** (KMP/Z/Manacher) by reusing previous matches.
- Convert string problems into **DP or automata** when structure repeats.

## The Key Insight: Prefix Functions

```
Many string algorithms share a core idea:
Precompute how prefixes relate to suffixes.

For pattern P = "ABABC":
  Failure function / prefix function:
    π[0] = 0  (empty prefix)
    π[1] = 0  (A has no proper prefix = suffix)
    π[2] = 1  (AB: A = A)
    π[3] = 2  (ABA: AB ≠ A, but A = A → check: ABA has prefix "A" = suffix "A", AB = prefix, BA = suffix? No. A = A ✓)
    π[4] = 0  (ABAB: AB prefix, AB suffix ✓)

Wait, let me recalculate:
  π[i] = longest proper prefix of P[0..i] that is also a suffix

  P = "ABABC"
      01234

  π[0] = 0 (by definition, single char)
  π[1] = 0 (AB: no prefix = suffix)
  π[2] = 1 (ABA: "A" prefix = "A" suffix)
  π[3] = 2 (ABAB: "AB" prefix = "AB" suffix)
  π[4] = 0 (ABABC: no match)
```

## Longest Palindromic Substring

```
Expand around each center, or use Manacher's O(n):

String: "abacaba"
         0123456

Centers and radii:
  Position 0: "a" → radius 1
  Position 1: "b" → radius 1
  Position 2: "a" → try "aba" ✓, "cabac" no → radius 2
  Position 3: "c" → try "aca" no → radius 1
  Position 4: "a" → try "aba" ✓, "cabac" no, but try "bacab" no → radius 2
  ...

Manacher's trick: Use mirror property within known palindrome.
```

## LCS (Longest Common Subsequence)

```
DP to find longest subsequence common to both strings.

A = "ABCDE"
B = "ACE"

DP table (lcs[i][j] = LCS of A[0..i-1] and B[0..j-1]):

      ""  A  C  E
  ""   0  0  0  0
  A    0  1  1  1
  B    0  1  1  1
  C    0  1  2  2
  D    0  1  2  2
  E    0  1  2  3

If A[i-1] == B[j-1]: lcs[i][j] = lcs[i-1][j-1] + 1
Else: lcs[i][j] = max(lcs[i-1][j], lcs[i][j-1])

LCS = "ACE", length = 3
```

## Algorithm Walkthrough: Palindrome

```
Find longest palindrome in "babad":

Expand around each center:

Center 0 (b):
  Check "b" → ✓ (length 1)

Center 1 (a):
  Check "a" → ✓
  Check "bab" → ✓ (length 3)
  Check "?bab?" → out of bounds

Center 2 (b):
  Check "b" → ✓
  Check "aba" → ✓ (length 3)
  Check "babad"? → 'd' ≠ 'b' ✗

Center 3 (a):
  Check "a" → ✓
  Check "bad" → 'd' ≠ 'b' ✗

Center 4 (d):
  Check "d" → ✓

Also check even-length centers (between characters):
  Between 0-1: "ba" ✗
  Between 1-2: "ab" ✗
  Between 2-3: "ba" ✗
  Between 3-4: "ad" ✗

Longest: "bab" or "aba" at positions 0-2 or 1-3
```

## Example Usage

```mbt check
///|
test "string algorithms example" {
  let s : Array[Char] = ['a', 'b', 'b', 'a']
  let (start, len) = @string.longest_palindrome_range(s[:])
  inspect((start, len), content="(0, 4)")
  let a : Array[Char] = ['A', 'B', 'C']
  let b : Array[Char] = ['A', 'C']
  inspect(@string.lcs_length(a[:], b[:]), content="2")
}
```

## Common Applications

### 1. Text Editors
```
Find and replace using pattern matching.
Spell check with edit distance.
Undo/redo with LCS for diff.
```

### 2. Bioinformatics
```
DNA sequence alignment (LCS variants).
Finding repeated patterns in genomes.
Palindrome detection for restriction sites.
```

### 3. Data Compression
```
LZ77/LZ78 use longest match finding.
Burrows-Wheeler uses suffix sorting.
```

### 4. Plagiarism Detection
```
LCS to find common passages.
Hashing for fingerprinting (Rabin-Karp).
```

## Complexity Analysis

| Algorithm | Time | Space |
|-----------|------|-------|
| Longest Palindrome (naive) | O(n²) | O(1) |
| Longest Palindrome (Manacher) | O(n) | O(n) |
| LCS | O(nm) | O(nm) or O(min(n,m)) |
| Edit Distance | O(nm) | O(nm) or O(min(n,m)) |
| KMP | O(n + m) | O(m) |
| Z-algorithm | O(n) | O(n) |

## String Algorithm Comparison

| Problem | Best Algorithm | Time |
|---------|---------------|------|
| Single pattern match | KMP / Z-algorithm | O(n + m) |
| Multiple pattern match | Aho-Corasick | O(n + m + z) |
| Longest palindrome | Manacher | O(n) |
| All palindromes | Eertree | O(n) |
| LCS | DP | O(nm) |
| Edit distance | DP | O(nm) |
| Substring search (hash) | Rabin-Karp | O(n + m) avg |

## Pattern Matching Variants

```
KMP (Knuth-Morris-Pratt):
  Build failure function, never backtrack in text.

Z-algorithm:
  Z[i] = length of longest substring starting at i
         that matches a prefix of the string.

Boyer-Moore:
  Skip characters based on bad character / good suffix rules.
  Sublinear in practice for long patterns.

Rabin-Karp:
  Use rolling hash for O(1) comparison per position.
  Best for multiple pattern search.
```

## Implementation Notes

- Handle edge cases: empty strings, single character
- For LCS, can reconstruct the actual subsequence by backtracking
- Manacher adds special characters between each position for even-length handling
- Consider case sensitivity and Unicode for real applications
- For very long strings, consider suffix arrays or FM-index
