// Property-based tests for Floyd / Brent cycle detection on random functions
// over small finite domains `{0, ..., m-1}`, compared with a naive
// first-visit table.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// A function on `{0, ..., m-1}` given by its table, and a start point.
/// Some tables are random (short cycles, long tails are rare), some are
/// built as "a path of length `t` feeding into a cycle of length `c`" so
/// long tails and long cycles both show up.
priv struct Func {
  table : Array[Int]
  x0 : Int
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Func with fn arbitrary(size, rs) {
  let m = rint(rs, 1, size + 1)
  if rint(rs, 0, 1) == 0 {
    let table = Array::makei(m, _ => rint(rs, 0, m - 1))
    { table, x0: rint(rs, 0, m - 1), }
  } else {
    // Relabel a tail 0 -> 1 -> ... -> t-1 -> t -> ... -> m-1 -> t by a random
    // permutation so structure is not tied to the labels.
    let t = rint(rs, 0, m - 1)
    let perm = Array::makei(m, i => i)
    for i = m - 1; i > 0; i = i - 1 {
      let j = rint(rs, 0, i)
      let tmp = perm[i]
      perm[i] = perm[j]
      perm[j] = tmp
    }
    let table = Array::make(m, 0)
    for i in 0..<m {
      let next = if i + 1 < m { i + 1 } else { t }
      table[perm[i]] = perm[next]
    }
    { table, x0: perm[0], }
  }
}

///|
/// Shrinks the table while keeping every entry and `x0` inside the domain.
impl @quickcheck.Shrink for Func with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.table, self.x0))
  .filter(p => p.0.length() > 0)
  .map(p => {
    let (table, x0) = p
    let m = table.length()
    { table: table.map(v => (v % m).abs()), x0: (x0 % m).abs(), }
  })
}

///|
/// Naive `(mu, lam)` from the index of the first visit of each value.
fn naive_cycle(f : Func) -> (Int, Int) {
  let first = Array::make(f.table.length(), -1)
  let mut x = f.x0
  let mut i = 0
  while first[x] == -1 {
    first[x] = i
    x = f.table[x]
    i = i + 1
  }
  (first[x], i - first[x])
}

///|
test "qc: floyd_cycle matches the naive first-visit table" {
  @quickcheck.check(
    (f : Func) => {
      @cycle_detection.floyd_cycle(x => f.table[x], f.x0) == naive_cycle(f)
    },
    count=400,
    max_size=60,
    max_shrinks=1000,
    seed=101,
    observe=f => {
      let (mu, lam) = naive_cycle(f)
      [
        @quickcheck.classify(mu == 0, "mu == 0 (pure cycle)"),
        @quickcheck.classify(lam == 1, "lam == 1 (fixed point)"),
        @quickcheck.classify(mu >= 10, "mu >= 10"),
        @quickcheck.classify(lam >= 10, "lam >= 10"),
      ]
    },
  )
}

///|
test "qc: brent_cycle matches the naive first-visit table" {
  @quickcheck.check(
    (f : Func) => {
      @cycle_detection.brent_cycle(x => f.table[x], f.x0) == naive_cycle(f)
    },
    count=400,
    max_size=60,
    max_shrinks=1000,
    seed=102,
  )
}

///|
test "qc: floyd and brent agree on Int64 affine maps modulo m" {
  // x -> (a * x + b) mod m over Int64 values, a different element type.
  @quickcheck.check(
    (input : (Int, Int, Int, Int)) => {
      let m = (input.0 % 200).abs() + 1
      let a = (input.1 % m).abs().to_int64()
      let b = (input.2 % m).abs().to_int64()
      let x0 = (input.3 % m).abs().to_int64()
      let mm = m.to_int64()
      let f = (x : Int64) => (a * x + b) % mm
      let fl = @cycle_detection.floyd_cycle(f, x0)
      let br = @cycle_detection.brent_cycle(f, x0)
      let table = Array::makei(m, i => f(i.to_int64()).to_int())
      fl == br && fl == naive_cycle({ table, x0: x0.to_int(), })
    },
    count=200,
    seed=103,
  )
}
