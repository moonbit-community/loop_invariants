# Dynamic Programming Techniques

## Overview

**Dynamic Programming (DP)** solves problems by breaking them into overlapping
subproblems and storing solutions to avoid redundant computation.

- **Key insight**: Optimal substructure + overlapping subproblems
- **Approach**: Bottom-up (tabulation) or top-down (memoization)

## What This Package Contains

This package is a **collection of worked DP implementations**. The functions
are kept internal to emphasize learning and to avoid exposing a large public
API. Use the code as a reference or copy patterns into your own solutions.

Algorithms included (see `dp.mbt`):

- 0/1 Knapsack, Unbounded Knapsack
- LIS (binary search optimization)
- Coin Change (min coins, number of ways)
- LCS, Edit Distance
- Matrix Chain Multiplication
- Palindrome cuts and longest palindromic subsequence
- Grid path DPs (unique paths, min path sum)
- Word break, House robber, Egg drop, Kadane's DP

### Mini Example (Pseudocode)

```mbt nocheck
///|
// dp[i] = best value up to i
dp[0] = base
for i in 1..n-1 {
  dp[i] = f(dp[i-1], dp[i-2], ..., input[i])
}
```

## The DP Pattern

```
1. Define state: What does dp[i] represent?
2. Find recurrence: How does dp[i] relate to smaller subproblems?
3. Identify base cases: What are the initial values?
4. Determine order: In what order should we fill the table?
5. Optimize space: Can we reduce O(n²) to O(n)?
```

## Classic Problems

### 1. 0/1 Knapsack

Given n items with weights and values, maximize value within capacity W.

```
Items: [(weight=1, value=1), (weight=2, value=4), (weight=3, value=5)]
Capacity: 4

DP Table (rows=items, cols=capacity):
        0   1   2   3   4
item 0: 0   1   1   1   1
item 1: 0   1   4   5   5
item 2: 0   1   4   5   6  ← max value = 6 (items 1,2: w=2+3=5? No, w=1+3=4, v=1+5=6)

Recurrence: dp[i][w] = max(dp[i-1][w], dp[i-1][w-weight[i]] + value[i])
```

**Space optimization**: Process weights in reverse to use O(W) space.

### 2. Longest Increasing Subsequence (LIS)

Find the longest strictly increasing subsequence.

```
Array: [10, 9, 2, 5, 3, 7, 101, 18]

tails[i] = smallest ending element of LIS of length i+1

Process:
10 → tails = [10]
9  → tails = [9]           (9 < 10, replace)
2  → tails = [2]           (2 < 9, replace)
5  → tails = [2, 5]        (5 > 2, extend)
3  → tails = [2, 3]        (3 replaces 5)
7  → tails = [2, 3, 7]     (extend)
101→ tails = [2, 3, 7, 101] (extend)
18 → tails = [2, 3, 7, 18] (18 replaces 101)

LIS length = 4 (e.g., [2, 3, 7, 18])
```

**Key insight**: tails is always sorted, use binary search for O(n log n).

### 3. Coin Change

Find minimum coins to make amount, or count ways.

```
Coins: [1, 2, 5], Amount: 11

Minimum coins (dp[a] = min coins for amount a):
dp[0] = 0
dp[1] = 1 (1)
dp[2] = 1 (2)
dp[3] = 2 (2+1)
dp[5] = 1 (5)
dp[11] = 3 (5+5+1)

Recurrence: dp[a] = min(dp[a-coin] + 1) for all valid coins
```

### 4. Longest Common Subsequence (LCS)

Find longest subsequence common to both strings.

```
s1 = "ABCDE", s2 = "ACE"

DP Table:
      ""  A  C  E
  ""   0  0  0  0
  A    0  1  1  1
  B    0  1  1  1
  C    0  1  2  2
  D    0  1  2  2
  E    0  1  2  3  ← LCS = "ACE" (length 3)

Recurrence:
  if s1[i] == s2[j]: dp[i][j] = dp[i-1][j-1] + 1
  else: dp[i][j] = max(dp[i-1][j], dp[i][j-1])
```

### 5. Edit Distance

Minimum operations (insert, delete, replace) to transform s1 to s2.

