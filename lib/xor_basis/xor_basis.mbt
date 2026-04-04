// ============================================================================
// XOR LINEAR BASIS - Maintain a basis for xor combinations
// ============================================================================
//
// A xor basis stores a set of vectors such that every inserted value can be
// represented as xor of basis vectors. It supports:
// - inserting values
// - checking representability
// - maximizing xor with a given value
//
// THEORY (GF(2) linear algebra):
// Treat each Int64 as a 63-bit vector over GF(2) (the field with two elements,
// where addition is XOR and multiplication is AND). The xor basis is a set of
// linearly independent vectors that spans the same subspace as all inserted
// values.
//
// THE BASIS ARRAY:
// basis[k] holds either 0 (slot empty) or a value whose highest set bit is k.
// At most one vector occupies each bit position. This is row echelon form:
//
//   bit:  62 ... 5  4  3  2  1  0
//   slot:  0 ... 0  0  v  w  0  0
//                       |  |
//                 v has bit 4 set as leading bit
//                    w has bit 3 set as leading bit
//
// GAUSSIAN ELIMINATION (over GF(2)):
// To insert x, reduce it by existing basis vectors from the highest bit down.
// If x reduces to 0, it is already in the span (linearly dependent).
// If x reduces to a nonzero remainder, store it in the slot for its leading bit.
//
// GREEDY MAX XOR:
// To maximize value ^ y over all y in span, sweep from highest to lowest bit.
// At each bit k, if toggling basis[k] increases the running value, toggle it.
// Higher bits dominate lower ones, so greedy is optimal.
//
// INVARIANTS:
// 1. basis[k] == 0  OR  bit k is the highest set bit of basis[k]
// 2. size == number of nonzero entries in basis[]
// 3. The span of nonzero basis vectors equals the span of all inserted values
//
// TIME COMPLEXITY: O(B) per operation, where B is bit width (<= 63)
// SPACE COMPLEXITY: O(B)

///|
const MAX_BITS : Int = 63

///|
/// An XOR linear basis over 63-bit integers.
///
/// The basis maintains a set of linearly independent `Int64` vectors under
/// XOR (GF(2) arithmetic). It can answer in O(B) time:
/// - whether a value is XOR-representable by the inserted set,
/// - the maximum XOR achievable with any value from the inserted set,
/// - the number of linearly independent vectors inserted (the rank).
///
/// Internally the basis is stored in echelon form: `basis[k]` is either 0
/// (slot unused) or a value whose highest set bit is exactly bit `k`. At most
/// one vector occupies each bit position, mirroring Gaussian elimination.
///
/// ```
/// bit slot:  62  ...  4   3   2   1   0
/// contents:   0  ...  0  v3   0  v1   0
///                         |        |
///                  leading bit 3   leading bit 1
/// ```
///
/// The span of the stored vectors equals the span of all inserted values.
pub struct XorBasis {
  basis : Array[Int64]
  mut size : Int
}

///|
/// Creates a new, empty `XorBasis` with all bit slots set to zero and rank 0.
///
/// Time complexity: O(B) to allocate the slot array (B = 63).
///
/// Example:
/// ```
/// let b = XorBasis::new()
/// assert_eq!(b.rank(), 0)
/// ```
pub fn XorBasis::new() -> XorBasis {
  { basis: Array::make(MAX_BITS + 1, 0L), size: 0 }
}

///|
/// Inserts `value` into the basis using Gaussian elimination over GF(2).
///
/// Returns `true` if `value` is linearly independent of the current basis
/// (i.e. it is not representable as an XOR of already-inserted values) and
/// the rank increases by one. Returns `false` if `value` lies in the current
/// span and the basis is unchanged.
///
/// Algorithm:
/// 1. Find the highest set bit `k` of the running remainder.
/// 2. If `basis[k]` is occupied, XOR the remainder with `basis[k]` to
///    eliminate bit `k` (the leading bits cancel because both have bit `k` set).
/// 3. If `basis[k]` is empty, store the remainder there and return `true`.
/// 4. If the remainder reaches 0, return `false`.
///
/// Elimination trace for value = 6 (110) with basis[2] = 5 (101), basis[1] = 3 (011):
/// ```
/// remainder = 110  (bit 2 is leading)
/// basis[2]  = 101  -> XOR -> 011  (bit 2 eliminated)
/// remainder = 011  (bit 1 is leading)
/// basis[1]  = 011  -> XOR -> 000  (bit 1 eliminated)
/// remainder = 0    -> return false  (6 is in span of {5, 3})
/// ```
///
/// Time complexity: O(B).
pub fn XorBasis::insert(self : XorBasis, value : Int64) -> Bool {
  for bit = MAX_BITS, x = value; bit >= 0; {
    if ((x >> bit) & 1L) == 0L {
      continue bit - 1, x
    }
    if self.basis[bit] == 0L {
      self.basis[bit] = x
      self.size = self.size + 1
      break true
    }
    continue bit - 1, x ^ self.basis[bit]
  } nobreak {
    false
  }
}

