# String Algorithms

This module contains pattern matching, hashing, suffix structures, palindromic
structures, tries, automata, and string rotation algorithms.

Packages are organized as one algorithm or data structure per directory. Each
package contains a `README.mbt.md` tutorial with examples that are checked by
`moon test`.

Run from the workspace root:

```bash
moon check
moon test
moon info
moon fmt
```

## Release notes

### Unreleased

- **Behaviour change — `aho_corasick`:** an empty pattern in the dictionary
  now never matches (like every other searcher in this module). Previously it
  was reported at some positions depending on the other patterns. Pattern
  indices are unchanged.
- `kmp.z_search` and `z_algorithm.find_pattern`/`z_search`/`count_pattern`
  no longer miss matches followed by `$` in the text.
- `rabin_karp` and `rolling_hash` pattern search no longer miss matches
  containing characters below `'a'`.
