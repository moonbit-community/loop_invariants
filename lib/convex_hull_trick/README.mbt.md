# Convex Hull Trick (Monotone)

## Overview

The **Convex Hull Trick** is a technique for optimizing dynamic programming
problems involving linear functions. This variant handles lines with monotone
slopes and monotone queries in O(1) amortized time.

- **Time**: O(1) amortized per operation
- **Space**: O(n)
- **Requirement**: Monotone slopes AND monotone queries

## The Key Insight

```
Problem: Maintain a set of lines y = mx + b, answer "max y at x" queries

Naive: Check all lines → O(n) per query

Convex Hull Trick insight:
  - For max queries, only lines on the "upper envelope" matter
  - With monotone slopes, lines form a convex hull in order
  - With monotone queries, we never need to look back!

This gives O(1) amortized per operation.
```

## Understanding the Upper Envelope

```
Lines: y = 1x + 0, y = 2x + 1, y = 3x - 1

At different x values, different lines are optimal:

y
│        ╱ y=3x-1
│       ╱
│      ╱  y=2x+1
│     ╱  ╱
│    ╱  ╱
│   ╱  ╱  y=x
│  ╱  ╱  ╱
│ ╱  ╱  ╱
│╱__╱__╱__________ x
    ^   ^
    │   │
    │   intersection points

Upper envelope: the maximum at each x
  x < 0.5: y = x is best
  0.5 ≤ x < 2: y = 2x + 1 is best
  x ≥ 2: y = 3x - 1 is best
```

## Why Monotone Slopes Help

```
With increasing slopes, lines intersect in order:

Slopes: m1 < m2 < m3

Line 1 and 2 intersect at x₁₂
Line 2 and 3 intersect at x₂₃

Because slopes are ordered: x₁₂ < x₂₃ (always!)

      ╱  Line 3 (steep)
     ╱ ╱ Line 2 (medium)
    ╱ ╱
   ╱ ╱   Line 1 (gentle)
  ╱ ╱
 ╱ ╱
╱_╱_______ x
  ^  ^
 x₁₂ x₂₃

The "best" line transitions happen in x order.
→ We can process them left to right without backtracking!
```

## Why Monotone Queries Help

```
If queries come in increasing x order:

Query 1 at x=1: Line 2 is best
Query 2 at x=3: Line 3 is best (can only move forward!)
Query 3 at x=5: Still Line 3 (never go back to Line 1 or 2)

     Best line over time:
     Line 1 ──► Line 2 ──► Line 3 ──► ...
              ^         ^
              │         │
           query at   query at
           some x     larger x

We maintain a "pointer" that only moves forward.
Total pointer movement across all queries: O(n)
→ O(1) amortized per query!
```

## Visual: The Deque Structure

```
Maintaining lines in a deque (double-ended queue):

Add line with slope m₃ > m₂ > m₁:

Before adding m₃:
  Front ──► [Line₁, Line₂] ◄── Back

Check: Does Line₂ become useless?
  If Line₃ beats Line₂ before Line₂ beats Line₁ → remove Line₂

After (Line₂ was useless):
  Front ──► [Line₁, Line₃] ◄── Back

Query at x:
  Pop from front while next line is better at x
  Return current front's value
```

## Algorithm Walkthrough

```
Add lines: (m=1, b=0), (m=2, b=1), (m=3, b=-1)

Step 1: Add (1, 0)
  Deque: [(1, 0)]

Step 2: Add (2, 1)
  Intersection of (1,0) and (2,1): x = -1
  Deque: [(1, 0), (2, 1)]

Step 3: Add (3, -1)
  Intersection of (2,1) and (3,-1): x = 2
  Is (2,1) useless? Check if (3,-1) beats (2,1) before x=-1
    (3,-1) at x=-1: y = -4
    (2,1) at x=-1: y = -1
    No, (2,1) is still useful
  Deque: [(1, 0), (2, 1), (3, -1)]

Queries (must be non-decreasing x):

Query x=0:
  Line (1,0): y = 0
  Line (2,1): y = 1  ← best
  Answer: 1

Query x=1:
  Check front: (1,0) gives y=1, (2,1) gives y=3
  Pop (1,0), use (2,1): y=3

Query x=2:
  Check front: (2,1) gives y=5, (3,-1) gives y=5
  Equal, keep (2,1) or move to (3,-1): y=5

Query x=3:
  Check front: (2,1) gives y=7, (3,-1) gives y=8
  Pop (2,1), use (3,-1): y=8
```

## When This Variant Applies

Use this monotone version when:
- Lines are inserted in **increasing slope** order
- Query `x` values are **non-decreasing**

If either order is arbitrary, use a Li Chao tree instead.

## Quick Start

```mbt check
///|
test "convex hull trick quick start" {
  let cht = @convex_hull_trick.ConvexHullTrick::new()
  cht.add_line(1L, 0L) // y = x
  cht.add_line(2L, 1L) // y = 2x + 1
  cht.add_line(3L, -1L) // y = 3x - 1
  inspect(cht.query(0L), content="1")
  inspect(cht.query(1L), content="3")
  inspect(cht.query(2L), content="5")
  inspect(cht.query(3L), content="8")
}
```

## DP Optimization Example

```
Classic problem: Minimize cost to cut a stick

dp[i] = min over j < i of { dp[j] + cost[j] * length[i] }

This has the form: dp[j] + cost[j] * x where x = length[i]

Each state j defines a line: y = cost[j] * x + dp[j]
  - Slope: cost[j]
  - Intercept: dp[j]

If costs are monotone, use Convex Hull Trick!
  - Add line for each j as we compute dp[j]
  - Query at x = length[i] to get dp[i]

Complexity: O(n²) → O(n) !
```

## Why It Works (Intuition)

Lines with increasing slopes intersect in increasing `x` order. That means the
best line for the next query never comes **before** the best line for the
previous query, so we only move the deque head forward.

## Minimum Queries

To get minimum values instead of maximum values:
- Negate each line `(m, b) -> (-m, -b)` when inserting
- Negate the query result

Or maintain "lower envelope" by flipping comparison logic.

## Complexity Analysis

| Operation | Amortized Time |
|-----------|----------------|
| Add Line | O(1) |
| Query | O(1) |
| Total for n lines, q queries | O(n + q) |

## Convex Hull Trick vs Other Approaches

| Method | Add Line | Query | Requirements |
|--------|----------|-------|--------------|
| **Monotone CHT** | O(1) | O(1) | Monotone slopes & queries |
| Li Chao Tree | O(log n) | O(log n) | Any order |
| Divide & Conquer | - | O(n log n) | Offline queries |

**Choose Monotone CHT when**: You have monotone slopes and can process queries in order.

## Implementation Notes

- Use a deque (double-ended queue) for efficient front/back operations
- Check line intersection to determine when to remove lines
- Be careful with integer overflow in intersection calculation
- Handle vertical lines (same slope) as special case

