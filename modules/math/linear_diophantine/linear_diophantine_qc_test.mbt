///|
fn big(x : Int64) -> @bigint.BigInt {
  @bigint.BigInt::from_int64(x)
}

///|
fn gcd(a : Int64, b : Int64) -> Int64 {
  let x = if a < 0L { -a } else { a }
  let y = if b < 0L { -b } else { b }
  if y == 0L {
    x
  } else {
    gcd(y, x % y)
  }
}

///|
/// Coefficients with |a|, |b| <= 2^31 and |c| <= 2^31 (so every solution
/// the algorithm builds fits in Int64, away from the README's documented
/// overflow region near 2^63), with frequent zeros, shared factors and
/// c chosen as a multiple of gcd(a, b).
priv struct Eqn {
  a : Int64
  b : Int64
  c : Int64
} derive(Debug)

///|
fn coef(rs : @quickcheck.RandomState, bound : Int64) -> Int64 {
  rs
  .next_uint64(limit=(2L * bound + 1L).reinterpret_as_uint64())
  .reinterpret_as_int64() -
  bound
}

///|
impl @quickcheck.Arbitrary for Eqn with fn arbitrary(_size, rs) {
  let bound = if rs.next_uint(limit=2) == 0 { 30L } else { 2147483648L }
  let g = 1L + rs.next_uint64(limit=50UL).reinterpret_as_int64()
  let pick = fn() {
    match rs.next_uint(limit=5) {
      0 => 0L
      1 => g * coef(rs, if bound >= 100L { bound / 50L } else { 2L })
      _ => coef(rs, bound)
    }
  }
  let a = pick()
  let b = pick()
  let c = if rs.next_uint(limit=2) == 0 {
    // a solvable right-hand side
    let d = gcd(a, b)
    d * coef(rs, if d == 0L { 0L } else { bound / d })
  } else {
    coef(rs, bound)
  }
  { a, b, c, }
}

///|
impl @quickcheck.Shrink for Eqn with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.a, self.b, self.c)).map(t => {
    a: t.0,
    b: t.1,
    c: t.2,
  })
}

///|
fn solvable(e : Eqn) -> Bool {
  let g = gcd(e.a, e.b)
  if g == 0L {
    e.c == 0L
  } else {
    e.c % g == 0L
  }
}

///|
fn satisfies(e : Eqn, x : Int64, y : Int64) -> Bool {
  big(e.a) * big(x) + big(e.b) * big(y) == big(e.c)
}

///|
test "qc: solve finds a solution exactly when gcd(a, b) | c" {
  @quickcheck.check(
    (e : Eqn) => {
      match @linear_diophantine.solve(e.a, e.b, e.c).solution {
        Some((x, y)) => solvable(e) && satisfies(e, x, y)
        None => !solvable(e)
      }
    },
    count=1000,
    seed=161,
    observe=e => {
      [
        @quickcheck.classify(solvable(e), "solvable"),
        @quickcheck.classify(e.a == 0L || e.b == 0L, "a zero coefficient"),
        @quickcheck.classify(e.a < 0L || e.b < 0L, "negative coefficient"),
      ]
    },
  )
}

///|
test "qc: the period (b/g, -a/g) maps solutions to solutions" {
  @quickcheck.check(
    (p : (Eqn, Int)) => {
      let (e, t) = p
      let r = @linear_diophantine.solve(e.a, e.b, e.c)
      match r.solution {
        None => r.period == (0L, 0L)
        Some((x, y)) => {
          let (dx, dy) = r.period
          let g = gcd(e.a, e.b)
          let expected_period = if e.a == 0L && e.b == 0L {
            (0L, 0L)
          } else if e.a == 0L {
            (1L, 0L)
          } else if e.b == 0L {
            (0L, 1L)
          } else {
            (e.b / g, -(e.a / g))
          }
          let t = (t % 1000).to_int64()
          r.period == expected_period && satisfies(e, x + t * dx, y + t * dy)
        }
      }
    },
    count=1000,
    seed=162,
  )
}

///|
test "qc: solve_min_x returns the least non-negative x of the family" {
  @quickcheck.check(
    (e : Eqn) => {
      let r = @linear_diophantine.solve_min_x(e.a, e.b, e.c)
      match r.solution {
        None => !solvable(e)
        Some((x, y)) => {
          let (dx, _) = r.period
          let dx_abs = if dx < 0L { -dx } else { dx }
          satisfies(e, x, y) && (dx == 0L || (x >= 0L && x < dx_abs))
        }
      }
    },
    count=1000,
    seed=163,
  )
}
