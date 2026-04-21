# Trie (Prefix Tree)

A trie stores strings so that **common prefixes share the same path**.
This makes prefix queries and autocomplete fast.

This package implements:

- a classic trie for lowercase letters `a..z`
- a compressed trie (radix tree) for saving space

---

## 1) Why a trie?

Consider storing the four words: `cat`, `car`, `card`, `care`.

A hash set stores each word as an independent entry. A trie stores shared
prefixes once and fans out only where words diverge.

---

## 2) Structure of a trie storing "cat", "car", "card", "care"

Each box is a trie node. An asterisk (*) marks a word-end node.

```
                    (root)
                      |
                     [c]
                      |
                     [a]
                    /   \
                 [t]*   [r]*
                         |
                        [d]*
                         |
                        [e]*
```

Reading paths from the root:

```
root -> c -> a -> t           "cat"  (*)
root -> c -> a -> r           "car"  (*)
root -> c -> a -> r -> d      "card" (*)
root -> c -> a -> r -> e      "care" (*)
```

The prefix `ca` is stored exactly once in the two nodes `[c]` and `[a]`.
All four words share that path segment.

---

## 3) Step-by-step: inserting "car", then "card"

### After inserting "car"

```
(root)
  |
 [c]  prefix_count=1
  |
 [a]  prefix_count=1
  |
 [r]* prefix_count=1, is_end=true, count=1
```

Every node on the path from root to `[r]` has its `prefix_count` incremented
by 1 (recording that one word passes through it). The terminal node `[r]` also
gets `is_end = true` and `count = 1`.

### After inserting "card"

```
(root)
  |
 [c]  prefix_count=2
  |
 [a]  prefix_count=2
  |
 [r]* prefix_count=2, is_end=true, count=1
  |
 [d]* prefix_count=1, is_end=true, count=1
```

The shared nodes `[c]`, `[a]`, `[r]` each have their `prefix_count` bumped to
2. A new node `[d]` is created as a child of `[r]`. `[r]` retains `is_end=true`
because "car" still ends there.

---

## 4) Step-by-step: searching for "car" and "ca"

### Searching "car"

1. Start at root, follow `c`.
2. From `[c]`, follow `a`.
3. From `[a]`, follow `r`.
4. We have consumed all characters. Check `[r].is_end` -> `true`. Found.

### Searching "ca" (not a word, but a valid prefix)

1. Start at root, follow `c`.
2. From `[c]`, follow `a`.
3. We have consumed all characters. `[a].is_end` is `false`. Not a word.
4. But `starts_with("ca")` returns `true` because node `[a]` exists.

---

## 5) Core operations (all O(length))

If `m` is the word length and `p` the prefix length:

```
Operation              Time
-------------------------------
insert                 O(m)
search (exact)         O(m)
starts_with            O(p)
count_prefix           O(p)
count_word             O(m)
delete                 O(m)
autocomplete           O(p + output size)
longest_prefix         O(m)
```

---

## 6) Example 1: insert + search

```mbt nocheck
///|
test "trie insert and search" {
  let trie = Trie()
  trie.insert("hello")
  trie.insert("world")
  trie.insert("help")
  inspect(trie.search("hello"), content="true")
  inspect(trie.search("help"), content="true")
  inspect(trie.search("hell"), content="false")
}
```

---

## 7) Example 2: prefix queries

```mbt nocheck
///|
test "trie prefix queries" {
  let trie = Trie()
  trie.insert("car")
  trie.insert("card")
  trie.insert("care")
  trie.insert("cat")
  inspect(trie.starts_with("ca"), content="true")
  inspect(trie.count_prefix("ca"), content="4")
  inspect(trie.count_prefix("car"), content="3")
  inspect(trie.count_prefix("dog"), content="0")
}
```

`count_prefix("ca")` is 4 because all four inserted words start with `ca`.
`count_prefix("car")` is 3 because "car", "card", and "care" start with `car`.

---

## 8) Example 3: duplicates

Duplicate insertions are tracked with `count` on the terminal node.

