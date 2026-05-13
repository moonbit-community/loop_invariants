# Cycle Detection

## Overview

Given a deterministic function `f : T -> T` and a starting value `x0`,
the orbit

```
  x_0, x_1, x_2, ...     where   x_{i+1} = f(x_i)
```

eventually enters a cycle (whenever the reachable set from `x0` is
finite -- by pigeonhole). The shape of the orbit is described by two
numbers:

- `mu`  -- the *tail length*: the index of the first value belonging
            to the cycle.
- `lam` -- the *cycle length* (period): the smallest positive integer
            with `f^lam(x_mu) == x_mu`.

```
  x_0 -> x_1 -> ... -> x_{mu-1} -> x_mu -> x_{mu+1} -> ... -> x_{mu+lam-1}
                                     ^                              |
                                     |______________________________|
                                            lam steps (the cycle)
```

This package gives two **O(1)-space** algorithms for computing
`(mu, lam)`:

| Function       | Time         | Space  | Signature                                             |
|----------------|--------------|--------|-------------------------------------------------------|
| `floyd_cycle`  | O(mu + lam)  | O(1)   | `floyd_cycle[T : Eq](f : (T) -> T, x0 : T) -> (Int, Int)` |
| `brent_cycle`  | O(mu + lam)  | O(1)   | `brent_cycle[T : Eq](f : (T) -> T, x0 : T) -> (Int, Int)` |

Both return the pair `(mu, lam)`. They differ only in how many times
`f` is invoked per iteration -- see the side-by-side comparison below.

Note: there is a separate Floyd implementation for **linked lists**
in `modules/techniques/techniques/advanced.mbt`. That one chases
`next` pointers; the package here works on **values produced by
iterating a function**, which subsumes the linked-list case (treat
`f(node) = node.next`) but is more useful in practice for Pollard
rho, RNG analysis, hash chains, and so on.

---

## 1. Floyd's tortoise-and-hare

Floyd's algorithm runs in three phases. Let `f^k` denote `k`-fold
iteration of `f`.

### Phase 1 -- find a meeting point

Initialise `tortoise = f(x0)` and `hare = f(f(x0))`, then step

```
  tortoise := f(tortoise)
  hare     := f(f(hare))
```

until `tortoise == hare`. Both are guaranteed to coincide somewhere
inside the cycle.

```
INVARIANT (Phase 1, parameterised by a counter t >= 1):
  tortoise == f^t(x0)
  hare     == f^(2t)(x0)

TERMINATION:
  Once `t >= mu`, both pointers are in the cycle. The hare gains one
  step on the tortoise per iteration (modulo `lam`), so they meet
  within `lam` more iterations.
```

### Phase 2 -- find `mu`

Reset the tortoise to `x0`, leave the hare at the meeting point, and
step both by one until they coincide. The number of steps taken is
`mu`; the coincidence point is `x_mu`, the **cycle entrance**.

```
INVARIANT (Phase 2):
  tortoise == f^steps(x0)
  hare     == f^(steps + meet_distance)(x0)
  where meet_distance == t from Phase 1, a multiple of lam.

CORRECTNESS:
  For `steps < mu` the tortoise is in the tail, which is disjoint from
  the cycle, so the two cannot coincide. At `steps == mu` the tortoise
  enters the cycle and the hare -- a whole number of periods ahead --
  is at the same point.
```

### Phase 3 -- find `lam`

Hold one pointer at the entrance; step the other by one until it
returns. The step count is `lam`.

```
INVARIANT (Phase 3):
  cur == f^n(entrance), and entrance is x_mu (a cycle value).

TERMINATION:
  The orbit from `entrance` is a pure cycle (no tail), so it returns
  to `entrance` after exactly `lam` steps.
```

---

## 2. Brent's variant

Brent's improvement keeps the tortoise **stationary** and lets the
hare walk forward by one step at a time. Each round, the hare gets a
fresh "window" of size `power`; if it doesn't meet the tortoise
within the window, the tortoise jumps to the hare's position and the
window doubles. The first time `tortoise == hare`, the distance the
hare has walked since the last reset is the cycle length.

