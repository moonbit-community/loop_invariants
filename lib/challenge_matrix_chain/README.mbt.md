# Challenge: Matrix Chain Multiplication (DP)

Matrix chain multiplication asks for the **best parenthesization** of a product
of matrices. The matrices are fixed, only the order of multiplication changes.
Different orders can have wildly different costs.

This package computes the **minimum number of scalar multiplications**.
It does **not** return the actual parenthesization.

---

## Problem restatement (plain words)

You are given a sequence of matrices:

```
A0, A1, A2, ... A(n-1)
```

Matrix multiplication is associative, so you can parenthesize in different ways.
Every multiplication has a scalar cost. The goal is to minimize the total cost.

---

## Cost of multiplying two matrices

If we multiply:

```
(a x b) * (b x c)
```

then:

- the result is size `(a x c)`
- the scalar cost is `a * b * c`

This is the only cost we count.

---

## How the input is represented

Instead of listing matrices directly, we list the dimension array `dims`:

```
dims = [d0, d1, d2, ..., dn]
```

Then:

- matrix `i` has size `dims[i] x dims[i+1]`
- number of matrices = `n` = `dims.length() - 1`

Example:

```
dims = [10, 30, 5, 60]

A0: 10 x 30
A1: 30 x 5
A2: 5 x 60
```

---

## Why order matters (small example)

With `dims = [10, 30, 5, 60]`, there are two ways:

1) `(A0 A1) A2`

- A0 A1 cost = 10 * 30 * 5 = 1500
- result is 10 x 5
- (A0 A1) A2 cost = 10 * 5 * 60 = 3000
- total = 4500

2) `A0 (A1 A2)`

- A1 A2 cost = 30 * 5 * 60 = 9000
- result is 30 x 60
- A0 (A1 A2) cost = 10 * 30 * 60 = 18000
- total = 27000

Minimum is 4500.

---

## Dynamic programming idea

Define:

```
dp[i][j] = minimum cost to multiply Ai..Aj (inclusive)
```

Base case:

```
dp[i][i] = 0
```

Recurrence:

```
dp[i][j] = min over k in [i..j-1] of
  dp[i][k] + dp[k+1][j] + dims[i] * dims[k+1] * dims[j+1]
```

The last term is the cost of multiplying the two subresults.

---

## Why the recurrence makes sense

If we split between `k` and `k+1`, then:

- Left subchain: `Ai..Ak`
- Right subchain: `A(k+1)..Aj`

We pay:

1) cost to compute left
2) cost to compute right
3) cost to multiply their final results

We choose the split `k` with minimum total cost.

---

## DP order (by chain length)

We fill by increasing length:

- length = 1 (single matrix) -> cost 0
- length = 2 -> one multiplication
- length = 3 -> try all splits
- ...

Visual of dp table (upper triangle only):

```
    j=0  j=1  j=2  j=3
 i=0  0    x    x    x
 i=1       0    x    x
 i=2            0    x
 i=3                 0
```

We compute shorter ranges first so longer ranges can use them.

---

## Step-by-step table (tiny example)

Let:

```
dims = [5, 4, 6, 2]

A0: 5x4
A1: 4x6
A2: 6x2
```

Chains of length 2:

- dp[0][1] = 5 * 4 * 6 = 120
- dp[1][2] = 4 * 6 * 2 = 48

Chain of length 3:

Split at k=0:
- dp[0][0] + dp[1][2] + 5 * 4 * 2 = 0 + 48 + 40 = 88

Split at k=1:
- dp[0][1] + dp[2][2] + 5 * 6 * 2 = 120 + 0 + 60 = 180

So dp[0][2] = 88 (best parenthesization is A0 (A1 A2)).

---

## Reference implementation

```mbt
///| pub fn matrix_chain_min_cost(dims : ArrayView[Int]) -> Int { ... }
```

The implementation is in `challenge_matrix_chain.mbt` and uses the DP above.

---

## Tests and examples

### Classic three-matrix example

```mbt check
///|
test "matrix chain example" {
  let dims : Array[Int] = [10, 30, 5, 60]
  let cost = @challenge_matrix_chain.matrix_chain_min_cost(dims[:])
  inspect(cost, content="4500")
}
```

### Another standard benchmark

```mbt check
///|
test "matrix chain classic" {
  let dims : Array[Int] = [40, 20, 30, 10, 30]
  let cost = @challenge_matrix_chain.matrix_chain_min_cost(dims[:])
  inspect(cost, content="26000")
}
```

### Single matrix (no multiplication)

```mbt check
///|
test "matrix chain single" {
  let dims : Array[Int] = [7, 9]
  let cost = @challenge_matrix_chain.matrix_chain_min_cost(dims[:])
  inspect(cost, content="0")
}
```

### Two matrices (only one choice)

```mbt check
///|
test "matrix chain two" {
  let dims : Array[Int] = [5, 10, 3]
  let cost = @challenge_matrix_chain.matrix_chain_min_cost(dims[:])
  inspect(cost, content="150")
}
```

### Small mixed sizes

```mbt check
///|
test "matrix chain small" {
  let dims : Array[Int] = [5, 4, 6, 2]
  let cost = @challenge_matrix_chain.matrix_chain_min_cost(dims[:])
  inspect(cost, content="88")
}
```

---

## Complexity

- Time: `O(n^3)` (three nested loops: length, i, split)
- Space: `O(n^2)` for the dp table

---

## Takeaways

- Different parenthesizations can change cost by orders of magnitude.
- The dimension array is the key to computing multiplication cost.
- DP over chain length gives the optimal result efficiently.
