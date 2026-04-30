# Challenge: Line Sweep (Max Overlap)

Line sweep turns a messy overlap problem into a sorted list of small, local
updates. We "sweep" from left to right and track how many intervals are
currently active, then keep the maximum.

This tutorial assumes **inclusive** integer intervals `(l, r)` where
`l <= r` means the interval covers every integer position from `l` to `r`.
If `l > r`, this implementation skips the interval (treats it as empty).

---

## Problem restatement (plain words)

You are given a list of segments on a number line. Each segment covers a range
of integer positions. At any position, several segments might overlap. Find the
**largest** number of segments covering the same position.

Think of it like scheduling: how many meetings happen at the same time, and
what is the peak count?

---

## Core idea: convert ranges into events

Instead of reasoning about whole ranges, we create **events**:

- At `l`, the interval starts: `+1`
- At `r + 1`, the interval ends: `-1`

That `r + 1` is the key. It turns inclusive ranges into half-open ranges:

```
[l, r]  becomes  [l, r + 1)
```

So the interval counts for every position `p` with `l <= p <= r`, and stops
being counted exactly at `r + 1`.

After we build all events, we:

1) Sort by position.
2) Sweep left to right, updating a running `active` count.
3) Track the maximum `active` value seen.

---

## Why `r + 1` avoids tie headaches

If you put an end event at `r` instead of `r + 1`, you must decide whether
starts at the same position are processed before or after ends. That choice
changes the overlap count.

Using `r + 1` is cleaner: starts at `l` and ends at `r + 1` never represent the
same position, so the tie case is mostly gone. The only remaining tie is when
one interval ends at `r + 1` and another starts at that same point. At that
position, the new interval **should** count and the old one **should not**.
We solve this by sorting events at the same position with `-1` first, then `+1`.
That guarantees we never briefly count both.

---

## Walkthrough example

Intervals:

- A = (1, 3)
- B = (2, 5)
- C = (4, 6)

ASCII picture of coverage:

```
position: 1 2 3 4 5 6
A:        [1---3]
B:          [2-----5]
C:              [4---6]
```

Events (using `r + 1`):

- A: (1, +1), (4, -1)
- B: (2, +1), (6, -1)
- C: (4, +1), (7, -1)

Sorted and swept:

```
pos  delta(s)  active
1    +1        1
2    +1        2
4    -1,+1     2   (A ended at 3, C starts at 4)
6    -1        1
7    -1        0
```

Maximum active = 2.

---

## Another visual: touching intervals

Intervals:

- A = (1, 1)
- B = (2, 2)

They do not overlap (A ends at 1, B starts at 2):

```
position: 1 2
A:        [1]
B:          [2]
```

Events:

- A: (1, +1), (2, -1)
- B: (2, +1), (3, -1)

At position 2 we have both `-1` and `+1`. We sort `-1` first, so the count
never spikes to 2. The maximum is 1, which is correct.

---

## Implementation details (what the code does)

1) Build an `events` array with `(pos, delta)` pairs.
2) Sort by `(pos, delta)` so that `-1` comes before `+1` at the same position.
3) Sweep, update `active`, update `best`.

Time complexity is `O(n log n)` because of sorting. Memory is `O(n)` for the
event list.

---

## Reference implementation

```mbt nocheck
///| priv struct Event { pos : Int, delta : Int }

///| pub fn max_overlap(intervals : ArrayView[(Int, Int)]) -> Int { ... }
```

The actual implementation is in `challenge_line_sweep.mbt`.

---

## Tests and examples

### Basic overlap

```mbt check
///|
test "line sweep basic" {
  let intervals : Array[(Int, Int)] = [(1, 3), (2, 5), (4, 6)]
  let best = @challenge_line_sweep.max_overlap(intervals)
  inspect(best, content="2")
}
```

### Heavy overlap at a single point

```mbt check
///|
test "line sweep heavy overlap" {
  let intervals : Array[(Int, Int)] = [(2, 2), (2, 4), (2, 5)]
  let best = @challenge_line_sweep.max_overlap(intervals)
  inspect(best, content="3")
}
```

### Disjoint intervals

```mbt check
///|
test "line sweep disjoint" {
  let intervals : Array[(Int, Int)] = [(1, 2), (4, 5), (7, 9)]
  let best = @challenge_line_sweep.max_overlap(intervals)
  inspect(best, content="1")
}
```

### Touching but not overlapping

```mbt check
///|
test "line sweep touching" {
  let intervals : Array[(Int, Int)] = [(1, 1), (2, 2), (3, 3)]
  let best = @challenge_line_sweep.max_overlap(intervals)
  inspect(best, content="1")
}
```

### Negative coordinates and mixed ranges

```mbt check
///|
test "line sweep negatives" {
  let intervals : Array[(Int, Int)] = [(-3, -1), (-2, 1), (0, 2)]
  let best = @challenge_line_sweep.max_overlap(intervals)
  inspect(best, content="2")
}
```

### Intervals with l > r are ignored

```mbt check
///|
test "line sweep skip invalid" {
  let intervals : Array[(Int, Int)] = [(5, 3), (1, 2), (2, 2)]
  let best = @challenge_line_sweep.max_overlap(intervals)
  inspect(best, content="2")
}
```

---

## Takeaways

- Convert range problems into **event problems**.
- Sorting by position turns global overlap into a local running count.
- Using `r + 1` makes inclusive ranges easy and eliminates confusing tie logic.
- With a tiny tie-breaker (`-1` before `+1`), the sweep stays correct even when
  events share the same position.
