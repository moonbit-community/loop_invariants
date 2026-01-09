# Loop Invariants in MoonBit

A comprehensive collection of algorithms with rigorous loop invariants and mathematical reasoning, demonstrating how formal verification techniques can guide code generation and improve code quality.

## What Are Loop Invariants?

A **loop invariant** is a property that:
1. **Base Case**: Holds before the loop starts
2. **Inductive Step**: If it holds before an iteration, it holds after
3. **Termination**: When the loop ends, it implies the desired postcondition

Loop invariants serve as *mathematical contracts* that help both humans and AI systems reason about code correctness.

## Why This Repository?

This repository demonstrates that:
- **Deep mathematical reasoning** improves code quality
- **Loop invariants** can guide AI code generation
- **Formal specifications** catch bugs before runtime
- **Complex algorithms** become understandable through invariants

## Repository Structure

| File | Description | Key Algorithms |
|------|-------------|----------------|
| `examples.mbt` | Core examples | Binary search, GCD, power, factorial |
| `examples_arithmetic.mbt` | Arithmetic algorithms | Karatsuba multiplication, Newton-Raphson |
| `examples_streaming.mbt` | Streaming algorithms | Online mean/variance, median tracking |
| `examples_wildcards.mbt` | Pattern matching | Wildcard matching, regex-like patterns |
| `examples_advanced.mbt` | Classic algorithms | Floyd's cycle detection, KMP, Convex Hull |
| `examples_number_theory.mbt` | Number theory | Miller-Rabin, CRT, Extended Euclidean |
| `examples_graph.mbt` | Graph algorithms | Dijkstra, Topological Sort, Union-Find |
| `examples_probabilistic.mbt` | Randomized algorithms | Reservoir Sampling, Fisher-Yates |
| `examples_string_algorithms.mbt` | String processing | Z-Algorithm, Manacher's, Rabin-Karp |
| `examples_monotonic.mbt` | Monotonic structures | Monotonic Stack/Deque, Sliding Window |
| `examples_matrix.mbt` | Matrix algorithms | Matrix exponentiation, Fast Fibonacci |
| `examples_fenwick.mbt` | Tree structures | Fenwick Tree (BIT), 2D variants |
| `examples_tarjan.mbt` | Graph connectivity | Tarjan's SCC, Articulation Points, Bridges |
| `examples_segment_tree.mbt` | Segment Trees | Lazy propagation, Persistent, 2D queries |
| `examples_two_pointers.mbt` | Two Pointers | Sliding window, Dutch flag, Partition |
| `examples_dp.mbt` | Dynamic Programming | Knapsack, LIS, LCS, Matrix chain |
| `examples_more_graph.mbt` | Advanced Graph | Bellman-Ford, Floyd-Warshall, MST |
| `examples_bit_game.mbt` | Bits & Games | XOR tricks, Nim, Sprague-Grundy |

## Featured Insights

### Binary Representation Magic (Fenwick Tree)

The Fenwick Tree exploits a beautiful property of binary numbers:
```
For index i, the parent in update tree is: i + (i & -i)
For index i, the parent in query tree is:  i - (i & -i)
```

**Invariant**: `sum[1..i] = tree[i] + tree[i - LSB(i)] + tree[i - LSB(i) - LSB(i - LSB(i))] + ...`

### Matrix Exponentiation for Recurrences

Any linear recurrence `F(n) = a₁F(n-1) + a₂F(n-2) + ... + aₖF(n-k)` can be computed in O(log n) time:

```
[F(n)  ]   [a₁ a₂ ... aₖ]^(n-k)   [F(k)  ]
[F(n-1)] = [1  0  ... 0 ]       × [F(k-1)]
[...]     [0  1  ... 0 ]         [...]
[F(n-k+1)] [0  0  ... 1 ]         [F(1)  ]
```

**Invariant**: `M^original_power ≡ result × M^remaining_power (mod m)`

### Tarjan's Low-Link Values

In Tarjan's SCC algorithm, the low-link value captures reachability through back edges:

```
low[v] = min(disc[v], min{disc[u] : u is reachable from v via tree + one back edge})
```

**Invariant**: A vertex v is an SCC root iff `low[v] == disc[v]` after exploring all descendants.

### Monotonic Stack Properties

For "next greater element" problems:

**Invariant**: Stack maintains indices in decreasing order of their values.
**Key insight**: Each element is pushed and popped at most once → O(n) amortized.

## MoonBit Loop Invariant Syntax

```moonbit
fn algorithm(input : Array[Int]) -> Int {
  for i = 0, result = initial_value; i < n; i = i + 1, result = update(result) {
    // loop body
  } else {
    result
  } where {
    invariant: condition_that_always_holds,
    reasoning: (
      #|LOOP INVARIANT: Mathematical property
      #|
      #|BASE CASE (i = 0):
      #|  - Property holds initially because...
      #|
      #|INDUCTIVE STEP (i → i + 1):
      #|  - Assuming property holds at i
      #|  - After iteration, property still holds because...
      #|
      #|TERMINATION (i = n):
      #|  - Property implies our postcondition...
    ),
  }
}
```

## Running the Examples

```bash
# Build and run tests
moon test

# Check with full warnings
moon check

# Format code
moon fmt
```

## Algorithm Complexity Summary

| Algorithm | Time | Space | Key Invariant |
|-----------|------|-------|---------------|
| Binary Search | O(log n) | O(1) | Target in `arr[lo..hi]` if exists |
| Fenwick Update/Query | O(log n) | O(n) | Prefix sum decomposition |
| Segment Tree Range | O(log n) | O(n) | Node covers interval `[l, r)` |
| Matrix Power | O(k³ log n) | O(k²) | `M^p ≡ result × base^remaining` |
| Tarjan's SCC | O(V + E) | O(V) | Low-link = earliest reachable |
| Floyd-Warshall | O(V³) | O(V²) | Uses vertices `{0..k}` as intermediates |
| Bellman-Ford | O(VE) | O(V) | Shortest using at most k edges |
| KMP Search | O(n + m) | O(m) | Failure function = proper prefix-suffix |
| LIS (Binary Search) | O(n log n) | O(n) | tails[i] = smallest end of LIS length i |
| Nim Game | O(n) | O(1) | XOR = 0 iff losing position |
| Sprague-Grundy | O(n × moves) | O(n) | sg = mex of reachable positions |
| Union-Find | O(α(n)) | O(n) | Path compression maintains roots |

## Contributing

When adding new algorithms:
1. Include comprehensive loop invariants
2. Provide base case, inductive step, and termination reasoning
3. Add test cases that verify correctness
4. Document the mathematical insights

## License

MIT License - See LICENSE file for details.

---

*This repository demonstrates that rigorous mathematical reasoning, expressed through loop invariants, leads to more reliable and understandable code.*
