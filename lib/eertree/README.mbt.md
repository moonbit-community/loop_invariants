# Palindromic Tree (Eertree)

## Overview

The **Palindromic Tree** (also called **Eertree**) maintains all distinct
palindromic substrings of a string in linear time. It's a remarkable data
structure that combines features of suffix trees and automata.

- **Build**: O(n)
- **Space**: O(n)
- **Distinct palindromes**: At most n

## Warm-up: Palindrome vs Substring

```
Substring means "contiguous":
  "abac" contains "aba" (positions 0..2)
  "abac" does NOT contain "aac" (not contiguous)

Palindrome means "reads the same forward and backward":
  "aba" is a palindrome
  "ab" is not

Eertree stores palindromic substrings only.
```

## Core Idea

- Each node represents a **distinct palindrome** with a suffix link.
- Extending the current longest palindrome gives at most **one new node**.
- Suffix links allow amortized O(1) extension per character.

## What Each Node Stores

```
For each palindrome node:
  - length of the palindrome
  - suffix link (longest proper palindromic suffix)
  - edges by character: c -> palindrome cPc
  - occurrence count (if you choose to track it)
```

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
  - Root -1: imaginary palindrome of length -1 (odd-length starter)
  - Root 0: empty string of length 0 (even-length starter)

Example string: "ababa"
Distinct palindromes: "a", "b", "aba", "bab", "ababa"

Edges (adding a character on both ends):

Root(-1) --a--> "a" --b--> "bab"
Root(-1) --b--> "b" --a--> "aba" --b--> "ababa"

Suffix links (longest proper palindromic suffix):
  "ababa" → "aba" → "a" → Root(-1)
  "bab"   → "b"   → Root(-1)

Even-length palindromes would hang off Root(0).
```

## Why Two Roots?

```
Odd-length palindromes need a center character.
Even-length palindromes have an empty center.

Root(-1) lets us "match" any character at the start:
  len = -1 => i - len - 1 = i
  So any character can extend it.

Root(0) lets us build even-length palindromes:
  "aa", "bb", "abba", ...
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

## Pseudocode

```
init tree with two roots (-1 and 0)
last = root(0)

for each character c at position i:
  cur = last
  while s[i - len(cur) - 1] != c:
    cur = suffix_link[cur]

  if edge(cur, c) exists:
    last = edge(cur, c)
    count[last]++
  else:
    create node new with len = len(cur) + 2
    edge(cur, c) = new
    if len(new) == 1:
      suffix_link[new] = root(0)
    else:
      link_candidate = suffix_link[cur]
      while s[i - len(link_candidate) - 1] != c:
        link_candidate = suffix_link[link_candidate]
      suffix_link[new] = edge(link_candidate, c)
    last = new
```

## Step-by-Step Build (ababa)

```
Index: 0 1 2 3 4
Char : a b a b a

i  s[i]  longest pal ending at i   new palindrome?
-- ----- ------------------------ ---------------
0   a    "a"                       yes
1   b    "b"                       yes
2   a    "aba"                     yes
3   b    "bab"                     yes
4   a    "ababa"                   yes

Distinct palindromes: {a, b, aba, bab, ababa}
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

## Finding an Extendable Suffix

```
At position i with new character c = s[i]:
We need the longest palindrome P ending at i-1
such that the character just before P equals c.

We try:
  cur = last
  while s[i - len(cur) - 1] != c:
    cur = suffix_link[cur]

The first match tells us we can build c + P + c.
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

## Even-Length Example (abba)

```
Distinct palindromes:
  "a", "b", "bb", "abba"

Structure (simplified):

Root(-1) --a--> "a"
Root(-1) --b--> "b"
Root(0)  --b--> "bb" --a--> "abba"

Suffix links:
  "bb"   -> Root(0)
  "abba" -> "bb" -> Root(0)
```

## Visual: Complete Eertree

