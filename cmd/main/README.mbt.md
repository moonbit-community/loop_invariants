# Command Line Entry (Mini Tutorial)

## Problem

"I want a quick way to run a small demo or sanity check without editing tests."

## Simple Solution

Use the `cmd/main` package. It is the executable entry point. You can print a message, call a library function, or run a tiny example.

## How It Works

- `cmd/main/main.mbt` is the program entry
- The file is intentionally small
- Most real logic stays in `lib/` packages

## Try It

```mbt nocheck
moon run cmd/main
```

You should see a short message telling you to run tests.

## How to Add a Small Demo

1. Open `cmd/main/main.mbt`
2. Import a package in `cmd/main/moon.pkg.json` (if needed)
3. Call the function and print its result

Example shape:

```mbt nocheck
///|
fn main {
  println("Demo")
  // println(@some_pkg.some_function(...))
}
```

## Notes

- Keep demos tiny so tests stay fast
- The real tutorials live in each `lib/<package>/README.mbt.md`
