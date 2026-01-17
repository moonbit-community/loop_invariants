# Command-Line Entry (Mini Tutorial)

This package is the **executable entry point** for the repository. It is meant
for quick, manual experiments without touching tests.

## Why it exists

When you are learning or debugging, it is useful to run a tiny program:

- print a value
- call a library function
- verify a small idea without editing tests

`cmd/main` provides that lightweight sandbox.

## How to run it

From the repo root:

```mbt nocheck
moon run cmd/main
```

You should see the message from `cmd/main/main.mbt`.

## What to edit

- `cmd/main/main.mbt` contains `fn main`.
- Keep it **small**. Real algorithms and documentation live in `lib/`.

## Example: call a library function

Suppose you want to try `@avl_tree.avl_sorted` quickly.

1. Add the package to `cmd/main/moon.pkg.json`:

```mbt nocheck
{
  "import": [
    "bobzhang/loop_invariants/lib/avl_tree"
  ]
}
```

2. Call it in `cmd/main/main.mbt`:

```mbt nocheck
///|
fn main {
  let sorted = @avl_tree.avl_sorted([3L, 1L, 4L, 1L][:])
  println("sorted = \{sorted}")
}
```

3. Run:

```mbt nocheck
moon run cmd/main
```

## Example output

```
sorted = [1, 1, 3, 4]
```

## Notes and best practices

- Keep demos tiny and focused.
- Avoid heavy computations or long output here.
- Use tests (`moon test`) for real verification.
- Remove temporary imports when you are done.
