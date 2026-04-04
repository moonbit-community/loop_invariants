# `moon prove` Notes

This file records practical suggestions from trying to formalize parts of this
repo with `moon prove`.

## Current observation

The main issue is not raw prover strength. The main issue is the gap between
ordinary MoonBit code and the subset that is currently easy to verify.

This repo already contains many good informal invariants, but a lot of existing
packages are written around:

- `ArrayView`
- mutable `Array`
- `push` / `pop`
- sorting
- nested loops
- DFS / BFS over graph structures
- in-place construction of tables and auxiliary arrays

By contrast, the smoothest path for `moon prove` today is usually:

- scalar state
- small proof-oriented loops
- `FixedArray`
- explicitly written `.mbtp` predicates
- proof-native kernels extracted from larger algorithms

That is why the first successful proofs in this repo were new proof-native
packages rather than direct proofs of the existing implementations.

After more experiments on existing packages, there is now one important
refinement:

- existing packages can still gain meaningful proofs if they keep their public
  `ArrayView` / `Array` API but route the proof-critical kernel through a
  private `FixedArray` helper

This worked well for:

- [`lib/challenge_coordinate_compress`](./lib/challenge_coordinate_compress)
- [`lib/challenge_meet_in_middle`](./lib/challenge_meet_in_middle)
- [`lib/challenge_lis_nlogn`](./lib/challenge_lis_nlogn)
- [`lib/challenge_ternary_search`](./lib/challenge_ternary_search)
- [`lib/challenge_prefix_sum`](./lib/challenge_prefix_sum)
- [`lib/challenge_binary_search_answer`](./lib/challenge_binary_search_answer)

In both cases, the package stayed structurally the same, but the binary-search
helper was rewritten as a proof-carrying `FixedArray` function and the runtime
array was copied into a `FixedArray` before the proved call.

After the next round of experiments, there is a better version of that pattern:

- if the algorithm already maintains an internal table or small search window,
  it is better to keep that state in a private `FixedArray` buffer and prove a
  helper over that buffer directly

This preserves complexity much better than repeatedly copying runtime arrays
into new `FixedArray` values just to cross the proof boundary.

Another useful result from this repo:

- exact array-shape postconditions are possible without recursive logic
  functions if the specification is written as local equations

For example, prefix sums can be specified as:

- `prefix[0] == 0`
- `prefix[i + 1] == prefix[i] + arr[i]`

rather than trying to define a separate recursive logical summation function.

## Highest-priority improvements

### 1. Make proof adoption opt-in

Repo-wide `moon prove` currently attempts to prove packages that only contain
informal `invariant:` documentation. That causes immediate failures in existing
packages even when they were never intended to be proof-native.

It would help to support one of these models:

- package-level opt-in proof mode
- function-level opt-in proof mode
- `moon prove --only-explicit`
- ignore informal `invariant:` clauses unless proof mode is enabled

This would make gradual adoption practical.

### 2. Support `ArrayView` and mutable `Array` better

A large fraction of this repo uses `ArrayView[Int]` and mutable `Array[Int]`.
Today, proving these directly is much harder than proving `FixedArray`.

More specifically from this repo:

- `.mbtp` predicates over `ArrayView` did not work in my experiments
- contracted functions whose bodies directly manipulate `ArrayView` also ran
  into unsupported-expression restrictions
- `FixedArray` remains the practical proof boundary today
- prefix-length reasoning over `FixedArray` does work well
- witness-index proofs over `FixedArray` also work well

Better logical support for:

- `ArrayView`
- mutable `Array`
- array slices
- array updates
- length-preserving transformations

would let existing packages be proved in place instead of rewritten into
parallel proof-only variants.

### 3. Add standard proof models for common library operations

Many real algorithms depend on operations that are routine at runtime but hard
to reason about without library lemmas.

High-value built-ins would include:

- `sort_by_key`
- `rev_in_place`
- `push`
- `pop`
- `clear`
- copying between arrays
- prefix/suffix predicates
- sortedness lemmas
- uniqueness / dedup lemmas

Without these, a lot of effort goes into modeling library behavior rather than
proving the algorithm itself.

