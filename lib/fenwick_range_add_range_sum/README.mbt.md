# Fenwick Range Add + Range Sum

## Overview

This package supports **range add** and **range sum** on a 0‑indexed array
using two Fenwick trees. The trick converts range updates into prefix sums:

```
prefix(x) = sum(bit1, x) * x - sum(bit2, x)
```

Then `range_sum(l, r) = prefix(r) - prefix(l - 1)`.

- **Time**: O(log n) per update/query
- **Space**: O(n)

## Quick Start

```mbt check
///|
test "fenwick range add range sum example" {
  let st = @fenwick_range_add_range_sum.FenwickRangeAddRangeSum::from_array([
    1L, 2L, 3L, 4L, 5L,
  ])
  st.range_add(1, 3, 2L)
  inspect(st.range_sum(0, 4), content="21")
  inspect(st.range_sum(1, 3), content="15")
}
```

## Another Example

```mbt check
///|
test "fenwick range add point query" {
  let st = @fenwick_range_add_range_sum.FenwickRangeAddRangeSum::new(4)
  st.range_add(0, 3, 5L)
  inspect(st.range_sum(2, 2), content="5")
}
```

## Notes

- `range_add` and `range_sum` use inclusive indices.