```
INVARIANT (Brent phase 1):
  Let start_of_window be the orbit index of tortoise. Then
     tortoise == f^start_of_window(x0)
     hare     == f^(start_of_window + lam)(x0)
     1 <= lam <= power
```

After phase 1 you know `lam` but not `mu`. To recover `mu`, walk a
fresh hare `lam` steps ahead of `x0`, then advance both pointers in
lockstep until they meet -- exactly as in Floyd's phase 2.

### Why Brent uses fewer calls to `f`

Floyd's hare advances by `f(f(...))` -- two calls per iteration.
Brent's hare advances by `f(...)` -- one call per iteration. Both
methods visit roughly the same number of "logical" hare positions,
so Brent saves the doubled `f` step. On most inputs Brent calls `f`
about **25-30% fewer times** than Floyd. The trade-off is the small
amount of bookkeeping for the window-doubling logic.

---

## 3. Worked example

Take `f(x) = (x*x + 1) mod 5`. The function table is

| x     | 0 | 1 | 2 | 3 | 4 |
| ----- | - | - | - | - | - |
| f(x)  | 1 | 2 | 0 | 0 | 2 |

Starting at `x0 = 3`, the orbit is

```
  x_0 = 3
  x_1 = f(3) = 0
  x_2 = f(0) = 1
  x_3 = f(1) = 2
  x_4 = f(2) = 0   <-- same as x_1
  x_5 = f(0) = 1
  x_6 = 2
  ...
```

so `mu = 1` (the cycle is entered at index 1) and `lam = 3`
(the cycle is `0 -> 1 -> 2 -> 0`).

**Floyd's trace from `x0 = 3`:**

```
Phase 1:
  step  tortoise (= f^t(3))   hare (= f^{2t}(3))
   1    0                     1
   2    1                     0
   3    2                     2   <-- meet at value 2

Phase 2 (reset tortoise to 3):
  step  tortoise              hare
   0    3                     2
   1    0                     0   <-- meet at value 0 (the entrance, x_1).
                                       mu = 1.

Phase 3 (cycle from entrance 0):
  step  cur
   1    1
   2    2
   3    0   <-- back to entrance. lam = 3.
```

Result: `(mu, lam) = (1, 3)`.

**Brent's trace from `x0 = 3`:**

```
Phase 1 (doubling search):
  tortoise hare  power lam   action
  3        0     1     1     reset: tortoise := 0, power := 2, lam := 1
  0        1     2     1     advance: hare := 2, lam := 2
  0        2     2     2     reset: tortoise := 2, power := 4, lam := 1
  2        0     4     1     advance: hare := 1, lam := 2
  2        1     4     2     advance: hare := 2, lam := 3
  2        2     4     3     MEET. lam = 3.

Phase 2 (find mu):
  Pre-walk hare from x0 by lam=3 steps: 3 -> 0 -> 1 -> 2.
  step  tortoise  hare
   0    3         2
   1    0         0   <-- meet. mu = 1.
```

Result: `(mu, lam) = (1, 3)`.

---

## 4. Reference signatures

```
pub fn[T : Eq] floyd_cycle(f : (T) -> T, x0 : T) -> (Int, Int)
pub fn[T : Eq] brent_cycle(f : (T) -> T, x0 : T) -> (Int, Int)
```

Both return `(mu, lam)` with `mu >= 0` and `lam >= 1`.

---

## 5. Tests and examples

### Quadratic-mod-prime orbit

```mbt check
///|
test "cycle quadratic mod 5 from x0 = 3" {
  // x_0=3, x_1=0, x_2=1, x_3=2, x_4=0, ...  mu=1, lam=3.
  let f = fn(x : Int) { (x * x + 1) % 5 }
  debug_inspect(@cycle_detection.floyd_cycle(f, 3), content="(1, 3)")
  debug_inspect(@cycle_detection.brent_cycle(f, 3), content="(1, 3)")
}
```

