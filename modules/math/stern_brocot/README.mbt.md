# Stern-Brocot

## Overview

The Stern-Brocot tree is an infinite binary tree whose nodes are exactly
the **positive rationals in lowest terms**, each appearing exactly once.
It supports two natural operations:

1. **Path encoding** — every positive rational `p/q` corresponds to a
   unique finite `L`/`R` walk from the root.
2. **Best rational approximation** — descending until the denominator
   would exceed a cap produces the closest fraction `p/q` with
   `q <= max_denom`.

This package implements both.

- **Time**: `O(log max(num, den))` per descent.
- **Space**: `O(1)` for `best_rational_approximation`; `O(depth)` for
  `stern_brocot_path` (length of the path).
- **Signatures**:

  ```
  best_rational_approximation(num : Int64, den : Int64, max_denom : Int64)
      -> (Int64, Int64)
  stern_brocot_path(num : Int64, den : Int64) -> Array[Char]
  ```

## Where it sits

| Operation                          | Available                              |
|------------------------------------|----------------------------------------|
| Best rational with bounded denom   | **this package**                       |
| L/R path to a rational             | **this package**                       |
| Continued-fraction expansion       | the path's run-lengths are the partials |
| `gcd(a, b)`                        | local helper                            |
| Modular sqrt                       | `@tonelli_shanks`                       |
| Lattice-sum closed form            | `@floor_sum`                            |

## Theory

### Mediants and the tree

Given two fractions `a/b` and `c/d` in lowest terms with `a*d - b*c == -1`
(the **Farey neighbour** property), their **mediant** is

```
  mediant(a/b, c/d)  =  (a+c) / (b+d)
```

Three facts make the construction work:

- The mediant is in lowest terms.
- The mediant lies strictly between the two parents: `a/b < (a+c)/(b+d) < c/d`.
- Both pairs `(a/b, mediant)` and `(mediant, c/d)` are again Farey
  neighbours, so the determinant invariant is preserved.

Starting from the **frontier** `(0/1, 1/0)` (so `a=0, b=1, c=1, d=0`, with
`0*0 - 1*1 = -1`), repeated mediant-taking enumerates every positive
rational exactly once.

### The tree's first three levels

```
                              1/1
                          /        \
                       1/2          2/1
                      /   \        /   \
                   1/3    2/3    3/2    3/1
                  /  \   /  \   /  \   /  \
                1/4 2/5 3/5 3/4 4/3 5/3 5/2 4/1
```

Each child is the mediant of its parent and one of the inherited bounds:

- `1/2 = (0+1)/(1+1)` — mediant of `0/1` and `1/1`.
- `2/3 = (1+1)/(2+1)` — mediant of `1/2` and `1/1`.
- `3/5 = (1+2)/(2+3)` — mediant of `1/2` and `2/3`.

### The L/R encoding

Encoding the path from the root: `L` when we descend into the left subtree
(target less than current mediant), `R` when we descend right (target
greater). Examples:

```
  1/2  →  L           (left child of 1/1)
  2/3  →  L R         (left, then right: 1/1 → 1/2 → 2/3)
  3/2  →  R L         (mirror across the tree's axis)
  3/5  →  L R L       (1/1 → 1/2 → 2/3 → 3/5)
```

The L/R encoding is closely related to the **continued-fraction**
expansion of `p/q`: a run of `k` consecutive identical letters
corresponds to a partial quotient of `k`. For instance `2/3 = [0; 1, 2]`
has partial quotients `1, 2`, and the path `L R` has run-lengths `1, 1`
(plus an implicit `1` for the root). The exact correspondence is
`continued_fraction(p/q) ≅ (run_lengths(path)[0]+1, run_lengths(path)[1:])`.

### Best rational approximation

To approximate `target = num/den` with denominator bounded by `max_denom`:

1. Walk the tree as usual, but stop *just before* the next mediant's
   denominator `b + d` would exceed `max_denom`.
2. At that point the answer is one of three candidates:
   - the current left bound `a/b`,
   - the current right bound `c/d`,
   - the **semiconvergent** — advancing the closer bound by the largest
     integer multiple of the farther bound that still fits within the
     cap.
3. Return whichever minimises `|target - p/q|`.

This is the classical result that the best rational approximations of any
real number under a denominator bound are exactly the convergents and
some semiconvergents of its continued-fraction expansion.

## Worked example: best approximation of `355/113` with `max_denom = 7`

`355/113 ≈ 3.1415929...` (the famous "Milü" near-π convergent). The
descent looks like this, with state `(a/b, c/d)` and mediant `p/q`:

```
Step 0:  bounds = (0/1, 1/0)    mediant = 1/1    diff = 355*1 - 113*1 = 242 > 0
                                                  step R
Step 1:  bounds = (1/1, 1/0)    mediant = 2/1    diff = 355 - 226 = 129 > 0
                                                  step R
Step 2:  bounds = (2/1, 1/0)    mediant = 3/1    diff = 355 - 339 = 16 > 0
                                                  step R
Step 3:  bounds = (3/1, 1/0)    mediant = 4/1    diff = 355 - 452 = -97 < 0
                                                  step L
Step 4:  bounds = (3/1, 4/1)    mediant = 7/2    diff = 710 - 791 = -81 < 0
                                                  step L
Step 5:  bounds = (3/1, 7/2)    mediant = 10/3   diff = 1065 - 1130 = -65 < 0
                                                  step L
Step 6:  bounds = (3/1, 10/3)   mediant = 13/4   diff = 1420 - 1469 = -49 < 0
                                                  step L
Step 7:  bounds = (3/1, 13/4)   mediant = 16/5   diff = 1775 - 1808 = -33 < 0
                                                  step L
Step 8:  bounds = (3/1, 16/5)   mediant = 19/6   diff = 2130 - 2147 = -17 < 0
                                                  step L
Step 9:  bounds = (3/1, 19/6)   mediant = 22/7   diff = 2485 - 2486 = -1 < 0
                                                  would step L, but next q = 8 > 7
                                                  STOP
```

