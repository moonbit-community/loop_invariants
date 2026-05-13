# Suffix Tree (Beginner-Friendly)

A suffix tree is a **compressed trie of all suffixes** of a string.
Once built, it can answer substring queries in **O(m)** time, where m is the
length of the query pattern.

This package builds the tree in **O(n²)** using naive one-by-one suffix
insertion, which keeps the algorithm easy to follow and verify.

---

## 1. What is a suffix tree?

Take every suffix of a string, insert them all into a trie, then compress each
unbranched chain of nodes into a single edge. The edge label is a substring of
the original text stored as a `(start, end)` index pair — no character copying
needed.

Suffixes of `"banana"`:

```
index  suffix
  0    banana
  1    anana
  2    nana
  3    ana
  4    na
  5    a
```

Each of these becomes a root-to-leaf path in the tree.

---

## 2. Why append a sentinel character?

Without a sentinel some suffix can be a prefix of another (e.g. `"a"` is a
prefix of `"ana"`). That would allow a suffix to end in the middle of an edge,
making leaf counts ambiguous. Appending `\0` (NUL, the `SENTINEL` constant)
guarantees every suffix ends at a **leaf**.

```
Without sentinel:  "aa"   -> suffixes "aa",  "a"   (one is a prefix of the other)
With sentinel:     "aa\0" -> suffixes "aa\0","a\0","\0"  (all end uniquely)
```

---

## 3. Full ASCII tree for `"banana$"` (where `$` stands for `\0`)

```
                       root
                      / | \ \
                     /  |  \ \
              "a"  /   |   \ \ "banana$"
                  /  "na"   \
                 v    |    "n"
               [A]    |      \
              /   \   |      [N]
           "na"  "$"  |       \
           /       \  |      "ana$"
          v         v |          \
        [AA]      [AB]|           v
        /   \         |          [NA] (leaf)
     "na$"  "$"       |
      /       \       v
     v         v    [NR]
   (leaf)   (leaf)  /   \
                  "na$" "$"
                  /       \
                 v         v
              (leaf)    (leaf)
```

Cleaner flat view (edges shown as quoted substrings):

```
root
 ├── "a"          -> node A
 │    ├── "na"    -> node AA
 │    │    ├── "na$"  -> leaf  (suffix "anana$")
 │    │    └── "$"    -> leaf  (suffix "ana$")
 │    └── "$"         -> leaf  (suffix "a$")
 ├── "banana$"        -> leaf  (suffix "banana$")
 ├── "na"         -> node N
 │    ├── "na$"   -> leaf  (suffix "nana$")
 │    └── "$"     -> leaf  (suffix "na$")
 └── "$"              -> leaf  (suffix "$")
```

Key observations:

- Every **leaf** is one suffix.
- Every **internal node** is where two or more suffixes share a common prefix.
- Each edge is a **substring** (`text[start..end)`), not a single character.
- The root has one outgoing edge per distinct first character in the suffix set.

---

## 4. How edge labels compress paths

An uncompressed trie for `"banana$"` would have one edge per character and many
internal nodes with only one child. Compression merges every chain of single-
child nodes into a single edge:

```
Uncompressed (trie):           Compressed (suffix tree):

root                           root
 └─ 'b'                         └── "banana$"  (leaf)
     └─ 'a'
         └─ 'n'
             └─ 'a'
                 └─ 'n'
                     └─ 'a'
                         └─ '$'  (leaf)
```

For the shared `"ana"` prefix the compression is:

```
Uncompressed:                  Compressed:

root                           root
 └─ 'a'                         └── "a" -> node A
     └─ 'n'                              ├── "na" -> node AA
         └─ 'a'                          │         ├── "na$" -> leaf
             ├─ 'n' ...                  │         └── "$"   -> leaf
             └─ '$' (leaf)               └── "$"   -> leaf
```

Storing edges as `(start, end)` indices means adding a new edge costs O(1) in
both time and space regardless of how long the label is.

---

## 5. How pattern search walks the tree

To check whether `"ana"` is in `"banana"`:

```
Pattern: a n a
         ^ ^ ^
         i=0 i=1 i=2

Step 1: at root, look for edge starting with 'a'.
        Found: edge "a" -> node A.
        Match 'a' against edge label. Edge exhausted after 1 char.
        Advance to node A (i=1).

Step 2: at node A, look for edge starting with 'n'.
        Found: edge "na" -> node AA.
        Match 'n','a' against edge label "na".
        After matching 'n' (i=2) and 'a' (i=3), pattern is exhausted.
        Pattern found!

        root --"a"--> [A] --"na"--> [AA]
                                     ^
                               pattern ends here (mid-edge is fine)
```

To count occurrences, once the search lands on a node (or mid-edge child), read
`leaf_count`:

```
node AA has leaf_count = 2
  (leaves: "anana$" and "ana$" both contain "ana")
```

---

## 6. Edge splitting during construction

When inserting suffix `"ana$"` into a tree that already has the path for
`"anana$"`, the algorithm detects a mismatch mid-edge and splits:

```
Before:  [A] --"nana$"--> leaf

Insert "na$" branching off at 'n':
  text chars: n a n a $
              match      mismatch at second 'n' vs end-of-pattern

After:   [A] --"na"--> [AA] --"na$"--> leaf (original)
                          \
                           "--"$"--> leaf (new suffix "ana$")
```

The split node `[AA]` preserves the original subtree while branching for the
new suffix. This is the only structural change needed during insertion.

---

## 7. Example usage (public API)

```mbt check
///|
test "suffix tree contains" {
  let tree = @suffix_tree.SuffixTree("banana")
  debug_inspect(tree.contains("ana"), content="true")
  debug_inspect(tree.contains("apple"), content="false")
}
```

```mbt check
///|
test "suffix tree count" {
  let tree = @suffix_tree.SuffixTree("banana")
  debug_inspect(tree.count_occurrences("ana"), content="2")
  debug_inspect(tree.count_occurrences("na"), content="2")
}
```

---

## 8. Step-by-step walkthrough: `"banana"`, query `"ana"`

```
Tree path for "ana":
  root -> (edge "a") -> [A] -> (edge "na") -> [AA]

Pattern consumed: "a" on first edge, "na" on second edge. Done.

leaf_count of [AA] = 2
  leaf 1: suffix "anana$" (starts at index 1, contains "ana" at position 0)
  leaf 2: suffix "ana$"   (starts at index 3, contains "ana" at position 0)

Result: 2 occurrences at text positions 1 and 3.
```

---

## 9. Complexity

```
Build (this implementation):  O(n^2) time,  O(n^2) space
contains(pattern):            O(m)   time,  O(m)   space (for pattern array)
count_occurrences(pattern):   O(m)   time,  O(m)   space

n = text length
m = pattern length
```

For large texts (n > 10^5) consider Ukkonen's O(n) algorithm. This
implementation is ideal for educational use and moderate-sized inputs.

---

## 10. When to use suffix trees

Good for:

- many different substring queries on the same text,
- counting overlapping occurrences,
- understanding compressed-trie / suffix-structure concepts.

Not ideal for:

- one-off substring search (use `String::contains` instead),
- very large texts where O(n) construction time matters (use Ukkonen or suffix arrays).

---

## 11. Summary

A suffix tree stores all suffixes of a text compactly by sharing common
prefixes and compressing unbranched chains into single labelled edges. After
O(n²) construction:

- `contains(P)` answers in O(|P|) by walking edges,
- `count_occurrences(P)` also answers in O(|P|) by reading a precomputed leaf
  count at the node where the pattern ends.
