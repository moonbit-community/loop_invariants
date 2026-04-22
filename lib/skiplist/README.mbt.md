# Skip List (Probabilistic Ordered Structure)

This package implements a skip list: a probabilistic alternative to balanced
trees. Skip lists give expected O(log n) search, insert, and delete with
simple pointer updates and no rotations.

---

## 1. Big idea (beginner friendly)

A skip list is multiple sorted linked lists stacked on top of each other.
Higher levels act as "express lanes" that skip over many elements:

```
Level 2: HEAD ─────────────────> 5 ─────────────────> 9 ──> NIL
Level 1: HEAD ──────> 3 ────────> 5 ────────> 7 ────────> 9 ──> NIL
Level 0: HEAD -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9 ──> NIL
```

Each node at level i also exists on all levels below i.  The header
sentinel exists at every level and is treated as negative infinity.

Searching moves right on the current level while the next key is smaller
than the target, then drops down one level when it would overshoot.

---

## 2. Visual search path

Search for key 6 in the structure above:

```
Level 2: HEAD ─────────────────> 5   (next is 9 > 6, drop down)
                                  |
Level 1:                          5 ────────> 7   (7 > 6, drop down)
                                  |
Level 0:                          5 -> 6   (found!)
```

The search touches only a handful of nodes rather than scanning the whole
list.  Expected nodes visited = O(log n).

---

## 3. Structure of a single node

Each node stores an array of forward pointers, one per level it occupies:

```
     key=5, value=50
     forward:
       [0] -> node(6)
       [1] -> node(7)
       [2] -> node(9)
```

The header sentinel has forward pointers at every level up to max_level
and its key is treated as negative infinity:

```
     HEAD (sentinel, key = -inf)
     forward:
       [0] -> node(1)   -- level 0: all elements
       [1] -> node(3)   -- level 1: promoted elements
       [2] -> node(5)   -- level 2: highly promoted elements
       ...
```

---

## 4. How heights are chosen (random level assignment)

When a new node is inserted its height is chosen by repeatedly flipping a
biased coin until the coin shows "tails":

```
level = 0
while random() % 4 == 0 and level < max_level - 1:
    level = level + 1
```

With promotion probability p = 1/4:

```
P(level >= 0) = 1          (every node is at level 0)
P(level >= 1) = 1/4
P(level >= 2) = 1/16
P(level >= k) = (1/4)^k
```

This gives a geometric distribution.  Most nodes are short towers; a few
are tall.  The expected number of forward pointers per node is 4/3.

---

## 5. Step-by-step insertion example

Insert key 4 (value 40) into this skip list:

```
Before:
Level 2: HEAD ──────────────────────> 5 ──────> 9 ──> NIL
Level 1: HEAD ──────────> 3 ─────────> 5 ──> 7 ──> 9 ──> NIL
Level 0: HEAD -> 1 -> 2 -> 3 ─────────> 5 -> 6 -> 7 -> 8 -> 9 ──> NIL
```

Step 1 — walk and fill the update array (predecessor at each level):

```
Level 2: HEAD (next=5 > 4)   -> update[2] = HEAD
Level 1:    3 (next=5 > 4)   -> update[1] = node(3)
Level 0:    3 (next=5 > 4)   -> update[0] = node(3)
```

Step 2 — assign a random level.  Suppose the coin gives level=1 (height 2).

Step 3 — splice the new node at levels 0 and 1:

```
new_node(4).forward[0] = update[0].forward[0]   -- was node(5)
update[0].forward[0]   = new_node(4)

new_node(4).forward[1] = update[1].forward[1]   -- was node(5)
update[1].forward[1]   = new_node(4)
```

Result:

```
After:
Level 2: HEAD ──────────────────────> 5 ──────> 9 ──> NIL
Level 1: HEAD ──────────> 3 ──> 4 ──> 5 ──> 7 ──> 9 ──> NIL
Level 0: HEAD -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9 ──> NIL
```

Only two forward pointers changed; no rotations or rebalancing.

---

