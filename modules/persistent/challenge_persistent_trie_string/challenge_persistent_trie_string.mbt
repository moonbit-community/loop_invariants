// ============================================================================
// Challenge: Persistent String Trie
// Path-copying trie for lowercase ASCII words
// ============================================================================

///|
/// Persistent string trie node for lowercase ASCII words.
///
/// Each node stores a 26-slot child array indexed by `ch - 'a'` plus
/// an `end` flag marking whether a word terminates here. The trie
/// supports `add` to insert a word and `contains` to test membership,
/// each running in `O(L)` where `L` is the word length. Insertion is
/// persistent and path-copying: only the at-most `L` nodes along the
/// inserted path are reallocated, while every other subtree is shared
/// with the previous root. Start with `empty`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let t = @challenge_persistent_trie_string.empty()
///   let t1 = @challenge_persistent_trie_string.add(t, "cat")
///   let t2 = @challenge_persistent_trie_string.add(t1, "car")
///   @debug.assert_eq(@challenge_persistent_trie_string.contains(t2, "cat"), true)
///   @debug.assert_eq(@challenge_persistent_trie_string.contains(t2, "car"), true)
///   @debug.assert_eq(@challenge_persistent_trie_string.contains(t1, "car"), false)
/// }
/// ```
pub struct Node {
  end : Bool
  children : Array[Node?]
} derive(Debug)

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
  insert(root, s, 0)
}

///|
/// Check whether a word exists in the trie.
pub fn contains(root : Node, s : String) -> Bool {
  contains_view(root, s, 0)
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
  @debug.assert_eq(contains(root3, "cat"), true)
  @debug.assert_eq(contains(root3, "car"), true)
  @debug.assert_eq(contains(root3, "cow"), false)
  @debug.assert_eq(contains(root1, "cat"), true)
  @debug.assert_eq(contains(root1, "dog"), false)
}
