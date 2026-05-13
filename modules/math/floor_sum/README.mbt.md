# Floor Sum

## Overview

Compute the sum of floors of an arithmetic progression:

```
S(n, m, a, b) = sum_{i=0}^{n-1} floor((a*i + b) / m)
```

The key insight is that this sum **counts integer lattice points** lying
strictly below the line `y = (a*x + b) / m` over `0 <= x < n`.  A
Euclidean-style coordinate swap reduces the problem size at each step,
giving the same O(log min(a, m)) depth as the GCD algorithm.

- **Time**: O(log min(a, m))
- **Space**: O(1)
- **Signature**: `floor_sum(n, m, a, b) -> Int64`

## Lattice Point Counting Interpretation

Every term `floor((a*i + b) / m)` equals the number of positive integers `j`
satisfying `j <= (a*i + b) / m`, i.e., `m*j <= a*i + b`.  Summing over all
`i` gives the total count of lattice points `(i, j)` in the region:

```
  0 <= i < n    and    1 <= j <= floor((a*i + b) / m)
```

### Example: n=5, m=3, a=2, b=1

The line is `y = (2x + 1) / 3`.  Lattice points counted are marked with `*`:

```
  j
  3 |                   *
  2 |             *     *
  1 |       *     *     *
  0 +---+---+---+---+---+---> i
        0   1   2   3   4

  Column i=0: floor(1/3) = 0  ->  no points
  Column i=1: floor(3/3) = 1  ->  j=1
  Column i=2: floor(5/3) = 1  ->  j=1
  Column i=3: floor(7/3) = 2  ->  j=1,2
  Column i=4: floor(9/3) = 3  ->  j=1,2,3

  Total lattice points = 0 + 1 + 1 + 2 + 3 = 7
```

The sum counts the `*` marks: **S(5, 3, 2, 1) = 7**.

## The Euclidean Reduction

### Why a direct summation is too slow

A naive loop computes n terms one by one: O(n).  For n = 10^9 that is
10^9 operations.  The Euclidean approach takes only ~60 iterations.

### Three reductions that shrink the problem

Starting with `S(n, m, a, b)` (all parameters non-negative, m > 0):

**Reduction A -- strip multiples of m from the slope a:**

```
  floor((a*i + b) / m)  =  floor(a/m)*i  +  floor((a%m)*i + b) / m)
                           ^^^^^^^^^^^         ^^^^^^^^^^^^^^^^^^^
                           arithmetic sum      same form with a' = a%m < m
                           = floor(a/m) * n*(n-1)/2
```

**Reduction B -- strip multiples of m from the constant b:**

```
  floor((a*i + b) / m)  =  floor(b/m)  +  floor(a*i + b%m) / m)
                           ^^^^^^^^^^       ^^^^^^^^^^^^^^^^^^^
                           n equal terms    same form with b' = b%m < m
                           total = floor(b/m) * n
```

After A and B, both `a < m` and `b < m`.

**Reduction C -- coordinate swap (the Euclidean step):**

When `a < m`, the line has slope less than 1.  Swap the roles of `i`
and `j`: count the same lattice points by sweeping across `j` instead of `i`.

```
  Original region              After swap
  (sweep i, stack j columns)   (sweep j, stack i columns)

  j                             i
  ^  * * *                      ^  * * * * *
  |  * * * *                    |  * * * *
  |  * * * * *                  |  * * *
  +-----------> i               +-----------> j

  The set of lattice points is the same.
  The new problem is S(y_max/m, a, m, y_max%m)
  where y_max = a*n + b.

  New denominator = a  (was the slope, now < old denominator m).
  => denominator strictly decreases each full cycle of reductions.
  => terminates in O(log min(a, m)) steps.
```

### Formal recurrence

```
  S(n, m, a, b)
    where  a' = a % m,  b' = b % m,  y = a'*n + b'

  = floor(a/m)*n*(n-1)/2          -- from Reduction A
  + floor(b/m)*n                  -- from Reduction B
  + (if y < m then 0              -- base case: all floors are 0
     else  (n * floor(y/m)        -- rectangle above the diagonal
            - S(floor(y/m), a', m, y % m)))  -- recursive sub-problem
```

The recursion depth is O(log min(a, m)) because each call swaps `a'` and `m`
with `a' < m`, mirroring the Euclidean GCD argument.

## Step-by-Step Walkthrough: S(5, 3, 2, 1) = 7

```
Call: n=5  m=3  a=2  b=1  accumulated=0

--- Iteration 1 ---
  Reduction A: a=2 < m=3, skip
  Reduction B: b=1 < m=3, skip
  y_max = a*n + b = 2*5 + 1 = 11
  y_max=11 >= m=3, so apply coordinate swap:
    new_n = 11 / 3 = 3
    new_b = 11 % 3 = 2
    swap(a, m):  new_a = m = 3,  new_m = a = 2
  Continue: n=3  m=2  a=3  b=2  accumulated=0

--- Iteration 2 ---
  Reduction A: a=3 >= m=2
    q = 3/2 = 1
    accumulated += q * n*(n-1)/2 = 1 * 3*2/2 = 3  ->  accumulated=3
    a = 3 % 2 = 1
  Reduction B: b=2 >= m=2
    q = 2/2 = 1
    accumulated += q * n = 1 * 3 = 3               ->  accumulated=6
    b = 2 % 2 = 0
  y_max = a*n + b = 1*3 + 0 = 3
  y_max=3 >= m=2, so apply coordinate swap:
    new_n = 3 / 2 = 1
    new_b = 3 % 2 = 1
    swap(a, m):  new_a = 2,  new_m = 1
  Continue: n=1  m=1  a=2  b=1  accumulated=6

--- Iteration 3 ---
  Reduction A: a=2 >= m=1
    q = 2/1 = 2
    accumulated += q * n*(n-1)/2 = 2 * 0 = 0       ->  accumulated=6
    a = 2 % 1 = 0
  Reduction B: b=1 >= m=1
    q = 1/1 = 1
    accumulated += q * n = 1 * 1 = 1               ->  accumulated=7
    b = 1 % 1 = 0
  y_max = a*n + b = 0*1 + 0 = 0
  y_max=0 < m=1, break.

Result: 7
```

