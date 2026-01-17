# Mo's Algorithm (Offline Range Queries)

This package is a **tutorial** package (no exported functions). It explains
Mo's algorithm, a technique for answering many **range queries** on a static
array by carefully ordering the queries to minimize sliding-window movement.

Mo's is ideal when:

- all queries are known in advance (offline),
- the array does not change,
- the answer can be updated in O(1) or O(log n) when a single element is added
  or removed from the current window.

---

## 1. Problem statement (what we want to accelerate)

We are given:

- an array `a[0..n-1]`,
- queries `[l, r]` (inclusive),
- and a function `answer(l, r)` to compute for each range.

Example: count **distinct values** in each range.

```
Array:  [1, 2, 1, 3, 1, 2, 4]
Index:   0  1  2  3  4  5  6

Queries:
  Q0: [0, 2] -> {1,2} -> 2
  Q1: [1, 4] -> {1,2,3} -> 3
  Q2: [2, 6] -> {1,2,3,4} -> 4
```

Naive: recompute each range from scratch => O(q * n).

Mo's: reorder queries so L and R move slowly => about O((n + q) * sqrt(n)).

---

## 2. Sliding window model

Maintain a current window `[L, R]` and a data structure that can:

- `add(i)` when we extend the window to include `a[i]`,
- `remove(i)` when we shrink the window past `a[i]`.

For distinct count:

```
count[x] = occurrences of value x in the window
distinct = number of x with count[x] > 0

add(i):
  x = a[i]
  if count[x] == 0: distinct += 1
  count[x] += 1

remove(i):
  x = a[i]
  count[x] -= 1
  if count[x] == 0: distinct -= 1
```

Each add/remove is O(1). The trick is to **minimize how many** add/remove
operations we do in total.

---

## 3. Block decomposition (the core trick)

Let block size be `B = floor(sqrt(n))`.

We sort queries by:

1. **block(L)** = `L / B`
2. **R** (ascending within the same block)

This groups queries by similar L, and within each group makes R mostly move
forward.

Example with `n = 9`, `B = 3`:

```
Index:  0  1  2  3  4  5  6  7  8
Block:  0  0  0  1  1  1  2  2  2
```

If L is in block 1, it means L is in [3, 5], so those queries are grouped
together and sorted by R.

---

## 4. Step-by-step example

Array:

```
a = [1, 2, 1, 3, 1, 2, 4]
```

Queries:

```
Q0: [0, 6]
Q1: [0, 2]
Q2: [2, 4]
Q3: [1, 3]
```

Let `B = 2` (sqrt(7) rounded).

Block of each L:

```
L=0 -> block 0
L=1 -> block 0
L=2 -> block 1
```

Sorted by (block(L), R):

```
Q1: [0, 2]
Q3: [1, 3]
Q0: [0, 6]
Q2: [2, 4]
```

Now simulate:

```
Start: L=0, R=-1, window empty

Q1 [0,2]:
  add 0,1,2 -> [1,2,1] -> distinct=2

Q3 [1,3]:
  remove 0  -> [2,1]   -> distinct=2
  add 3     -> [2,1,3] -> distinct=3

Q0 [0,6]:
  add 0,4,5,6 -> [1,2,1,3,1,2,4] -> distinct=4

Q2 [2,4]:
  remove 0,1 -> [1,3,1,2,4] -> distinct=4
  remove 5,6 -> [1,3,1]     -> distinct=2
```

Answers in original order:

```
Q0 -> 4
Q1 -> 2
Q2 -> 2
Q3 -> 3
```

---

## 5. Diagram: how the window moves

```
Array:   [1, 2, 1, 3, 1, 2, 4]
Index:    0  1  2  3  4  5  6

Q1 [0,2]:  L-----R
Q3 [1,3]:    L-----R
Q0 [0,6]:  L-----------------R
Q2 [2,4]:       L-----R

R mostly moves forward. L moves only within a small block.
```

---

## 6. Conceptual MoonBit template

No public API is defined in this package. The following is an **illustration**
of the workflow:

```mbt nocheck
///|
struct Query {
  l : Int
  r : Int
  idx : Int
}

fn block_of(i : Int, block_size : Int) -> Int {
  i / block_size
}

fn sort_mo(qs : Array[Query], block_size : Int) -> Unit {
  qs.sort_by((a, b) => {
    let ba = block_of(a.l, block_size)
    let bb = block_of(b.l, block_size)
    if ba != bb {
      ba - bb
    } else {
      a.r - b.r
    }
  })
}

fn solve(a : ArrayView[Int], qs : Array[Query]) -> Array[Int] {
  let n = a.length()
  let block_size = (n.to_float().sqrt().to_int()).max(1)
  sort_mo(qs, block_size)

  let answers : Array[Int] = Array::make(qs.length(), 0)
  let mut l = 0
  let mut r = -1

  // state for distinct count:
  let mut distinct = 0
  let freq : Map[Int, Int] = {}

  let add = (i : Int) => {
    let x = a[i]
    let c = freq.get(x).unwrap_or(0)
    if c == 0 { distinct = distinct + 1 }
    freq[x] = c + 1
  }

  let remove = (i : Int) => {
    let x = a[i]
    let c = freq[x]
    freq[x] = c - 1
    if c - 1 == 0 { distinct = distinct - 1 }
  }

  for q in qs {
    loop {
      if l <= q.l { break }
      l = l - 1
      add(l)
    }
    loop {
      if r >= q.r { break }
      r = r + 1
      add(r)
    }
    loop {
      if l >= q.l { break }
      remove(l)
      l = l + 1
    }
    loop {
      if r <= q.r { break }
      remove(r)
      r = r - 1
    }
    answers[q.idx] = distinct
  }
  answers
}
```

---

## 7. More examples (what Mo can support)

Mo's algorithm works for any range query where add/remove is easy.

### Example A: number of equal pairs

If count[x] is how many times value x appears, then:

```
pairs = sum over x of count[x] * (count[x] - 1) / 2
```

Update when adding x:

```
pairs += count[x]
count[x]++
```

Update when removing x:

```
count[x]--
pairs -= count[x]
```

### Example B: sum of squared frequencies

```
answer = sum over x of count[x]^2
```

On add/remove, adjust only the changed value.

### Example C: range xor

```
answer = xor of all values in [l, r]
```

Add/remove just toggles that value.

---

## 8. Complexity (why sqrt appears)

Let `B = sqrt(n)`.

- **R movement**: within each block, R moves forward at most n steps.
  There are about n / B blocks => O(n * n / B) = O(n * sqrt(n)).
- **L movement**: each query shifts L at most B => O(q * B) = O(q * sqrt(n)).

Total:

```
O((n + q) * sqrt(n))
```

Sorting queries costs O(q log q), which is usually smaller.

---

## 9. Practical tips

1. **Coordinate-compress values** if they are large (so counts fit in arrays).
2. **Odd-even block order** can reduce R backtracking:
   - even blocks: sort by R ascending
   - odd blocks: sort by R descending
3. **Choose B carefully**:
   - default: `B = sqrt(n)`
   - if q << n, use `B = n / sqrt(q)`
4. **Store original indices** to output answers in original order.
5. **Do not use Mo's** if queries must be answered online or if updates exist.

---

## 10. Summary

Mo's algorithm is a reordering technique:

- it turns expensive query recomputation into cheap incremental updates,
- it is simple once add/remove are defined,
- it is most effective when queries are offline and static.

If your query fits the "add/remove" pattern, Mo's is a strong and elegant tool.