```
s1 = "horse", s2 = "ros"

DP Table:
      ""  r  o  s
  ""   0  1  2  3
  h    1  1  2  3
  o    2  2  1  2
  r    3  2  2  2
  s    4  3  3  2
  e    5  4  4  3  ← 3 operations

Operations: horse → rorse → rose → ros
```

### 6. Matrix Chain Multiplication

Optimal parenthesization to minimize scalar multiplications.

```
Matrices: A(10×30), B(30×5), C(5×60)

Option 1: (AB)C = 10×30×5 + 10×5×60 = 1500 + 3000 = 4500 ✓
Option 2: A(BC) = 30×5×60 + 10×30×60 = 9000 + 18000 = 27000

Recurrence: dp[i][j] = min over k of (dp[i][k] + dp[k+1][j] + cost)
```

## DP Optimization Techniques

### 1. Space Optimization

Many 2D DPs only need the previous row:

```
Original:  dp[i][j] uses dp[i-1][j], dp[i-1][j-1], dp[i][j-1]
Optimized: Use two 1D arrays (prev, curr) or single array with careful ordering

Example (Knapsack):
  for each item i:
    for w = capacity down to weight[i]:  // Reverse to avoid reusing
      dp[w] = max(dp[w], dp[w-weight[i]] + value[i])
```

### 2. Convex Hull Trick

Optimize DPs of the form: `dp[i] = min(dp[j] + cost(j, i))`

When cost has special structure (linear in j), use convex hull:

```
dp[i] = min over j (m[j] * x[i] + b[j])

This is finding minimum over a set of lines!
Use convex hull to eliminate dominated lines.

Time: O(n) or O(n log n) depending on query order
```

### 3. Divide and Conquer Optimization

When optimal k for dp[i] is monotonic:

```
If opt[i] ≤ opt[i+1], we can use divide and conquer:
  solve(l, r, optL, optR):
    mid = (l + r) / 2
    find opt[mid] in [optL, optR]
    solve(l, mid-1, optL, opt[mid])
    solve(mid+1, r, opt[mid], optR)

Reduces O(n²) to O(n log n)
```

### 4. Knuth's Optimization

For optimal BST-like problems where `cost[i][j] + cost[i'][j'] ≤ cost[i][j'] + cost[i'][j]`:

```
opt[i][j-1] ≤ opt[i][j] ≤ opt[i+1][j]

Fill table in order of increasing interval length.
Each cell only checks O(1) amortized candidates.

Reduces O(n³) to O(n²)
```

## Common DP Patterns

| Pattern | Example Problems | Recurrence Style |
|---------|------------------|------------------|
| Linear DP | LIS, Max Subarray | dp[i] = f(dp[i-1], ...) |
| Interval DP | Matrix Chain, Palindrome | dp[i][j] = f(dp[i][k], dp[k][j]) |
| Knapsack | 0/1, Unbounded, Bounded | dp[i][w] = f(dp[i-1][...]) |
| String DP | LCS, Edit Distance | dp[i][j] = f(dp[i-1][...], dp[...][j-1]) |
| Grid DP | Paths, Min Sum | dp[i][j] = f(dp[i-1][j], dp[i][j-1]) |
| Tree DP | Subtree problems | dp[v] = f(dp[children]) |
| Bitmask DP | TSP, Subset | dp[mask] = f(dp[mask ^ bit]) |
| Digit DP | Count numbers | dp[pos][tight][...] |

## Complexity Summary

| Problem | Time | Space | Optimized Space |
|---------|------|-------|-----------------|
| 0/1 Knapsack | O(nW) | O(nW) | O(W) |
| LIS | O(n log n) | O(n) | O(n) |
| LCS | O(mn) | O(mn) | O(min(m,n)) |
| Edit Distance | O(mn) | O(mn) | O(min(m,n)) |
| Matrix Chain | O(n³) | O(n²) | O(n²) |
| Coin Change | O(nW) | O(W) | O(W) |

## Tips for Solving DP Problems

1. **Start with recursion**: Write naive recursive solution first
2. **Identify states**: What information do you need to solve a subproblem?
3. **Draw the DAG**: Visualize dependencies between subproblems
4. **Check overlapping**: Are subproblems computed multiple times?
5. **Optimize**: Can you reduce dimensions or use monotonicity?
