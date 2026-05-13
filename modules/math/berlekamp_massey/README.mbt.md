# Berlekamp-Massey (Find a Linear Recurrence)

Berlekamp-Massey finds the **shortest linear recurrence** that generates a
sequence, working modulo a prime number.  It is a classic tool in competitive
programming and number theory: once you have the recurrence you can predict
far-future terms in O(L^2 log n) time.

This package exports a single function:

- `@berlekamp_massey.berlekamp_massey(seq, m)` -> `Array[Int64]`

The result is a list of coefficients `[c0, c1, ..., c{L-1}]` so that:

```
s[i] = c0*s[i-1] + c1*s[i-2] + ... + c{L-1}*s[i-L]  (mod m)
```

## Problem statement

You are given the first `n` terms of a sequence (modulo a prime `m`).  You
want the *shortest* recurrence that reproduces those terms.  The recurrence
length `L` should be as small as possible.

## Why this is useful

Once you know the recurrence you can:

- Predict future terms in O(L^2 log n) with the Kitamasa / matrix method.
- Compress a sequence into a small set of coefficients.
- Detect the period structure of a sequence over a finite field.

## What the algorithm guarantees

Berlekamp-Massey processes the sequence left to right and maintains the
shortest recurrence that matches the prefix seen so far.  If the sequence
truly follows a linear recurrence, the algorithm returns the minimal one.

The modulus **must be prime**, because the algorithm requires modular inverses.

## How to read the output

If the output is `coeffs = [c0, c1, c2]`, the recurrence is:

```
s[i] = c0*s[i-1] + c1*s[i-2] + c2*s[i-3]  (mod m)
```

The length `L` equals `coeffs.length()`.  If the output is empty the sequence
is empty (input length 0).

---

## Algorithm overview

### Key data structures

The algorithm maintains two arrays, both stored as *connection polynomials*
with a leading 1 coefficient:

```
C(x) = 1 + C[1]*x + C[2]*x^2 + ... + C[L]*x^L
B(x) = (copy of C from the last length-increase step)
```

The recurrence coefficients live in positions C[1]…C[L], so the polynomial
form is just a bookkeeping convenience.

### The discrepancy

At step `i` the algorithm checks whether the current recurrence C already
predicts `s[i]`:

```
d_i = s[i] + C[1]*s[i-1] + C[2]*s[i-2] + ... + C[L]*s[i-L]  (mod m)
```

(Because C has a leading 1, d_i is zero iff C predicts s[i] correctly.)

### The update rule

When `d_i = 0` nothing changes; just advance to `i+1`.

When `d_i != 0` the current recurrence is wrong and must be corrected.
Let `last_d` be the discrepancy at the last length-increase step, and let
`m_steps` count how many steps have passed since then.  The correction is:

```
C_new(x)  =  C(x)  -  (d_i / last_d)  *  x^{m_steps}  *  B(x)
```

This is the *discrepancy update rule*: it cancels the new discrepancy while
preserving correctness for every earlier index.

If the length must grow (condition `2*L <= i`), set `B = C_old`, `L = i+1-L`,
`last_d = d_i`, and reset `m_steps = 1`.  Otherwise only C is updated.

### Diagram: state transitions

```
for i = 0 to n-1:

  compute discrepancy d_i
         |
         v
  d_i == 0 ? ----YES----> advance (m_steps++)
         |
         NO
         |
         v
  correction:
  C_new = C - (d_i/last_d)*x^{m_steps}*B
         |
         v
  2*L <= i ? --YES--> length grows:
                       B = C_old, L = i+1-L
                       last_d = d_i, m_steps = 1
         |
         NO
         v
  length unchanged, m_steps++
```

---

## Step-by-step example: sequence [1, 2, 7, 20, 61, 182]

This sequence follows `s[i] = 2*s[i-1] + 3*s[i-2]` with the first two terms
`s[0]=1, s[1]=2`.

We work modulo `m = 1000000007` (effectively exact for these small values).

**Initial state**: C = [1], B = [1], L = 0, last_d = 1, m_steps = 1.

### Step i = 0, s[0] = 1

Compute discrepancy (only j=0 contributes, C[0] = 1):

```
d = C[0] * s[0]  =  1 * 1  =  1
```

d != 0, but 2*L = 0 <= 0, so the length grows.

```
coef = d / last_d = 1/1 = 1
C_new = [1] - 1 * x^1 * [1] = [1, -1]  =>  [1, m-1]
B = [1]  (old C),  L = 0+1-0 = 1,  last_d = 1,  m_steps = 1
C = [1, m-1]
```

### Step i = 1, s[1] = 2

```
d = C[0]*s[1] + C[1]*s[0]  =  1*2 + (m-1)*1  =  2 - 1  =  1  (mod m)
```

d != 0, check 2*L = 2 <= 1?  No (2 > 1), so length stays at 1, m_steps++.

```
coef = 1/1 = 1
C_new = [1, m-1] - 1 * x^1 * [1]
      = [1, m-1] - [0, 1]
      = [1, m-2]
m_steps = 2,  L = 1
```

### Step i = 2, s[2] = 7

```
d = C[0]*s[2] + C[1]*s[1]  =  1*7 + (m-2)*2  =  7 - 4  =  3  (mod m)
```

d != 0, check 2*L = 2 <= 2?  Yes, length grows.

