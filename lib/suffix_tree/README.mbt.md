# Suffix Tree

## Overview

A **Suffix Tree** is a compressed trie of all suffixes of a string. It enables
fast substring queries, pattern matching, and many string algorithms.

This implementation uses naive O(n²) construction for clarity.

- **Time**: O(n²) construction, O(m) queries (m = pattern length)
- **Space**: O(n²)
- **Key Feature**: All substring queries in O(m) after construction

## The Key Insight

```
Problem: Fast substring search in a fixed text

Naive substring search: O(n·m) per query

Suffix tree insight:
  Build a trie of ALL suffixes of the text.
  Every substring is a prefix of some suffix!

  Text: "banana"
  Suffixes: "banana", "anana", "nana", "ana", "na", "a"

  To find "ana": Walk down the trie following "a" → "n" → "a"
  If path exists, "ana" is a substring!

Query time: O(m) - just walk down the trie
```

## Visual: Suffix Tree Structure

```
Text: "banana$" ($ = sentinel character)

Suffix tree (compressed trie):

                    root
                   / | \
                  a  b  n
                  |  |  |
                 na  a  a
                / \  |  |
               $  na na na
                  |  |  |
                  $  na $
                     |
                     $

Edge labels are substrings, not single characters!

Actual structure with edge labels:
                    root
                   / |  \
              "a" /  |   \ "na"
                 /   |"banana$"
                ●    ●    ●
               /|        / \
          "na" | "$"  "$"  "na$"
              /  |
             ●   ●
            /|
      "na$" | "$"
           /  |
          ●   ●
```

## Why Use a Sentinel?

```
Without sentinel:
  "aa" has suffixes "aa", "a"
  "a" is a prefix of "aa" - ends at internal node!

With sentinel "$":
  "aa$" has suffixes "aa$", "a$", "$"
  Each suffix ends at a unique leaf!

Benefits:
  - Every suffix reaches a leaf
  - Counting occurrences = counting leaves below
  - Clean tree structure
```

## Example Usage

```mbt check
///|
test "suffix tree contains" {
  let tree = @suffix_tree.SuffixTree::new("banana")
  inspect(tree.contains("ana"), content="true")
  inspect(tree.contains("apple"), content="false")
}
```

```mbt check
///|
test "suffix tree count" {
  let tree = @suffix_tree.SuffixTree::new("banana")
  inspect(tree.count_occurrences("ana"), content="2")
  inspect(tree.count_occurrences("na"), content="2")
}
```

## Algorithm: Substring Query

```
contains(pattern):
  node = root
  pos = 0  // position in pattern

  while pos < pattern.length:
    // Find edge starting with pattern[pos]
    edge = find_edge(node, pattern[pos])
    if edge is None:
      return false

    // Match edge label against pattern
    for each char c in edge.label:
      if pos >= pattern.length:
        return true  // Pattern exhausted, found!
      if c != pattern[pos]:
        return false  // Mismatch
      pos++

    node = edge.target

  return true  // Matched entire pattern
```

## Algorithm: Count Occurrences

```
count_occurrences(pattern):
  // First, navigate to the node representing the pattern
  node = navigate_to_pattern(pattern)
  if node is None:
    return 0

  // Count leaves in subtree (each leaf = one occurrence)
  return count_leaves(node)

count_leaves(node):
  if node is leaf:
    return 1
  sum = 0
  for each child of node:
    sum += count_leaves(child)
  return sum
```

## Algorithm Walkthrough

```
Text: "banana"
Find: "ana"

Step 1: Navigate from root
  Look for edge starting with 'a'
  Found: edge labeled "a" or "ana" depending on construction

Step 2: If edge is "ana":
  Match 'a' ✓, 'n' ✓, 'a' ✓
  Pattern exhausted at this node

Step 3: Count leaves below
  "ana" occurs at positions 1 and 3
  Leaves: 2 (one for each suffix starting with "ana")

Result: 2 occurrences ✓
```

## Common Applications

### 1. Substring Search
```
Find all occurrences of a pattern.
O(m + k) where k = number of occurrences.
```

### 2. Longest Repeated Substring
```
Find the deepest internal node.
Its path label is the longest repeated substring.
```

### 3. Longest Common Substring
```
Build suffix tree for "text1$text2#".
Find deepest node with descendants from both texts.
```

### 4. Suffix Array Construction
```
DFS on suffix tree in lexicographic order.
Leaf labels give suffix array.
```

## Complexity Analysis

| Operation | Time | Notes |
|-----------|------|-------|
| Construction (this impl) | O(n²) | Naive insertion |
| Construction (Ukkonen) | O(n) | Linear-time algorithm |
| Substring check | O(m) | Walk down tree |
| Count occurrences | O(m + k) | Walk + count leaves |
| All occurrences | O(m + k) | Walk + list leaves |

## Suffix Tree vs Other Structures

| Structure | Build | Query | Space |
|-----------|-------|-------|-------|
| Suffix Tree | O(n) or O(n²) | O(m) | O(n) |
| Suffix Array | O(n log n) | O(m log n) | O(n) |
| Suffix Array + LCP | O(n log n) | O(m + log n) | O(n) |

**Choose Suffix Tree when**: You need O(m) queries and space isn't critical.

## Ukkonen's Algorithm (O(n) Construction)

```
This package uses naive O(n²) construction.

For O(n), use Ukkonen's online algorithm:
  - Build tree incrementally, one character at a time
  - Use "suffix links" to jump between nodes
  - Use "implicit" representation that's extended at each step

Ukkonen's is more complex but essential for large texts.
```

## Implementation Notes

- Append sentinel character (like '\0') to ensure each suffix ends at leaf
- Edge labels store (start, end) indices into original text, not copies
- Use hash map or array for child edges (tradeoff: space vs speed)
- This implementation works on UTF-16 code units

## When to Use This Package

```
Good for:
  - Educational purposes (clear algorithm)
  - Small to medium texts (n < 10,000)
  - Multiple substring queries on same text
  - Understanding suffix tree concepts

Not ideal for:
  - Very large texts (use Ukkonen's algorithm)
  - Single query on text (just use KMP or Z-algorithm)
  - Memory-constrained environments
```

