///|
test "binary trie remove" {
  let trie = @binary_trie_xor.BinaryTrie(5)
  trie.insert(5L)
  trie.insert(1L)
  trie.insert(7L)
  assert_true(trie.remove(1L))
  assert_eq(trie.size(), 2)
  inspect(trie.max_xor(2L), content="7")
  inspect(trie.min_xor(2L), content="5")
}

///|
test "binary trie duplicates" {
  let trie = @binary_trie_xor.BinaryTrie(5)
  trie.insert(5L)
  trie.insert(5L)
  assert_eq(trie.size(), 2)
  assert_true(trie.remove(5L))
  assert_eq(trie.size(), 1)
  assert_true(trie.remove(5L))
  assert_eq(trie.size(), 0)
  assert_true(!trie.remove(5L))
}
