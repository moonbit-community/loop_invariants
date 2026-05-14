# Hopcroft DFA Minimization

## Overview

Hopcroft's 1971 algorithm minimizes a deterministic finite automaton
(DFA) in `O(k · n log n)` time, where `n` is the number of states and
`k` is the alphabet size. The output is the *unique* minimal DFA
(Myhill-Nerode), in which no two states are language-equivalent.

DFA minimization is the standard primitive behind:

- **Regex engines** — minimizing a compiled DFA shrinks match tables.
- **Lexer generators** — `flex`, `re2c`, JFlex all run Hopcroft (or
  Moore, which is simpler but `O(k · n²)`).
- **Compiler optimization** — equivalence of finite automata is the
  same problem as table-driven state-machine reduction.

- **Time**: `O(k · n log n)`
- **Space**: `O(k · n)` for transitions + reverse table
- **Signatures**:
  - `minimize(n, k, transitions, accepting) -> Array[Int]`
  - `block_count_of(block_of) -> Int`

---

## The idea

Two DFA states `p`, `q` are **equivalent** iff for every input string
`w`, `δ*(p, w)` is accepting iff `δ*(q, w)` is. Hopcroft computes the
coarsest such partition by *refinement*:

```
P  = { F, Q \ F }                  # initial partition
W  = { (smaller of F, Q\F, c) : c in alphabet }   # worklist
while W not empty:
  (A, c) <- W.pop
  for each block B in P:
    B1 = { q in B : δ(q, c) in A }
    B2 = B \ B1
    if both nonempty:
      replace B in P with {B1, B2}
      for each c' in alphabet:
        if (B, c') in W:  also add (B', c') for B' in {B1, B2}
        else:             add the SMALLER of B1, B2 with c'
```

The "always add the smaller half" rule is the trick that delivers
`n log n`: each state participates in at most `log n` "smaller half"
splits (because each split halves its block size).

---

## The invariant

> After processing any prefix of the worklist, two states `p`, `q` are
> in the same block iff no string `w` considered so far can take one
> into `F` and the other out.

Initially "considered so far" is the empty string (which separates
exactly `F` from `Q \ F`). Each refinement step extends the set of
"considered" strings by one symbol. After termination, the invariant
covers all strings, so the partition is the Myhill-Nerode equivalence.

---

## Reference implementation

```
pub fn minimize(
  n : Int,
  k : Int,
  transitions : Array[Array[Int]],
  accepting : Array[Bool]
) -> Array[Int]

pub fn block_count_of(block_of : Array[Int]) -> Int
```

`transitions[s][c]` is the destination of state `s` on input symbol `c`
(symbols are integers in `[0, k)`). The return value `block_of[s]`
gives the equivalence-class id of state `s`, with class ids contiguous
in `[0, m)` where `m` is `block_count_of(...)`.

---

## Tests and examples

```mbt check
///|
test "hopcroft trivial" {
  let bo = @hopcroft_dfa_minimization.minimize(1, 1, [[0]], [false])
  debug_inspect(@hopcroft_dfa_minimization.block_count_of(bo), content="1")
}
```

```mbt check
///|
test "hopcroft merges equivalent" {
  // 4-state DFA, alphabet {a, b}. States 1 and 2 are equivalent;
  // 0 and 3 are distinct.
  let bo = @hopcroft_dfa_minimization.minimize(
    4,
    2,
    [[1, 2], [3, 3], [3, 3], [3, 3]],
    [false, false, false, true],
  )
  debug_inspect(@hopcroft_dfa_minimization.block_count_of(bo), content="3")
  debug_inspect(bo[1] == bo[2], content="true")
}
```

```mbt check
///|
test "hopcroft all states equivalent" {
  let bo = @hopcroft_dfa_minimization.minimize(
    5,
    1,
    [[0], [1], [2], [3], [4]],
    [false, false, false, false, false],
  )
  // All non-accepting, no transitions matter -- one equivalence class.
  debug_inspect(@hopcroft_dfa_minimization.block_count_of(bo), content="1")
}
```

```mbt check
///|
test "hopcroft regex .*ab" {
  // DFA recognizing strings ending in "ab" over alphabet {a, b}.
  // Already minimal: 3 states.
  let bo = @hopcroft_dfa_minimization.minimize(3, 2, [[1, 0], [1, 2], [1, 0]], [
    false, false, true,
  ])
  debug_inspect(@hopcroft_dfa_minimization.block_count_of(bo), content="3")
}
```

---

## Complexity

| Operation | Cost |
|---|---|
| Building reverse table | `O(k · n)` |
| Main loop, total | `O(k · n log n)` |
| Block normalization | `O(n)` |

The constant in front of `n log n` is small enough that Hopcroft beats
Moore's `O(k n²)` on essentially all inputs except very small DFAs.

---

## Pitfalls

- **Unreachable states**: `minimize` does *not* prune them. Run a BFS
  from the start state first if you care.
- **Dead states** (no path to an accepting state): merge them into a
  single trap state if you want, but standard DFA minimization treats
  every dead state as equivalent regardless.
- **Alphabet size in transition matrix**: every state must define a
  transition for every symbol — pre-pad with a trap state if not.
- **Initial worklist**: pushing the *smaller* of `F`, `Q \ F` is the
  key to the `n log n` bound. Pushing both is correct but only gives
  `O(k · n²)`.

---

## Related concepts

```
Hopcroft (this)         O(k n log n) DFA minimization
Moore's algorithm       O(k n²) partition refinement
Brzozowski's algorithm  reverse-determinize-reverse-determinize; cleaner but exponential
Myhill-Nerode theorem   theoretical foundation; counts minimal-DFA states
NFA-to-DFA              subset construction; produces input for minimize
```