### Pure cycle (no tail)

```mbt check
///|
test "cycle pure ring of length 4" {
  // f(x) = (x + 1) mod 4 is a single 4-cycle: 0 -> 1 -> 2 -> 3 -> 0.
  let f = fn(x : Int) { (x + 1) % 4 }
  debug_inspect(@cycle_detection.floyd_cycle(f, 0), content="(0, 4)")
}
```

### Fixed point

```mbt check
///|
test "cycle fixed point" {
  // f(x) = x.  Every value is its own fixed point: mu=0, lam=1.
  let f = fn(x : Int) { x }
  debug_inspect(@cycle_detection.brent_cycle(f, 42), content="(0, 1)")
}
```

### Long tail, short cycle

```mbt check
///|
test "cycle long tail short cycle" {
  // Tail of length 100 followed by a self-loop at 100.
  let f = fn(x : Int) { if x < 100 { x + 1 } else { 100 } }
  debug_inspect(@cycle_detection.floyd_cycle(f, 0), content="(100, 1)")
  debug_inspect(@cycle_detection.brent_cycle(f, 0), content="(100, 1)")
}
```

---

## 6. Applications

- **Pollard rho factoring.** The integer factoriser in `@pollard_rho`
  iterates `f(x) = (x^2 + c) mod n` and detects a non-trivial
  collision by GCD probing; Floyd's tortoise-and-hare is the
  standard scheduler, and Brent's variant is what Pollard himself
  recommended for the speedup on `f`.
- **Pollard rho discrete log.** The same technique (with a more
  intricate `f`) solves the discrete-log problem in groups where
  squaring is cheap but inversion is not.
- **RNG period detection.** Linear congruential generators and other
  deterministic PRNGs eventually cycle. Cycle detection on the state
  sequence reveals the period, which is a key quality metric.
- **Hash-chain analysis.** Iterating a one-way hash `h` on a seed
  eventually cycles; the cycle length sets a security floor for
  hash-chain-based time-memory tradeoffs (rainbow tables).
- **Self-referential function reachability.** Static analysis of
  callbacks or iterated state machines often boils down to detecting
  whether `f` reaches a cycle from a given seed.

---

## 7. Common pitfalls

- **Non-deterministic `f`.** Both algorithms assume `f` is a pure
  function. If `f` reads mutable state (a counter, the system clock,
  random number generator), the "tortoise" and "hare" walk different
  orbits and the math breaks down.
- **No cycle at all.** If the orbit is genuinely infinite (the values
  reached from `x0` form an unbounded set), neither algorithm
  terminates. In practice you must already know the value domain is
  finite, or wrap the call with an external step budget.
- **Cycle entered immediately (`mu == 0`).** This is a valid output;
  the cycle entrance is `x0` itself and Phase 2 returns `0` on the
  first iteration. The algorithms handle this without special-casing.
- **Cycle of length 1 (a fixed point).** Also a valid output;
  `lam == 1` means `f(x_mu) == x_mu`.
- **Floyd vs. Brent results.** Both algorithms compute the *same*
  `(mu, lam)`, but Brent's intermediate "meeting point" is *not* a
  cycle value in general -- so do not try to read `mu` or `lam` out
  of Brent's first phase by analogy with Floyd. Always use the
  reported pair.
- **Equality of `T`.** Each iteration calls `==` once on `T`; for
  large structured values this dominates the runtime. Hashing or
  cheap fingerprinting of states is a common follow-up optimisation.

---

## 8. Related concepts

```
Tortoise-and-hare (linked list)  same idea on pointer chains:
                                  modules/techniques/techniques/advanced.mbt
Pollard rho factorisation         @pollard_rho.factor / @pollard_rho.is_prime
Pollard rho discrete log          not yet
Birthday paradox                  bounds on expected mu + lam for random f
Time-memory tradeoff (Hellman)    table-based variant for short-cycle hashes
```