///|
/// Returns `true` if `value` can be expressed as an XOR of some subset of
/// the inserted values; returns `false` otherwise.
///
/// Equivalently, reduces `value` by the basis from the highest bit downward.
/// If all bits are eliminated (remainder reaches 0), the value is in the span.
///
/// Reduction trace for value = 6 (110) with basis[2] = 5 (101), basis[1] = 3 (011):
/// ```
/// reduced = 110  (bit 2 set, basis[2] = 101 exists) -> XOR -> 011
/// reduced = 011  (bit 1 set, basis[1] = 011 exists) -> XOR -> 000
/// reduced = 0    -> true
/// ```
///
/// Reduction trace for value = 1 (001) with same basis:
/// ```
/// reduced = 001  (bit 2 not set, skip)
///           001  (bit 1 not set, skip)
///           001  (bit 0 not set, skip)
/// reduced != 0   -> false
/// ```
///
/// Time complexity: O(B).
pub fn XorBasis::can_represent(self : XorBasis, value : Int64) -> Bool {
  for bit = MAX_BITS, reduced = value; bit >= 0; {
    let new_reduced = if self.basis[bit] != 0L && ((reduced >> bit) & 1L) != 0L {
      reduced ^ self.basis[bit]
    } else {
      reduced
    }
    continue bit - 1, new_reduced
  } nobreak {
    reduced == 0L
  } where {
    proof_invariant: bit >= -1 && bit <= MAX_BITS,
    proof_reasoning: (
      #|INVARIANT (representation reduction):
      #|reduced equals value xor'd with basis vectors whose leading bits are
      #|strictly greater than bit, so higher bits are eliminated when possible.
      #|MAINTENANCE:
      #|If the current bit is set and a basis vector exists, xor it out.
      #|TERMINATION:
      #|At bit = -1, reduced is fully eliminated; reduced == 0 iff representable.
    ),
  }
}

///|
/// Returns the maximum value of `value XOR y` over all `y` representable by
/// the current basis.
///
/// Uses a greedy sweep from the highest bit to the lowest. At each bit `k`,
/// toggling `basis[k]` into the running value can only raise or maintain the
/// result, because bit `k` outweighs the sum of all lower bits.
///
/// Greedy trace for value = 2 (010) with basis[2] = 5 (101), basis[1] = 3 (011):
/// ```
/// x = 010
/// bit 2: candidate = 010 ^ 101 = 111  (111 > 010) -> take it, x = 111
/// bit 1: candidate = 111 ^ 011 = 100  (100 < 111) -> keep x  = 111
/// bit 0: basis[0] = 0, skip
/// result = 111 = 7
/// ```
///
/// Note: `max_xor(0)` returns the largest value representable by the basis
/// alone (the maximum XOR of any subset of inserted values).
///
/// Time complexity: O(B).
pub fn XorBasis::max_xor(self : XorBasis, value : Int64) -> Int64 {
  for bit = MAX_BITS, x = value; bit >= 0; {
    let candidate = x ^ self.basis[bit]
    continue bit - 1, if candidate > x { candidate } else { x }
  } nobreak {
    x
  } where {
    proof_invariant: bit >= -1 && bit <= MAX_BITS,
    proof_reasoning: (
      #|INVARIANT (greedy max):
      #|x is the maximum possible value considering basis vectors with leading
      #|bits greater than the current bit.
      #|MAINTENANCE:
      #|If toggling basis[bit] increases x, take it to improve higher bits.
      #|TERMINATION:
      #|At bit = -1, x is the maximum achievable xor value (returned via else).
    ),
  }
}

///|
/// Returns the rank of the basis: the number of linearly independent vectors
/// currently stored.
///
/// If `r = rank()`, the basis spans exactly `2^r` distinct values (including 0).
/// The rank equals the number of `insert` calls that returned `true`.
///
/// Time complexity: O(1).
pub fn XorBasis::rank(self : XorBasis) -> Int {
  self.size
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "xor basis insert and rank" {
  let b = XorBasis::new()
  inspect(b.insert(1L), content="true")
  inspect(b.insert(2L), content="true")
  inspect(b.insert(3L), content="false")
  inspect(b.rank(), content="2")
}

///|
test "xor basis represent" {
  let b = XorBasis::new()
  let _ = b.insert(5L) // 101
  let _ = b.insert(6L) // 110
  inspect(b.max_xor(0L), content="6")
  inspect(b.can_represent(3L), content="true")
  inspect(b.can_represent(5L), content="true")
  inspect(b.can_represent(6L), content="true")
  inspect(b.can_represent(7L), content="false")
  inspect(b.can_represent(8L), content="false")
}

///|
test "xor basis dependent insert" {
  let b = XorBasis::new()
  let _ = b.insert(5L)
  let _ = b.insert(6L)
  inspect(b.insert(3L), content="false")
}

///|
test "xor basis copy insert" {
  let b = XorBasis::new()
  let _ = b.insert(5L)
  let _ = b.insert(6L)
  let copy = { basis: b.basis.copy(), size: b.size }
  inspect(copy.basis[2], content="5")
  inspect(copy.insert(3L), content="false")
}

///|
test "xor basis max" {
  let b = XorBasis::new()
  let _ = b.insert(8L)
  let _ = b.insert(5L)
  let _ = b.insert(10L)
  inspect(b.max_xor(0L), content="15")
  inspect(b.max_xor(7L), content="15")
}