```
coef = 3/1 = 3
B_old = [1]   (the B still stored from step 0)
C_new = [1, m-2] - 3 * x^2 * [1]
      = [1, m-2, 0] - [0, 0, 3]
      = [1, m-2, m-3]
B = [1, m-2]  (old C),  L = 2+1-1 = 2,  last_d = 3,  m_steps = 1
```

### Step i = 3, s[3] = 20

```
d = C[0]*s[3] + C[1]*s[2] + C[2]*s[1]
  = 1*20 + (m-2)*7 + (m-3)*2
  = 20 - 14 - 6  =  0  (mod m)
```

d == 0, advance.  m_steps = 2, L = 2.

### Step i = 4, s[4] = 61

```
d = 1*61 + (m-2)*20 + (m-3)*7  =  61 - 40 - 21  =  0  (mod m)
```

d == 0, advance.  m_steps = 3, L = 2.

### Step i = 5, s[5] = 182

```
d = 1*182 + (m-2)*61 + (m-3)*20  =  182 - 122 - 60  =  0  (mod m)
```

d == 0.  Algorithm finishes with `C = [1, m-2, m-3]`, `L = 2`.

### Final output

The return value strips C[0]=1 and negates the remaining entries:

```
result[0] = -C[1] mod m = -( m-2 ) mod m = 2
result[1] = -C[2] mod m = -( m-3 ) mod m = 3
```

Output: `[2, 3]`, meaning `s[i] = 2*s[i-1] + 3*s[i-2]`.

---

## Examples

### Example 1: Fibonacci

Fibonacci satisfies `s[i] = s[i-1] + s[i-2]`.

```mbt check
///|
test "fibonacci recurrence" {
  let m = 1000000007L
  let seq : Array[Int64] = [0L, 1L, 1L, 2L, 3L, 5L, 8L]
  let coeffs = @berlekamp_massey.berlekamp_massey(seq, m)
  debug_inspect(coeffs, content="[1, 1]")
}
```

### Example 2: geometric progression

If `s[i] = 2 * s[i-1]`, the recurrence length is 1.

```mbt check
///|
test "geometric progression" {
  let m = 1000000007L
  let seq : Array[Int64] = [1L, 2L, 4L, 8L, 16L]
  let coeffs = @berlekamp_massey.berlekamp_massey(seq, m)
  debug_inspect(coeffs, content="[2]")
}
```

### Example 3: constant sequence

A constant sequence has recurrence `s[i] = s[i-1]`.

```mbt check
///|
test "constant sequence" {
  let m = 1000000007L
  let seq : Array[Int64] = [7L, 7L, 7L, 7L]
  let coeffs = @berlekamp_massey.berlekamp_massey(seq, m)
  debug_inspect(coeffs, content="[1]")
}
```

### Example 4: custom length-2 recurrence

Let the rule be `s[i] = 2*s[i-1] + 3*s[i-2]`.

```mbt check
///|
test "custom recurrence length 2" {
  let m = 1000000007L
  let seq : Array[Int64] = [1L, 2L, 7L, 20L, 61L, 182L]
  let coeffs = @berlekamp_massey.berlekamp_massey(seq, m)
  debug_inspect(coeffs, content="[2, 3]")
}
```

### Example 5: verify the recurrence on the next term

Here we recompute the next term from the coefficients and confirm that it
matches the sequence.

```mbt check
///|
test "verify next term" {
  let m = 1000000007L
  let seq : Array[Int64] = [1L, 2L, 7L, 20L, 61L]
  let coeffs = @berlekamp_massey.berlekamp_massey(seq, m)
  debug_inspect(coeffs, content="[2, 3]")
  // Predict the next term using the recurrence.
  let next = (coeffs[0] * seq[4] + coeffs[1] * seq[3]) % m
  debug_inspect(next, content="182")
}
```

---

## Discrepancy update rule (formal)

Given:

- `C(x)` — current connection polynomial of degree L
- `B(x)` — saved polynomial from the last length-increase step
- `d`     — discrepancy at position i
- `last_d` — discrepancy that triggered the last length increase
- `m_steps` — number of steps since the last length increase

The update is:

```
C_new(x)  =  C(x)  -  (d / last_d) * x^{m_steps} * B(x)
```

The factor `(d / last_d)` is computed as `d * inv_mod(last_d)  mod m`.

The shift `x^{m_steps}` aligns B so its correction lands exactly at index i.

After the update `C_new` predicts all positions 0..i correctly.  The length
can only grow when `2*L <= i`, which guarantees that the returned recurrence
is always minimal.

---

## Complexity

| Operation | Cost |
|-----------|------|
| Finding the recurrence | O(n^2) |
| Using the recurrence (Kitamasa) | O(L^2 log n) |
| Using the recurrence (matrix exp) | O(L^3 log n) |

## Practical notes and pitfalls

- **Modulus must be prime** so that modular inverses exist.
- **More data is better**: to reliably recover a recurrence of true length L,
  provide at least 2*L terms.
- **Output is modulo m**: coefficients are always in [0, m).  A "negative"
  mathematical coefficient `c` appears as `m + c`.
- **Sequence is assumed to follow a recurrence**: if it does not, the output
  only guarantees correctness for the prefix provided.

## When to use Berlekamp-Massey

Use it when:

- You suspect a sequence is linear-recurring modulo a prime.
- You want a compact description of the sequence.
- You plan to compute large-index terms efficiently (combine with `@linear_recurrence`).
