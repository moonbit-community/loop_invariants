# Link-Cut Tree (Reference, Alternate)

Another link-cut tree implementation focusing on explicit splay rotations and
path-parent management.

## What it demonstrates

- Preferred path decomposition
- Splaying to expose paths
- Dynamic link and cut operations

## Core Idea

Link-cut trees represent each tree as a forest of preferred paths, each stored
as a splay tree. The `access(x)` operation exposes the path from `x` to the
root by cutting and re-linking preferred edges, which makes path queries and
updates efficient.

## What You Can Support

- Path aggregates (sum, max, min) by maintaining data in each splay node.
- Dynamic connectivity with `link` and `cut`.

## Typical Operations

- `access(x)`: expose path from root to `x`
- `evert(x)`: make `x` the root
- `link(x, y)`: connect root of `x`'s tree under `y`
- `cut(x, y)`: remove the edge between `x` and `y`

## Pseudocode sketch

```mbt nocheck
access(x)
link(x, y)
cut(x, y)
```

## Notes

- Amortized time: O(log n)
- This package is a reference implementation with invariants (not a public API)
