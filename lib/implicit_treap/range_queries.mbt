// ============================================================================
// IMPLICIT TREAP - Range Queries
// ============================================================================
//
// Range operations on the sequence:
//   - range_sum(l, r): Sum of elements in [l, r)
//   - range_min(l, r): Minimum in [l, r)
//   - range_max(l, r): Maximum in [l, r)
//   - reverse(l, r): Reverse elements in [l, r)
//
// All operations use split/merge pattern:
//   1. Split to isolate range [l, r)
//   2. Query or modify the isolated range
//   3. Merge back together
//
// TIME: O(log n) expected for each operation

///|
/// Query sum in range [l, r).
///
/// ALGORITHM:
/// ```
///   1. Split into: [0,l) + [l,r) + [r,n)
///   2. Return sum of middle part (stored in root's aggregate)
///   3. Merge all three parts back
/// ```
///
/// VISUAL:
/// ```
///   range_sum([A,B,C,D,E], 1, 4):
///
///   Split: [A] + [B,C,D] + [E]
///   Query: sum([B,C,D]) = B + C + D
///   Merge: [A,B,C,D,E] (restored)
/// ```
pub fn ImplicitTreap::range_sum(
  self : ImplicitTreap,
  l : Int,
  r : Int,
) -> Int64 {
  if l >= r || l < 0 || r > self.size() {
    return 0L
  }

  // Split into [0, l) + [l, r) + [r, n)
  let (left, mid_right) = self.split(self.root, l)
  let (mid, right) = self.split(mid_right, r - l)

  // Query middle part
  let result = self.get_sum(mid)

  // Merge back
  self.root = self.merge(left, self.merge(mid, right))
  result
}

///|
/// Query minimum in range [l, r).
pub fn ImplicitTreap::range_min(
  self : ImplicitTreap,
  l : Int,
  r : Int,
) -> Int64? {
  if l >= r || l < 0 || r > self.size() {
    return None
  }
  let (left, mid_right) = self.split(self.root, l)
  let (mid, right) = self.split(mid_right, r - l)
  let result = if mid >= 0 { Some(self.nodes[mid].min_val) } else { None }
  self.root = self.merge(left, self.merge(mid, right))
  result
}

///|
/// Query maximum in range [l, r).
pub fn ImplicitTreap::range_max(
  self : ImplicitTreap,
  l : Int,
  r : Int,
) -> Int64? {
  if l >= r || l < 0 || r > self.size() {
    return None
  }
  let (left, mid_right) = self.split(self.root, l)
  let (mid, right) = self.split(mid_right, r - l)
  let result = if mid >= 0 { Some(self.nodes[mid].max_val) } else { None }
  self.root = self.merge(left, self.merge(mid, right))
  result
}

///|
/// Reverse range [l, r).
///
/// LAZY REVERSAL:
/// ```
///   Instead of actually swapping all elements, we set a lazy flag
///   on the isolated subtree's root. The actual reversal happens
///   during push_down when we traverse the tree later.
///
///   This enables O(log n) reversal regardless of range size.
/// ```
///
/// ALGORITHM:
/// ```
///   1. Split to isolate [l, r)
///   2. Toggle reversal flag on root of [l, r)
///   3. Merge back
/// ```
///
/// EXAMPLE:
/// ```
///   reverse([1,2,3,4,5], 1, 4):
///
///   Before: [1, 2, 3, 4, 5]
///   After:  [1, 4, 3, 2, 5]  (indices 1-3 reversed)
/// ```
pub fn ImplicitTreap::reverse(self : ImplicitTreap, l : Int, r : Int) -> Unit {
  if l >= r || l < 0 || r > self.size() {
    return
  }
  let (left, mid_right) = self.split(self.root, l)
  let (mid, right) = self.split(mid_right, r - l)

  // Toggle reversal flag (lazy)
  if mid >= 0 {
    self.nodes[mid].rev = !self.nodes[mid].rev
  }
  self.root = self.merge(left, self.merge(mid, right))
}
