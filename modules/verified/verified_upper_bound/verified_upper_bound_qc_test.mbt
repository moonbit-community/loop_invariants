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
  SortedKey((xs, gen_elem().run(size, rs)))
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
test "qc: upper_bound equals the number of elements <= key" {
  @quickcheck.check(
    (sk : SortedKey) => {
      let (xs, key) = sk.0
      @verified_upper_bound.upper_bound(FixedArray::from_array(xs), key) ==
      xs.filter(x => x <= key).length()
    },
    observe=sk => {
      let (xs, key) = sk.0
      let ub = xs.filter(x => x <= key).length()
      [
        @quickcheck.classify(ub == 0, "before all"),
        @quickcheck.classify(ub == xs.length(), "after all"),
      ]
    },
    count=1000,
    seed=0x0B_0001,
  )
}
