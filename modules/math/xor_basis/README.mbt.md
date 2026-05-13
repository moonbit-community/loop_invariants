# XOR Basis

## Overview

An XOR basis (also called a linear basis over GF(2)) maintains a set of
`Int64` vectors under XOR so you can answer in O(B) time:

- Can I make `x` by XORing some subset of inserted values?
- What is the maximum `x XOR y` where `y` comes from the inserted set?
- How many linearly independent values have been inserted (the rank)?

It is Gaussian elimination applied to bit vectors, working in the field GF(2)
where addition is XOR and the only scalars are 0 and 1.

```
insert         O(B)
can_represent  O(B)
max_xor        O(B)
rank           O(1)
```

B is at most 63 for `Int64`, so all operations are effectively constant time.

---

## GF(2) Linear Algebra in One Paragraph

Over the ordinary real numbers, Gaussian elimination reduces a matrix using
subtraction. Over GF(2) (integers mod 2), subtraction equals addition equals
XOR. A "row" is an integer interpreted as a bit vector. Eliminating a leading
bit means XORing with a pivot row whose leading bit matches, cancelling that
bit to zero. Because XOR is its own inverse, the same operation serves for
both "add row" and "subtract row".

---

## Echelon Form of the Basis

The basis array has one slot per bit position. Slot `k` is either empty (0)
or holds a vector whose highest set bit is exactly `k`. This is row echelon
form over GF(2):

```
bit position:  62  61  ...  5   4   3   2   1   0
basis slot:     0   0  ...  0  v4  v3   0   0   0

v4 = some Int64 with bit 4 as its leading bit
v3 = some Int64 with bit 3 as its leading bit

All bits above each vector's leading bit are already zero within that slot
(they were eliminated when the vector was inserted).
```

At most one vector occupies each slot, so the basis holds at most 63 vectors.
The span of those vectors (all possible XOR subsets) equals the span of every
value ever inserted.

---

## Gaussian Elimination: Insert Step by Step

Inserting a value reduces it by existing basis vectors from the top bit down.

```
State: basis is empty
       basis[ k ] = 0 for all k

Insert 5 = 101:

  remainder = 101
  bit 2 is set, basis[2] = 0 (empty) -> store 101 in basis[2], rank++

  basis[2] = 101
  basis[1] = 0
  basis[0] = 0

Insert 3 = 011:

  remainder = 011
  bit 2: not set in remainder, skip
  bit 1: bit 1 is set, basis[1] = 0 (empty) -> store 011 in basis[1], rank++

  basis[2] = 101
  basis[1] = 011
  basis[0] = 0

Insert 6 = 110:

  remainder = 110
  bit 2: set, basis[2] = 101 -> XOR: 110 ^ 101 = 011  (bit 2 eliminated)
  remainder = 011
  bit 1: set, basis[1] = 011 -> XOR: 011 ^ 011 = 000  (bit 1 eliminated)
  remainder = 0 -> 6 is in the span of {5, 3}, rank unchanged

Final basis:
  basis[2] = 101  (= 5)
  basis[1] = 011  (= 3)
  rank = 2
```

The key rule: when reducing, XOR the remainder with `basis[k]` to cancel the
leading bit `k`. Both have bit `k` set, so XOR clears it. Bits below `k` may
change, but bit `k` and higher are eliminated. The process terminates in at
most B steps because each step either clears the leading bit or stores the
vector and stops.

---

## Echelon Form After Multiple Inserts

After inserting a collection of values the non-zero slots form an upper-left
staircase pattern:

```
         leading bit position
           (one per row)
         62         0
          .         .
           \
  row 0:   [  v_a  ]   <- basis[a], leading bit = a
  row 1:      [v_b ]   <- basis[b], leading bit = b  (b < a)
  row 2:        [vc]   <- basis[c], leading bit = c  (c < b)

Empty slots have a 0 in the diagram.
```

No two rows share the same leading bit. This is exactly row echelon form.

---

## Membership Check: can_represent

To test whether `value` is in the span, apply the same reduction as insert
but without modifying the basis:

```
Reduce value by basis vectors top-down.
If remainder reaches 0 -> value is representable.
Otherwise -> value is not representable.

Example: can_represent(7 = 111) with basis[2]=101, basis[1]=011

  reduced = 111
  bit 2: set, basis[2]=101 -> XOR -> 111^101 = 010
  reduced = 010
  bit 1: bit 1 not set in 010, skip
  bit 0: not set, skip
  reduced = 010 != 0 -> false  (7 is not in the span)

Example: can_represent(6 = 110) with same basis

  reduced = 110
  bit 2: set, basis[2]=101 -> XOR -> 110^101 = 011
  reduced = 011
  bit 1: set, basis[1]=011 -> XOR -> 011^011 = 000
  reduced = 0 -> true  (6 = 5 XOR 3)
```

