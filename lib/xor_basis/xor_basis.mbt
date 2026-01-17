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
// TIME COMPLEXITY: O(B) per operation, where B is bit width (<= 63)
// SPACE COMPLEXITY: O(B)

///|
const MAX_BITS : Int = 63

///|
pub struct XorBasis {
  basis : Array[Int64]
  mut size : Int
}

///|
pub fn XorBasis::new() -> XorBasis {
  { basis: Array::make(MAX_BITS + 1, 0L), size: 0 }
}

///|
/// Insert a value into the basis. Returns true if it increases rank.
pub fn XorBasis::insert(self : XorBasis, value : Int64) -> Bool {
  let mut x = value
  for bit in MAX_BITS >=.. 0 {
    if ((x >> bit) & 1L) == 0L {
      continue
    }
    if self.basis[bit] == 0L {
      self.basis[bit] = x
      self.size = self.size + 1
      return true
    }
    x = x ^ self.basis[bit]
  }
  false
}

///|
/// Check if a value can be represented by the current basis.
pub fn XorBasis::can_represent(self : XorBasis, value : Int64) -> Bool {
  for bit = MAX_BITS, reduced = value; bit >= 0; {
    let new_reduced = if self.basis[bit] != 0L && ((reduced >> bit) & 1L) != 0L {
      reduced ^ self.basis[bit]
    } else {
      reduced
    }
    continue bit - 1, new_reduced
  } else {
    reduced == 0L
  } where {
    invariant: bit >= -1 && bit <= MAX_BITS,
    reasoning: (
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
/// Maximize (value xor y) over all y representable by the basis.
pub fn XorBasis::max_xor(self : XorBasis, value : Int64) -> Int64 {
  for bit = MAX_BITS, x = value; bit >= 0; {
    let candidate = x ^ self.basis[bit]
    continue bit - 1, if candidate > x { candidate } else { x }
  } else {
    x
  } where {
    invariant: bit >= -1 && bit <= MAX_BITS,
    reasoning: (
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
