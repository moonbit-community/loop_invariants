## 2026-01-11: Index Loops For Invariants
- Problem: `for .. in` loops cannot carry `where` invariants, triggering warnings and parse errors when annotated.
- Change: Convert `for .. in` loops to indexed `for i = ...; i < ...; i = i + 1` loops and attach invariants plus reasoning.
- Result: Loop-spec warnings removed while preserving algorithm intent.
- Example:
// Before
for i in 0..<n {
  sum = sum + arr[i]
}

// After
for i = 0; i < n; i = i + 1 {
  sum = sum + arr[i]
} where {
  invariant: i >= 0 && i <= n,
  reasoning: (
    #|sum equals the prefix sum of arr[0..i).
  ),
}
