# Gaussian Elimination

## Overview

**Gaussian Elimination** solves systems of linear equations by transforming
the augmented matrix into row echelon form. It's fundamental to linear algebra
and has applications in graphics, physics, and optimization.

- **Time**: O(n³) for n×n system
- **Space**: O(n²)

## The Problem

```
Solve the system:
  2x + y - z = 8
  -3x - y + 2z = -11
  -2x + y + 2z = -3

As matrix equation Ax = b:
┌  2  1 -1 ┐   ┌ x ┐   ┌  8  ┐
│ -3 -1  2 │ × │ y │ = │ -11 │
└ -2  1  2 ┘   └ z ┘   └ -3  ┘
```

## The Key Insight

```
Use elementary row operations to create zeros below
the diagonal, then back-substitute to find solutions.

Elementary operations (preserve solutions):
1. Swap two rows
2. Multiply a row by non-zero constant
3. Add multiple of one row to another

Goal: Transform to upper triangular form
┌ *  *  * | * ┐     ┌ *  *  * | * ┐
│ *  *  * | * │  →  │ 0  *  * | * │
└ *  *  * | * ┘     └ 0  0  * | * ┘
```

## Algorithm Walkthrough

```
Augmented matrix [A|b]:
┌  2  1 -1 |  8  ┐
│ -3 -1  2 | -11 │
└ -2  1  2 | -3  ┘

Step 1: Eliminate column 1 below pivot
  R2 = R2 + (3/2)R1
  R3 = R3 + R1

┌  2   1  -1 |  8  ┐
│  0  1/2 1/2|  1  │
└  0   2   1 |  5  ┘

Step 2: Eliminate column 2 below pivot
  R3 = R3 - 4·R2

┌  2   1  -1 |  8  ┐
│  0  1/2 1/2|  1  │
└  0   0  -1 |  1  ┘

Step 3: Back substitution
  From R3: -z = 1  →  z = -1
  From R2: y/2 + z/2 = 1  →  y = 3
  From R1: 2x + y - z = 8  →  x = 2

Solution: (x, y, z) = (2, 3, -1)
```

## Visual: Row Operations

```
Forward elimination (create zeros below diagonal):

┌ 2  1 -1 ┐     ┌ 2  1  -1 ┐     ┌ 2  1  -1 ┐
│ *  *  * │ →   │ 0  ½  ½  │ →   │ 0  ½  ½  │
└ *  *  * ┘     └ *  *   * ┘     └ 0  0  -1 ┘
    ↑               ↑                 ↑
  Col 1           Col 1             Col 2
 cleared         cleared           cleared
```

## Pivot Selection

```
Partial pivoting: Choose largest absolute value in column
as pivot to improve numerical stability.

Before elimination in column k:
1. Find row i ≥ k with maximum |a[i][k]|
2. Swap row i with row k
3. Proceed with elimination

This prevents division by very small numbers!
```

## Example Usage

```mbt nocheck
// Solve system of linear equations
let a = [
  [2.0, 1.0, -1.0],
  [-3.0, -1.0, 2.0],
  [-2.0, 1.0, 2.0],
]
let b = [8.0, -11.0, -3.0]

let solution = gauss_solve(a, b)
// solution = Some([2.0, 3.0, -1.0])
```

## Common Applications

### 1. Solving Linear Systems
```
Core application: Find x such that Ax = b.
Used everywhere from circuit analysis to curve fitting.
```

### 2. Matrix Inversion
```
Augment A with identity matrix [A|I].
Row reduce to [I|A⁻¹].
```

### 3. Computing Determinant
```
det(A) = product of diagonal elements after elimination
       × (-1)^(number of row swaps)
```

### 4. Finding Matrix Rank
```
Rank = number of non-zero rows after elimination
     = number of pivots
```

### 5. Computing Null Space
```
Row reduce, identify free variables,
express leading variables in terms of free ones.
```

## Special Cases

```
No solution (inconsistent):
┌ 1  2 | 3 ┐
└ 0  0 | 1 ┘   ← 0 = 1 impossible!

Infinite solutions (underdetermined):
┌ 1  2 | 3 ┐
└ 0  0 | 0 ┘   ← y is free variable
                x = 3 - 2y for any y

Unique solution:
┌ 1  2 | 3 ┐
└ 0  1 | 1 ┘   ← y = 1, x = 1
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| Solve n×n system | O(n³) |
| Matrix inversion | O(n³) |
| Determinant | O(n³) |
| Rank | O(n²m) for n×m |

## Gauss vs Other Methods

| Method | Time | Best For |
|--------|------|----------|
| **Gaussian** | O(n³) | General dense systems |
| LU decomposition | O(n³) | Multiple right-hand sides |
| Cholesky | O(n³/3) | Symmetric positive definite |
| Iterative | O(n² × iters) | Large sparse systems |

**Choose Gaussian Elimination when**: You need a straightforward general-purpose solver.

## Gauss-Jordan Elimination

```
Extended version: eliminate above AND below pivots
to get reduced row echelon form (RREF).

Standard:            Gauss-Jordan (RREF):
┌ *  *  * | * ┐      ┌ 1  0  0 | * ┐
│ 0  *  * | * │  →   │ 0  1  0 | * │
└ 0  0  * | * ┘      └ 0  0  1 | * ┘

RREF gives solution directly without back substitution.
Useful for matrix inversion and finding null space.
```

## Numerical Stability

```
Issues with naive implementation:
1. Division by small numbers → large errors
2. Catastrophic cancellation
3. Accumulated rounding errors

Solutions:
1. Partial pivoting (swap rows)
2. Full pivoting (swap rows AND columns)
3. Use higher precision arithmetic
4. Iterative refinement
```

## Implementation Notes

- Use partial pivoting for numerical stability
- Check for zero pivot (singular matrix)
- For exact arithmetic (integers, rationals), no pivoting needed
- Store elimination multipliers for LU decomposition
- For sparse matrices, use specialized algorithms
- Consider using existing library (BLAS/LAPACK) for production code

