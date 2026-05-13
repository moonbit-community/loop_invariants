///|
test "binary trie remove" {
  let trie = @binary_trie_xor.BinaryTrie(5)
  trie.insert(5L)
  trie.insert(1L)
  trie.insert(7L)
  assert_true(trie.remove(1L))
  @debug.assert_eq(trie.size(), 2)
  debug_inspect(trie.max_xor(2L), content="7")
  debug_inspect(trie.min_xor(2L), content="5")
}

///|
test "binary trie duplicates" {
  let trie = @binary_trie_xor.BinaryTrie(5)
  trie.insert(5L)
  trie.insert(5L)
  @debug.assert_eq(trie.size(), 2)
  assert_true(trie.remove(5L))
  @debug.assert_eq(trie.size(), 1)
  assert_true(trie.remove(5L))
  @debug.assert_eq(trie.size(), 0)
  assert_true(!trie.remove(5L))
}
