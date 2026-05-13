// ============================================================================
// SUFFIX TREE - Tests
// ============================================================================

///|
test "contains: basic patterns" {
  let tree = @suffix_tree.SuffixTree("banana")
  debug_inspect(tree.contains("ana"), content="true")
  debug_inspect(tree.contains("ban"), content="true")
  debug_inspect(tree.contains("nan"), content="true")
  debug_inspect(tree.contains("banana"), content="true")
}

///|
test "contains: pattern not found" {
  let tree = @suffix_tree.SuffixTree("banana")
  debug_inspect(tree.contains("apple"), content="false")
  debug_inspect(tree.contains("bananaa"), content="false")
  debug_inspect(tree.contains("xyz"), content="false")
}

///|
test "contains: edge cases" {
  let tree = @suffix_tree.SuffixTree("banana")
  debug_inspect(tree.contains(""), content="true") // empty pattern
  debug_inspect(tree.contains("a"), content="true") // single char
  debug_inspect(tree.contains("b"), content="true")
}

///|
test "count: repeated patterns" {
  let tree = @suffix_tree.SuffixTree("banana")
  debug_inspect(tree.count_occurrences("ana"), content="2") // overlapping
  debug_inspect(tree.count_occurrences("na"), content="2")
  debug_inspect(tree.count_occurrences("a"), content="3")
  debug_inspect(tree.count_occurrences("n"), content="2")
}

///|
test "count: unique patterns" {
  let tree = @suffix_tree.SuffixTree("banana")
  debug_inspect(tree.count_occurrences("ban"), content="1")
  debug_inspect(tree.count_occurrences("banana"), content="1")
  debug_inspect(tree.count_occurrences("b"), content="1")
}

///|
test "count: pattern not found" {
  let tree = @suffix_tree.SuffixTree("banana")
  debug_inspect(tree.count_occurrences("xyz"), content="0")
  debug_inspect(tree.count_occurrences("bananax"), content="0")
}

///|
test "count: empty pattern" {
  let tree = @suffix_tree.SuffixTree("banana")
  debug_inspect(tree.count_occurrences(""), content="0")
}

///|
test "repeated characters" {
  let tree = @suffix_tree.SuffixTree("aaaa")
  debug_inspect(tree.contains("aa"), content="true")
  debug_inspect(tree.count_occurrences("a"), content="4")
  debug_inspect(tree.count_occurrences("aa"), content="3")
  debug_inspect(tree.count_occurrences("aaa"), content="2")
  debug_inspect(tree.count_occurrences("aaaa"), content="1")
}

///|
test "single character string" {
  let tree = @suffix_tree.SuffixTree("x")
  debug_inspect(tree.contains("x"), content="true")
  debug_inspect(tree.contains("y"), content="false")
  debug_inspect(tree.count_occurrences("x"), content="1")
}

///|
test "empty string" {
  let tree = @suffix_tree.SuffixTree("")
  debug_inspect(tree.contains(""), content="true")
  debug_inspect(tree.contains("a"), content="false")
  debug_inspect(tree.count_occurrences("a"), content="0")
}
