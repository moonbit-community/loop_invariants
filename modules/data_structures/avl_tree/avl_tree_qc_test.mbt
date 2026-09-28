// Property-based tests for `avl_sorted`: the result is the input sorted
// (a permutation, duplicates preserved), and equal keys keep insertion order
// because duplicates are inserted to the right of existing equal keys.

///|
test "qc: avl_sorted equals Array::sort on Int64" {
  @quickcheck.check(
    (xs : Array[Int64]) => {
      let expected = xs.copy()
      expected.sort()
      @avl_tree.avl_sorted(xs[:]) == expected
    },
    seed=0xA71_0001,
    count=300,
  )
}

///|
/// Arrays of small keys, so duplicates are frequent.
priv struct SmallKeys(Array[Int]) derive(Debug)

///|
impl @quickcheck.Arbitrary for SmallKeys with fn arbitrary(size, rs) {
  let n = rs
    .next_uint(limit=(size + 1).reinterpret_as_uint())
    .reinterpret_as_int()
  SmallKeys(Array::makei(n, _ => rs.next_uint(limit=6).reinterpret_as_int()))
}

///|
impl @quickcheck.Shrink for SmallKeys with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).map(x => SmallKeys(x))
}

///|
/// A key with a tag that the ordering ignores; used to observe stability.
priv struct Tagged {
  key : Int
  tag : Int
}

///|
impl Eq for Tagged with fn equal(a, b) {
  a.key == b.key
}

///|
impl Compare for Tagged with fn compare(a, b) {
  a.key.compare(b.key)
}

///|
test "qc: avl_sorted is stable for equal keys" {
  @quickcheck.check(
    (ks : SmallKeys) => {
      let input = ks.0.mapi((i, k) => { key: k, tag: i, })
      let out = @avl_tree.avl_sorted(input[:])
      if out.length() != input.length() {
        return false
      }
      // Keys sorted; ties broken by original position (tag).
      for i in 1..<out.length() {
        let a = out[i - 1]
        let b = out[i]
        if a > b || (a == b && a.tag > b.tag) {
          return false
        }
      }
      // Permutation: every tag appears exactly once.
      let seen = Array::make(input.length(), false)
      for t in out {
        if seen[t.tag] {
          return false
        }
        seen[t.tag] = true
      }
      true
    },
    seed=0xA71_0002,
    count=300,
    observe=ks => {
      let distinct = ks.0.iter().fold(init=0, (acc, k) => acc | (1 << k))
      [
        @quickcheck.classify(ks.0.length() == 0, "empty"),
        @quickcheck.classify(ks.0.length() > 20, "length > 20"),
        @quickcheck.classify(
          ks.0.length() > 0 && distinct.popcnt() < ks.0.length(),
          "has duplicates",
        ),
      ]
    },
  )
}