## 6. Delete walkthrough

Delete key 7:

```
Step 1: fill update array exactly as in insert.
Step 2: verify forward[0] of the predecessor is indeed node(7).
Step 3: for each level i where update[i].forward[i] == node(7):
            update[i].forward[i] = node(7).forward[i]
```

Before and after at the affected levels:

```
Before:
  Level 1: ... -> 5 -> 7 -> 9 -> NIL
  Level 0: ... -> 6 -> 7 -> 8 -> 9 -> NIL

After:
  Level 1: ... -> 5 ────────> 9 -> NIL
  Level 0: ... -> 6 -> 8 -> 9 -> NIL
```

If the top level becomes empty the current level counter is decremented.

---

## 7. Range query

To collect all entries with keys in [L, R]:

1. Search for the predecessor of L in O(log n) expected time.
2. Walk forward at level 0, collecting nodes while key <= R.

Level 0 is the base list and contains every element in sorted order, so a
forward scan from the first node >= L is all that is needed.

```
range_query(5, 13) on keys [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]:

  Search lands just before key 6.
  Walk: 6, 8, 10, 12 (14 > 13, stop)
  Result: [(6, 60), (8, 80), (10, 100), (12, 120)]
```

Total cost: O(log n + k) where k is the number of results.

---

## 8. Why expected cost is O(log n)

With p = 1/4:

- Level i contains approximately n / 4^i nodes on average.
- The expected height of the tallest tower is O(log_4 n).
- Search visits at most a constant expected number of nodes per level
  (because at each level the run of "right" steps is geometrically bounded).

Memory cost: 1 + 1/4 + 1/16 + ... = 4/3 forward pointers per node on
average, so total space is O(n).

---

## 9. Skip list vs balanced tree

```
                  Skip list          Balanced BST (e.g. AVL / red-black)
Search           O(log n) expected   O(log n) worst case
Insert           O(log n) expected   O(log n) worst case
Delete           O(log n) expected   O(log n) worst case
Worst case       O(n) (very rare)    O(log n)
Implementation   Simple              Moderately complex (rotations/recoloring)
Concurrency      Lock-free friendly  Hard to make lock-free
Range scan       Natural (level 0)   Needs in-order traversal
```

Use a skip list when simplicity and concurrent access matter more than
strict worst-case guarantees.

---

## 10. This implementation

The package provides two internal data structures:

- `SkipList[K, V]` — a standard ordered map with unique keys.
- `MultiSkipList[K, V]` — allows duplicate keys; each key maps to an array
  of values.

Both use `max_level = 16` and promotion probability 1/4.

```mbt nocheck
///|
let sl : SkipList[Int, String] = SkipList::new()

sl.insert(3, "three")
sl.insert(1, "one")
sl.insert(4, "four")
sl.insert(1, "one-again") // duplicate: update is silently skipped in this impl
sl.insert(5, "five")

sl.search(3)  // Some("three")
sl.search(2)  // None

sl.delete(4)  // true

sl.min()   // Some((1, "one"))
sl.max()   // Some((5, "five"))

sl.ceil(2)   // Some((3, "three"))
sl.floor(2)  // Some((1, "one"))

sl.range_query(1, 4)  // [(1, "one"), (3, "three")]
```

---

## 11. Common applications

1. Ordered sets and maps (this package).
2. Concurrent data structures — skip lists are easier to make lock-free
   than rotation-based trees.
3. Databases and in-memory indexes — Redis uses a skip list for sorted sets.
4. Range queries — O(log n) entry point, then a fast sequential scan.

---

## 12. Key invariants maintained at all times

1. Every node at level i also appears on all levels 0..i-1.
2. Each level is a sorted singly-linked list of forward pointers.
3. The header sentinel is present at every level and acts as -infinity.
4. `self.level` always equals the index of the highest non-empty level.

---

## 13. Summary

Skip lists are a clean probabilistic alternative to balanced trees:

- simple pointer updates (no rotations),
- expected O(log n) operations,
- great for ordered or concurrent data.
