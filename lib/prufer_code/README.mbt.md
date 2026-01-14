# Prufer Code

## Overview

A **Prufer code** (or Prüfer sequence) is a unique sequence of `n-2` integers
that encodes a labeled tree with `n` vertices. It provides a bijection between
labeled trees and integer sequences, proving Cayley's formula.

- **Time**: O(n log n) with heap, O(n) with optimizations
- **Space**: O(n)
- **Key Feature**: Bijective tree representation

## The Key Insight

```
Problem: Represent a labeled tree as a sequence of integers

Key observation:
  A labeled tree with n vertices has n-1 edges.
  A vertex's degree determines how often it appears in the code!

  degree(v) in tree = count(v in code) + 1

Encoding: Repeatedly remove smallest leaf
  Leaf = degree 1 = not in remaining code
  Record neighbor of removed leaf
  After n-2 removals, 2 vertices remain

Decoding: Reconstruct from degree counts
  Vertex missing from code = leaf (degree 1)
  Connect smallest leaf to current code element
  Repeat until done

This bijection proves Cayley's formula:
  Number of labeled trees on n vertices = n^(n-2)
```

## Visual: Encoding Process

```
Tree with 5 vertices (0-indexed):

    0 ─── 1 ─── 2
          │
          3
          │
          4

Edges: (0,1), (1,2), (1,3), (3,4)
Degrees: [1, 3, 1, 2, 1]  (0, 2, 4 are leaves)

Encoding steps:
  Step 1: Smallest leaf = 0, neighbor = 1
          Code: [1]
          Remove 0, update: degrees = [-, 2, 1, 2, 1]

  Step 2: Smallest leaf = 2, neighbor = 1
          Code: [1, 1]
          Remove 2, update: degrees = [-, 1, -, 2, 1]

  Step 3: Smallest leaf = 1, neighbor = 3
          Code: [1, 1, 3]
          Remove 1, update: degrees = [-, -, -, 1, 1]

  Two vertices remain: 3 and 4

Final Prufer code: [1, 1, 3]
```

## Visual: Decoding Process

```
Code: [1, 1, 3], n = 5

Step 1: Compute degrees
  degree[v] = count(v in code) + 1
  degree = [1, 3, 1, 2, 1]
  (0, 2, 4 have degree 1 = leaves)

Step 2: Decode
  Code[0] = 1, smallest leaf = 0
  Add edge (0, 1), decrease degrees
  degrees = [0, 2, 1, 2, 1]

  Code[1] = 1, smallest leaf = 2
  Add edge (2, 1), decrease degrees
  degrees = [0, 1, 0, 2, 1]

  Code[2] = 3, smallest leaf = 1
  Add edge (1, 3), decrease degrees
  degrees = [0, 0, 0, 1, 1]

Step 3: Connect remaining vertices (3, 4)
  Add edge (3, 4)

Reconstructed tree: (0,1), (2,1), (1,3), (3,4) ✓
```

## The Algorithm

```
// Encoding
prufer_encode(n, edges):
  build adjacency list
  degree = [count neighbors for each vertex]
  leaves = min-heap of vertices with degree 1

  code = []
  for i = 0 to n-3:
    leaf = leaves.pop_min()
    neighbor = only remaining neighbor of leaf
    code.append(neighbor)
    degree[neighbor] -= 1
    if degree[neighbor] == 1:
      leaves.push(neighbor)

  return code

// Decoding
prufer_decode(code):
  n = len(code) + 2
  degree = [1] * n
  for v in code:
    degree[v] += 1

  leaves = min-heap of vertices with degree 1
  edges = []

  for v in code:
    leaf = leaves.pop_min()
    edges.append((leaf, v))
    degree[leaf] -= 1
    degree[v] -= 1
    if degree[v] == 1:
      leaves.push(v)

  // Connect last two vertices
  last_two = [v for v if degree[v] == 1]
  edges.append((last_two[0], last_two[1]))

  return edges
```

