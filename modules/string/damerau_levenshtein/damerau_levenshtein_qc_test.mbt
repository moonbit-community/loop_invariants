// Property-based tests for the restricted Damerau-Levenshtein (OSA) distance:
// agreement with a memoised suffix recursion, its laws (symmetry, identity,
// length bounds) and its relation to plain Levenshtein distance. OSA is not a
// metric (no triangle inequality), so that law is deliberately not asserted.

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
/// `a` after a few random edits (insert / delete / substitute / swap);
/// adjacent swaps are half of all edits so transpositions matter often.
fn mutate(rs : @quickcheck.RandomState, a : Array[Int]) -> Array[Int] {
  let b = a.copy()
  for _ in 0..<rint(rs, 0, 3) {
    let n = b.length()
    match rint(rs, 0, 5) {
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
fn abs(x : Int) -> Int {
  if x < 0 {
    -x
  } else {
    x
  }
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
/// Reference OSA distance of the suffixes a[i..] and b[j..], memoised.
fn naive_osa(a : Array[Int], b : Array[Int]) -> Int {
  let memo : Map[(Int, Int), Int] = Map([])
  fn go(i : Int, j : Int) -> Int {
    if i == a.length() {
      return b.length() - j
    }
    if j == b.length() {
      return a.length() - i
    }
    match memo.get((i, j)) {
      Some(v) => return v
      None => ()
    }
    let s = if a[i] == b[j] { 0 } else { 1 }
    let mut best = go(i + 1, j + 1) + s
    let d = go(i + 1, j) + 1
    if d < best {
      best = d
    }
    let n = go(i, j + 1) + 1
    if n < best {
      best = n
    }
    if i + 1 < a.length() &&
      j + 1 < b.length() &&
      a[i] == b[j + 1] &&
      a[i + 1] == b[j] {
      let t = go(i + 2, j + 2) + 1
      if t < best {
        best = t
      }
    }
    memo[(i, j)] = best
    best
  }

  go(0, 0)
}

///|
/// Plain Levenshtein distance (textbook DP).
fn lev(a : Array[Int], b : Array[Int]) -> Int {
  let d = Array::makei(a.length() + 1, i => {
    Array::makei(b.length() + 1, j => {
      if i == 0 {
        j
      } else if j == 0 {
        i
      } else {
        0
      }
    })
  })
  for i in 1..<=a.length() {
    for j in 1..<=b.length() {
      let s = if a[i - 1] == b[j - 1] { 0 } else { 1 }
      let mut best = d[i - 1][j - 1] + s
      if d[i - 1][j] + 1 < best {
        best = d[i - 1][j] + 1
      }
      if d[i][j - 1] + 1 < best {
        best = d[i][j - 1] + 1
      }
      d[i][j] = best
    }
  }
  d[a.length()][b.length()]
}

///|
test "qc: damerau distance agrees with the recursive OSA definition" {
  @quickcheck.check(
    (p : Pair) => @damerau_levenshtein.distance(p.a, p.b) == naive_osa(p.a, p.b),
    observe=p => {
      [
        @quickcheck.classify(
          naive_osa(p.a, p.b) < lev(p.a, p.b),
          "transposition helps",
        ),
      ]
    },
    count=500,
    seed=0xda0001,
  )
}

///|
test "qc: damerau distance laws" {
  @quickcheck.check(
    (p : Pair) => {
      let d = @damerau_levenshtein.distance(p.a, p.b)
      let l = lev(p.a, p.b)
      d == @damerau_levenshtein.distance(p.b, p.a) &&
      (d == 0) == (p.a == p.b) &&
      abs(p.a.length() - p.b.length()) <= d &&
      d <= max(p.a.length(), p.b.length()) &&
      // each transposition is worth at most two Levenshtein edits
      d <= l &&
      l <= 2 * d
    },
    count=500,
    seed=0xda0002,
  )
}

///|
test "qc: one adjacent swap costs at most one" {
  @quickcheck.check(
    (c : (Array[Int], Int)) => {
      let (a, k) = c
      guard a.length() >= 2 else { return true }
      let i = (k % (a.length() - 1)).abs()
      let b = a.copy()
      b[i] = a[i + 1]
      b[i + 1] = a[i]
      @damerau_levenshtein.distance(a, b) ==
      (if a[i] == a[i + 1] { 0 } else { 1 })
    },
    count=300,
    max_size=10,
    seed=0xda0003,
  )
}
