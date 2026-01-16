// ============================================================================
// IMPLICIT TREAP - Helper Functions
// ============================================================================
//
// Internal utilities for treap operations:
//   - Random priority generation
//   - Node allocation
//   - Subtree aggregate queries
//   - Aggregate updates
//   - Lazy reversal propagation

///|
/// Generate random priority using linear congruential generator.
///
/// PARAMETERS:
/// ```
///   a = 1103515245
///   c = 12345
///   m = 2^31 - 1 = 2147483647
///
///   X_{n+1} = (a * X_n + c) mod m
/// ```
///
/// WHY RANDOM PRIORITIES?
/// ```
///   Random priorities ensure the treap is balanced in expectation.
///   Expected height = O(log n).
///   Any sequence of insert/delete operations maintains balance
///   without explicit rebalancing.
/// ```
fn ImplicitTreap::random_priority(self : ImplicitTreap) -> Int {
  self.rand_state = (self.rand_state * 1103515245 + 12345) % 2147483647
  if self.rand_state < 0 {
    -self.rand_state
  } else {
    self.rand_state
  }
}

///|
/// Allocate a new node with given value.
///
/// MEMORY STRATEGY:
/// ```
///   1. If free_list has recycled indices, reuse one
///   2. Otherwise, append to nodes array
///
///   This avoids memory fragmentation and allows
///   O(1) amortized allocation.
/// ```
fn ImplicitTreap::alloc_node(self : ImplicitTreap, val : Int64) -> Int {
  let priority = self.random_priority()
  if self.free_list.pop() is Some(idx) {
    self.nodes[idx] = {
      val,
      priority,
      size: 1,
      sum: val,
      min_val: val,
      max_val: val,
      rev: false,
      left: -1,
      right: -1,
    }
    idx
  } else {
    let idx = self.nodes.length()
    self.nodes.push({
      val,
      priority,
      size: 1,
      sum: val,
      min_val: val,
      max_val: val,
      rev: false,
      left: -1,
      right: -1,
    })
    idx
  }
}

///|
/// Get size of subtree (handles -1 for null).
fn ImplicitTreap::get_size(self : ImplicitTreap, node : Int) -> Int {
  if node < 0 {
    0
  } else {
    self.nodes[node].size
  }
}

///|
/// Get sum of subtree values (returns 0 for null).
fn ImplicitTreap::get_sum(self : ImplicitTreap, node : Int) -> Int64 {
  if node < 0 {
    0L
  } else {
    self.nodes[node].sum
  }
}

///|
/// Get minimum value in subtree (returns MAX_INT64 for null).
fn ImplicitTreap::get_min(self : ImplicitTreap, node : Int) -> Int64 {
  if node < 0 {
    9223372036854775807L // Int64 max
  } else {
    self.nodes[node].min_val
  }
}

///|
/// Get maximum value in subtree (returns MIN_INT64 for null).
fn ImplicitTreap::get_max(self : ImplicitTreap, node : Int) -> Int64 {
  if node < 0 {
    -9223372036854775807L // Int64 min (approximately)
  } else {
    self.nodes[node].max_val
  }
}

///|
/// Update node's aggregate values based on children.
///
/// AGGREGATES:
/// ```
///   size    = size(left) + size(right) + 1
///   sum     = sum(left) + sum(right) + val
///   min_val = min(min(left), val, min(right))
///   max_val = max(max(left), val, max(right))
/// ```
///
/// CALL AFTER:
/// ```
///   - Any structural change (rotation, split, merge)
///   - Value update
///   - Child pointer modification
/// ```
fn ImplicitTreap::update(self : ImplicitTreap, node : Int) -> Unit {
  if node < 0 {
    return
  }
  let left = self.nodes[node].left
  let right = self.nodes[node].right
  let val = self.nodes[node].val

  // Update size
  self.nodes[node].size = self.get_size(left) + self.get_size(right) + 1

  // Update sum
  self.nodes[node].sum = self.get_sum(left) + self.get_sum(right) + val

  // Update min
  let left_min = self.get_min(left)
  let right_min = self.get_min(right)
  let min1 = if val < left_min { val } else { left_min }
  self.nodes[node].min_val = if min1 < right_min { min1 } else { right_min }

  // Update max
  let left_max = self.get_max(left)
  let right_max = self.get_max(right)
  let max1 = if val > left_max { val } else { left_max }
  self.nodes[node].max_val = if max1 > right_max { max1 } else { right_max }
}

///|
/// Push down lazy reversal flag.
///
/// LAZY REVERSAL:
/// ```
///   Instead of reversing an entire subtree immediately,
///   we set a flag and propagate it lazily during traversal.
///
///   When rev flag is set:
///   1. Swap left and right children
///   2. Toggle rev flag on both children
///   3. Clear our own rev flag
///
///   This enables O(log n) range reversal.
/// ```
fn ImplicitTreap::push_down(self : ImplicitTreap, node : Int) -> Unit {
  if node < 0 || not(self.nodes[node].rev) {
    return
  }

  // Swap children
  let tmp = self.nodes[node].left
  self.nodes[node].left = self.nodes[node].right
  self.nodes[node].right = tmp

  // Propagate reversal to children
  let left = self.nodes[node].left
  let right = self.nodes[node].right
  if left >= 0 {
    self.nodes[left].rev = not(self.nodes[left].rev)
  }
  if right >= 0 {
    self.nodes[right].rev = not(self.nodes[right].rev)
  }
  self.nodes[node].rev = false
}

///|
/// Helper to rebuild aggregates after point update.
///
/// Note: This is a simple but inefficient approach.
/// A better implementation would track the path and update only ancestors.
fn ImplicitTreap::rebuild_aggregates(self : ImplicitTreap, node : Int) -> Unit {
  if node < 0 {
    return
  }
  self.rebuild_aggregates(self.nodes[node].left)
  self.rebuild_aggregates(self.nodes[node].right)
  self.update(node)
}
