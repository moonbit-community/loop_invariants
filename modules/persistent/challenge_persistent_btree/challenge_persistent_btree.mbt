// ============================================================================
// Challenge: Persistent B-Tree (min degree 2)
// Nodes hold 1-3 keys, path-copying insertion with splits
// ============================================================================

///|
struct BNode[T] {
  keys : Array[T]
  children : Array[BNode[T]]
} derive(Debug)

///|
/// A persistent B-tree of minimum degree 2, storing keys of type `T`.
///
/// Each node holds 1 to 3 keys and (for internal nodes) one more child
/// than keys; insertions that overflow a node trigger a split that
/// promotes the median to the parent, keeping all leaves at the same
/// depth. Search and insert both run in `O(log n)`; `insert` copies only
/// the `O(log n)` nodes on the inserted path, so prior versions remain
/// valid. See `empty`, `insert`, `contains`, `size`, and `from_array`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let t = @challenge_persistent_btree.from_array([5, 2, 8, 1, 3, 7])
///   @debug.assert_eq(@challenge_persistent_btree.contains(t, 3), true)
///   @debug.assert_eq(@challenge_persistent_btree.contains(t, 4), false)
///   @debug.assert_eq(@challenge_persistent_btree.size(t), 6)
/// }
/// ```
pub enum Tree[T] {
  Empty
  Node(node~ : BNode[T])
} derive(Debug)

///|
enum InsertResult[T] {
  Done(node~ : BNode[T])
  Split(key~ : T, left~ : BNode[T], right~ : BNode[T])
} derive(Debug)

///|
fn[T] is_leaf(node : BNode[T]) -> Bool {
  node.children.length() == 0
}

///|
fn[T] node_size(node : BNode[T]) -> Int {
  if is_leaf(node) {
    node.keys.length()
  } else {
    for child in node.children; sum = node.keys.length() {
      continue sum + node_size(child)
    } nobreak {
      sum
    }
  }
}

///|
fn[T] tree_size(t : Tree[T]) -> Int {
  match t {
    Empty => 0
    Node(node=n) => node_size(n)
  }
}

///|
fn[T] insert_key(keys : Array[T], pos : Int, key : T) -> Array[T] {
  let out = Array::new()
  for i, item in keys {
    if i == pos {
      out.push(key)
    }
    out.push(item)
  }
  if pos >= keys.length() {
    out.push(key)
  }
  out
}

///|
fn[T] insert_children(
  children : Array[BNode[T]],
  pos : Int,
  left : BNode[T],
  right : BNode[T],
) -> Array[BNode[T]] {
  let out = Array::new()
  for i, child in children {
    if i == pos {
      out.push(left)
      out.push(right)
    } else {
      out.push(child)
    }
  }
  if pos >= children.length() {
    out.push(left)
    out.push(right)
  }
  out
}

///|
fn[T : Compare] find_pos(keys : Array[T], key : T) -> (Int, Bool) {
  for i = 0 {
    if i >= keys.length() {
      break (keys.length(), false)
    } else if key < keys[i] {
      break (i, false)
    } else if keys[i] < key {
      continue i + 1
    } else {
      break (i, true)
    }
  } where {
    proof_invariant: i >= 0 && i <= keys.length(),
    proof_reasoning: (
      #|INVARIANT (Find position):
      #|keys[0..i) are strictly less than key.
      #|MAINTENANCE:
      #|Advance while key is greater than keys[i].
      #|TERMINATION:
      #|Return the first index where key should be placed.
    ),
  }
}

///|
fn[T] split_node(
  keys : Array[T],
  children : Array[BNode[T]],
) -> (T, BNode[T], BNode[T]) {
  let promote = keys[2]
  let left_keys = keys[0:2].to_owned()
  let right_keys = keys[3:4].to_owned()
  let left_children = if children.length() == 0 {
    []
  } else {
    children[0:3].to_owned()
  }
  let right_children = if children.length() == 0 {
    []
  } else {
    children[3:5].to_owned()
  }
  let left = { keys: left_keys, children: left_children }
  let right = { keys: right_keys, children: right_children }
  (promote, left, right)
}

///|
fn[T : Compare] insert_node(node : BNode[T], key : T) -> InsertResult[T] {
  let (pos, exists) = find_pos(node.keys, key)
  if exists {
    Done(node~)
  } else if is_leaf(node) {
    let new_keys = insert_key(node.keys, pos, key)
    if new_keys.length() <= 3 {
      Done(node={ keys: new_keys, children: [] })
    } else {
      let (promote, left, right) = split_node(new_keys, [])
      Split(key=promote, left~, right~)
    }
  } else {
    let child = node.children[pos]
    match insert_node(child, key) {
      Done(node=updated_child) => {
        let new_children = node.children.copy()
        new_children[pos] = updated_child
        Done(node={ keys: node.keys, children: new_children })
      }
      Split(key=pk, left=pl, right=pr) => {
        let new_keys = insert_key(node.keys, pos, pk)
        let new_children = insert_children(node.children, pos, pl, pr)
        if new_keys.length() <= 3 {
          Done(node={ keys: new_keys, children: new_children })
        } else {
          let (promote, left, right) = split_node(new_keys, new_children)
          Split(key=promote, left~, right~)
        }
      }
    }
  }
}

///|
/// Create an empty B-tree.
pub fn[T] empty() -> Tree[T] {
  Empty
}

///|
/// Return the number of keys in the tree.
pub fn[T] size(t : Tree[T]) -> Int {
  tree_size(t)
}

///|
/// Insert key and return the new tree.
pub fn[T : Compare] insert(t : Tree[T], key : T) -> Tree[T] {
  match t {
    Empty => Node(node={ keys: [key], children: [] })
    Node(node=n) =>
      match insert_node(n, key) {
        Done(node=done) => Node(node=done)
        Split(key=pk, left=pl, right=pr) =>
          Node(node={ keys: [pk], children: [pl, pr] })
      }
  }
}

///|
/// Check whether a key exists in the tree.
pub fn[T : Compare] contains(t : Tree[T], key : T) -> Bool {
  match t {
    Empty => false
    Node(node=n) => {
      let (pos, exists) = find_pos(n.keys, key)
      if exists {
        true
      } else if is_leaf(n) {
        false
      } else {
        contains(Node(node=n.children[pos]), key)
      }
    }
  }
}

///|
/// Build a B-tree by inserting keys in order.
pub fn[T : Compare] from_array(arr : ArrayView[T]) -> Tree[T] {
  for key in arr; tree = Empty {
    continue insert(tree, key)
  } nobreak {
    tree
  }
}
