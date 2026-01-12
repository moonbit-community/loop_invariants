# KMP (Knuth-Morris-Pratt) String Matching Algorithm

## Overview

KMP finds all occurrences of a pattern in a text in **O(n + m)** time, where:
- n = text length
- m = pattern length

This is a significant improvement over naive O(n * m) search.

## The Core Problem

Given text `"ABABDABACDABABCABAB"` and pattern `"ABAB"`, find all positions
where the pattern occurs.

```
Text:    ABABDABACDABABCABAB
         ^^^^      ^^^^  ^^^^
Matches: 0         10    15
```

## Key Insight: The Failure Function

When a mismatch occurs, instead of restarting from scratch, we use
previously matched characters. The **failure function** (or LPS array)
tells us: "What's the longest proper prefix that's also a suffix?"

### Building the Failure Function

```
Pattern: A  B  A  B
Index:   0  1  2  3

Step-by-step:
  i=0: "A"    -> fail[0] = 0  (no proper prefix)
  i=1: "AB"   -> fail[1] = 0  (A != B)
  i=2: "ABA"  -> fail[2] = 1  ("A" is prefix and suffix)
  i=3: "ABAB" -> fail[3] = 2  ("AB" is prefix and suffix)

Result: fail = [0, 0, 1, 2]
```

### Visual Explanation of fail[3] = 2

```
Pattern: A B A B
         ===       <- prefix "AB"
             ===   <- suffix "AB"

"AB" appears both at start and end, so fail[3] = 2
```

## The Matching Process

```
Text:    A B A B D A B A C D A B A B C A B A B
Pattern: A B A B
         i=0,j=0: A=A match, advance both

Text:    A B A B D A B A C D A B A B C A B A B
           ^
Pattern:   A B A B
           i=1,j=1: B=B match, advance both

Text:    A B A B D A B A C D A B A B C A B A B
             ^
Pattern:     A B A B
             i=2,j=2: A=A match, advance both

Text:    A B A B D A B A C D A B A B C A B A B
               ^
Pattern:       A B A B
               i=3,j=3: B=B match, j becomes 4

j=4 (full match!) -> Record position 0

After match, j = fail[3] = 2 (keep "AB" matched)

Text:    A B A B D A B A C D A B A B C A B A B
                 ^
Pattern:     A B A B  <- shifted, but "AB" still aligned
                 j=2: D != A, mismatch!

j = fail[1] = 0, continue from j=0...
```

## Why It's Efficient

The naive approach re-examines characters:

```
Naive for "AAAAAAB" with pattern "AAAB":
  Position 0: AAA? fail     (4 comparisons)
  Position 1: AAA? fail     (4 comparisons) <- redundant!
  Position 2: AAA? fail     (4 comparisons) <- redundant!
  Position 3: AAAB match!   (4 comparisons)
  Total: 16 comparisons

KMP approach:
  Uses failure function to skip redundant work
  Total: O(n + m) = 11 comparisons
```

## Use Cases

1. **Text Editors**: Find/replace functionality
2. **DNA Analysis**: Find gene sequences in genomes
3. **Plagiarism Detection**: Find copied text segments
4. **Log Analysis**: Search for error patterns
5. **Network Security**: Detect malicious packet patterns
6. **Compilers**: Lexical analysis and token matching

## API Reference

```mbt check
///|
test "kmp complete example" {
  // Find all occurrences
  let text = "ababcababa"
  let pattern = "aba"
  inspect(@kmp.kmp_search(text, pattern), content="[0, 5, 7]")

  // Find first occurrence
  inspect(@kmp.kmp_find_first(text, "cab"), content="4")
  inspect(@kmp.kmp_find_first(text, "xyz"), content="-1")

  // Count occurrences
  inspect(@kmp.kmp_count(text, pattern), content="3")

  // Build failure function directly
  let fail = @kmp.compute_failure("ABAB")
  inspect(fail, content="[0, 0, 1, 2]")

  // Prefix-function alias (pi array)
  let pi = @kmp.prefix_function("ababa")
  inspect(pi, content="[0, 0, 1, 2, 3]")
}
```

## The Z-Function Alternative

This module also includes the Z-function, which computes for each position
the longest substring starting there that matches a prefix:

```
String:  A A B X A A B
Z-value: 7 1 0 0 3 1 0
         ^       ^
         |       "AAB" matches prefix
         entire string matches itself
```

```mbt check
///|
test "z-function example" {
  let z = @kmp.compute_z_function("AABXAAB")
  inspect(z[0], content="7") // whole string
  inspect(z[1], content="1") // "A" matches
  inspect(z[4], content="3") // "AAB" matches

  // Use Z-function for pattern matching
  let matches = @kmp.z_search("ABABDABACDABABCABAB", "ABAB")
  inspect(matches.length(), content="3")
}
```

## Algorithm Comparison

| Algorithm   | Preprocess | Search   | Space  | Best For              |
|-------------|------------|----------|--------|-----------------------|
| Naive       | O(1)       | O(nm)    | O(1)   | Very short patterns   |
| **KMP**     | O(m)       | O(n)     | O(m)   | Single pattern search |
| Rabin-Karp  | O(m)       | O(n)*    | O(1)   | Multiple patterns     |
| Z-function  | O(n+m)     | O(n+m)   | O(n+m) | Alternative to KMP    |

*Average case; worst case O(nm)

## Complexity Analysis

- **Time**: O(n + m) - linear in input size
- **Space**: O(m) - only stores failure function

The key insight is that `i` never decreases, and `j` can only decrease
a total of O(n) times (since it increases at most n times). This gives
the linear time bound.
