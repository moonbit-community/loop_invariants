// Property-based tests for coin-change counting and `min_coins` against
// explicit enumeration (multisets) and a recursive definition (sequences),
// on distinct positive denominations as documented.

///|
const MOD : Int64 = 1000000007L

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Distinct positive coins (possibly one far larger than any amount) and an
/// amount in `[-2, 30]`.
priv struct Change {
  coins : Array[Int]
  amount : Int
} derive(Debug)

///|
fn distinct_positive(xs : Array[Int]) -> Array[Int] {
  let out : Array[Int] = []
  for x in xs {
    let x = if x <= 0 { 1 - x } else { x }
    if !out.contains(x) {
      out.push(x)
    }
  }
  out
}

///|
impl @quickcheck.Arbitrary for Change with fn arbitrary(_, rs) {
  let coins = Array::makei(rint(rs, 0, 4), _ => {
    if rint(rs, 0, 9) == 0 {
      2147483647
    } else {
      rint(rs, 1, 6)
    }
  })
  { coins: distinct_positive(coins), amount: rint(rs, -2, 30), }
}

///|
impl @quickcheck.Shrink for Change with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.coins, self.amount)).map(p => {
    coins: distinct_positive(p.0),
    amount: p.1,
  })
}

///|
/// Enumerates multisets by choosing a count for each coin; returns
/// `(number of multisets, fewest coins or -1)`.
fn enumerate(coins : Array[Int], amount : Int) -> (Int64, Int) {
  if amount < 0 {
    return (0L, -1)
  }
  let mut ways = 0L
  let mut best = -1
  fn go(i : Int, remaining : Int, used : Int) -> Unit {
    if i == coins.length() {
      if remaining == 0 {
        ways = ways + 1L
        if best == -1 || used < best {
          best = used
        }
      }
      return
    }
    let c = coins[i]
    for k = 0; k * c <= remaining; k = k + 1 {
      go(i + 1, remaining - k * c, used + k)
      if c > remaining {
        break
      }
    }
  }

  go(0, amount, 0)
  (ways % MOD, best)
}

///|
/// Ordered sequences: `f(0) = 1`, `f(a) = sum_{c <= a} f(a - c)`, memoised.
fn ref_ordered(coins : Array[Int], amount : Int) -> Int64 {
  if amount < 0 {
    return 0L
  }
  let memo : Map[Int, Int64] = Map([])
  fn f(a : Int) -> Int64 {
    if a == 0 {
      return 1L
    }
    match memo.get(a) {
      Some(v) => return v
      None => ()
    }
    let mut s = 0L
    for c in coins {
      if c <= a {
        s = (s + f(a - c)) % MOD
      }
    }
    memo[a] = s
    s
  }

  f(amount)
}

///|
test "qc: count_unordered counts coin multisets" {
  @quickcheck.check(
    (c : Change) => {
      @coin_change_count.count_unordered(c.coins, c.amount) ==
      enumerate(c.coins, c.amount).0
    },
    count=400,
    max_shrinks=1000,
    seed=261,
    observe=c => {
      let (ways, _) = enumerate(c.coins, c.amount)
      [
        @quickcheck.classify(ways == 0L, "no way"),
        @quickcheck.classify(ways >= 10L, ">= 10 ways"),
        @quickcheck.classify(c.amount <= 0, "amount <= 0"),
      ]
    },
  )
}

///|
test "qc: count_ordered matches the recursive composition count" {
  @quickcheck.check(
    (c : Change) => {
      @coin_change_count.count_ordered(c.coins, c.amount) ==
      ref_ordered(c.coins, c.amount)
    },
    count=400,
    max_shrinks=1000,
    seed=262,
  )
}

///|
test "qc: min_coins is the fewest coins over all multisets (-1 if none)" {
  @quickcheck.check(
    (c : Change) => {
      @coin_change_count.min_coins(c.coins, c.amount) ==
      enumerate(c.coins, c.amount).1
    },
    count=400,
    max_shrinks=1000,
    seed=263,
  )
}

///|
test "qc: ordered count >= unordered count, equal with at most one coin" {
  @quickcheck.check(
    (c : Change) => {
      let u = @coin_change_count.count_unordered(c.coins, c.amount)
      let o = @coin_change_count.count_ordered(c.coins, c.amount)
      o >= u && (c.coins.length() > 1 || o == u)
    },
    seed=264,
  )
}
