# Segment Tree Beats

## Overview

**Segment Tree Beats** is an advanced segment tree that supports range "clamp"
operations (like range chmin: set each a[i] = min(a[i], x)) while maintaining
aggregate queries like range sum. It achieves amortized O(log n) per operation.

- **Time**: O(log n) amortized for updates, O(log n) for queries
- **Space**: O(n)
- **Key Feature**: Range chmin/chmax with range sum queries

## The Key Insight

```
Problem: Support these operations efficiently:
  1. range_chmin(l, r, x): For i in [l,r), set a[i] = min(a[i], x)
  2. range_sum(l, r): Return sum of a[l..r)
  3. range_max(l, r): Return max of a[l..r)

Challenge: After chmin, some elements change, some don't.
           How do we update the sum without visiting every element?

Segment Tree Beats insight:
  Track max, second_max, and count_of_max in each node.
  If second_max < x < max, only max elements change!
  We can update the node directly: sum -= count_max * (max - x)
```

## Understanding the Node Structure

```
For a segment [l, r), maintain:

  max        = largest value in segment
  second_max = second largest (strictly less than max)
  count_max  = how many elements equal max
  sum        = sum of all elements

Example segment: [5, 3, 5, 2, 5]
  max = 5
  second_max = 3
  count_max = 3 (three 5's)
  sum = 20
```

## Visual: How chmin Works

```
Segment: [5, 3, 5, 2, 5]  (max=5, second_max=3, count_max=3, sum=20)

Case 1: chmin(x=6) where x >= max
  Nothing changes (all elements already ≤ 6)
  Result: [5, 3, 5, 2, 5] unchanged

Case 2: chmin(x=4) where second_max < x < max
  Only the max elements (5's) change to 4
  New segment: [4, 3, 4, 2, 4]
  Update: sum = 20 - 3*(5-4) = 17
  New max = 4, second_max = 3, count_max = 3

Case 3: chmin(x=2) where x <= second_max
  Need to recurse to children (can't update directly)
  Some 3's might change, some might not
  Must visit child nodes to determine effect
```

## Algorithm Walkthrough

```
Array: [5, 1, 7, 3, 9]

Build tree (showing [l,r) with max/second_max/count_max/sum):

                [0,5): max=9, 2nd=7, cnt=1, sum=25
               /                              \
      [0,3): max=7, 2nd=5, cnt=1, sum=13    [3,5): max=9, 2nd=3, cnt=1, sum=12
      /              \                       /              \
[0,2):max=5,2nd=1  [2,3):max=7         [3,4):max=3    [4,5):max=9
sum=6,cnt=1        sum=7,cnt=1          sum=3,cnt=1   sum=9,cnt=1

Operation: range_chmin(1, 4, 4)
  Apply chmin(4) to positions [1, 4)

At [0,5): x=4 < second_max=7? No, 4 < 9 but we check second_max=7.
          4 < 7? Yes, need to recurse.

At [0,3): x=4 < max=7? Yes. second_max=5, and 5 < 4? No.
          So 4 ≤ second_max=5, must recurse.

At [2,3): x=4 < max=7? Yes, second_max=-∞ (leaf), cnt=1
          Update: 7 → 4, sum = 7 - 1*(7-4) = 4

At [0,2): x=4 < max=5? Yes, second_max=1, and 1 < 4 < 5? Yes!
          Update directly: max = 4, sum = 6 - 1*(5-4) = 5

At [3,5): x=4 < max=9? Yes, second_max=3, and 3 < 4 < 9? Yes!
          Only need to update position 4 (has value 9)
          Recurse to [4,5)...

After operation: range_sum(0, 5) = 22 (was 25, reduced by 3)
```

## Why Amortized O(log n)?

```
Key insight: The potential function argument

Define potential Φ = Σ (number of distinct values in each node)

When we do a "break" (must recurse because x ≤ second_max):
  - We spend O(log n) work
  - But we also REDUCE the number of distinct values somewhere
  - This "pays" for the extra work

Over a sequence of operations:
  - Total "tag" operations (x > second_max): O(Q log n)
  - Total "break" operations: bounded by potential, which is O(n log n)
  - Overall: O((n + Q) log n) amortized
```

## Example Usage

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

## More Examples

```mbt check
///|
test "segment tree beats range operations" {
  let st = @segment_tree_beats.SegmentTreeBeats::new([10L, 20L, 30L, 40L, 50L])

  // Initial state
  inspect(st.range_sum(0, 5), content="150")
  inspect(st.range_max(0, 5), content="50")

  // Clamp all values to at most 25
  st.range_chmin(0, 5, 25L)
  // 10, 20, 25, 25, 25 → sum = 105
  inspect(st.range_sum(0, 5), content="105")
  inspect(st.range_max(0, 5), content="25")
}
```

## Common Applications

### 1. Range Capping
```
Given an array, repeatedly cap ranges to a maximum value
while querying sums. Classic segment tree beats use case.
```

### 2. Stock Price Limits
```
Simulate price limits: prices can't exceed a cap.
Track total value after applying caps.
```

### 3. Resource Allocation
```
Allocate resources with per-item limits.
Query total allocation after applying limits.
```

### 4. Image Processing
```
Clamp pixel values to a maximum (brightness limiting).
Query statistics on the result.
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| Build | O(n) |
| range_chmin | O(log n) amortized |
| range_sum | O(log n) |
| range_max | O(log n) |

## Segment Tree Beats vs Other Approaches

| Method | range_chmin | range_sum | Use Case |
|--------|-------------|-----------|----------|
| **Seg Tree Beats** | O(log n) amort | O(log n) | chmin + sum |
| Lazy Seg Tree | O(n) worst | O(log n) | Only if chmin is rare |
| Square Root | O(√n) | O(√n) | Simpler implementation |

**Choose Segment Tree Beats when**: You need both range chmin/chmax AND range sum.

## Extensions

```
Segment Tree Beats can be extended to support:
- range_chmax: a[i] = max(a[i], x)
- range_add: a[i] += x (combined with chmin/chmax)
- range_assign: a[i] = x

The key is maintaining enough metadata to handle
lazy propagation correctly.
```

## Implementation Notes

- The amortized bound comes from limiting how often a node's max can change
- Works well for range chmin + max/sum queries
- Need to track: max, second_max, count_max, sum
- Lazy propagation is more complex than standard segment tree
- Handle edge cases: empty ranges, single elements