### 4. Improve loop verification ergonomics

The easy cases today are loops that already look like textbook binary search.
Many packages here use:

- nested loops
- early `break`
- multiple `continue` branches
- shrinking and expanding windows
- synthetic guards chosen only to satisfy proof tooling

Better support for:

- explicit loop measures on imperative loops
- clearer loop-exit reasoning
- better diagnostics on which invariant branch failed
- more robust support for accumulator-style proofs

would make existing packages much more approachable.

One concrete issue from this repo: the older loop style

```moonbit
for lo = 0, hi = n {
  if lo >= hi { break lo } else { ... }
} where { ... }
```

can be accepted by `moon prove`, but it is not the reliable shape for adding a
real function contract. The proof-friendly shape was the more explicit form:

```moonbit
for lo = 0, hi = n; lo < hi; {
  ...
} nobreak {
  lo
} where { ... }
```

Supporting both forms equally well would lower migration cost a lot.

Another concrete issue from this repo: when a loop updates multiple state
variables with `continue`, proof generation seems much happier if array reads
are first bound to locals.

For example, this shape caused hard proof obligations:

```moonbit
continue i + 1, used + 1, weights[i]
```

while this shape proved cleanly:

```moonbit
let w = weights[i]
continue i + 1, used + 1, w
```

The likely issue is not the algorithm but how tuple-style `continue` updates are
lowered for proof obligations.

### 5. Support mixed-mode verification inside normal packages

The ideal workflow is:

- keep an existing package structure
- add proof contracts to one or two functions
- verify only those functions
- leave the rest of the package as normal code

Right now the workflow often pushes toward separate proof-native packages.
Those are useful, but they are not a substitute for incremental proof adoption
inside ordinary packages.

## Tooling suggestions

### Better error messages

The current errors are correct but often too low-level.

Examples of useful upgrades:

- if `invariant:` appears in proof mode, suggest `proof_invariant:`
- if a proof predicate is unbound, suggest checking `.mbtp` export / naming
- if a loop shape is hard to prove, say what variant shape is expected

This would reduce trial-and-error significantly.

### Better proof reports

A compact proof report per package would help review and maintenance:

- proved functions
- goal counts
- failed obligations grouped by function / loop
- timing information

This would make proof progress visible over time.

Another practical issue: a package can report `Succeeded: 0 goals proved`.
That is easy to misread as "proved" even when no meaningful contract was
actually checked. The tool should make this state much more explicit.

### Better incremental performance

Incremental caching matters if proof adoption grows. Small packages prove
quickly now, but repo-scale usage will depend on fast reruns after local edits.

## Language / proof features that would help

### Ghost-friendly ordinary code

It would help if ghost state and proof helpers fit more naturally into ordinary
`.mbt` files without forcing a heavy split between runtime code and proof code.

### Easier bridges between runtime helpers and logic helpers

A lot of duplication comes from needing a runtime helper in `.mbt` and a logic
predicate or model in `.mbtp` that expresses nearly the same idea.

Better support for pure helper reuse would reduce friction.

### Stronger standard patterns

The prover would benefit from built-in support or canonical examples for:

- binary search
- lower / upper bound
- lower / upper bound over a prefix `arr[0 .. len)`
- prefix scans
- accumulator bounds
- witness-index proofs
- monotonic stack patterns
- queue / BFS invariants
- local-equation specs for array construction

These patterns appear repeatedly in this repo.

## Documentation suggestions

The most useful official examples would not be toy proofs. They would be
"prove an existing package incrementally" examples.

Especially valuable examples:

- proving a binary-search helper in an existing package
- proving a prefix-sum constructor over arrays
- proving a coordinate-compression helper
- proving a queue-based traversal kernel
- proving a monotonic-stack kernel

That would map much more directly to real codebases like this one.

## Repo-specific takeaway

For this repo, the most realistic near-term path is:

1. prove small kernels first
2. focus on search / scan / arithmetic helpers
3. add proof-native examples where needed
4. only later revisit graph-heavy and mutation-heavy packages

That path is already productive, but the features above would make it possible
to prove more of the existing packages directly rather than creating separate
verified versions.
