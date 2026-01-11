# Persistent Bitset

Immutable bitset backed by a path-copying segment tree.

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
