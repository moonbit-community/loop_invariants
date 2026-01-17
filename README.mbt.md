# Loop Invariants in MoonBit (Gentle Guide)

This repository is a teaching collection: each package explains **a problem** and the **simplest correct way to solve it**, with loop invariants that make the reasoning explicit. Think of it as a cookbook for algorithms where every recipe shows *why it works*.

## How to Use This Repo

Each package follows the same learning flow:

1. **Problem statement** in the package README
2. **Key idea** in plain language
3. **Step-by-step algorithm**
4. **Loop invariants** that justify correctness
5. **Complexity** and common pitfalls

If you are new, start with small packages like:
- `lib/union_find`
- `lib/fenwick`
- `lib/segment_tree`
- `lib/dp`

## What Is a Loop Invariant?

A loop invariant is a statement that stays true every time the loop repeats. It lets you explain correctness in three easy steps:

- **Before** the loop starts: the statement is true
- **During** each iteration: the statement stays true
- **After** the loop ends: the statement implies the answer is correct

You do not need formal math to use invariants. A good invariant is often just a sentence like:

> "After processing the first i items, the partial result matches the best answer for those items."

## Example (No-Frills)

Below is the shape of a loop with an invariant. You will see this structure across the packages.

```mbt nocheck
///|
fn example(xs : ArrayView[Int]) -> Int {
  let n = xs.length()
  for i = 0, acc = 0; i < n; {
    continue i + 1, acc + xs[i]
  } else {
    acc
  } where {
    invariant: 0 <= i && i <= n,
    reasoning: "acc holds the sum of xs[0..i).",
  }
}
```

## Running the Code

```bash
moon test
moon check
moon fmt
```

## Repository Map

- `lib/` contains the main algorithms, grouped by topic
- Each `lib/<package>/README.mbt.md` is the package tutorial
- `examples*.mbt` files show stand-alone demonstrations

## Contributing

When adding or improving a package tutorial:

1. Describe the **problem** in one short paragraph
2. Explain the **core idea** in simple words
3. Give a **step-by-step algorithm**
4. Show the **loop invariant** used in the implementation
5. Note **time and space complexity**

If a loop is simple, a `for .. in` loop is preferred and no invariant is needed.

## License

See `LICENSE`.
