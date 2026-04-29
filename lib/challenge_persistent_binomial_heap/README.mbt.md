# Challenge: Persistent Binomial Heap

A **binomial heap** is a priority queue built from a forest of binomial trees.
This implementation is **persistent**, so merges and insertions create new
heaps while old versions remain usable.

This package provides:

- `empty()` to create an empty heap
- `merge(a, b)` to combine two heaps
- `insert(h, value)` to insert a value (persistent)
- `find_min(h)` to read the minimum value
- `delete_min(h)` to remove the minimum value

---

## What is a binomial tree?

A binomial tree of rank `k` has:

- exactly `2^k` nodes
- height `k`
- children that are binomial trees of ranks `k-1, k-2, ..., 0`

Small ranks:

```
Rank 0:    o

Rank 1:    o
          /
         o

Rank 2:        o
            / | \
           o  o  o
          /
         o
```

Each binomial tree is min-heap ordered: parent <= children.

---

## Heap as a binary number

A binomial heap stores at most one tree of each rank. This is like a binary
number where:

- bit `i` is 1 if there is a tree of rank `i`
- bit `i` is 0 if there is no tree of rank `i`

Merging two heaps is like binary addition with carry:

```
rank: 0 1 2 3
heap A: 1 0 1 0
heap B: 1 1 0 0
----------------
sum:    0 0 0 1   (with carries)
```

When two trees of the same rank meet, we **link** them into one tree of the
next rank (just like carry).

---

## Link operation

To link two trees of the same rank:

- Compare their root values
- The smaller root becomes the new root
- The larger root becomes a child
- Rank increases by 1

```
link(Ta, Tb) -> T'
```

This preserves the heap property.

---

## Persistence (path copying)

This heap is persistent because it never mutates old trees. When we merge or
insert, we build new arrays and new nodes where needed, and share the rest.

Old versions remain valid forever.

---

## Reference implementation

```mbt nocheck
///| pub fn[T] empty() -> Heap[T]

///| pub fn[T : Compare] merge(a : Heap[T], b : Heap[T]) -> Heap[T]

///| pub fn[T : Compare] insert(h : Heap[T], value : T) -> Heap[T]

///| pub fn[T : Compare] find_min(h : Heap[T]) -> T?

///| pub fn[T : Compare] delete_min(h : Heap[T]) -> Heap[T]?
```

---

## Tests and examples

### Insert and find minimum

```mbt check
///|
test "binomial heap basic" {
  let h0 = @challenge_persistent_binomial_heap.empty()
  let h1 = @challenge_persistent_binomial_heap.insert(h0, 5)
  let h2 = @challenge_persistent_binomial_heap.insert(h1, 2)
  let h3 = @challenge_persistent_binomial_heap.insert(h2, 8)
  debug_inspect(
    @challenge_persistent_binomial_heap.find_min(h3),
    content="Some(2)",
  )
  debug_inspect(
    @challenge_persistent_binomial_heap.find_min(h0),
    content="None",
  )
}
```

### Merge two heaps

```mbt check
///|
test "binomial heap merge" {
  let a = @challenge_persistent_binomial_heap.insert(
    @challenge_persistent_binomial_heap.empty(),
    4,
  )
  let b = @challenge_persistent_binomial_heap.insert(
    @challenge_persistent_binomial_heap.empty(),
    1,
  )
  let merged = @challenge_persistent_binomial_heap.merge(a, b)
  debug_inspect(
    @challenge_persistent_binomial_heap.find_min(merged),
    content="Some(1)",
  )
}
```

### Delete minimum

```mbt check
///|
test "binomial heap delete min" {
  let h = @challenge_persistent_binomial_heap.insert(
    @challenge_persistent_binomial_heap.insert(
      @challenge_persistent_binomial_heap.empty(),
      3,
    ),
    1,
  )
  let h2 = @challenge_persistent_binomial_heap.delete_min(h)
  match h2 {
    None => fail("expected non-empty heap")
    Some(next) =>
      debug_inspect(
        @challenge_persistent_binomial_heap.find_min(next),
        content="Some(3)",
      )
  }
}
```

### Persistence across versions

```mbt check
///|
test "binomial heap persistence" {
  let h0 = @challenge_persistent_binomial_heap.empty()
  let h1 = @challenge_persistent_binomial_heap.insert(h0, 10)
  let h2 = @challenge_persistent_binomial_heap.insert(h1, 4)
  debug_inspect(
    @challenge_persistent_binomial_heap.find_min(h1),
    content="Some(10)",
  )
  debug_inspect(
    @challenge_persistent_binomial_heap.find_min(h2),
    content="Some(4)",
  )
}
```

---

## Complexity

Let `n` be the number of elements.

- Insert: `O(log n)` (merge with a singleton heap)
- Merge: `O(log n)` (one pass over ranks)
- Find min: `O(log n)` (scan all tree roots)
- Delete min: `O(log n)` (remove one tree and merge children)

---

## Takeaways

- A binomial heap is a forest of binomial trees, one per rank.
- Merging is like binary addition with carries.
- Persistence means every insert or merge creates a new version.
