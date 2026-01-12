# Aho-Corasick (Reference)

Multi-pattern string matching by combining patterns into a trie and adding
failure links. This allows scanning the text once while reporting matches.

## What it demonstrates

- Trie construction from patterns
- Failure links via BFS
- Streaming matching with output links

## Pseudocode sketch

```mbt nocheck
build_trie(patterns)
build_failure_links()
for c in text:
  state = next_state(state, c)
  report matches at state
```

## Example

```mbt check
///|
test "aho corasick example" {
  let patterns : Array[String] = ["he", "she", "his", "hers"]
  let matches = @aho_corasick.find_all_matches(patterns[:], "ushers")
  inspect(matches.length(), content="3")
  let found_she = matches.filter(fn(m) { m.2 == "she" }).length() > 0
  let found_he = matches.filter(fn(m) { m.2 == "he" }).length() > 0
  let found_hers = matches.filter(fn(m) { m.2 == "hers" }).length() > 0
  inspect(found_she && found_he && found_hers, content="true")
  inspect(@aho_corasick.count_all_matches(patterns[:], "ushers"), content="3")
}
```

## Notes

- Time complexity: O(text length + total pattern length)
- This package is a reference implementation with invariants
