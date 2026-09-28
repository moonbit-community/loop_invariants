// Property-based tests for Levenshtein distance: agreement with a memoised
// suffix recursion (unit and weighted costs) plus the metric laws.

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
/// Reference: edit distance of the suffixes a[i..] and b[j..], memoised.
fn naive_weighted(
  a : Array[Int],
  b : Array[Int],
  ins : Int,
  del : Int,
  sub : Int,
) -> Int {
  let memo : Map[(Int, Int), Int] = Map([])
  fn go(i : Int, j : Int) -> Int {
    if i == a.length() {
      return (b.length() - j) * ins
    }
    if j == b.length() {
      return (a.length() - i) * del
    }
    match memo.get((i, j)) {
      Some(v) => return v
      None => ()
    }
    let s = if a[i] == b[j] { 0 } else { sub }
    let mut best = go(i + 1, j + 1) + s
    let d = go(i + 1, j) + del
    if d < best {
      best = d
    }
    let n = go(i, j + 1) + ins
    if n < best {
      best = n
    }
    memo[(i, j)] = best
    best
  }

  go(0, 0)
}

///|
priv struct Costs {
  pair : Pair
  ins : Int
  del : Int
  sub : Int
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Costs with fn arbitrary(size, rs) {
  {
    pair: @quickcheck.Arbitrary::arbitrary(size, rs),
    ins: rint(rs, 0, 5),
    del: rint(rs, 0, 5),
    sub: rint(rs, 0, 10),
  }
}

///|
impl @quickcheck.Shrink for Costs with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.pair).map(pair => { ..self, pair, })
}

///|
test "qc: distance agrees with the recursive definition" {
  @quickcheck.check(
    (p : Pair) => {
      @levenshtein_distance.distance(p.a, p.b) ==
      naive_weighted(p.a, p.b, 1, 1, 1)
    },
    observe=p => {
      let d = naive_weighted(p.a, p.b, 1, 1, 1)
      [
        @quickcheck.classify(d == 0, "distance 0"),
        @quickcheck.classify(d > 0 && d <= 2, "distance 1-2"),
        @quickcheck.classify(d > 2, "distance > 2"),
      ]
    },
    count=500,
    seed=0x1e0001,
  )
}

///|
test "qc: distance_weighted agrees with the recursive definition" {
  @quickcheck.check(
    (c : Costs) => {
      @levenshtein_distance.distance_weighted(
        c.pair.a,
        c.pair.b,
        cost_insert=c.ins,
        cost_delete=c.del,
        cost_subst=c.sub,
      ) ==
      naive_weighted(c.pair.a, c.pair.b, c.ins, c.del, c.sub)
    },
    count=500,
    seed=0x1e0002,
  )
}

///|
test "qc: distance is a metric with the length bounds" {
  @quickcheck.check(
    (t : Triple) => {
      let d = @levenshtein_distance.distance
      let ab = d(t.a, t.b)
      ab == d(t.b, t.a) &&
      (ab == 0) == (t.a == t.b) &&
      d(t.a, t.c) <= ab + d(t.b, t.c) &&
      abs(t.a.length() - t.b.length()) <= ab &&
      ab <= max(t.a.length(), t.b.length())
    },
    count=500,
    seed=0x1e0003,
  )
}

///|
test "qc: distance_weighted with unit costs is distance" {
  @quickcheck.check(
    (p : Pair) => {
      @levenshtein_distance.distance_weighted(
        p.a,
        p.b,
        cost_insert=1,
        cost_delete=1,
        cost_subst=1,
      ) ==
      @levenshtein_distance.distance(p.a, p.b)
    },
    count=300,
    seed=0x1e0004,
  )
}