---

## Maximum XOR Query: Greedy From High to Low

To maximize `value XOR y` over all `y` in the span, sweep bits from high to
low. At each step, toggle `basis[k]` if it improves the running value.

Greedy is correct because bit `k` is worth more than the sum of all lower bits
combined: 2^k > 2^0 + 2^1 + ... + 2^(k-1). So a gain at bit `k` can never be
undone by losses at lower bits.

```
Query max_xor(x = 010) with basis[2]=101, basis[1]=011

  x = 010
  bit 2: candidate = 010 ^ 101 = 111
         111 > 010, so take it: x = 111
  bit 1: candidate = 111 ^ 011 = 100
         100 < 111, so keep:    x = 111
  bit 0: basis[0] = 0, candidate = 111 ^ 0 = 111, unchanged

  result = 111 = 7

Explanation: the optimal y is basis[2] = 101 = 5, giving 010 ^ 101 = 111.
```

Decision table at each step:

```
  x before   basis[k]   candidate = x ^ basis[k]   keep candidate?
  --------   --------   -------------------------   ---------------
  010        101        111                         yes (higher)
  111        011        100                         no  (lower)
```

`max_xor(0)` gives the largest XOR-combination of inserted values (the maximum
over all non-empty subsets, including single elements).

---

## Span Size and Rank

The span of a basis with rank `r` contains exactly `2^r` distinct values
(including 0, the empty XOR). Each independent bit doubles the reachable set.

```
rank = 0 -> span = {0}              (1 value)
rank = 1 -> span = {0, v}           (2 values)
rank = 2 -> span = {0, v, w, v^w}   (4 values)
rank = 3 -> ...                     (8 values)
```

---

## API Reference

```
XorBasis()              -> XorBasis
XorBasis::insert(x)          -> Bool      (true if rank increased)
XorBasis::can_represent(x)   -> Bool
XorBasis::max_xor(x)         -> Int64
XorBasis::rank()             -> Int
```

All values are `Int64`.

---

## Example: Insert and Membership

```mbt check
///|
test "xor basis membership" {
  let b = @xor_basis.XorBasis()
  let _ = b.insert(5L) // 101
  let _ = b.insert(3L) // 011

  // Span is {0, 3, 5, 6}
  debug_inspect(b.can_represent(0L), content="true")
  debug_inspect(b.can_represent(3L), content="true")
  debug_inspect(b.can_represent(5L), content="true")
  debug_inspect(b.can_represent(6L), content="true")
  debug_inspect(b.can_represent(1L), content="false")
}
```

---

## Example: Rank (Linear Independence)

```mbt check
///|
test "xor basis rank" {
  let b = @xor_basis.XorBasis()
  debug_inspect(b.rank(), content="0")
  debug_inspect(b.insert(5L), content="true")
  debug_inspect(b.rank(), content="1")
  debug_inspect(b.insert(3L), content="true")
  debug_inspect(b.rank(), content="2")
  // 6 = 5 XOR 3, so it does not increase rank
  debug_inspect(b.insert(6L), content="false")
  debug_inspect(b.rank(), content="2")
}
```

---

## Example: Maximum XOR

```mbt check
///|
test "xor basis max xor" {
  let b = @xor_basis.XorBasis()
  let _ = b.insert(8L)
  let _ = b.insert(5L)
  let _ = b.insert(10L)
  debug_inspect(b.max_xor(0L), content="15")
}
```

---

## Common Applications

```
Maximum XOR subarray (sliding or static window)
Maximum XOR pair in a set of numbers
Check linear independence of a set of bit vectors over GF(2)
Count distinct XOR values from a set
XOR cycle basis in graphs (minimum/maximum XOR cycle weight)
Competitive programming: XOR game problems
```

---

## Common Pitfalls

- Use `Int64` literals (`5L`, not `5`); the basis slots are `Array[Int64]`.
- Insert order does not affect the span; it only affects which specific vectors
  end up stored in which slots.
- `rank()` counts independent vectors inserted, not the total number of
  `insert` calls.
- `can_represent(0)` always returns `true` (the empty XOR is 0, always in span).
- Copying the basis requires copying both the `basis` array and the `size`
  field: `{ basis: b.basis.copy(), size: b.size }`.
