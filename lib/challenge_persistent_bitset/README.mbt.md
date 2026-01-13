# Persistent Bitset

Immutable bitset backed by a path-copying segment tree.

## Core Idea

Each update returns a new segment tree root. Only nodes on the path to the
updated index are copied, while the rest of the tree is shared.

This allows fast versioned queries like `count_range` without mutating
previous versions.

## Example

```mbt check
///|
test "persistent bitset" {
  let bs0 = @challenge_persistent_bitset.make(8)
  let bs1 = @challenge_persistent_bitset.set(bs0, 2, 1)
  let bs2 = @challenge_persistent_bitset.set(bs1, 5, 1)
  inspect(@challenge_persistent_bitset.get(bs2, 2), content="1")
  inspect(@challenge_persistent_bitset.get(bs2, 3), content="0")
  inspect(@challenge_persistent_bitset.count_range(bs2, 0, 6), content="2")
  inspect(@challenge_persistent_bitset.length(bs2), content="8")
}
```

## Another Example

```mbt check
///|
test "persistent bitset from indices" {
  let bs = @challenge_persistent_bitset.from_indices(6, [1, 4][:])
  inspect(@challenge_persistent_bitset.get(bs, 1), content="1")
  inspect(@challenge_persistent_bitset.count_range(bs, 0, 6), content="2")
}
```

## Notes

- Indices are 0-based.
- `count_range` uses half-open ranges.
