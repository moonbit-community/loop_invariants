# XOR Linear Basis

## Overview

A **XOR basis** stores a set of integers such that any XOR combination of the
stored values can be represented. It supports fast insertion, membership
queries, and maximizing XOR with a given value.

- **Time**: O(B) per operation, where B ≤ 63 bits
- **Space**: O(B)
- **Key Feature**: Gaussian elimination over GF(2)

## The Key Insight

```
Problem: Given a set of integers, what values can we make by XORing subsets?

Naive: Try all 2^n subsets → exponential

XOR Basis insight: The "span" of n numbers has at most B dimensions
  - Store one representative for each bit position
  - Like Gaussian elimination, but with XOR instead of subtraction
  - At most 64 basis vectors for 64-bit integers!

Operations become O(B) = O(64) = O(1) for practical purposes.
```

## Understanding XOR as Linear Algebra

```
XOR over GF(2) (field with 2 elements: 0 and 1):

a ⊕ a = 0     (self-inverse)
a ⊕ 0 = a     (identity)
a ⊕ b = b ⊕ a (commutative)

Numbers as bit vectors:
  5 = 101
  3 = 011
  6 = 110

We can XOR any combination:
  5 ⊕ 3 = 110 = 6
  5 ⊕ 6 = 011 = 3
  3 ⊕ 6 = 101 = 5
  5 ⊕ 3 ⊕ 6 = 000 = 0

The "span" is {0, 3, 5, 6} - all XOR combinations.
```

## Visual: Building the Basis

```
Insert 5 (101), 3 (011), 6 (110) into basis:

Initial: basis = [_, _, _] (3 bit positions)
                  ^  ^  ^
               bit2 bit1 bit0

Insert 5 = 101:
  Highest bit = 2 (position of leftmost 1)
  basis[2] is empty → store 5
  basis = [101, _, _]

Insert 3 = 011:
  Highest bit = 1
  basis[1] is empty → store 3
  basis = [101, 011, _]

Insert 6 = 110:
  Highest bit = 2
  basis[2] = 101, so XOR: 110 ⊕ 101 = 011
  Now highest bit = 1
  basis[1] = 011, so XOR: 011 ⊕ 011 = 000
  Reduced to 0 → 6 is already representable!
  Don't insert (rank stays same)

Final basis: [101, 011, _]
Rank = 2 (we can represent 2² = 4 values)
```

## Algorithm: Insertion

```
insert(x):
  for bit from highest to lowest:
    if bit is set in x:
      if basis[bit] is empty:
        basis[bit] = x
        return true  // rank increased
      else:
        x = x XOR basis[bit]  // eliminate this bit
  return false  // x reduced to 0, already representable
```

## Algorithm: Maximum XOR

```
Goal: Given x, find max(x XOR y) where y is in the span.

Greedy approach (works because XOR is bitwise):
  for bit from highest to lowest:
    if XORing with basis[bit] would set this bit in result:
      x = x XOR basis[bit]
  return x

Why greedy works:
  - Higher bits contribute more to the value
  - Setting bit k adds 2^k, clearing it loses 2^k
  - Decisions at higher bits always dominate lower bits
```

## Visual: Maximum XOR Query

```
basis = [101, 011, _] (from earlier)
Query: max_xor(2) where 2 = 010

Start with x = 010

Bit 2: x has bit 2 = 0
  XOR with basis[2]=101: 010 ⊕ 101 = 111
  Bit 2 would become 1 → better! Do it.
  x = 111

Bit 1: x has bit 1 = 1
  XOR with basis[1]=011: 111 ⊕ 011 = 100
  Bit 1 would become 0 → worse! Skip.
  x = 111 (unchanged)

Bit 0: (no basis vector for bit 0)

Result: max_xor(2) = 111 = 7
```

## Algorithm: Can Represent

```
can_represent(x):
  for bit from highest to lowest:
    if bit is set in x:
      if basis[bit] is empty:
        return false  // can't eliminate this bit
      x = x XOR basis[bit]
  return x == 0  // successfully reduced to 0
```

## API

- `insert(x)` returns true if the rank increases.
- `can_represent(x)` checks if x is in the span.
- `max_xor(x)` returns the maximum possible `x ^ y`.
- `rank()` returns the basis size.

## Example Usage

```mbt check
///|
test "xor basis max" {
  let b = @xor_basis.XorBasis::new()
  let _ = b.insert(8L)
  let _ = b.insert(5L)
  let _ = b.insert(10L)
  inspect(b.max_xor(0L), content="15")
}
```

## More Examples

```mbt check
///|
test "xor basis membership" {
  let b = @xor_basis.XorBasis::new()
  let _ = b.insert(5L) // 101
  let _ = b.insert(3L) // 011
  // Can represent: 0, 3, 5, 6 (= 5 XOR 3)
  inspect(b.can_represent(0L), content="true")
  inspect(b.can_represent(3L), content="true")
  inspect(b.can_represent(5L), content="true")
  inspect(b.can_represent(6L), content="true")
  inspect(b.can_represent(1L), content="false")
  inspect(b.can_represent(2L), content="false")
}
```

```mbt check
///|
test "xor basis rank" {
  let b = @xor_basis.XorBasis::new()
  inspect(b.rank(), content="0")
  let r1 = b.insert(5L)
  inspect(r1, content="true")
  inspect(b.rank(), content="1")
  let r2 = b.insert(3L)
  inspect(r2, content="true")
  inspect(b.rank(), content="2")
  // 6 = 5 XOR 3, so it's already in span
  let r3 = b.insert(6L)
  inspect(r3, content="false")
  inspect(b.rank(), content="2")
}
```

## Common Applications

### 1. Maximum XOR Subarray
```
Given array, find subarray with maximum XOR.
Use prefix XOR + basis of all prefix values.
```

### 2. Linear Independence Check
```
Check if a set of numbers is linearly independent over GF(2).
Independent iff every insert increases rank.
```

### 3. Counting Distinct XOR Values
```
If rank = r, there are exactly 2^r distinct values in the span.
```

### 4. XOR Minimization
```
To minimize XOR instead of maximize:
  - Greedily try to clear high bits instead of set them
```

### 5. Graph XOR Cycles
```
In a graph with edge weights, the XOR of any cycle is in the
span of the "fundamental cycle" basis.
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| Insert | O(B) |
| Can Represent | O(B) |
| Max XOR | O(B) |
| Min XOR | O(B) |

Where B = number of bits (typically 64).

## XOR Basis vs Other Approaches

| Approach | Time | Space | Use Case |
|----------|------|-------|----------|
| **XOR Basis** | O(B) | O(B) | Span queries |
| Brute Force | O(2^n) | O(n) | Small n |
| Trie | O(B) | O(nB) | k-th smallest XOR |

## Notes

- The basis is not unique; any reduced form works.
- Rank equals the number of independent vectors.
- At most 64 vectors in basis for 64-bit integers.
- The span always contains 0 (XOR of nothing).

## Implementation Notes

- Use `Int64` for 64-bit support
- Initialize basis array with zeros (empty slots)
- Use `count_leading_zeros` or bit scanning for highest bit
- The order of insertion doesn't affect the final span

