# Treap (Randomized Binary Search Tree)

A treap is a **binary search tree** that stays balanced using **random
priorities** instead of complex rotation rules. It combines two properties:

1) **BST by key**: left < node < right  
2) **Heap by priority**: parent priority > child priority

Random priorities make the expected height O(log n), so insert/delete/search
are all O(log n) on average.

This package provides a generic `Treap[T]` where `T : Compare`.

---

## API summary (what you can call)

```
@treap.Treap::new() -> Treap[T]
Treap::insert(key)
Treap::delete(key) -> Bool
Treap::contains(key) -> Bool
Treap::size() -> Int
Treap::min() -> T?
Treap::max() -> T?
Treap::to_array() -> Array[T]           // inorder (sorted)
Treap::kth_element(k) -> T?             // 0-indexed
Treap::count_less_than(x) -> Int        // strict
```

Notes:
- Duplicates are allowed; delete removes **one** copy.
- `kth_element(0)` means the smallest element.
- `count_less_than(x)` counts strictly smaller keys.

---

## The core idea (in one picture)

Each node has a key and a random priority:

```
        (key=5, pri=90)
        /            \
   (key=2, pri=70)  (key=8, pri=45)

BST check: 2 < 5 < 8     (by key)
Heap check: 90 > 70, 90 > 45   (by priority)
```

The key orders the tree like a normal BST. The priority makes it "randomly
balanced" like a heap.

---

## Why random priorities balance the tree

Imagine inserting all keys in **priority order** (highest first). That produces
the same structure as the treap.

If priorities are random, that insertion order is random. A random BST has:
- expected depth O(log n)
- very low chance of becoming tall

So even if keys are inserted in sorted order, the priorities prevent the tree
from degenerating.

---

## Visual: sorted input vs treap

Insert keys 1,2,3,4,5:

```
Naive BST (sorted input):      Treap (random priorities):
      1                        priorities:
       \                       1->30, 2->90, 3->50, 4->70, 5->10
        2
         \                     tree:
          3                      (2,90)
           \                     /     \
            4                 (1,30)  (4,70)
             \                          /    \
              5                     (3,50) (5,10)

Height = 5 (bad)               Height = 3 (good)
```

---

## How treap operations work (split + merge)

Most treap operations are built from two primitives:

### 1) Split by key

`split(t, key)` returns two trees:
- `left`: all keys < key
- `right`: all keys >= key

```
Split at key = 6:

        (5,90)                      left:           right:
       /      \                      (5,90)          (8,70)
   (3,50)   (8,70)        ->         /                   \
      \      /  \                 (3,50)               (9,30)
   (4,20) (7,40) (9,30)               \
                                     (4,20)
```

### 2) Merge two trees

`merge(left, right)` assumes all keys in `left` < all keys in `right`.
The root with higher priority becomes the new root.

```
left:           right:
 (3,80)          (7,50)
    \               \
   (5,40)         (9,30)

Result:
       (3,80)
             \
            (7,50)
           /     \
        (5,40)  (9,30)
```

These two primitives are simple and give clean insert/delete logic.

---

## Insert (conceptual)

```
insert(key):
  new_node = (key, random_priority)
  (left, right) = split(root, key)
  root = merge(merge(left, new_node), right)
```

This implementation uses exactly that approach.

---

## Delete (conceptual)

Delete one occurrence:

```
delete(key):
  (left, mid_right) = split(root, key)
  (mid, right) = split(mid_right, key + epsilon)
  // mid holds all nodes == key
  if mid is empty: not found
  else: mid = merge(mid.left, mid.right)  // remove one
  root = merge(left, merge(mid, right))
```

The actual code uses a recursive delete, but the behavior matches this idea.

---

## Example 1: empty treap

```mbt check
///|
test "treap empty" {
  let t : @treap.Treap[Int] = @treap.Treap::new()
  inspect(t.size(), content="0")
  inspect(t.min(), content="None")
  inspect(t.max(), content="None")
  inspect(t.kth_element(0), content="None")
}
```

---

## Example 2: insert, contains, size

```mbt check
///|
test "treap basic insert and contains" {
  let t = @treap.Treap::new()
  t.insert(5)
  t.insert(3)
  t.insert(7)
  t.insert(1)
  t.insert(9)
  inspect(t.size(), content="5")
  inspect(t.contains(5), content="true")
  inspect(t.contains(10), content="false")
}
```

---

## Example 3: min, max, inorder (sorted)

The inorder traversal of a treap is always sorted by key.
`to_array()` returns that order.

```mbt check
///|
test "treap min max and to_array" {
  let t = @treap.Treap::new()
  for x in [5, 3, 7, 1, 9] {
    t.insert(x)
  }
  inspect(t.min(), content="Some(1)")
  inspect(t.max(), content="Some(9)")
  inspect(t.to_array(), content="[1, 3, 5, 7, 9]")
}
```

---

## Example 4: delete

```mbt check
///|
test "treap delete one key" {
  let t = @treap.Treap::new()
  t.insert(5)
  t.insert(3)
  t.insert(7)
  inspect(t.delete(3), content="true")
  inspect(t.contains(3), content="false")
  inspect(t.size(), content="2")
  inspect(t.delete(42), content="false")
}
```

---

## Example 5: duplicates

Duplicates are allowed. `delete` removes **one** copy.

```mbt check
///|
test "treap duplicates" {
  let t = @treap.Treap::new()
  t.insert(5)
  t.insert(5)
  t.insert(5)
  inspect(t.size(), content="3")
  inspect(t.to_array(), content="[5, 5, 5]")
  inspect(t.delete(5), content="true")
  inspect(t.size(), content="2")
  inspect(t.to_array(), content="[5, 5]")
}
```

---

## Example 6: order statistics (kth and rank)

`kth_element(k)` returns the k-th smallest (0-indexed).
`count_less_than(x)` returns how many keys are smaller than `x`.

```mbt check
///|
test "treap order statistics" {
  let t = @treap.Treap::new()
  for x in [5, 3, 7, 1, 9] {
    t.insert(x)
  }
  inspect(t.kth_element(0), content="Some(1)")
  inspect(t.kth_element(2), content="Some(5)")
  inspect(t.kth_element(4), content="Some(9)")
  inspect(t.kth_element(5), content="None")
  inspect(t.count_less_than(5), content="2")
  inspect(t.count_less_than(10), content="5")
}
```

---

## How order statistics work (visual)

Each node stores `size = 1 + size(left) + size(right)`:

```
        (5, size=5)
       /           \
  (3, size=2)   (8, size=2)
    /               \
 (1, size=1)     (9, size=1)
```

To find `kth_element(2)` (3rd smallest):

```
At 5: left.size = 2, k = 2
  k == left.size -> answer is 5
```

---

## When to use a treap

- You want a **sorted set** with simple code.
- You need **split/merge** or **order statistics**.
- You want expected O(log n) without complex balancing logic.

---

## Complexity

```
Operation            Expected time
----------------------------------
insert/delete/search O(log n)
min/max              O(log n) worst, O(1) expected depth
kth/count_less_than  O(log n)
to_array             O(n)
```

Worst case is O(n), but the probability of a bad height is extremely small
because priorities are random.

---

## Common pitfalls

- Remember `kth_element` is 0-indexed.
- If you need stable ordering of equal keys, you must include a tie-breaker
  in the key (e.g., `(value, id)`).
- The treap is randomized; structure may vary, but `to_array()` order is always
  sorted.
