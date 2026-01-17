# Skip List (Probabilistic Ordered Structure)

This package documents **skip lists**, a probabilistic alternative to balanced
trees. Skip lists give expected **O(log n)** search, insert, and delete with
very simple logic.

---

## 1. Big idea (beginner friendly)

A skip list is **multiple linked lists stacked in levels**.

Higher levels “skip” over many elements, like an express lane:

```
Level 2: 1 ─────────→ 5 ─────────→ 9
Level 1: 1 ──→ 3 ──→ 5 ──→ 7 ──→ 9
Level 0: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9
```

To search, you:

1. Move right while the next value is smaller than target.
2. Drop down one level when you cannot move right.

This gives O(log n) expected steps.

---

## 2. Visual search example

Search for **6**:

```
Level 2: 1 → 5 (next is 9 > 6) drop down
Level 1: 5 → 7 (7 > 6) drop down
Level 0: 5 → 6 ✓ found
```

Only a few comparisons instead of scanning the whole list.

---

## 3. How levels are chosen

Each node gets a random height:

```
level = 1
while coin_flip() == heads:
  level++
```

Probability:

```
P(level >= k) = (1/2)^(k-1)
```

So most nodes are level 1, fewer are level 2, and so on.

---

## 4. Insert walkthrough

Suppose we insert `4` into:

```
Level 2: HEAD ──→ 5 ──→ 9
Level 1: HEAD ─→ 3 ─→ 5 ─→ 7 ─→ 9
Level 0: HEAD → 1 → 2 → 3 → 5 → 6 → 7 → 8 → 9
```

Steps:

1. Search down to find insertion points at each level (after 3).
2. Flip coins → say the new node gets level 2.
3. Update forward pointers at levels 0 and 1 (and 2 if present).

After insert:

```
Level 2: HEAD ──→ 4 ──→ 5 ──→ 9
Level 1: HEAD ─→ 3 ─→ 4 ─→ 5 ─→ 7 ─→ 9
Level 0: HEAD → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9
```

---

## 5. Delete idea (also easy)

Deletion is just pointer rewiring:

1. Search for the node.
2. At each level where it appears, bypass it.

No rebalancing is needed (unlike trees).

---

## 6. Example usage (conceptual)

This package is tutorial‑only; it does not export a concrete API.

```mbt nocheck
///|
let sl = SkipList::new()

sl.insert(3)
sl.insert(1)
sl.insert(4)
sl.insert(1)
sl.insert(5)

sl.contains(3) // true
sl.contains(2) // false

sl.delete(4)
```

---

## 7. Why it is O(log n) expected

At each level, you move only a few steps on average.

Expected nodes per level ~ 2.

With O(log n) levels, total expected work is O(log n).

---

## 8. Common applications

1. **Ordered sets / maps** (simpler than balanced trees)
2. **Concurrent structures** (skip lists are easier to make lock‑free)
3. **Databases** (Redis uses skip lists for sorted sets)
4. **Range queries** (scan at level 0 after O(log n) search)

---

## 9. Skip list vs balanced tree

```
Skip list:
  - Simple code
  - Randomized O(log n)
  - Worst case O(n) (rare)

Balanced tree:
  - More complex code
  - Guaranteed O(log n)
```

Use a skip list when simplicity and concurrency matter more than worst‑case.

---

## 10. Beginner checklist

1. Always start search from the highest level.
2. Move right while next key is < target, then drop down.
3. Use a sentinel HEAD node with max level.
4. Random levels keep the structure balanced in expectation.

---

## 11. Summary

Skip lists are a clean, probabilistic alternative to balanced trees:

- simple pointer updates,
- expected log‑time operations,
- great for concurrent or ordered data.
