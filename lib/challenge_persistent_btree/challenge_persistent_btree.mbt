// ============================================================================
// Challenge: Persistent B-Tree (min degree 2)
// Nodes hold 1-3 keys, path-copying insertion with splits
// ============================================================================

///|
struct BNode {
  keys : Array[Int]
  children : Array[BNode]
} derive(Show)

///|
pub enum Tree {
  Empty
  Node(node~ : BNode)
} derive(Show)

///|
enum InsertResult {
  Done(node~ : BNode)
  Split(key~ : Int, left~ : BNode, right~ : BNode)
} derive(Show)

///|
fn is_leaf(node : BNode) -> Bool {
  node.children.length() == 0
}

///|
fn node_size(node : BNode) -> Int {
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
fn tree_size(t : Tree) -> Int {
  match t {
    Tree::Empty => 0
    Tree::Node(node=n) => node_size(n)
  }
}

///|
fn insert_key(keys : Array[Int], pos : Int, key : Int) -> Array[Int] {
  let out = Array::new()
  for i = 0; i < keys.length(); i = i + 1 {
    if i == pos {
      out.push(key)
    }
    out.push(keys[i])
  } where {
    invariant: i >= 0 && i <= keys.length(),
    reasoning: (
      #|INVARIANT (Insert key):
      #|out equals keys[0..i) with key inserted at position pos.
      #|MAINTENANCE:
      #|Append keys[i] and inject key when i == pos.
      #|TERMINATION:
      #|After the loop, key is inserted into the proper position.
    ),
  }
  if pos >= keys.length() {
    out.push(key)
  }
  out
}

///|
fn insert_children(
  children : Array[BNode],
  pos : Int,
  left : BNode,
  right : BNode,
) -> Array[BNode] {
  let out = Array::new()
  for i = 0; i < children.length(); i = i + 1 {
    if i == pos {
      out.push(left)
      out.push(right)
    } else {
      out.push(children[i])
    }
  } where {
    invariant: i >= 0 && i <= children.length(),
    reasoning: (
      #|INVARIANT (Insert children):
      #|out equals children[0..i) with the split inserted at position pos.
      #|MAINTENANCE:
      #|Replace the old child at pos with left/right, keep others in order.
      #|TERMINATION:
      #|After the loop, the children array is updated for the split.
    ),
  }
  if pos >= children.length() {
    out.push(left)
    out.push(right)
  }
  out
}

///|
fn find_pos(keys : Array[Int], key : Int) -> (Int, Bool) {
  for i = 0 {
    if i >= keys.length() {
      break (keys.length(), false)
    } else if key == keys[i] {
      break (i, true)
    } else if key < keys[i] {
      break (i, false)
    } else {
      continue i + 1
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
fn split_node(
  keys : Array[Int],
  children : Array[BNode],
) -> (Int, BNode, BNode) {
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
fn insert_node(node : BNode, key : Int) -> InsertResult {
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
pub fn empty() -> Tree {
  Tree::Empty
}

///|
/// Return the number of keys in the tree.
pub fn size(t : Tree) -> Int {
  tree_size(t)
}

///|
/// Insert key and return the new tree.
pub fn insert(t : Tree, key : Int) -> Tree {
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

///|
/// Check whether a key exists in the tree.
pub fn contains(t : Tree, key : Int) -> Bool {
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
#warnings("+missing_invariant+missing_reasoning")
pub fn from_array(arr : ArrayView[Int]) -> Tree {
  let n = arr.length()
  for i = 0, tree = Tree::Empty {
    if i >= n {
      break tree
    } else {
      continue i + 1, insert(tree, arr[i])
    }
  } where {
    invariant: i >= 0 && i <= n,
    invariant: tree_size(tree) == i,
    reasoning: (
      #|INVARIANT (B-tree build):
      #|tree contains the first i keys and respects B-tree constraints.
      #|MAINTENANCE:
      #|Insert arr[i], splitting full nodes as needed.
      #|TERMINATION:
      #|At i = n, all keys are inserted.
    ),
  }
}
