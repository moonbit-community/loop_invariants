# Linear Recurrence (Kitamasa Method)

## What It Solves

Given a linear recurrence of order `k`:

```
f(n) = c0*f(n-1) + c1*f(n-2) + ... + c_{k-1}*f(n-k)
```

this module computes **f(n) mod M** in **O(k^2 log n)** time.

It is faster than matrix exponentiation if you only need **one term**.

## Big Picture

Matrix exponentiation treats the recurrence as a k×k matrix:

```
[f(n)    ]   [c0 c1 ... c_{k-1}]^n   [f(k-1)]
[f(n-1)  ] = [1  0  ...    0   ]   · [f(k-2)]
[  ...   ]   [0  1  ...    0   ]     [  ...  ]
[f(n-k+1)]   [0  0  ...    1   ]     [f(0)  ]
```

That is **O(k^3 log n)**.

**Kitamasa** skips the matrix and directly computes coefficients that express
`f(n)` as a linear combination of the initial terms.

## Key Insight

There exists a vector `A` such that:

```
f(n) = A0*f(0) + A1*f(1) + ... + A_{k-1}*f(k-1)
```

Kitamasa computes these coefficients by doing polynomial exponentiation and
reducing modulo the **characteristic polynomial**:

```
P(x) = x^k - c0*x^{k-1} - c1*x^{k-2} - ... - c_{k-1}
```

## Fibonacci Example (k=2)

```
f(n) = f(n-1) + f(n-2)
coeffs = [1, 1]
initial = [f(0)=0, f(1)=1]
```

We want coefficients `[a0, a1]` such that:

```
f(n) = a0*f(0) + a1*f(1)
```

For small n:

```
f(0) => [1, 0]
f(1) => [0, 1]
f(2) => [1, 1]
f(3) => [1, 2]
f(4) => [2, 3]
```

## Visual: Coefficient Growth

```
Fibonacci coefficient vectors (a0, a1):

n=0: (1, 0)
n=1: (0, 1)
n=2: (1, 1)
n=3: (1, 2)
n=4: (2, 3)
n=5: (3, 5)

These are exactly Fibonacci pairs.
```

## Algorithm Outline (Binary Exponentiation on Polynomials)

We treat `x^n mod P(x)` as a coefficient vector of length k.

```
res  = representation of x^0
base = representation of x^1

while n > 0:
  if n is odd: res = combine(res, base)
  base = combine(base, base)
  n >>= 1

answer = sum(res[i] * initial[i])
```

`combine` multiplies two coefficient vectors and reduces them modulo `P(x)`.

## Worked Example: Fibonacci f(7)

Binary: `7 = 111₂`

```
start: res = x^0, base = x^1

bit1:
  res = res * base   => x^1
  base = base^2      => x^2 = x + 1

bit2:
  res = x^1 * x^2    => x^3 = 2x + 1
  base = (x^2)^2     => x^4 = 3x + 2

bit3:
  res = (2x+1)*(3x+2) => x^7 = 13x + 8

f(7) = 8*f(0) + 13*f(1) = 13
```

## Example Usage

```mbt check
///|
test "linear recurrence fibonacci" {
  let m = 1000000007L
  let coeffs : Array[Int64] = [1L, 1L]
  let initial : Array[Int64] = [0L, 1L]
  inspect(
    @linear_recurrence.linear_recurrence_nth(coeffs, initial, 7L, m),
    content="13",
  )
}
```

```mbt check
///|
test "linear recurrence geometric" {
  let m = 1000000007L
  let coeffs : Array[Int64] = [2L] // f(n) = 2*f(n-1)
  let initial : Array[Int64] = [1L]
  inspect(
    @linear_recurrence.linear_recurrence_nth(coeffs, initial, 5L, m),
    content="32",
  )
}
```

```mbt check
///|
test "tribonacci" {
  let m = 1000000007L
  let coeffs : Array[Int64] = [1L, 1L, 1L]
  let initial : Array[Int64] = [0L, 0L, 1L]
  inspect(
    @linear_recurrence.linear_recurrence_nth(coeffs, initial, 7L, m),
    content="13",
  )
}
```

## Complexity

| Method | Time | Space |
|--------|------|-------|
| Naive iteration | O(n) | O(k) |
| Matrix exponentiation | O(k^3 log n) | O(k^2) |
| **Kitamasa** | **O(k^2 log n)** | **O(k)** |

## Common Pitfalls

- `coeffs` and `initial` must have the same length `k`.
- Use a modulus `m` to prevent overflow.
- This method returns **only** f(n), not the full state vector.

## When to Use Kitamasa

- You need a **single term** of a large‑index recurrence.
- The order `k` is large (saves a factor of `k`).
- You are working modulo a number.

## Implementation Notes (This Package)

- Uses polynomial multiplication + reduction (`combine`).
- Binary exponentiation drives the doubling.
- Handles k=1 as a fast power special case.
