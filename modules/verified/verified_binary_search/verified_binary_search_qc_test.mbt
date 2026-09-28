///|
priv struct SortedKey((Array[Int], Int)) derive(Debug)

///|
fn gen_elem() -> @quickcheck.Generator[Int] {
  @quickcheck.frequency([
    (4, @quickcheck.int_range(-5, 6)),
    (1, @quickcheck.elements([@int.MIN_VALUE, @int.MAX_VALUE])),
    (1, @quickcheck.spawn()),
  ])
}

///|
impl @quickcheck.Arbitrary for SortedKey with fn arbitrary(size, rs) {
  let n = @quickcheck.int_range(0, (if size < 40 { size } else { 40 }) + 1).run(
    size, rs,
  )
  let xs = gen_elem().array_with_size(n).run(size, rs)
  xs.sort()
  let key = if n > 0 && @quickcheck.Arbitrary::arbitrary(size, rs) {
    xs[@quickcheck.int_range(0, n).run(size, rs)]
  } else {
    gen_elem().run(size, rs)
  }
  SortedKey((xs, key))
}

///|
impl @quickcheck.Shrink for SortedKey with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).map(p => {
    let xs = p.0.copy()
    xs.sort()
    SortedKey((xs, p.1))
  })
}

///|
test "qc: binary_search agrees with linear scan on sorted arrays" {
  @quickcheck.check(
    (sk : SortedKey) => {
      let (xs, key) = sk.0
      let fa = FixedArray::from_array(xs)
      match @verified_binary_search.binary_search(fa, key) {
        Some(i) => i >= 0 && i < xs.length() && xs[i] == key
        None => !xs.contains(key)
      }
    },
    observe=sk => [@quickcheck.classify(sk.0.0.contains(sk.0.1), "key present")],
    count=1000,
    seed=0xB5_0001,
  )
}
