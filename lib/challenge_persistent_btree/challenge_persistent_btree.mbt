// ============================================================================
// Challenge: Persistent B-Tree (min degree 2)
// Nodes hold 1-3 keys, path-copying insertion with splits
// ============================================================================

///|
struct BNode[T] {
  keys : Array[T]
  children : Array[BNode[T]]
} derive(Show)

///|
pub enum Tree[T] {
  Empty
  Node(node~ : BNode[T])
} derive(Show)

///|
enum InsertResult[T] {
  Done(node~ : BNode[T])
  Split(key~ : T, left~ : BNode[T], right~ : BNode[T])
} derive(Show)

///|
fn[T] is_leaf(node : BNode[T]) -> Bool {
  node.children.length() == 0
}

///|
fn[T] node_size(node : BNode[T]) -> Int {
  if is_leaf(node) {
    node.keys.length()
  } else {
    let mut sum = node.keys.length()
    for child in node.children {
      sum = sum + node_size(child)
    }
    sum
  }
}

///|
fn[T] tree_size(t : Tree[T]) -> Int {
  match t {
    Tree::Empty => 0
    Tree::Node(node=n) => node_size(n)
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
    invariant: i >= 0 && i <= keys.length(),
    reasoning: (
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
  let left_keys = keys[0:2].to_array()
  let right_keys = keys[3:4].to_array()
  let left_children = if children.length() == 0 {
    []
  } else {
    children[0:3].to_array()
  }
  let right_children = if children.length() == 0 {
    []
  } else {
    children[3:5].to_array()
  }
  let left = { keys: left_keys, children: left_children }
  let right = { keys: right_keys, children: right_children }
  (promote, left, right)
}

///|
fn[T : Compare] insert_node(node : BNode[T], key : T) -> InsertResult[T] {
  let (pos, exists) = find_pos(node.keys, key)
  if exists {
    InsertResult::Done(node~)
  } else if is_leaf(node) {
    let new_keys = insert_key(node.keys, pos, key)
    if new_keys.length() <= 3 {
      InsertResult::Done(node={ keys: new_keys, children: [] })
    } else {
      let (promote, left, right) = split_node(new_keys, [])
      InsertResult::Split(key=promote, left~, right~)
    }
  } else {
    let child = node.children[pos]
    match insert_node(child, key) {
      InsertResult::Done(node=updated_child) => {
        let new_children = node.children.copy()
        new_children[pos] = updated_child
        InsertResult::Done(node={ keys: node.keys, children: new_children })
      }
      InsertResult::Split(key=pk, left=pl, right=pr) => {
        let new_keys = insert_key(node.keys, pos, pk)
        let new_children = insert_children(node.children, pos, pl, pr)
        if new_keys.length() <= 3 {
          InsertResult::Done(node={ keys: new_keys, children: new_children })
        } else {
          let (promote, left, right) = split_node(new_keys, new_children)
          InsertResult::Split(key=promote, left~, right~)
        }
      }
    }
  }
}

///|
/// Create an empty B-tree.
pub fn[T] empty() -> Tree[T] {
  Tree::Empty
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
    Tree::Empty => Tree::Node(node={ keys: [key], children: [] })
    Tree::Node(node=n) =>
      match insert_node(n, key) {
        InsertResult::Done(node=done) => Tree::Node(node=done)
        InsertResult::Split(key=pk, left=pl, right=pr) =>
          Tree::Node(node={ keys: [pk], children: [pl, pr] })
      }
  }
}

///|
/// Check whether a key exists in the tree.
pub fn[T : Compare] contains(t : Tree[T], key : T) -> Bool {
  match t {
    Tree::Empty => false
    Tree::Node(node=n) => {
      let (pos, exists) = find_pos(n.keys, key)
      if exists {
        true
      } else if is_leaf(n) {
        false
      } else {
        contains(Tree::Node(node=n.children[pos]), key)
      }
    }
  }
}

///|
/// Build a B-tree by inserting keys in order.
pub fn[T : Compare] from_array(arr : ArrayView[T]) -> Tree[T] {
  let mut tree = Tree::Empty
  for key in arr {
    tree = insert(tree, key)
  }
  tree
}