```
String: "eertree"

        Root(-1)            Root(0)
       /   |   \               |
      e    r    t              e
      |                        |
     "e"                      "ee"

Suffix links:
  ee → e → root(-1)
  r → root(-1)
  t → root(-1)

Edges labeled by the character that extends the palindrome.
```

## Node Table (ababa)

```
String: "ababa"

Node | Palindrome | Length | Suffix link
-----+------------+--------+------------
  2  | "a"        |   1    | Root(-1)
  3  | "b"        |   1    | Root(-1)
  4  | "aba"      |   3    | "a"
  5  | "bab"      |   3    | "b"
  6  | "ababa"    |   5    | "aba"
```

## Example Usage

```mbt check
///|
test "eertree example" {
  inspect(@eertree.distinct_count("ababa"), content="5")
  inspect(@eertree.longest_length("abacaba"), content="7")
}
```

```mbt check
///|
test "eertree palindromes list" {
  let pals = @eertree.palindromes("aba")
  inspect(pals.length(), content="3")
  inspect(pals.contains("a"), content="true")
  inspect(pals.contains("b"), content="true")
  inspect(pals.contains("aba"), content="true")
}
```

```mbt check
///|
test "eertree edge cases" {
  inspect(@eertree.distinct_count(""), content="0")
  inspect(@eertree.distinct_count("aaaa"), content="4")
  inspect(@eertree.longest_length("abba"), content="4")
}
```

```mbt check
///|
test "eertree even palindromes" {
  let pals = @eertree.palindromes("abba")
  inspect(@eertree.distinct_count("abba"), content="4")
  inspect(pals.contains("bb"), content="true")
  inspect(pals.contains("abba"), content="true")
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

## Edge Cases to Remember

```
Empty string:
  "" -> 0 palindromes

All equal characters:
  "aaaa" -> "a", "aa", "aaa", "aaaa"

No repeats:
  "abcd" -> only single letters

Even-length only:
  "abccba" includes "cc", "bccb", "abccba"
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| Build eertree | O(n) |
| Count distinct palindromes | O(1) after build |
| Find longest palindrome | O(n) or O(1) with tracking |
| Count occurrences | O(n) |

## Why O(n) Time?

```
At each new character:
  - We move along suffix links until we can extend.
  - Each move strictly decreases the palindrome length.

Across the entire build:
  - The total number of suffix-link jumps is O(n)
  - Each character adds at most one new node

So the overall build is linear.
```

## Eertree vs Other Palindrome Algorithms

| Algorithm | Time | Returns |
|-----------|------|---------|
| **Eertree** | O(n) | All distinct palindromes |
| Manacher | O(n) | Longest at each center |
| Suffix Array | O(n) | Requires additional work |
| Hash-based | O(n²) | All palindromic substrings |

**Choose Eertree when**: You need to work with all distinct palindromic substrings.

## Common Pitfalls

- **Forgetting the two roots**: both odd and even palindromes are needed.
- **Wrong link target**: suffix link must be the longest proper palindromic suffix.
- **Order of palindromes**: `palindromes()` returns in DFS order, not sorted.
- **Counting occurrences**: you must propagate counts via suffix links.

## Counting Occurrences

```
To count how many times each palindrome appears:

1. During build, increment count for each visited node
2. After build, propagate counts via suffix links (in reverse order)

For string "aaa":
  Longest-palindrome counts after build:
    cnt["a"] = 1   (from position 0)
    cnt["aa"] = 1  (from position 1)
    cnt["aaa"] = 1 (from position 2)

  Propagate from long to short:
    cnt["aa"] += cnt["aaa"]  => 2
    cnt["a"]  += cnt["aa"]   => 3

Final totals:
  "a"  appears 3 times
  "aa" appears 2 times
  "aaa" appears 1 time
```

## Implementation Notes

- Two roots: -1 (odd length starter) and 0 (even length starter)
- Each node stores: length, suffix link, transitions
- Use array for transitions (faster) or map (space-efficient)
- Track "last" node: longest palindrome ending at previous position
- For suffix links of new nodes, follow suffix links until match found
- Time complexity proof: each character is "visited" at most twice via suffix links
