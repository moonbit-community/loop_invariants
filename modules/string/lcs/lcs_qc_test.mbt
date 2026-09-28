// Property-based tests for longest common subsequence: the length agrees
// with a memoised recursion, the reconstructed path is a common subsequence
// of the stated length, and the length obeys its algebraic laws.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// A short sequence: usually over a 3-symbol alphabet, sometimes arbitrary
/// integers (including extreme values).
fn gen_seq(rs : @quickcheck.RandomState, max_len : Int) -> Array[Int] {
  let len = rint(rs, 0, max_len)
  if rint(rs, 0, 4) == 0 {
    Array::makei(len, _ => @quickcheck.Arbitrary::arbitrary(max_len, rs))
  } else {
    Array::makei(len, _ => rint(rs, 0, 2))
  }
}

///|
/// `a` after a few random edits (insert / delete / substitute / swap).
fn mutate(rs : @quickcheck.RandomState, a : Array[Int]) -> Array[Int] {
  let b = a.copy()
  for _ in 0..<rint(rs, 0, 3) {
    let n = b.length()
    match rint(rs, 0, 3) {
      0 => b.insert(rint(rs, 0, n), rint(rs, 0, 2))
      1 => if n > 0 { b.remove(rint(rs, 0, n - 1)) |> ignore }
      2 => if n > 0 { b[rint(rs, 0, n - 1)] = rint(rs, 0, 2) }
      _ =>
        if n > 1 {
          let i = rint(rs, 0, n - 2)
          let t = b[i]
          b[i] = b[i + 1]
          b[i + 1] = t
        }
    }
  }
  b
}

///|
priv struct Pair {
  a : Array[Int]
  b : Array[Int]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Pair with fn arbitrary(size, rs) {
  let max_len = if size < 8 { size } else { 8 }
  let a = gen_seq(rs, max_len)
  let b = if rint(rs, 0, 1) == 0 { mutate(rs, a) } else { gen_seq(rs, max_len) }
  { a, b, }
}

///|
impl @quickcheck.Shrink for Pair with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.a, self.b)).map(p => { a: p.0, b: p.1, })
}

///|
priv struct Triple {
  a : Array[Int]
  b : Array[Int]
  c : Array[Int]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Triple with fn arbitrary(size, rs) {
  let max_len = if size < 8 { size } else { 8 }
  let a = gen_seq(rs, max_len)
  let b = mutate(rs, a)
  let c = if rint(rs, 0, 1) == 0 { mutate(rs, b) } else { gen_seq(rs, max_len) }
  { a, b, c, }
}

///|
impl @quickcheck.Shrink for Triple with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.a, self.b, self.c)).map(p => {
    a: p.0,
    b: p.1,
    c: p.2,
  })
}

///|
fn max(x : Int, y : Int) -> Int {
  if x > y {
    x
  } else {
    y
  }
}

///|
/// Reference LCS length of the suffixes a[i..] and b[j..], memoised.
fn naive_lcs(a : Array[Int], b : Array[Int]) -> Int {
  let memo : Map[(Int, Int), Int] = Map([])
  fn go(i : Int, j : Int) -> Int {
    if i == a.length() || j == b.length() {
      return 0
    }
    match memo.get((i, j)) {
      Some(v) => return v
      None => ()
    }
    let r = if a[i] == b[j] {
      go(i + 1, j + 1) + 1
    } else {
      max(go(i + 1, j), go(i, j + 1))
    }
    memo[(i, j)] = r
    r
  }

  go(0, 0)
}

///|
fn is_subseq(sub : Array[Int], full : Array[Int]) -> Bool {
  let mut i = 0
  for x in full {
    if i < sub.length() && sub[i] == x {
      i = i + 1
    }
  }
  i == sub.length()
}

///|
test "qc: length agrees with the recursive definition" {
  @quickcheck.check(
    (p : Pair) => @lcs.length(p.a, p.b) == naive_lcs(p.a, p.b),
    observe=p => {
      let l = naive_lcs(p.a, p.b)
      [
        @quickcheck.classify(l == 0, "lcs empty"),
        @quickcheck.classify(
          l > 0 && l < p.a.length() && l < p.b.length(),
          "lcs proper in both",
        ),
      ]
    },
    count=500,
    seed=0x1c0001,
  )
}

///|
test "qc: length_and_path returns a common subsequence of the LCS length" {
  @quickcheck.check(
    (p : Pair) => {
      let (len, path) = @lcs.length_and_path(p.a, p.b)
      len == naive_lcs(p.a, p.b) &&
      path.length() == len &&
      is_subseq(path, p.a) &&
      is_subseq(path, p.b)
    },
    count=500,
    seed=0x1c0002,
  )
}

///|
test "qc: length laws" {
  @quickcheck.check(
    (t : Triple) => {
      let l = @lcs.length
      let ab = l(t.a, t.b)
      ab == l(t.b, t.a) &&
      l(t.a, t.a) == t.a.length() &&
      ab <= t.a.length() &&
      ab <= t.b.length() &&
      // appending a common symbol extends the LCS by exactly one
      l([..t.a, 7], [..t.b, 7]) == ab + 1 &&
      // the LCS with a concatenation is at least the LCS with a part
      l(t.a, [..t.b, ..t.c]) >= ab &&
      l(t.a, [..t.b, ..t.c]) <= ab + l(t.a, t.c)
    },
    count=300,
    seed=0x1c0003,
  )
}