The next mediant would be `25/8` (denominator `8 > 7`), so we halt with
bounds `(3/1, 19/6)` and last valid mediant `22/7`. Among `3/1`, `19/6`,
and the semiconvergent (which is `22/7` itself in this case), `22/7` is
closest to `355/113` and is returned.

## Reference signatures

```
pub fn best_rational_approximation(
  num : Int64,
  den : Int64,
  max_denom : Int64,
) -> (Int64, Int64)

pub fn stern_brocot_path(num : Int64, den : Int64) -> Array[Char]
```

## Tests and examples

### Exact target fits within the cap

```mbt check
///|
test "exact target within cap" {
  // 22/7 has denominator 7; with cap 7 we get it back unchanged.
  debug_inspect(
    @stern_brocot.best_rational_approximation(22L, 7L, 7L),
    content="(22, 7)",
  )
}
```

### Pi-ish approximation bounded by denominator 7

```mbt check
///|
test "best pi approximation under cap 7" {
  debug_inspect(
    @stern_brocot.best_rational_approximation(355L, 113L, 7L),
    content="(22, 7)",
  )
}
```

### A small L/R path

```mbt check
///|
test "path for 3 over 5" {
  // 1/1 -L-> 1/2 -R-> 2/3 -L-> 3/5
  debug_inspect(
    @stern_brocot.stern_brocot_path(3L, 5L),
    content="['L', 'R', 'L']",
  )
}
```

### Rounding to nearest integer with `max_denom = 1`

```mbt check
///|
test "round to nearest integer" {
  // 7/4 = 1.75 rounds to 2/1.
  debug_inspect(
    @stern_brocot.best_rational_approximation(7L, 4L, 1L),
    content="(2, 1)",
  )
}
```

## Complexity

For `stern_brocot_path(num, den)`:
- **Time**: `O(K + L)` where `K + L` is the total path length. This
  equals the sum of the partial quotients of the continued-fraction
  expansion of `num/den`, which is `O(log max(num, den))` for "typical"
  inputs and `O(max(num, den))` worst-case (e.g. an integer like `n/1`
  whose path is `R^(n-1)`).
- **Space**: `O(path length)` for the returned `Array[Char]`.

For `best_rational_approximation(num, den, max_denom)`:
- **Time**: `O(log max(num, max_denom))`. The descent halts once the
  denominator sum exceeds `max_denom`, which can take at most
  `O(log max_denom)` steps along any single side (and the semiconvergent
  finishes the work in `O(1)`).
- **Space**: `O(1)` — four `Int64` slots for the bounds.

## Common applications

- **Continued-fraction expansion**: read the path's run-lengths to get
  the partial quotients of `num/den`. The first run is the integer part.
- **Gear ratios and lattice-period synthesis**: synthesize a target
  ratio with a strict component count cap (denominator = number of teeth
  on a gear, frets on a fretboard, lattice steps in a model).
- **Rational rounding**: render a floating-point value to a "nice"
  fraction `p/q` with bounded `q`, e.g. for UI display of "1/3 cup" vs
  "0.3333".
- **Mediant-based scheduling**: the Stern-Brocot tree underlies certain
  rate-controlled schedulers (Liu-Layland-style) and fair queueing
  algorithms that need bounded-denominator rate approximations.
- **Diophantine equations**: every solution to `a*x + b*y = 1` with
  `gcd(a, b) = 1` is encoded by a Stern-Brocot path; the extended
  Euclidean algorithm and the tree walk are dual views of the same
  computation.

## Common pitfalls

- **`den` must be positive**: the tree enumerates positive rationals.
  Passing `den == 0` is treated as the right frontier `1/0` in the path
  function, and is unspecified for the approximation function. The
  approximation function handles `num == 0` and negative `num` by
  factoring out the sign first.
- **Overflow in cross products**: the descent computes
  `num * (b + d) - den * (a + c)`. As long as `num`, `den`, `b + d`, and
  `a + c` fit in `Int63`, the product stays within `Int64`. For very
  large inputs near `2^31`, consider using a wider type or comparing
  bound-by-bound rather than as a single cross product.
- **The two roots of the path**: `stern_brocot_path` returns the path
  to the *reduced* form of `num/den`. Calling it on `6/10` and `3/5`
  yields the same path.
- **Frontier inputs**: `stern_brocot_path(0L, 1L)` and
  `stern_brocot_path(1L, 0L)` return the empty array — these rationals
  are the bounds the tree starts with, not interior nodes.

## Related concepts

```
Mediant                    (a+c)/(b+d), the building block
Farey neighbour            two fractions with a*d - b*c = ±1
Stern-Brocot tree (this)   tree of all positive rationals in lowest terms
Calkin-Wilf tree           a different traversal of the same rationals
Continued fractions        partial quotients are L/R run-lengths
Convergent                 best rational with q below some convergent's q
Semiconvergent             a closer step toward the convergent under a cap
```
