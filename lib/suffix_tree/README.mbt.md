# Suffix Tree (Naive Construction)

## Overview

A **suffix tree** indexes all suffixes of a string in a compact trie with
compressed edges. It enables fast substring queries by walking along edge
labels.

This implementation builds the tree by inserting every suffix and splitting
edges when partial matches occur. It is easy to understand but **O(n^2)**.

- **Time**: O(n^2)
- **Space**: O(n^2)

## Design Choices

- We append a **sentinel character** `\u0000` so every suffix ends at a leaf.
- Edges store substring ranges `(start, end)` into the original text.
- The tree works on UTF-16 code units (`String::to_array()`).

## API

- `SuffixTree::new(text)` builds the tree.
- `contains(pattern)` checks if a substring exists.
- `count_occurrences(pattern)` counts occurrences (empty pattern returns 0).

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

## When To Use

- Educational settings (clear correctness reasoning).
- Small to medium inputs where O(n^2) is acceptable.
- Fast substring checks without building a suffix array.
