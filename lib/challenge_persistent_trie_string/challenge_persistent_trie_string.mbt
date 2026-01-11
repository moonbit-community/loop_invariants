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
pub fn add(root : Node, s : String) -> Node {
  insert(root, s[:], 0)
}

///|
#warnings("+missing_invariant+missing_reasoning")
pub fn contains(root : Node, s : String) -> Bool {
  let view = s[:]
  for i = 0, cur = root {
    if i >= view.length() {
      break cur.end
    } else {
      match view.get_char(i) {
        None => break false
        Some(ch) => {
          let idx = char_index(ch)
          match cur.children[idx] {
            None => break false
            Some(next) => continue i + 1, next
          }
        }
      }
    }
  } where {
    invariant: i >= 0 && i <= view.length(),
    reasoning: (
      #|INVARIANT (Trie walk):
      #|cur corresponds to the prefix s[0..i). If a word exists, it must be
      #|in the subtree rooted at cur.
      #|MAINTENANCE:
      #|Advance one character and descend into the matching child.
      #|TERMINATION:
      #|At i = |s|, cur.end indicates presence of the word.
    ),
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
