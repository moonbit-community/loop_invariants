# Berlekamp–Massey Algorithm

## Overview

The **Berlekamp–Massey algorithm** finds the shortest linear recurrence relation
that generates a given sequence. This is incredibly useful for computing the
n-th term of a sequence in O(L² log n) time where L is the recurrence length.

- **Time**: O(n²) to find recurrence, O(L² log n) to compute n-th term
- **Space**: O(n)
- **Requirement**: Modulus M must be prime

## The Key Insight

```
Problem: Given sequence s[0], s[1], ..., s[n-1], find coefficients c[]
         such that: s[i] = c[0]*s[i-1] + c[1]*s[i-2] + ... + c[L-1]*s[i-L]

Why useful?
  - Fibonacci: s[i] = 1*s[i-1] + 1*s[i-2], so c = [1, 1]
  - Once we know c, we can compute s[10^18] in O(L² log n) time!

Berlekamp-Massey: Finds the SHORTEST such recurrence automatically.
```

## Understanding Linear Recurrences

```
A linear recurrence of length L:
  s[n] = c[0]*s[n-1] + c[1]*s[n-2] + ... + c[L-1]*s[n-L]

Examples:
  Fibonacci: c = [1, 1]
    s[n] = 1*s[n-1] + 1*s[n-2]

  Powers of 2: c = [2]
    s[n] = 2*s[n-1]
    1, 2, 4, 8, 16, ...

  Sum of indices: c = [2, -1]
    s[n] = 2*s[n-1] - s[n-2]
    0, 1, 2, 3, 4, ... (yes, the identity!)
```

## Algorithm Intuition

```
The algorithm processes the sequence one element at a time,
maintaining the current shortest recurrence.

For each new element s[i]:
  1. Compute what the current recurrence predicts: predicted
  2. Compute error: delta = s[i] - predicted

  If delta ≠ 0:
    The current recurrence is wrong!
    Update it using a previous "useful" recurrence.

Key insight: When we fix an error at position i,
we can use any previous error at position j < i to help.
```

## Visual: Building the Recurrence

```
Sequence: 0, 1, 1, 2, 3, 5, 8 (Fibonacci)

Step 0: s[0] = 0
  Recurrence: [] (empty)

Step 1: s[1] = 1
  Predict: 0 (no coefficients yet)
  Error: 1 - 0 = 1 ≠ 0
  Update: c = [1] (just copy previous value)

Step 2: s[2] = 1
  Predict: 1*s[1] = 1
  Error: 1 - 1 = 0 ✓
  No update needed

Step 3: s[3] = 2
  Predict: 1*s[2] = 1
  Error: 2 - 1 = 1 ≠ 0
  Update: c = [1, 1] (Fibonacci recurrence found!)

Step 4-6: Verify c = [1, 1] predicts correctly
  s[4] = 1*s[3] + 1*s[2] = 2 + 1 = 3 ✓
  s[5] = 1*s[4] + 1*s[3] = 3 + 2 = 5 ✓
  s[6] = 1*s[5] + 1*s[4] = 5 + 3 = 8 ✓

Result: c = [1, 1]
```

## How to Read the Output

If the result is `[c0, c1, ..., c_{L-1}]`, then for all `i >= L`:

```
seq[i] = c0*seq[i-1] + c1*seq[i-2] + ... + c_{L-1}*seq[i-L] (mod M)
```

## Quick Start

```mbt check
///|
test "berlekamp massey quick start" {
  let m = 1000000007L
  let seq : Array[Int64] = [0L, 1L, 1L, 2L, 3L, 5L, 8L]
  let coeffs = @berlekamp_massey.berlekamp_massey(seq, m)
  inspect(coeffs, content="[1, 1]")
}
```

## More Examples

```mbt check
///|
test "berlekamp massey geometric" {
  let m = 1000000007L
  let seq : Array[Int64] = [1L, 2L, 4L, 8L, 16L]
  let coeffs = @berlekamp_massey.berlekamp_massey(seq, m)
  inspect(coeffs, content="[2]")
}
```

```mbt check
///|
test "berlekamp massey tribonacci" {
  let m = 1000000007L
  // Tribonacci: each term = sum of previous 3
  let seq : Array[Int64] = [0L, 0L, 1L, 1L, 2L, 4L, 7L, 13L]
  let coeffs = @berlekamp_massey.berlekamp_massey(seq, m)
  inspect(coeffs, content="[1, 1, 1]")
}
```

## Common Applications

### 1. Computing n-th Term
```
Given a recurrence, compute s[10^18] in O(L² log n) time
using matrix exponentiation or polynomial multiplication.
```

### 2. Discovering Patterns
```
Given DP values for small n, find the recurrence automatically.
Then compute DP[large n] using the recurrence.
```

### 3. Sequence Verification
```
Check if a sequence follows a linear recurrence.
The length of the result tells you the recurrence order.
```

### 4. Counting Problems
```
Many counting problems have linear recurrences.
Compute a few values, find the recurrence, extrapolate.
```

## Computing n-th Term with Recurrence

```
Once you have c = [c0, c1, ..., c_{L-1}], to compute s[n]:

Method 1: Matrix Exponentiation O(L³ log n)
  [ s[n]   ]   [ c0 c1 ... c_{L-1} ]^n   [ s[L-1] ]
  [ s[n-1] ]   [ 1  0  ... 0       ]     [ s[L-2] ]
  [ ...    ] = [ 0  1  ... 0       ]   × [ ...    ]
  [ s[n-L+1]]  [ 0  0  ... 1  0    ]     [ s[0]   ]

Method 2: Kitamasa's Algorithm O(L² log n)
  Faster polynomial-based method
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| Find recurrence | O(n²) |
| Compute n-th term | O(L² log n) |
| Verify recurrence | O(n × L) |

## When It Doesn't Work

```
Berlekamp-Massey needs:
1. The sequence actually follows a linear recurrence
2. Enough terms to determine the recurrence (need 2L terms for order L)
3. Prime modulus (for modular inverse)

If your sequence doesn't follow a linear recurrence:
- Result may be very long (length ≈ n/2)
- Or the recurrence only works for the given terms
```

## Implementation Notes

- Requires a prime modulus for modular inverse
- The algorithm maintains two recurrences: current and "backup"
- When an error occurs, we combine them cleverly
- Input needs at least 2L terms to find a recurrence of length L
- Always verify the result on your sequence!

