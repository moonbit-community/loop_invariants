// ============================================================================
// Challenge: Persistent String Trie
// Path-copying trie for lowercase ASCII words
// ============================================================================

///|
pub struct Node {
  end : Bool
  children : Array[Node?]
} derive(Show)

///|
/// Create an empty persistent trie.
pub fn empty() -> Node {
  { end: false, children: Array::make(26, None) }
}

///|
fn char_index(ch : Char) -> Int {
  ch.to_int() - 'a'.to_int()
}

///|
fn insert(node : Node, s : StringView, idx : Int) -> Node {
  if idx >= s.length() {
    { end: true, children: node.children }
  } else {
    match s.get_char(idx) {
      None => node
      Some(ch) => {
        let i = char_index(ch)
        let child = match node.children[i] {
          None => empty()
          Some(n) => n
        }
        let updated = insert(child, s, idx + 1)
        let new_children = node.children.copy()
        new_children[i] = Some(updated)
        { end: node.end, children: new_children }
      }
    }
  }
}

///|
/// Insert a word into the trie and return the new root.
pub fn add(root : Node, s : String) -> Node {
  insert(root, s[:], 0)
}

///|
/// Check whether a word exists in the trie.
pub fn contains(root : Node, s : String) -> Bool {
  contains_view(root, s[:], 0)
}

///|
fn contains_view(node : Node, view : StringView, idx : Int) -> Bool {
  if idx >= view.length() {
    node.end
  } else {
    match view.get_char(idx) {
      None => false
      Some(ch) => {
        let i = char_index(ch)
        match node.children[i] {
          None => false
          Some(next) => contains_view(next, view, idx + 1)
        }
      }
    }
  }
}

///|
test "persistent_trie_string" {
  let root0 = empty()
  let root1 = add(root0, "cat")
  let root2 = add(root1, "car")
  let root3 = add(root2, "dog")
  assert_eq(contains(root3, "cat"), true)
  assert_eq(contains(root3, "car"), true)
  assert_eq(contains(root3, "cow"), false)
  assert_eq(contains(root1, "cat"), true)
  assert_eq(contains(root1, "dog"), false)
}
