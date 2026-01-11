# Persistent String Trie

Path-copying trie for lowercase ASCII words.

## Example

```mbt check
///|
test "persistent trie" {
  let root0 = @challenge_persistent_trie_string.empty()
  let root1 = @challenge_persistent_trie_string.add(root0, "cat")
  let root2 = @challenge_persistent_trie_string.add(root1, "car")
  let root3 = @challenge_persistent_trie_string.add(root2, "dog")
  inspect(
    @challenge_persistent_trie_string.contains(root3, "cat"),
    content="true",
  )
  inspect(
    @challenge_persistent_trie_string.contains(root3, "cow"),
    content="false",
  )
  inspect(
    @challenge_persistent_trie_string.contains(root1, "dog"),
    content="false",
  )
}
```
