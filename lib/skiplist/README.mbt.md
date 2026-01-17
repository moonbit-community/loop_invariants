# Skip List (Probabilistic Ordered Structure)

This package documents skip lists, a probabilistic alternative to balanced
trees. Skip lists give expected O(log n) search, insert, and delete with
simple pointer updates.

---

## 1. Big idea (beginner friendly)

A skip list is multiple sorted linked lists stacked in levels.

Higher levels "skip" many nodes, like express lanes:

```
Level 2: 1 ------------> 5 ------------> 9
Level 1: 1 ----> 3 ----> 5 ----> 7 ----> 9
Level 0: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9
```

Searching goes right on the current level, and drops down when you would
overshoot.

---

## 2. Visual search path

Search for key 6:

```
Level 2: 1 -> 5 (next is 9 > 6) drop down
           |
Level 1:   5 -> 7 (7 > 6) drop down
           |
Level 0:   5 -> 6 (found)
```

You only touch a few nodes per level instead of scanning the whole list.

---

## 3. How heights are chosen (random levels)

Each node gets a random height by flipping a coin:

```
level = 1
while coin_flip() == heads:
  level = level + 1
```

With probability p = 1/2:

```
P(level >= k) = (1/2)^(k-1)
```

So most nodes are height 1, fewer are height 2, and so on. This "pyramid"
shape is why searching is fast on average.

Example heights for values 1..9 (one possible outcome):

```
value : 1 2 3 4 5 6 7 8 9
height: 1 1 2 1 3 1 2 1 1
```

---

## 4. Anatomy of a node

Each node stores an array of forward pointers, one per level:

```
Node(value=5, next=[L0 -> 6, L1 -> 7, L2 -> 9])
```

There is a HEAD sentinel with the maximum level, so search can always start
from the top:

```
HEAD (level = max_level)
```

Some implementations also keep a TAIL sentinel to simplify edge cases.

---

## 5. Insert walkthrough (with update array)

Insert 4 into:

```
Level 2: HEAD ----> 5 ----> 9
Level 1: HEAD -> 3 -> 5 -> 7 -> 9
Level 0: HEAD -> 1 -> 2 -> 3 -> 5 -> 6 -> 7 -> 8 -> 9
```

Step 1: search and record the last node before the insertion point
at each level. This is usually called the update array.

```
Level 2: stop at HEAD (next 5 > 4)  -> update[2] = HEAD
Level 1: move to 3 (next 5 > 4)     -> update[1] = 3
Level 0: stop at 3 (next 5 > 4)     -> update[0] = 3
```

Step 2: flip coins, suppose the new node has height 2 (levels 0 and 1).

Step 3: rewire pointers on those levels:

```
Level 2: HEAD ----> 5 ----> 9
Level 1: HEAD -> 3 -> 4 -> 5 -> 7 -> 9
Level 0: HEAD -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9
```

Only a few pointers change, no rotations are needed.

---

## 6. Delete walkthrough

Delete key 7 from the structure:

1. Search and build the update array (same as insert).
2. If the next node at level 0 is 7, remove it.
3. At every level where 7 appears, bypass it.

Diagram (remove 7):

```
Before:
Level 1: ... -> 5 -> 7 -> 9
Level 0: ... -> 6 -> 7 -> 8 -> 9

After:
Level 1: ... -> 5 ------> 9
Level 0: ... -> 6 -> 8 -> 9
```

---

## 7. Range query (simple and fast)

To list all keys in [L, R]:

1. Search for the first node >= L (O(log n) expected).
2. Walk forward on level 0 until you pass R.

This is why skip lists are popular for ordered maps and sorted sets.

---

## 8. Why the expected cost is O(log n)

Two facts when p = 1/2:

- Expected number of nodes per level halves each level.
- Expected height of the tallest tower is O(log n).

So a search touches a few nodes per level, across O(log n) levels.

Memory is also reasonable: expected pointers per node is 1 / (1 - p) = 2.

---

## 9. Skip list vs balanced tree

```
Skip list:
  - Simple code
  - Randomized expected O(log n)
  - Worst case O(n) (rare)

Balanced tree:
  - More complex code
  - Guaranteed O(log n)
```

Use a skip list when simplicity and concurrency matter more than strict
worst-case guarantees.

---

## 10. Example usage (conceptual)

This package is tutorial-only; it does not export a concrete API.

```mbt nocheck
///|
let sl = SkipList::new()

sl.insert(3)
sl.insert(1)
sl.insert(4)
sl.insert(1) // duplicates may be allowed depending on the design
sl.insert(5)

sl.contains(3) // true
sl.contains(2) // false

sl.delete(4)
```

---

## 11. Common applications

1. Ordered sets and maps
2. Concurrent data structures (skip lists are easier to make lock-free)
3. Databases and in-memory indexes (Redis uses skip lists for sorted sets)
4. Range queries (scan at level 0 after O(log n) search)

---

## 12. Beginner checklist

1. Always start searching from the highest level.
2. Move right while next key < target, then drop down.
3. Keep a HEAD sentinel with max level.
4. Update arrays (or predecessor lists) make insert/delete easy.
5. Random heights keep the structure balanced in expectation.

---

## 13. Summary

Skip lists are a clean, probabilistic alternative to balanced trees:

- simple pointer updates,
- expected O(log n) operations,
- great for ordered or concurrent data.