```mbt nocheck
///|
test "trie duplicates" {
  let trie = Trie()
  trie.insert("hello")
  trie.insert("hello")
  trie.insert("hello")
  inspect(trie.count_word("hello"), content="3")
  inspect(trie.count_prefix("hello"), content="3")
}
```

---

## 9) Example 4: delete

`delete` removes **one** occurrence. The word remains searchable until the last
copy is removed.

```mbt nocheck
///|
test "trie delete one copy" {
  let trie = Trie()
  trie.insert("hello")
  trie.insert("hello")
  inspect(trie.count_word("hello"), content="2")
  inspect(trie.delete("hello"), content="true")
  inspect(trie.count_word("hello"), content="1")
  inspect(trie.search("hello"), content="true")
  inspect(trie.delete("hello"), content="true")
  inspect(trie.search("hello"), content="false")
}
```

---

## 10) Example 5: autocomplete

`autocomplete` collects every word whose path starts at the prefix node.

```mbt nocheck
///|
test "trie autocomplete" {
  let trie = Trie()
  trie.insert("car")
  trie.insert("card")
  trie.insert("care")
  trie.insert("cat")
  let results = trie.autocomplete("car")
  inspect(results.length(), content="3") // car, card, care
}
```

The results are returned in lexicographic order because the trie iterates
children by their character index (a=0, b=1, ..., z=25).

---

## 11) Example 6: longest prefix

`longest_prefix` walks the trie character by character, tracking the furthest
word-end node reached. It returns the corresponding prefix of the query string.

```mbt nocheck
///|
test "trie longest prefix" {
  let trie = Trie()
  trie.insert("a")
  trie.insert("app")
  trie.insert("apple")
  inspect(trie.longest_prefix("application"), content="app")
  inspect(trie.longest_prefix("apple"), content="apple")
  inspect(trie.longest_prefix("appetizer"), content="app")
}
```

---

## 12) Compressed trie (radix tree)

The standard trie allocates one node per character. When many nodes have only
one child, that is wasteful. A compressed trie collapses unbranched chains into
a single edge whose **label** is a multi-character string.

### Visualization: "test", "testing", "tested"

Standard trie (7 internal nodes just for "test"):

```
root - [t] - [e] - [s] - [t]* - [i] - [n] - [g]*
                              \
                               [e] - [d]*
```

Compressed trie (radix tree, same words):

```
(root)
  |
"test" (*)
  |  \
"ing"(*) "ed"(*)
```

The label `"test"` covers all four characters at once. The tree has three
nodes instead of nine.

The implementation here supports insert and search.

```mbt nocheck
///|
test "compressed trie basic" {
  let trie = CompressedTrie()
  trie.insert("test")
  trie.insert("testing")
  trie.insert("tested")
  inspect(trie.search("test"), content="true")
  inspect(trie.search("testing"), content="true")
  inspect(trie.search("tested"), content="true")
  inspect(trie.search("tes"), content="false")
}
```

### Edge splitting during insert

When a new word shares only part of an existing edge label, the edge is split
at the common prefix:

```
Before inserting "team" into a trie that contains "test":

(root)
  |
"test"(*)

After inserting "team":

(root)
  |
"te"
 / \
"st"(*) "am"(*)
```

The original edge `"test"` is split into a new internal node at `"te"`, with
children `"st"` (the remaining suffix of the old label) and `"am"` (the
remaining suffix of the new word).

---

## 13) Common pitfalls

- This trie is **lowercase only** (`a..z`). Non-lowercase characters are
  silently skipped during traversal, but they do not cause errors.
- `autocomplete` output order is lexicographic, not insertion order.
- The structure is mutable. If concurrent reads and writes are needed, external
  locking is required.

---

## 14) Complexity summary

```
Operation            Time          Notes
-----------------------------------------
insert               O(m)          m = word length
search               O(m)
starts_with          O(p)          p = prefix length
count_prefix         O(p)
count_word           O(m)
autocomplete         O(p + output)
delete               O(m)
longest_prefix       O(m)
```
