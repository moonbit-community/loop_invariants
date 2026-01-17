# Challenge: Coordinate Compression

Coordinate compression maps arbitrary values to a compact range `0..k-1` while
preserving order. It is a standard trick to replace large or sparse numbers
with dense indices.

## Problem statement

Given a list of values (possibly large, negative, or repeated), produce:

- a sorted list of **unique** values
- for each original value, its **rank** in that unique list

The rank is the compressed coordinate.

## Why it matters

Many data structures (Fenwick tree, segment tree, arrays) require small,
contiguous indices. Compression makes problems like range counting possible
without huge memory.

## Algorithm overview

1. Copy values into a new array.
2. Sort the array.
3. Remove duplicates to get `unique`.
4. For each original value, find its position in `unique` with `lower_bound`.

## Diagram: example mapping

Values:

```
[100, 50, 100, -10]
```

Unique sorted:

```
[-10, 50, 100]
```

Mapping table:

```
value  -> index
-10    -> 0
50     -> 1
100    -> 2
```

Compressed output:

```
[2, 1, 2, 0]
```

## Examples

### Example 1: basic compression

```mbt check
///|
test "coordinate compress basic" {
  let values : Array[Int] = [100, 50, 100, -10]
  let (comp, uniq) = @challenge_coordinate_compress.coordinate_compress(
    values[:],
  )
  inspect(uniq, content="[-10, 50, 100]")
  inspect(comp, content="[2, 1, 2, 0]")
}
```

### Example 2: all duplicates

```mbt check
///|
test "coordinate compress duplicates" {
  let values : Array[Int] = [5, 5, 5]
  let (comp, uniq) = @challenge_coordinate_compress.coordinate_compress(
    values[:],
  )
  inspect(uniq, content="[5]")
  inspect(comp, content="[0, 0, 0]")
}
```

### Example 3: large and negative values

```mbt check
///|
test "coordinate compress large values" {
  let values : Array[Int] = [1_000_000_000, -500, 42, 42, 7]
  let (comp, uniq) = @challenge_coordinate_compress.coordinate_compress(
    values[:],
  )
  inspect(uniq, content="[-500, 7, 42, 1000000000]")
  inspect(comp, content="[3, 0, 2, 2, 1]")
}
```

### Example 4: already sorted

```mbt check
///|
test "coordinate compress sorted" {
  let values : Array[Int] = [-3, -1, 2, 5]
  let (comp, uniq) = @challenge_coordinate_compress.coordinate_compress(
    values[:],
  )
  inspect(uniq, content="[-3, -1, 2, 5]")
  inspect(comp, content="[0, 1, 2, 3]")
}
```

## Complexity

- Sorting: O(n log n)
- Each `lower_bound`: O(log n)
- Total: O(n log n)

## Practical notes and pitfalls

- If you need to compress multiple arrays together, concatenate them before
  building the unique list. Otherwise, ranks may be inconsistent.
- Compression preserves **order**, not spacing. Only the relative order matters.
- Use the returned `unique` array if you need to recover original values.

## When to use it

Use coordinate compression whenever you need dense indices for large or sparse
values, especially before using Fenwick or segment trees.
