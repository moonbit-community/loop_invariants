# Palindromic Tree (Eertree)

## Overview

The **Palindromic Tree** (also called **Eertree**) maintains all distinct
palindromic substrings of a string in linear time. It's a remarkable data
structure that combines features of suffix trees and automata.

- **Build**: O(n)
- **Space**: O(n)
- **Distinct palindromes**: At most n

## Core Idea

- Each node represents a **distinct palindrome** with a suffix link.
- Extending the current longest palindrome gives at most **one new node**.
- Suffix links allow amortized O(1) extension per character.

## The Key Insight

```
A string of length n has at most n distinct palindromic substrings!
(Not O(n²) as you might expect)

String: "ababa"
Palindromes: "a", "b", "aba", "bab", "ababa" → 5 ≤ 5 ✓

The eertree represents all of them in O(n) nodes.
Each node = one distinct palindrome.
```

## Structure Overview

```
Two special roots:
  - Root -1: imaginary palindrome of length -1 (for building odd palindromes)
  - Root 0: empty string (for building even palindromes)

For string "abaab":

       Root(-1)
          ↓ suffix link
       Root(0)
          ↓
         "a" ←──────┐ suffix link
          ↓         │
        "aba" ──────┘
          ↓
      "abaab"? No, not a palindrome

         "b"
          ↓
        "bab"? No
        "baab"? No

        "aa"
```

## Building the Eertree

```
Process string character by character.
For each position, find longest palindrome ending there.

String: "eertree"
         0123456

Position 0 'e': palindrome "e" (length 1)
Position 1 'e': palindrome "ee" (length 2)
Position 2 'r': palindrome "r" (length 1)
Position 3 't': palindrome "t" (length 1)
Position 4 'r': palindrome "r" (already exists)
Position 5 'e': palindrome "e" (already exists)
           But also: "erttre"? No... "rtr"? No... "e" reused
Position 6 'e': palindrome "ee" (already exists)

Distinct palindromes: {e, ee, r, t} = 4
```

## Suffix Links

```
Suffix link from palindrome P points to the longest
proper palindromic suffix of P.

Example:
  "abacaba" → suffix link → "aba" → suffix link → "a"

       ┌────────────────────┐
       ↓                    │
  [abacaba] ──suffix──→ [aba] ──suffix──→ [a] ──→ root(-1)

Suffix links are used to find where to extend next.
```

## Algorithm Walkthrough

```
String: "abba"

Step 1: Process 'a' at position 0
  Start at last palindrome (root 0)
  Can we extend root 0 with 'a' on both sides? No (position -1 invalid)
  Follow suffix link to root -1
  Extend root -1 with 'a': creates "a" (length 1)
  Add edge 'a' from root -1 to node "a"

Step 2: Process 'b' at position 1
  Start at "a", can we extend with 'b'? s[-1] != 'b', no
  Follow suffix link to root -1
  Extend root -1 with 'b': creates "b"

Step 3: Process 'b' at position 2
  Start at "b", can we extend with 'b'? s[0] = 'a' != 'b', no
  Follow suffix link to root -1
  Extend root -1 with 'b': "b" already exists
  Try extending root 0 with 'b': s[1] = s[2] = 'b', yes!
  Create "bb" (length 2)

Step 4: Process 'a' at position 3
  Start at "bb", can we extend with 'a'? s[0] = 'a' = s[3], yes!
  Create "abba" (length 4)

Final tree nodes: {a, b, bb, abba} = 4 distinct palindromes
```

## Visual: Complete Eertree

```
String: "eertree"

        Root(-1)
       /   |   \
      e    r    t
     /
    ee

Suffix links:
  ee → e → root(-1)
  r → root(-1)
  t → root(-1)

Edges labeled by the character that extends the palindrome.
```

## Example Usage

```mbt check
///|
test "eertree example" {
  inspect(@eertree.distinct_count("ababa"), content="5")
  inspect(@eertree.longest_length("abacaba"), content="7")
}
```

## Common Applications

### 1. Count Distinct Palindromic Substrings
```
Answer = number of nodes in eertree (excluding roots)
Built in O(n) time!
```

### 2. Longest Palindromic Substring
```
Track maximum length node during construction.
```

### 3. Count Palindrome Occurrences
```
Each node can store count of occurrences.
Propagate counts via suffix links at the end.
```

### 4. Palindromic Factorization
```
Divide string into minimum number of palindromes.
Use DP with eertree for O(n√n) or O(n log n) solution.
```

## Why At Most n Distinct Palindromes?

```
Adding character at position i creates at most ONE new palindrome.

Proof sketch:
- Let P be longest palindrome ending at i
- Any other palindrome Q ending at i is a suffix of P
- Q is also a suffix of P reversed (since P is palindrome)
- So Q appeared earlier in the string!

Therefore: each position contributes ≤ 1 new palindrome.
Total distinct palindromes ≤ n.
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| Build eertree | O(n) |
| Count distinct palindromes | O(1) after build |
| Find longest palindrome | O(n) or O(1) with tracking |
| Count occurrences | O(n) |

## Eertree vs Other Palindrome Algorithms

| Algorithm | Time | Returns |
|-----------|------|---------|
| **Eertree** | O(n) | All distinct palindromes |
| Manacher | O(n) | Longest at each center |
| Suffix Array | O(n) | Requires additional work |
| Hash-based | O(n²) | All palindromic substrings |

**Choose Eertree when**: You need to work with all distinct palindromic substrings.

## Counting Occurrences

```
To count how many times each palindrome appears:

1. During build, increment count for each visited node
2. After build, propagate counts via suffix links (in reverse order)

For string "aaa":
  "a" appears 3 times
  "aa" appears 2 times (positions 0-1 and 1-2)
  "aaa" appears 1 time

Propagation:
  cnt["aaa"] = 1
  cnt["aa"] += cnt["aaa"] → 2 + 1 = 3? No, just 2

Actually: each node's count = occurrences as longest palindrome
Propagate to get total occurrences.
```

## Implementation Notes

- Two roots: -1 (odd length starter) and 0 (even length starter)
- Each node stores: length, suffix link, transitions
- Use array for transitions (faster) or map (space-efficient)
- Track "last" node: longest palindrome ending at previous position
- For suffix links of new nodes, follow suffix links until match found
- Time complexity proof: each character is "visited" at most twice via suffix links
