# Data Structures

This module contains array, range-query, tree, heap, trie, and ordered-set style
data structures, including Fenwick trees, segment trees, sparse tables, treaps,
skip lists, wavelet trees, and union-find.

Packages are organized as one structure or closely related structure family per
directory. Each package contains a `README.mbt.md` tutorial with examples that
are checked by `moon test`.

Run from the workspace root:

```bash
moon check
moon test
moon info
moon fmt
```

## Release notes

### 0.12.0

- **Behaviour change — `segment_tree_beats`:** `range_max` of an empty range
  (or of an empty tree) now returns `Int64::MIN` instead of `Int64::MIN + 1`.
  The `NEG_INF` sentinel is now the real `Int64::MIN`, so ranges containing
  `Int64::MIN` report it correctly; `range_chmin` to a cap at or below the
  sentinel no longer corrupts leaves.
- `implicit_treap`: `range_max` of values equal to `Int64::MIN` is now exact.
- `bitset`: `or_in`/`xor_in` no longer set bits past the capacity.
- `fenwick_range_add_range_sum`: `range_sum` with `r >= n` is clamped instead
  of aborting.
