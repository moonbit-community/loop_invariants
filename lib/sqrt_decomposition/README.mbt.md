# Sqrt Decomposition (Range Sum + Point Update)

This package implements a simple **sqrt decomposition** structure for range
sum queries with point updates.

It splits the array into blocks of size about √n and stores block sums.

---

## 1. Big idea (beginner friendly)

Instead of scanning the whole range, we:

1. Scan the left partial block.
2. Add whole block sums in the middle.
3. Scan the right partial block.

This gives **O(√n)** time per query.

---

## 2. Small visual example

Array:

```
[1, 2, 3, 4, 5, 6, 7, 8, 9]
```

Block size = 3:

```
Block 0: [1,2,3] sum = 6
Block 1: [4,5,6] sum = 15
Block 2: [7,8,9] sum = 24
```

Query [1, 7]:

```
Left partial: indices 1..2 -> 2 + 3 = 5
Full block: block 1 -> 15
Right partial: indices 6..7 -> 7 + 8 = 15

Answer = 5 + 15 + 15 = 35
```

---

## 3. Range query logic

```
range_sum(l, r):
  sum = 0

  // left partial
  repeat until l > r or l % block_size == 0:
    sum += arr[l]
    l++

  // full blocks
  repeat until l + block_size - 1 > r:
    sum += block_sum[l / block_size]
    l += block_size

  // right partial
  repeat until l > r:
    sum += arr[l]
    l++

  return sum
```

---

## 4. Point update logic

```
update(i, new_val):
  old = arr[i]
  arr[i] = new_val
  block = i / block_size
  block_sum[block] += (new_val - old)
```

Only one block sum changes.

---

## 5. Example usage (public API)

```mbt check
///|
test "sqrt decomposition example" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let sd = @sqrt_decomposition.SqrtSum::new(arr)
  inspect(sd.query(1, 3), content="9")
  sd.update(2, 10L)
  inspect(sd.query(1, 3), content="16")
}
```

---

## 6. Why √n is optimal

If block size is B:

```
work = O(B) for partial scan + O(n/B) for full blocks
```

Minimized at B = √n.

---

## 7. Complexity

```
Build:  O(n)
Query:  O(√n)
Update: O(1)
Space:  O(n)
```

---

## 8. Beginner checklist

1. Query ranges are inclusive [l, r].
2. Choose block size around √n.
3. Only the block containing i changes on update.
4. Sqrt decomposition is best for medium‑sized data.

---

## 9. Summary

Sqrt decomposition is a simple range‑sum structure:

- fast enough (O(√n)),
- easy to implement,
- great when you want simplicity over a segment tree.
