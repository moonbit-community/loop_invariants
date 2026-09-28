// Property-based tests for horspool: find_all / find_first are compared with a
// naive O(n*m) scan, including symbols that collide in the 16-bit shift table.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Symbol pools: a tiny alphabet (frequent matches), values that collide in
/// the low 16 bits the shift table is indexed by (1, 65537, -65535 all map to
/// slot 1), and arbitrary integers.
fn gen_symbols(rs : @quickcheck.RandomState, size : Int) -> Array[Int] {
  let len = rint(rs, 0, size)
  match rint(rs, 0, 3) {
    0 | 1 => Array::makei(len, _ => rint(rs, 0, 2))
    2 => {
      let pool = [0, 1, 65537, -65535, 65536, -1]
      Array::makei(len, _ => pool[rint(rs, 0, pool.length() - 1)])
    }
    _ => Array::makei(len, _ => @quickcheck.Arbitrary::arbitrary(size, rs))
  }
}

///|
priv struct Search {
  text : Array[Int]
  pattern : Array[Int]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Search with fn arbitrary(size, rs) {
  let text = gen_symbols(rs, size)
  let n = text.length()
  let pattern = if n > 0 && rint(rs, 0, 1) == 0 {
    let i = rint(rs, 0, n - 1)
    let hi = if rint(rs, 0, 3) == 0 || n - i < 5 { n - i } else { 5 }
    text[i:i + rint(rs, 1, hi)].to_owned()
  } else {
    let pool = if n > 0 { text } else { [0, 1] }
    Array::makei(rint(rs, 0, 4), _ => pool[rint(rs, 0, pool.length() - 1)])
  }
  { text, pattern, }
}

///|
impl @quickcheck.Shrink for Search with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.text, self.pattern)).map(p => {
    text: p.0,
    pattern: p.1,
  })
}

///|
/// Reference: all (overlapping) start indices; none for an empty pattern.
fn naive_search(text : Array[Int], pattern : Array[Int]) -> Array[Int] {
  let n = text.length()
  let m = pattern.length()
  let res : Array[Int] = []
  if m == 0 || m > n {
    return res
  }
  for i in 0..<=(n - m) {
    if text[i:i + m] == pattern[:] {
      res.push(i)
    }
  }
  res
}

///|
fn first_of(xs : Array[Int]) -> Int? {
  if xs.length() > 0 {
    Some(xs[0])
  } else {
    None
  }
}

///|
test "qc: horspool find_all and find_first agree with naive search" {
  @quickcheck.check(
    (c : Search) => {
      let expected = naive_search(c.text, c.pattern)
      @horspool.find_all(c.text, c.pattern) == expected &&
      @horspool.find_first(c.text, c.pattern) == first_of(expected)
    },
    observe=c => {
      let hits = naive_search(c.text, c.pattern).length()
      [
        @quickcheck.classify(hits > 0, "pattern occurs"),
        @quickcheck.classify(hits > 1, "several occurrences"),
        @quickcheck.classify(c.pattern.length() == 0, "empty pattern"),
      ]
    },
    count=1000,
    max_size=40,
    seed=0x77dc9a7a,
  )
}
