# Prufer Code (Prüfer Sequence)

This package encodes and decodes **labeled trees** using the Prufer code.

For a tree with `n` vertices labeled `0..n-1`:

- The Prufer code is a sequence of length `n - 2`.
- Every labeled tree has **exactly one** code.
- Every code corresponds to **exactly one** tree.

This is the classic proof of **Cayley’s formula**:

```
number of labeled trees on n vertices = n^(n-2)
```

---

## 1. The core idea (beginner friendly)

Encoding rule:

1. Find the **smallest leaf** (degree 1).
2. Record its **neighbor**.
3. Remove the leaf.
4. Repeat until only two vertices remain.

That list of recorded neighbors is the Prufer code.

Decoding is the reverse: rebuild the tree from the code by tracking degrees.

---

## 2. A small tree example

Tree with 5 vertices:

```
    0 ─── 1 ─── 2
          │
          3
          │
          4
```

Edges:

```
(0,1), (1,2), (1,3), (3,4)
```

Degrees:

```
deg = [1, 3, 1, 2, 1]
```

Leaves are {0, 2, 4}. We always remove the smallest.

---

## 3. Encoding step‑by‑step

```
Step 1: smallest leaf = 0, neighbor = 1
  code = [1]
  remove 0
  degrees become: [-, 2, 1, 2, 1]

Step 2: smallest leaf = 2, neighbor = 1
  code = [1, 1]
  remove 2
  degrees become: [-, 1, -, 2, 1]

Step 3: smallest leaf = 1, neighbor = 3
  code = [1, 1, 3]
  remove 1
  degrees become: [-, -, -, 1, 1]

Stop (two vertices remain: 3 and 4)

Final Prufer code = [1, 1, 3]
```

---

## 4. Decoding step‑by‑step

Start with code `[1, 1, 3]` and `n = 5`.

Compute degrees:

```
degree[v] = 1 + count(v in code)
degree = [1, 3, 1, 2, 1]
```

Leaves are {0, 2, 4}.

Process each code value:

```
v = 1, smallest leaf = 0  -> add edge (0,1)
degrees: [0,2,1,2,1]

v = 1, smallest leaf = 2  -> add edge (2,1)
degrees: [0,1,0,2,1]

v = 3, smallest leaf = 1  -> add edge (1,3)
degrees: [0,0,0,1,1]
```

Two vertices left: 3 and 4.

```
add edge (3,4)
```

Reconstructed tree matches the original.

---

## 5. Visual summary diagram

```
Encoding:
  Tree  -> remove smallest leaf -> record neighbor -> repeat

Decoding:
  Code  -> degree counts -> connect smallest leaf to next code value
        -> repeat -> connect last two leaves
```

---

## 6. Example usage (public API)

```mbt check
///|
test "prufer example" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
  let code = @prufer_code.prufer_encode(4, edges[:]).unwrap()
  inspect(code, content="[1, 2]")
  let edges2 = @prufer_code.prufer_decode(code[:]).unwrap()
  inspect(edges2.length(), content="3")
}
```

---

## 7. Example: star tree

Star with center 0:

```
    1
    |
2 --0-- 3
    |
    4
```

The code is always:

```
[0, 0, 0]   (repeated center)
```

```mbt check
///|
test "prufer star tree" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
  let code = @prufer_code.prufer_encode(5, edges[:]).unwrap()
  inspect(code, content="[0, 0, 0]")
}
```

---

## 8. Example: path tree

Path: 0‑1‑2‑3‑4

The code is:

```
[1, 2, 3]
```

```mbt check
///|
test "prufer path tree" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
  let code = @prufer_code.prufer_encode(5, edges[:]).unwrap()
  inspect(code, content="[1, 2, 3]")
}
```

---

## 9. Why it works (intuition)

Removing the smallest leaf is deterministic.

So:

- Every tree → exactly one code.
- Decoding always rebuilds the original tree.

Therefore the mapping is a bijection.

And since there are `n^(n-2)` sequences of length `n-2`, we get Cayley’s
formula.

---

## 10. Complexity

Using a min‑heap of leaves:

```
Encoding:  O(n log n)
Decoding:  O(n log n)
Space:     O(n)
```

There are also O(n) linear variants, but the heap version is simpler.

---

## 11. Beginner checklist

1. Vertices must be labeled `0..n-1`.
2. Code length must be `n-2`.
3. Always choose the **smallest leaf** at each step.
4. After decoding, connect the **last two leaves**.

---

## 12. Summary

Prufer codes give a one‑to‑one mapping between labeled trees and sequences:

- Easy encoding via leaf removal.
- Easy decoding via degree counts.
- Key tool in combinatorics and random tree generation.