## Step-by-Step Walkthrough: S(5, 4, 6, 7) = 21

This example triggers both Reductions A and B in the very first iteration.

```
Call: n=5  m=4  a=6  b=7  accumulated=0

--- Iteration 1 ---
  Reduction A: a=6 >= m=4
    q = 6/4 = 1
    accumulated += 1 * 5*4/2 = 10                  ->  accumulated=10
    a = 6 % 4 = 2
  Reduction B: b=7 >= m=4
    q = 7/4 = 1
    accumulated += 1 * 5 = 5                        ->  accumulated=15
    b = 7 % 4 = 3
  y_max = a*n + b = 2*5 + 3 = 13
  y_max=13 >= m=4, coordinate swap:
    new_n = 13 / 4 = 3
    new_b = 13 % 4 = 1
    swap(a, m):  new_a = 4,  new_m = 2
  Continue: n=3  m=2  a=4  b=1  accumulated=15

--- Iteration 2 ---
  Reduction A: a=4 >= m=2
    q = 4/2 = 2
    accumulated += 2 * 3*2/2 = 6                   ->  accumulated=21
    a = 4 % 2 = 0
  Reduction B: b=1 < m=2, skip
  y_max = a*n + b = 0*3 + 1 = 1
  y_max=1 < m=2, break.

Result: 21
```

## Example Usage

```mbt check
///|
test "floor sum quick start" {
  debug_inspect(@floor_sum.floor_sum(4L, 5L, 3L, 2L), content="4")
  debug_inspect(@floor_sum.floor_sum(5L, 4L, 2L, 1L), content="4")
  debug_inspect(@floor_sum.floor_sum(5L, 3L, 2L, 1L), content="7")
}
```

```mbt check
///|
test "floor sum with reductions" {
  debug_inspect(@floor_sum.floor_sum(5L, 4L, 6L, 7L), content="21")
}
```

## Edge Cases

```
n = 0                -> S = 0   (empty sum)
m = 0                -> S = 0   (guard; division by zero would occur)
a = 0, b = 0         -> S = 0   (all terms floor(0) = 0)
a = 0, b < m         -> S = 0   (all floors are 0)
a = 0, b >= m        -> S = n * floor(b/m)
b = 0, a < m, a*n < m -> S = 0  (line never reaches y=1 over [0,n))
```

## Complexity Analysis

| Metric     | Value                  | Notes                              |
|------------|------------------------|------------------------------------|
| Time       | O(log min(a, m))       | Same recurrence as Euclidean GCD   |
| Space      | O(1)                   | Single iterative loop, no stack    |
| Iterations | at most ~2 log_phi(m)  | phi = golden ratio ~1.618          |

Each full cycle of Reductions A, B, C reduces the denominator from `m` to
`a % m` (just like one GCD step), so the number of cycles is bounded by the
number of steps in `gcd(a, m)`.

For comparison:

```
Direct O(n) loop for n=10^9, m=10^9:
  ~10^9 operations (too slow)

Floor sum for n=10^9, m=10^9:
  ~60 iterations (log scale)

Speedup: ~10^7x
```

## Common Applications

### Lattice point counting

Count integer points `(x, y)` satisfying `0 <= x < n`, `0 < y`,
`a*x - m*y + b >= 0` (points on or below a line with rational slope).
Used in computational geometry and Pick's theorem computations.

### Number theory

Evaluate sums of the form `sum floor(k*alpha)` for rational `alpha`.
These appear in the study of Beatty sequences, Dedekind sums, and
continued-fraction expansions.

### Competitive programming

The function appears as-is in the AtCoder Library (ACL) under `floor_sum`.
Common use: count pairs `(x, y)` with `x*a + y*b = c` and `0 <= x`, `0 <= y`.

### Algorithm analysis

Analyse algorithms whose inner loop runs `floor((a*i + b) / m)` times for
each outer index `i`; the total iteration count is exactly this floor sum.

## Common Pitfalls

- **Parameter order**: the API is `floor_sum(n, m, a, b)`, not `(n, a, b, m)`.
- **Non-negative inputs**: this implementation requires `a >= 0` and `b >= 0`.
  Negative slope or offset require a separate signed variant.
- **Overflow**: intermediate products like `a * n` can reach `m * n`; use
  64-bit integers (`Int64`) when `n`, `a`, `m` are large.
- **n = 0 or m = 0**: the function returns 0 for these; callers do not need
  to guard against them separately.

## Related Concepts

```
floor_sum(n, m, a, b)     -- this function
ceil_sum(n, m, a, b)      -- use floor_sum(n, m, a, b + m - 1)
Dedekind sum s(a, m)      -- related floor sum with reciprocal structure
Beatty sequence           -- floor(n*alpha) for irrational alpha
Pick's theorem            -- lattice points inside a polygon
Farey sequence            -- fractions with bounded denominators
Euclidean GCD             -- same O(log) argument drives the complexity
```
