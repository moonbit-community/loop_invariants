# Bellman-Ford (Reference)

Compute single-source shortest paths with support for negative edges and
negative-cycle detection. This package is a reference implementation with
step-by-step invariants and includes an SPFA variant.

## What it demonstrates

- Edge-relaxation over `V - 1` rounds
- Early exit when no updates occur
- Negative-cycle detection via one extra relaxation pass
- SPFA queue-based relaxation

## Pseudocode sketch

```mbt nocheck
let bf = BellmanFord::new(n)
bf.add_edge(u, v, w)
let result = bf.compute(source)
result.get_distance(target)
```

## Notes

- This package is meant as a reference walkthrough; core types are private.
- For a public, testable API, see `lib/challenge_bellman_ford`.
- Time complexity: `O(V * E)`; SPFA is faster on many sparse graphs but can
  still be `O(V * E)` in the worst case.
