// Property-based tests for `min_coins` against explicit enumeration of coin
// multisets. Non-positive coins are documented as ignored.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
priv struct Change {
  coins : Array[Int]
  amount : Int
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Change with fn arbitrary(_, rs) {
  // Mostly positive small coins (duplicates allowed), sometimes 0,
  // negatives or a coin larger than any amount.
  let coins = Array::makei(rint(rs, 0, 4), _ => {
    match rint(rs, 0, 9) {
      0 => rint(rs, -3, 0)
      1 => 2147483647
      _ => rint(rs, 1, 6)
    }
  })
  { coins, amount: rint(rs, -2, 30), }
}

///|
impl @quickcheck.Shrink for Change with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.coins, self.amount)).map(p => {
    coins: p.0,
    amount: p.1,
  })
}

///|
/// Fewest coins over every multiset of the positive coins summing to
/// `amount`, by enumerating how many of each coin is used.
fn ref_min(coins : Array[Int], amount : Int) -> Int? {
  if amount < 0 {
    return None
  }
  let pos = coins.filter(c => c > 0)
  let mut best : Int? = None
  fn go(i : Int, remaining : Int, used : Int) -> Unit {
    if i == pos.length() {
      if remaining == 0 {
        match best {
          Some(b) if b <= used => ()
          _ => best = Some(used)
        }
      }
      return
    }
    let c = pos[i]
    for k = 0; k * c <= remaining; k = k + 1 {
      go(i + 1, remaining - k * c, used + k)
      if c > remaining {
        break
      }
    }
  }

  go(0, amount, 0)
  best
}

///|
test "qc: min_coins matches enumeration of coin multisets" {
  @quickcheck.check(
    (c : Change) => {
      @challenge_coin_change_min.min_coins(c.coins[:], c.amount) ==
      ref_min(c.coins, c.amount)
    },
    count=400,
    max_shrinks=1000,
    seed=251,
    observe=c => {
      let r = ref_min(c.coins, c.amount)
      [
        @quickcheck.classify(r is None, "impossible"),
        @quickcheck.classify(r is Some(k) && k >= 3, ">= 3 coins"),
        @quickcheck.classify(
          c.coins.iter().any(x => x <= 0),
          "non-positive coin",
        ),
        @quickcheck.classify(c.amount <= 0, "amount <= 0"),
      ]
    },
  )
}
