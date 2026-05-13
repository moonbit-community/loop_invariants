// ============================================================================
// IMPLICIT TREAP - Tests
// ============================================================================

///|
/// Test basic insert and get operations.
test "implicit treap basic" {
  let treap = @implicit_treap.ImplicitTreap::@implicit_treap.ImplicitTreap()

  // Insert elements: [10, 20, 30]
  treap.insert(0, 10L)
  treap.insert(1, 20L)
  treap.insert(2, 30L)
  inspect(treap.size(), content="3")
  debug_inspect(treap.get(0), content="Some(10)")
  debug_inspect(treap.get(1), content="Some(20)")
  debug_inspect(treap.get(2), content="Some(30)")
  debug_inspect(treap.get(3), content="None")
}

///|
/// Test insert at specific position.
///
/// SEQUENCE:
/// ```
///   Start:  [10, 30]
///   Insert: 20 at position 1
///   Result: [10, 20, 30]
/// ```
test "implicit treap insert at position" {
  let treap = @implicit_treap.ImplicitTreap::@implicit_treap.ImplicitTreap()

  // Build [10, 30]
  treap.insert(0, 10L)
  treap.insert(1, 30L)

  // Insert 20 at position 1: [10, 20, 30]
  treap.insert(1, 20L)
  inspect(treap.to_array(), content="[10, 20, 30]")
}

///|
/// Test delete operation.
///
/// SEQUENCE:
/// ```
///   Start:   [10, 20, 30, 40, 50]
///   Delete:  position 2 (value 30)
///   Result:  [10, 20, 40, 50]
///   Delete:  position 0 (value 10)
///   Result:  [20, 40, 50]
/// ```
test "implicit treap delete" {
  let treap = @implicit_treap.ImplicitTreap::from_array([
    10L, 20L, 30L, 40L, 50L,
  ])
  inspect(treap.size(), content="5")

  // Delete at position 2 (value 30)
  let deleted = treap.delete(2)
  debug_inspect(deleted, content="Some(30)")
  inspect(treap.to_array(), content="[10, 20, 40, 50]")

  // Delete at position 0 (value 10)
  let deleted2 = treap.delete(0)
  debug_inspect(deleted2, content="Some(10)")
  inspect(treap.to_array(), content="[20, 40, 50]")
}

///|
/// Test range sum queries.
///
/// SEQUENCE: [1, 2, 3, 4, 5]
/// ```
///   range_sum(0, 5) = 1+2+3+4+5 = 15
///   range_sum(1, 4) = 2+3+4 = 9
///   range_sum(2, 3) = 3
///   range_sum(3, 3) = 0 (empty range)
/// ```
test "implicit treap range sum" {
  let treap = @implicit_treap.ImplicitTreap::from_array([1L, 2L, 3L, 4L, 5L])

  // Sum of full range
  inspect(treap.range_sum(0, 5), content="15")

  // Sum of [1, 4) = 2+3+4 = 9
  inspect(treap.range_sum(1, 4), content="9")

  // Sum of single element
  inspect(treap.range_sum(2, 3), content="3")

  // Empty range
  inspect(treap.range_sum(3, 3), content="0")
}

///|
/// Test range min/max queries.
///
/// SEQUENCE: [5, 2, 8, 1, 9]
test "implicit treap range min max" {
  let treap = @implicit_treap.ImplicitTreap::from_array([5L, 2L, 8L, 1L, 9L])
  debug_inspect(treap.range_min(0, 5), content="Some(1)")
  debug_inspect(treap.range_max(0, 5), content="Some(9)")

  // Range [0, 3) = [5, 2, 8]
  debug_inspect(treap.range_min(0, 3), content="Some(2)")
  debug_inspect(treap.range_max(0, 3), content="Some(8)")

  // Range [2, 5) = [8, 1, 9]
  debug_inspect(treap.range_min(2, 5), content="Some(1)")
  debug_inspect(treap.range_max(2, 5), content="Some(9)")
}

