# Loop Invariants in MoonBit

This repository is a **learning library** for algorithms. Each package explains
one topic in clear, beginner-friendly language and shows *why it works* using
loop invariants.

If you are new to algorithms, you can read these packages like a book. Each
README is designed to be understandable without heavy math.

## What You Will Learn

- How to translate a problem into a step-by-step algorithm
- How to reason about correctness with loop invariants
- How to write clean, testable MoonBit implementations

## How the Tutorials Are Written

Each package README follows this structure:

1. **Problem statement** in simple terms
2. **Core idea** (the intuition)
3. **Step-by-step algorithm**
4. **Multiple examples**
5. **Complexity and pitfalls**

Think of the README as a Wikipedia article: definition, motivation, examples,
then implementation notes.

## How Examples Are Tested

`README.mbt.md` files include code blocks tagged `mbt check`. These blocks are
compiled and run by `moon test`, so documentation stays correct.

If you want a snippet that should not run, use `mbt nocheck` instead.

```mbt check
///|
test "doc example runs" {
  inspect(1 + 1, content="2")
}
```

## What Is a Loop Invariant?

A loop invariant is a sentence that stays true every time the loop repeats.
It connects code to reasoning.

A good invariant explains:

- what has been computed so far
- what remains to be processed
- why the algorithm will be correct at the end

### Example 1: Sum of an Array

We want the sum of all elements. The invariant is:

> "After processing the first i elements, sum equals their total."

```mbt check
///|
test "invariant sum example" {
  let xs : Array[Int] = [1, 2, 3, 4]
  let n = xs.length()
  let total = for i = 0, sum = 0; i < n; {
    continue i + 1, sum + xs[i]
  } nobreak {
    sum
  } where {
    invariant: 0 <= i && i <= n,
    reasoning: "sum equals the total of xs[0..i).",
  }
  inspect(total, content="10")
}
```

### Example 2: Maximum Value

We keep a running maximum. The invariant is:

> "best is the maximum of elements seen so far."

```mbt check
///|
test "invariant max example" {
  let xs : Array[Int] = [2, 7, 1, 5]
  let n = xs.length()
  let best = for i = 0, best = xs[0]; i < n; {
    let v = xs[i]
    continue i + 1, if v > best { v } else { best }
  } nobreak {
    best
  } where {
    invariant: 0 <= i && i <= n,
    reasoning: "best is max of xs[0..i).",
  }
  inspect(best, content="7")
}
```

### Example 3: Simple Loop Without Invariants

For very simple loops, a `for .. in` loop is clearer and needs no invariant.

```mbt check
///|
test "simple loop example" {
  let xs : Array[Int] = [1, 2, 3]
  let sum = for v in xs; sum = 0 {
    continue sum + v
  } nobreak {
    sum
  }
  inspect(sum, content="6")
}
```

## How to Read a Package

Each package lives in `lib/<name>/` and has:

- `README.mbt.md` (the tutorial)
- `.mbt` source files (the implementation)
- tests (often inside the README itself)

If a README feels too advanced, pick an easier package first and return later.

## Suggested Learning Path

Start small and build up:

- **Basics**: `lib/union_find`, `lib/fenwick`, `lib/segment_tree`
- **Dynamic Programming**: `lib/dp`, `lib/linear_recurrence`
- **Strings**: `lib/kmp`, `lib/aho_corasick`, `lib/suffix_array`
- **Graphs**: `lib/dijkstra`, `lib/bellman_ford`, `lib/mst`
- **Advanced**: `lib/centroid`, `lib/linkcut`, `lib/segment_tree_beats`

## Running the Code

```bash
moon test
moon check
moon fmt
moon run cmd/main
```

## Contributing

When improving a tutorial:

- Keep it beginner-friendly
- Add multiple examples
- Explain *why* the algorithm works
- Mention complexity and pitfalls

## License

See `LICENSE`.