## Example Usage

```mbt check
///|
test "prufer example" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
  let code = @prufer_code.prufer_encode(4, edges[:]).unwrap()
  inspect(code, content="[1, 2]")
  let edges2 = @prufer_code.prufer_decode(code[:]).unwrap()
  inspect(edges2.length(), content="3")
}
```

```mbt check
///|
test "prufer star tree" {
  // Star: center 0 connected to 1, 2, 3, 4
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
  let code = @prufer_code.prufer_encode(5, edges[:]).unwrap()
  inspect(code, content="[0, 0, 0]")
}
```

```mbt check
///|
test "prufer path tree" {
  // Path: 0-1-2-3-4
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
  let code = @prufer_code.prufer_encode(5, edges[:]).unwrap()
  inspect(code, content="[1, 2, 3]")
}
```

## Algorithm Walkthrough

```
Tree: 0-1-2-3 (path)

Step 1: Build initial state
  Adjacency: 0:[1], 1:[0,2], 2:[1,3], 3:[2]
  Degrees:   [1, 2, 2, 1]
  Leaves:    {0, 3}

Step 2: Encode
  i=0: Remove smallest leaf (0)
       Neighbor of 0 is 1
       Code: [1]
       Degrees: [0, 1, 2, 1]
       1 becomes a leaf! Leaves: {1, 3}

  i=1: Remove smallest leaf (1)
       Neighbor of 1 is 2
       Code: [1, 2]
       Degrees: [0, 0, 1, 1]
       2 becomes a leaf! Leaves: {2, 3}

Step 3: Two vertices remain (2, 3)
  Done!

Final code: [1, 2]
```

## Why It Works

```
Claim: Every labeled tree has a unique Prufer code.

Proof of uniqueness:
  At each step, we remove the SMALLEST leaf.
  This is deterministic given the current tree.
  So each tree produces exactly one code.

Proof of bijectivity:
  The decoding algorithm inverts encoding exactly.
  Each code produces exactly one tree.

The bijection implies:
  |labeled trees on n vertices| = |sequences of length n-2 with values in [0,n-1]|
                                = n^(n-2)

This is Cayley's formula!
```

## Common Applications

### 1. Cayley's Formula Proof
```
Bijection between trees and sequences proves:
Number of labeled trees = n^(n-2)
```

### 2. Random Tree Generation
```
Generate uniform random labeled tree:
  1. Generate n-2 random integers in [0, n-1]
  2. Decode to get tree
Result is uniformly distributed!
```

### 3. Tree Serialization
```
Compress tree to n-2 integers.
Useful for storing/transmitting tree structures.
```

### 4. Combinatorics Problems
```
Counting trees with specific properties.
Generating all labeled trees on n vertices.
```

## Complexity Analysis

| Operation | Time | Notes |
|-----------|------|-------|
| Build adjacency | O(n) | From edge list |
| Initialize heap | O(n) | All vertices |
| Encoding | O(n log n) | n heap operations |
| Decoding | O(n log n) | n heap operations |
| **Total** | **O(n log n)** | Dominated by heap |

## O(n) Optimization

```
Linear-time encoding without heap:
  Maintain pointer to smallest leaf.
  After removing leaf v with neighbor u:
    If u becomes leaf and u < current pointer:
      Process u immediately
    Else:
      Advance pointer to next leaf

This avoids heap overhead for sorted access.
```

## Special Cases

| Tree Shape | Prufer Code |
|------------|-------------|
| Path 0-1-...-n | [1, 2, ..., n-2] |
| Star (center 0) | [0, 0, ..., 0] |
| Binary tree | Varies by structure |

## Implementation Notes

- Vertices must be labeled 0 to n-1
- Code has exactly n-2 elements
- Each integer in code is in range [0, n-1]
- Decoding assumes valid Prufer code input
- Handle n=1 (empty code) and n=2 (single edge) specially