///|
/// Test range reverse operation.
///
/// SEQUENCE: [1, 2, 3, 4, 5]
/// ```
///   reverse(1, 4): [1, 4, 3, 2, 5]
///   reverse(0, 5): [5, 2, 3, 4, 1]
/// ```
test "implicit treap reverse" {
  let treap = @implicit_treap.ImplicitTreap::from_array([1L, 2L, 3L, 4L, 5L])

  // Reverse [1, 4): [1, 4, 3, 2, 5]
  treap.reverse(1, 4)
  inspect(treap.to_array(), content="[1, 4, 3, 2, 5]")

  // Reverse all: [5, 2, 3, 4, 1]
  treap.reverse(0, 5)
  inspect(treap.to_array(), content="[5, 2, 3, 4, 1]")
}

///|
/// Test set operation and aggregate updates.
test "implicit treap set" {
  let treap = @implicit_treap.ImplicitTreap::from_array([1L, 2L, 3L, 4L, 5L])
  treap.set(2, 100L)
  debug_inspect(treap.get(2), content="Some(100)")
  inspect(treap.to_array(), content="[1, 2, 100, 4, 5]")

  // Sum should update
  inspect(treap.range_sum(0, 5), content="112") // 1+2+100+4+5
}

///|
/// Test push/pop operations (deque behavior).
test "implicit treap push pop" {
  let treap = @implicit_treap.ImplicitTreap::@implicit_treap.ImplicitTreap()
  treap.push_back(1L)
  treap.push_back(2L)
  treap.push_front(0L)
  // Now: [0, 1, 2]
  inspect(treap.to_array(), content="[0, 1, 2]")
  debug_inspect(treap.pop_back(), content="Some(2)")
  debug_inspect(treap.pop_front(), content="Some(0)")
  inspect(treap.to_array(), content="[1]")
}

///|
/// Stress test with larger sequence.
test "implicit treap stress" {
  let treap = @implicit_treap.ImplicitTreap::@implicit_treap.ImplicitTreap()

  // Build sequence 0..99
  for i in 0..<100 {
    treap.push_back(i.to_int64())
  }
  inspect(treap.size(), content="100")
  inspect(treap.range_sum(0, 100), content="4950") // Sum 0..99

  // Reverse first half
  treap.reverse(0, 50)
  debug_inspect(treap.get(0), content="Some(49)")
  debug_inspect(treap.get(49), content="Some(0)")

  // Sum should be unchanged
  inspect(treap.range_sum(0, 100), content="4950")
}

///|
/// Test multiple consecutive reverses.
///
/// SEQUENCE: [1, 2, 3, 4, 5, 6]
test "implicit treap multiple reverses" {
  let treap = @implicit_treap.ImplicitTreap::from_array([1L, 2L, 3L, 4L, 5L, 6L])

  // Reverse [0, 3): [3, 2, 1, 4, 5, 6]
  treap.reverse(0, 3)
  inspect(treap.to_array(), content="[3, 2, 1, 4, 5, 6]")

  // Reverse [3, 6): [3, 2, 1, 6, 5, 4]
  treap.reverse(3, 6)
  inspect(treap.to_array(), content="[3, 2, 1, 6, 5, 4]")

  // Reverse all: [4, 5, 6, 1, 2, 3]
  treap.reverse(0, 6)
  inspect(treap.to_array(), content="[4, 5, 6, 1, 2, 3]")
}

///|
/// Test rope-like operations (concatenation and splitting).
test "implicit treap rope operations" {
  // Simulate rope: concatenate two sequences
  let treap1 = @implicit_treap.ImplicitTreap::from_array([1L, 2L, 3L])
  let treap2 = @implicit_treap.ImplicitTreap::from_array([4L, 5L, 6L])

  // Manual concatenation by inserting elements
  for i in 0..<treap2.size() {
    match treap2.get(i) {
      Some(v) => treap1.push_back(v)
      None => ()
    }
  }
  inspect(treap1.to_array(), content="[1, 2, 3, 4, 5, 6]")

  // Split simulation: delete elements
  for _ in 0..<3 {
    let _ = treap1.pop_front()
  }
  inspect(treap1.to_array(), content="[4, 5, 6]")
}
