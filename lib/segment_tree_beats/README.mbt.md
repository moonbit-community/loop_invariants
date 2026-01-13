# Segment Tree Beats

## Overview

Segment tree beats is a segment tree that supports **range chmin** updates
(`a[i] = min(a[i], x)`) while answering **range maximum** and **range sum**
queries. It keeps extra metadata per node (max, second max, and count of max)
so that many updates can be applied without descending to leaves.

- **Time**: O(log n) amortized for updates, O(log n) for queries
- **Space**: O(n)

## Key Idea

For a node covering [l, r), maintain:

- `max`: largest value in the interval
- `second_max`: second largest value (< max)
- `count_max`: number of elements equal to max
- `sum`: sum of the interval

If a chmin value `x` satisfies `second_max < x < max`, then only the elements
at `max` change, so we can update the node directly without descending.

## Example

```mbt check
///|
test "segment tree beats example" {
  let st = @segment_tree_beats.SegmentTreeBeats::new([5L, 1L, 7L, 3L, 9L])
  inspect(st.range_sum(0, 5), content="25")
  inspect(st.range_max(0, 5), content="9")
  st.range_chmin(1, 4, 4L)
  inspect(st.range_sum(0, 5), content="22")
  inspect(st.range_max(0, 5), content="9")
  st.range_chmin(0, 5, 4L)
  inspect(st.range_sum(0, 5), content="16")
  inspect(st.range_max(0, 5), content="4")
}
```

## Notes

- The amortized bound comes from limiting how often a node’s max can change.
- Works well for range chmin + max/sum queries.
