// Property-based tests for the shipping-capacity "binary search on answer":
// `can_ship` is compared with an `Int64` greedy reference and `min_capacity`
// with an `Int64` search over the answer, on non-negative weights that
// include values near `Int::MAX_VALUE`.

///|
const IMAX : Int = 2147483647

///|
const IMIN : Int = -2147483648

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Arrays whose elements come from one of three regimes: a tiny range (many
/// duplicates), full-range `Int` (hits the extrema), or a per-element mix of
/// small values and `Int` extrema.
priv struct Ints {
  xs : Array[Int]
}

///|
impl @quickcheck.Arbitrary for Ints with fn arbitrary(size, rs) {
  let len = rint(rs, 0, size)
  let mode = rint(rs, 0, 3)
  let xs = Array::makei(len, _ => {
    match mode {
      0 | 1 => rint(rs, -3, 3)
      2 => @quickcheck.Arbitrary::arbitrary(size, rs)
      _ =>
        if rint(rs, 0, 3) == 0 {
          [IMAX, IMIN, 0][rint(rs, 0, 2)]
        } else {
          rint(rs, -3, 3)
        }
    }
  })
  { xs, }
}

///|
/// Non-negative weights (negative draws are mapped with `lnot`, so `IMIN`
/// becomes `IMAX`) and a day budget `>= 1`.
priv struct Ship {
  ws : Array[Int]
  days : Int
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Ship with fn arbitrary(size, rs) {
  let a : Ints = @quickcheck.Arbitrary::arbitrary(size, rs)
  let ws = a.xs.map(x => if x < 0 { x.lnot() } else { x })
  let days = if rint(rs, 0, 7) == 0 {
    rint(rs, 1, IMAX)
  } else {
    rint(rs, 1, ws.length() + 1)
  }
  { ws, days, }
}

///|
impl @quickcheck.Shrink for Ship with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.ws, self.days)).map(p => {
    let (ws, days) = p
    {
      ws: ws.map(x => if x < 0 { x.lnot() } else { x }),
      days: if days < 1 {
        1
      } else {
        days
      },
    }
  })
}

///|
/// Greedy day count with 64-bit loads; `None` if some weight exceeds `cap`.
fn days_needed64(ws : Array[Int], cap : Int64) -> Int? {
  let mut used = 1
  let mut load = 0L
  for w in ws {
    let w = w.to_int64()
    if w > cap {
      return None
    }
    if load + w > cap {
      used = used + 1
      load = w
    } else {
      load = load + w
    }
  }
  Some(used)
}

///|
fn ref_can_ship(ws : Array[Int], days : Int, cap : Int) -> Bool {
  if days <= 0 || cap < 0 || ws.iter().any(w => w < 0) {
    return false
  }
  match days_needed64(ws, cap.to_int64()) {
    Some(d) => d <= days
    None => false
  }
}

///|
/// Smallest feasible capacity, searched over `Int64` so it cannot overflow.
fn ref_min_capacity(ws : Array[Int], days : Int) -> Int64 {
  let mut lo = 0L
  let mut hi = 0L
  for w in ws {
    hi = hi + w.to_int64()
  }
  while lo < hi {
    let mid = lo + (hi - lo) / 2L
    let ok = match days_needed64(ws, mid) {
      Some(d) => d <= days
      None => false
    }
    if ok {
      hi = mid
    } else {
      lo = mid + 1L
    }
  }
  lo
}

///|
test "qc: can_ship agrees with a 64-bit greedy reference" {
  @quickcheck.check(
    (input : (Ship, Int)) => {
      let (s, cap) = input
      // Aim the capacity near interesting values half of the time.
      let cap = if cap % 2 == 0 && s.ws.length() > 0 {
        s.ws[(cap / 2 % s.ws.length()).abs()]
      } else {
        cap
      }
      @challenge_binary_search_answer.can_ship(s.ws[:], s.days, cap) ==
      ref_can_ship(s.ws, s.days, cap)
    },
    count=400,
    max_size=40,
    max_shrinks=1000,
    seed=31,
  )
}

///|
test "qc: can_ship is monotone in capacity" {
  @quickcheck.check(
    (input : (Ship, Int)) => {
      let (s, cap) = input
      !@challenge_binary_search_answer.can_ship(s.ws[:], s.days, cap) ||
      @challenge_binary_search_answer.can_ship(s.ws[:], s.days, cap + 1)
    },
    filter=input => input.1 < IMAX,
    count=300,
    max_size=40,
    max_shrinks=1000,
    seed=32,
  )
}

///|
test "qc: min_capacity is the smallest feasible capacity" {
  @quickcheck.check(
    (s : Ship) => {
      let expected = ref_min_capacity(s.ws, s.days)
      @challenge_binary_search_answer.min_capacity(s.ws[:], s.days).to_int64() ==
      expected
    },
    // Only inputs whose answer is representable as an `Int`.
    filter=s => ref_min_capacity(s.ws, s.days) <= IMAX.to_int64(),
    count=400,
    max_size=40,
    max_shrinks=1000,
    seed=33,
    observe=s => {
      let total = s.ws.fold(init=0L, (acc, w) => acc + w.to_int64())
      [
        @quickcheck.classify(s.ws.length() == 0, "no weights"),
        @quickcheck.classify(s.days >= s.ws.length(), "days >= n"),
        @quickcheck.classify(
          total > IMAX.to_int64(),
          "sum of weights > Int max",
        ),
      ]
    },
  )
}

///|
test "qc: min_capacity on small weights matches a linear scan" {
  @quickcheck.check(
    (s : Ship) => {
      let ws = s.ws.map(w => w % 20)
      let got = @challenge_binary_search_answer.min_capacity(ws[:], s.days)
      let mut c = 0
      while !ref_can_ship(ws, s.days, c) {
        c = c + 1
      }
      got == c
    },
    count=300,
    max_size=30,
    seed=34,
  )
}

///|
test "regression: can_ship day load overflow" {
  // Days needed at capacity 2147483645 are [1] [2147483645] [3] = 3, but the
  // running load `2147483645 + 3` used to wrap negative and "fit".
  inspect(
    @challenge_binary_search_answer.can_ship([1, 2147483645, 3], 2, 2147483645),
    content="false",
  )
  inspect(
    @challenge_binary_search_answer.can_ship([1, 2147483645, 3], 3, 2147483645),
    content="true",
  )
}

///|
test "regression: min_capacity weight sum overflow" {
  // The weights sum to 2^31, so the search's upper bound used to wrap to
  // `Int::MIN_VALUE` and the search returned max(weights) = 2029815057,
  // which is not feasible in 2 days.
  inspect(
    @challenge_binary_search_answer.min_capacity(
      [50559729, 2029815057, 67108862],
      2,
    ),
    content="2080374786",
  )
}
