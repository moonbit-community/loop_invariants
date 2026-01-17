# Challenge: Persistent Implicit Treap

An **implicit treap** is a balanced sequence tree. It acts like an array where
indices are determined by subtree sizes rather than explicit keys.

This implementation is **persistent**: every insert returns a new treap while
old versions remain valid.

This package provides:

- `empty()` to create a treap
- `insert_at(t, idx, value)` to insert by index
- `get(t, idx)` to read by index
- `split(t, k)` to split into prefix/suffix
- `merge(a, b)` to concatenate
- `to_array(t)` to materialize
- `from_array(arr)` to build from a list

---

## Treap basics (heap + BST)

A treap uses **priorities** to keep balance:

- In-order traversal gives sequence order.
- Parent priority is >= child priorities (max-heap by priority).

Because the tree is balanced by random-like priorities, operations are `O(log n)`
on average.

In this implementation, priorities are derived deterministically:

```
priority = hash(value) + salt * 12345
```

The salt is the insertion index. This is fast and stable, but it is not
cryptographic randomness. For adversarial inputs, balance could degrade.

---

## What does "implicit" mean?

We do not store explicit keys. Instead, the **index** of a node is:

```
size(left subtree)
```

So in-order traversal is the sequence order.

Example:

```
        (X)
       /   \
     (A)   (B)

index(X) = size(left subtree) = size(A)
```

---

## Split by position

`split(t, k)` returns `(prefix, suffix)` such that:

- `prefix` contains the first `k` elements
- `suffix` contains the rest

Example sequence:

```
[10, 20, 30, 40, 50]
```

Split at `k = 3`:

```
prefix = [10, 20, 30]
Suffix = [40, 50]
```

---

## Merge

`merge(a, b)` concatenates two treaps, assuming **all elements of `a` should
come before all elements of `b`**.

It chooses the root by priority and recurses.

---

## Persistence (path copying)

Inserts and splits create new nodes only along the affected path. Other nodes
are shared with previous versions.

```
Old version:               New version:

     A                        A'
    / \                      / \
   B   C     insert x       B'  C
  / \                      / \
 D   E                    D   E
```

Only nodes on the path (`A`, `B`) are copied.

---

## Worked example: insert at index

Start with empty and insert 10, 20, then insert 15 in the middle:

```
insert_at(0, 10) -> [10]
insert_at(1, 20) -> [10, 20]
insert_at(1, 15) -> [10, 15, 20]
```

---

## Reference implementation

```mbt
///| pub fn[T] empty() -> Treap[T]

///| pub fn[T] split(t : Treap[T], k : Int) -> (Treap[T], Treap[T])

///| pub fn[T] merge(a : Treap[T], b : Treap[T]) -> Treap[T]

///| pub fn[T : Hash] insert_at(t : Treap[T], idx : Int, value : T) -> Treap[T]

///| pub fn[T] get(t : Treap[T], idx : Int) -> T?

///| pub fn[T] to_array(t : Treap[T]) -> Array[T]

///| pub fn[T : Hash] from_array(arr : ArrayView[T]) -> Treap[T]
```

---

## Tests and examples

### Basic insertion and get

```mbt check
///|
test "implicit treap basic" {
  let t0 : @challenge_persistent_implicit_treap.Treap[Int] = @challenge_persistent_implicit_treap.empty()
  let t1 = @challenge_persistent_implicit_treap.insert_at(t0, 0, 10)
  let t2 = @challenge_persistent_implicit_treap.insert_at(t1, 1, 20)
  let t3 = @challenge_persistent_implicit_treap.insert_at(t2, 1, 15)
  inspect(
    @challenge_persistent_implicit_treap.to_array(t3),
    content="[10, 15, 20]",
  )
  inspect(@challenge_persistent_implicit_treap.get(t3, 2), content="Some(20)")
}
```

### Split and merge

```mbt check
///|
test "implicit treap split merge" {
  let t = @challenge_persistent_implicit_treap.from_array([1, 2, 3, 4, 5][:])
  let (left, right) = @challenge_persistent_implicit_treap.split(t, 3)
  inspect(
    @challenge_persistent_implicit_treap.to_array(left),
    content="[1, 2, 3]",
  )
  inspect(
    @challenge_persistent_implicit_treap.to_array(right),
    content="[4, 5]",
  )
  let merged = @challenge_persistent_implicit_treap.merge(left, right)
  inspect(
    @challenge_persistent_implicit_treap.to_array(merged),
    content="[1, 2, 3, 4, 5]",
  )
}
```

### Persistence across versions

```mbt check
///|
test "implicit treap persistence" {
  let t0 = @challenge_persistent_implicit_treap.from_array([10, 20, 30][:])
  let t1 = @challenge_persistent_implicit_treap.insert_at(t0, 1, 15)
  inspect(
    @challenge_persistent_implicit_treap.to_array(t0),
    content="[10, 20, 30]",
  )
  inspect(
    @challenge_persistent_implicit_treap.to_array(t1),
    content="[10, 15, 20, 30]",
  )
}
```

---

## Complexity

Let `n = size`:

- `split` / `merge`: `O(log n)` average
- `insert_at`: `O(log n)` average (split + merge)
- `get`: `O(log n)` average
- `to_array`: `O(n)`

Worst-case can degrade if priorities are adversarial.

---

## Takeaways

- Implicit treaps store sequence order using subtree sizes.
- Split and merge are the core operations.
- Persistence keeps all versions with low memory overhead.
