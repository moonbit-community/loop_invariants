// ============================================================================
// IMPLICIT TREAP - Sequence Operations
// ============================================================================
//
// Operations on the sequence represented by the treap:
//   - insert(pos, val): Insert at position
//   - delete(pos): Delete at position
//   - get(pos): Get value at position
//   - set(pos, val): Set value at position
//   - push_back/front: Append/prepend
//   - pop_back/front: Remove from end/beginning
//   - to_array/from_array: Convert to/from array

///|
/// Insert value at position pos.
///
/// ALGORITHM:
/// ```
///   1. Create new node with value
///   2. Split tree at position: [0,pos) and [pos,n)
///   3. Merge: [0,pos) + new_node + [pos,n)
///
///   Time: O(log n) expected
/// ```
///
/// VISUAL:
/// ```
///   insert([A,B,D,E], 2, C):
///
///   [A,B,D,E] → split(2) → [A,B] + [D,E]
///            → merge([A,B], C) → [A,B,C]
///            → merge([A,B,C], [D,E]) → [A,B,C,D,E]
/// ```
pub fn ImplicitTreap::insert(
  self : ImplicitTreap,
  pos : Int,
  val : Int64,
) -> Unit {
  let new_node = self.alloc_node(val)
  let (left, right) = self.split(self.root, pos)
  self.root = self.merge(self.merge(left, new_node), right)
}

///|
/// Delete element at position pos.
///
/// RETURNS: The deleted value, or None if position is out of bounds.
///
/// ALGORITHM:
/// ```
///   1. Split at pos: [0,pos) and [pos,n)
///   2. Split [pos,n) at 1: [pos] and [pos+1,n)
///   3. Save value from [pos]
///   4. Merge: [0,pos) + [pos+1,n)
///   5. Recycle the deleted node
///
///   Time: O(log n) expected
/// ```
pub fn ImplicitTreap::delete(self : ImplicitTreap, pos : Int) -> Int64? {
  if pos < 0 || pos >= self.size() {
    return None
  }
  let (left, mid_right) = self.split(self.root, pos)
  let (mid, right) = self.split(mid_right, 1)
  if mid < 0 {
    self.root = self.merge(left, right)
    return None
  }
  let val = self.nodes[mid].val
  self.free_list.push(mid) // Recycle node
  self.root = self.merge(left, right)
  Some(val)
}

///|
/// Get value at position pos.
///
/// ALGORITHM:
/// ```
///   Starting from root, navigate using implicit keys:
///   - If target < left_size: go left
///   - If target == left_size: found
///   - If target > left_size: go right, target -= left_size + 1
///
///   Time: O(log n) expected
/// ```
pub fn ImplicitTreap::get(self : ImplicitTreap, pos : Int) -> Int64? {
  if pos < 0 || pos >= self.size() {
    return None
  }
  for node = self.root, target = pos; node >= 0; {
    self.push_down(node)
    let left_size = self.get_size(self.nodes[node].left)
    if target < left_size {
      continue self.nodes[node].left, target
    } else if target == left_size {
      break Some(self.nodes[node].val)
    } else {
      continue self.nodes[node].right, target - left_size - 1
    }
  } nobreak {
    None
  } where {
    proof_invariant: node >= 0 && node < self.nodes.length(),
    proof_invariant: target >= 0 && target < self.get_size(node),
    reasoning: (
      #|SEARCH INVARIANT:
      #|  (node, target) describes the target position within the
      #|  subtree rooted at node.
      #|
      #|IMPLICIT KEY COMPUTATION:
      #|  - target < left_size: target is in left subtree
      #|  - target == left_size: current node is at target position
      #|  - target > left_size: target is in right subtree
      #|    (adjust target by left_size + 1)
      #|
      #|MAINTENANCE:
      #|  Each step descends one level, adjusting target appropriately.
      #|
      #|TERMINATION:
      #|  Tree has finite height; we find the node or reach null.
    ),
  }
}

///|
/// Set value at position pos.
pub fn ImplicitTreap::set(self : ImplicitTreap, pos : Int, val : Int64) -> Unit {
  if pos < 0 || pos >= self.size() {
    return
  }
  for node = self.root, target = pos; node >= 0; {
    self.push_down(node)
    let left_size = self.get_size(self.nodes[node].left)
    if target < left_size {
      continue self.nodes[node].left, target
    } else if target == left_size {
      self.nodes[node].val = val
      // Rebuild aggregates from this node up
      self.rebuild_aggregates(self.root)
      break
    } else {
      continue self.nodes[node].right, target - left_size - 1
    }
  } where {
    proof_invariant: node == -1 || (node >= 0 && node < self.nodes.length()),
    reasoning: (
      #|INVARIANT (implicit index walk):
      #|  target is the index within the subtree rooted at node.
      #|
      #|MAINTENANCE:
      #|  Navigate left or right based on left_size comparison.
      #|
      #|TERMINATION:
      #|  When target equals left_size, update and exit.
    ),
  }
}

///|
/// Build treap from array.
///
/// Creates a treap with elements in array order.
/// Each element is inserted at the end in sequence.
pub fn ImplicitTreap::from_array(arr : Array[Int64]) -> ImplicitTreap {
  let treap = ImplicitTreap::new()
  for i, value in arr {
    treap.insert(i, value)
  }
  treap
}

///|
/// Convert treap to array.
///
/// Performs in-order traversal to extract elements in position order.
pub fn ImplicitTreap::to_array(self : ImplicitTreap) -> Array[Int64] {
  let result : Array[Int64] = []
  fn inorder(treap : ImplicitTreap, node : Int, result : Array[Int64]) -> Unit {
    if node < 0 {
      return
    }
    treap.push_down(node)
    inorder(treap, treap.nodes[node].left, result)
    result.push(treap.nodes[node].val)
    inorder(treap, treap.nodes[node].right, result)
  }

  inorder(self, self.root, result)
  result
}

///|
/// Append value at the end.
pub fn ImplicitTreap::push_back(self : ImplicitTreap, val : Int64) -> Unit {
  self.insert(self.size(), val)
}

///|
/// Prepend value at the beginning.
pub fn ImplicitTreap::push_front(self : ImplicitTreap, val : Int64) -> Unit {
  self.insert(0, val)
}

///|
/// Remove and return the last element.
pub fn ImplicitTreap::pop_back(self : ImplicitTreap) -> Int64? {
  if self.size() == 0 {
    return None
  }
  self.delete(self.size() - 1)
}

///|
/// Remove and return the first element.
pub fn ImplicitTreap::pop_front(self : ImplicitTreap) -> Int64? {
  if self.size() == 0 {
    return None
  }
  self.delete(0)
}
