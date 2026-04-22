// ============================================================================
// SUFFIX TREE - Tests
// ============================================================================

///|
test "contains: basic patterns" {
  let tree = SuffixTree::new("banana")
  inspect(tree.contains("ana"), content="true")
  inspect(tree.contains("ban"), content="true")
  inspect(tree.contains("nan"), content="true")
  inspect(tree.contains("banana"), content="true")
}

///|
test "contains: pattern not found" {
  let tree = SuffixTree::new("banana")
  inspect(tree.contains("apple"), content="false")
  inspect(tree.contains("bananaa"), content="false")
  inspect(tree.contains("xyz"), content="false")
}

///|
test "contains: edge cases" {
  let tree = SuffixTree::new("banana")
  inspect(tree.contains(""), content="true") // empty pattern
  inspect(tree.contains("a"), content="true") // single char
  inspect(tree.contains("b"), content="true")
}

///|
test "count: repeated patterns" {
  let tree = SuffixTree::new("banana")
  inspect(tree.count_occurrences("ana"), content="2") // overlapping
  inspect(tree.count_occurrences("na"), content="2")
  inspect(tree.count_occurrences("a"), content="3")
  inspect(tree.count_occurrences("n"), content="2")
}

///|
test "count: unique patterns" {
  let tree = SuffixTree::new("banana")
  inspect(tree.count_occurrences("ban"), content="1")
  inspect(tree.count_occurrences("banana"), content="1")
  inspect(tree.count_occurrences("b"), content="1")
}

///|
test "count: pattern not found" {
  let tree = SuffixTree::new("banana")
  inspect(tree.count_occurrences("xyz"), content="0")
  inspect(tree.count_occurrences("bananax"), content="0")
}

///|
test "count: empty pattern" {
  let tree = SuffixTree::new("banana")
  inspect(tree.count_occurrences(""), content="0")
}

///|
test "repeated characters" {
  let tree = SuffixTree::new("aaaa")
  inspect(tree.contains("aa"), content="true")
  inspect(tree.count_occurrences("a"), content="4")
  inspect(tree.count_occurrences("aa"), content="3")
  inspect(tree.count_occurrences("aaa"), content="2")
  inspect(tree.count_occurrences("aaaa"), content="1")
}

///|
test "single character string" {
  let tree = SuffixTree::new("x")
  inspect(tree.contains("x"), content="true")
  inspect(tree.contains("y"), content="false")
  inspect(tree.count_occurrences("x"), content="1")
}

///|
test "empty string" {
  let tree = SuffixTree::new("")
  inspect(tree.contains(""), content="true")
  inspect(tree.contains("a"), content="false")
  inspect(tree.count_occurrences("a"), content="0")
}
