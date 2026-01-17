# Challenge: Persistent String Trie

A **persistent trie** stores words in a tree of characters. Every insert returns
another version, while old versions remain usable.

This implementation supports **lowercase ASCII words** (`'a'..'z'`) and stores
children in a fixed-size array of length 26.

This package provides:

- `empty()`
- `add(root, word)`
- `contains(root, word)`

---

## Core idea: Trie by prefixes

Each node represents a prefix. It stores:

- `end`: whether a word ends here
- `children[0..25]`: links to next characters

For example, the words `cat` and `car` share the prefix `ca`:

```
root
  |
  c
  |
  a
 / \
t   r
```

Both words share nodes for `c` and `a`.

---

## Persistence (path copying)

When you insert a new word, you only copy the nodes on the path of the word.
All other nodes are reused.

```
Old version:               New version:

     A                        A'
    / \                      / \
   B   C     insert path     B'  C
  / \                      / \
 D   E                    D   E
```

Only the nodes on the word path (`A'`, `B'`) are new. The rest (`C`, `D`, `E`)
are shared.

---

## Character indexing

Each lowercase character maps to an index:

```
'a' -> 0
'b' -> 1
...
'z' -> 25
```

That lets the trie store children in a fixed array for fast access.

---

## API summary

- `add`: `O(L)` where `L` is word length
- `contains`: `O(L)`
- Space per insert: `O(L)` new nodes

---

## Example 1: Insert and query

```mbt check
///|
test "trie basic" {
  let root0 = @challenge_persistent_trie_string.empty()
  let root1 = @challenge_persistent_trie_string.add(root0, "cat")
  let root2 = @challenge_persistent_trie_string.add(root1, "car")
  let root3 = @challenge_persistent_trie_string.add(root2, "dog")
  inspect(
    @challenge_persistent_trie_string.contains(root3, "cat"),
    content="true",
  )
  inspect(
    @challenge_persistent_trie_string.contains(root3, "car"),
    content="true",
  )
  inspect(
    @challenge_persistent_trie_string.contains(root3, "cow"),
    content="false",
  )
}
```

---

## Example 2: Versions stay alive

```mbt check
///|
test "trie versions" {
  let root0 = @challenge_persistent_trie_string.empty()
  let root1 = @challenge_persistent_trie_string.add(root0, "hi")
  let root2 = @challenge_persistent_trie_string.add(root1, "hit")
  inspect(
    @challenge_persistent_trie_string.contains(root1, "hit"),
    content="false",
  )
  inspect(
    @challenge_persistent_trie_string.contains(root2, "hit"),
    content="true",
  )
  inspect(
    @challenge_persistent_trie_string.contains(root2, "hi"),
    content="true",
  )
}
```

---

## Example 3: Prefix vs full word

A trie stores prefixes implicitly, but `end` controls whether a full word is
present.

```mbt check
///|
test "trie prefix" {
  let root0 = @challenge_persistent_trie_string.empty()
  let root1 = @challenge_persistent_trie_string.add(root0, "car")
  inspect(
    @challenge_persistent_trie_string.contains(root1, "car"),
    content="true",
  )
  inspect(
    @challenge_persistent_trie_string.contains(root1, "ca"),
    content="false",
  )
}
```

---

## Complexity

Let `L` be the word length.

- Insert: `O(L)`
- Search: `O(L)`
- Space per insert: `O(L)` new nodes

---

## When to use this structure

Use this package when you need:

- persistent word dictionaries
- fast prefix-based lookup (future extensions)
- immutability with shared structure

If you need to support uppercase or Unicode, you should extend the character
mapping and child storage.

---

## Reference implementation

```mbt
///| pub fn empty() -> Node

///| pub fn add(root : Node, s : String) -> Node

///| pub fn contains(root : Node, s : String) -> Bool
```
