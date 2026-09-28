///|
fn big(x : Int64) -> @bigint.BigInt {
  @bigint.BigInt::from_int64(x)
}

///|
/// `a mod m` in `[0, m)` on big integers.
fn bmod(a : @bigint.BigInt, m : @bigint.BigInt) -> @bigint.BigInt {
  let r = a % m
  if r < 0N {
    r + m
  } else {
    r
  }
}

///|
fn gcd64(a : Int64, b : Int64) -> Int64 {
  if b == 0L {
    a
  } else {
    gcd64(b, a % b)
  }
}

///|
fn congruent(x : Int64, r : Int64, m : Int64) -> Bool {
  bmod(big(x) - big(r), big(m)).is_zero()
}

///|
fn rand_below(rs : @quickcheck.RandomState, bits : Int) -> Int64 {
  if bits <= 0 {
    0L
  } else {
    rs.next_uint64(limit=1UL << bits).reinterpret_as_int64()
  }
}

///|
/// Two positive moduli whose lcm is at most 2^62 (the bound the README
/// documents), with a controlled common factor, and two residues. Residues
/// are either derived from a common solution `t` (so the system is
/// consistent) or arbitrary Int64 values (including negatives/extrema).
priv struct MergeCase {
  r1 : Int64
  m1 : Int64
  r2 : Int64
  m2 : Int64
} derive(Debug)

///|
impl @quickcheck.Arbitrary for MergeCase with fn arbitrary(size, rs) {
  let g_bits = if rs.next_uint(limit=2) == 0 {
    0
  } else {
    rs.next_uint(limit=21).reinterpret_as_int()
  }
  let a_bits = rs
    .next_uint(limit=(63 - g_bits).reinterpret_as_uint())
    .reinterpret_as_int()
  let b_bits = 61 - g_bits - a_bits
  let g = rand_below(rs, g_bits) + 1L
  let (a, b) = if rs.next_uint(limit=4) == 0 {
    // small moduli
    (rand_below(rs, 6) + 1L, rand_below(rs, 6) + 1L)
  } else {
    (rand_below(rs, a_bits) + 1L, rand_below(rs, b_bits) + 1L)
  }
  let m1 = g * a
  let m2 = g * b
  match rs.next_uint(limit=3) {
    0 => {
      let t : Int64 = @quickcheck.Arbitrary::arbitrary(size, rs)
      let r1 = bmod(big(t), big(m1)).to_int64()
      let r2 = bmod(big(t), big(m2)).to_int64()
      { r1, m1, r2, m2, }
    }
    1 => {
      // consistent, but residues shifted by multiples of the moduli
      let t : Int64 = @quickcheck.Arbitrary::arbitrary(size, rs)
      let r1 = bmod(big(t), big(m1)).to_int64() - m1 * rand_below(rs, 2)
      let r2 = bmod(big(t), big(m2)).to_int64() + m2 * rand_below(rs, 1)
      { r1, m1, r2, m2, }
    }
    _ =>
      {
        r1: @quickcheck.Arbitrary::arbitrary(size, rs),
        m1,
        r2: @quickcheck.Arbitrary::arbitrary(size, rs),
        m2,
      }
  }
}

///|
impl @quickcheck.Shrink for MergeCase with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.r1, self.m1, self.r2, self.m2))
  .filter(p => {
    p.1 > 0L &&
    p.3 > 0L &&
    big(p.1) / big(gcd64(p.1, p.3)) * big(p.3) <= 4611686018427387904N
  })
  .map(p => { r1: p.0, m1: p.1, r2: p.2, m2: p.3, })
}

///|
test "qc: merge solves both congruences whenever lcm <= 2^62" {
  @quickcheck.check(
    (c : MergeCase) => {
      let g = gcd64(c.m1, c.m2)
      let lcm = c.m1 / g * c.m2
      let consistent = bmod(big(c.r1) - big(c.r2), big(g)).is_zero()
      match @crt.merge(c.r1, c.m1, c.r2, c.m2) {
        None => !consistent
        Some((x, m)) =>
          consistent &&
          m == lcm &&
          x >= 0L &&
          x < m &&
          congruent(x, c.r1, c.m1) &&
          congruent(x, c.r2, c.m2)
      }
    },
    count=1000,
    seed=51,
    observe=c => {
      let g = gcd64(c.m1, c.m2)
      [
        @quickcheck.classify(g == 1L, "coprime moduli"),
        @quickcheck.classify(
          bmod(big(c.r1) - big(c.r2), big(g)).is_zero(),
          "consistent",
        ),
        @quickcheck.classify(
          c.m1 / g * c.m2 > 1000000000000000000L,
          "lcm > 10^18",
        ),
      ]
    },
  )
}

///|
/// A small system (1..4 congruences, moduli 1..12) with arbitrary residues.
priv struct SmallSystem {
  residues : Array[Int64]
  moduli : Array[Int64]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for SmallSystem with fn arbitrary(size, rs) {
  let k = 1 + rs.next_uint(limit=4).reinterpret_as_int()
  let residues = []
  let moduli = []
  for _ in 0..<k {
    moduli.push(rs.next_uint64(limit=12UL).reinterpret_as_int64() + 1L)
    residues.push(
      if rs.next_uint(limit=3) == 0 {
        @quickcheck.Arbitrary::arbitrary(size, rs)
      } else {
        rs.next_uint64(limit=30UL).reinterpret_as_int64() - 5L
      },
    )
  }
  { residues, moduli, }
}

///|
impl @quickcheck.Shrink for SmallSystem with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.residues, self.moduli))
  .filter(p => {
    p.0.length() == p.1.length() && p.0.length() > 0 && p.1.all(m => m > 0L)
  })
  .map(p => { residues: p.0, moduli: p.1, })
}

///|
test "qc: solve returns the least non-negative solution and the lcm (brute force)" {
  @quickcheck.check(
    (s : SmallSystem) => {
      let mut lcm = 1L
      for m in s.moduli {
        lcm = lcm / gcd64(lcm, m) * m
      }
      let mut expected : Int64? = None
      for x in 0L..<lcm {
        let mut ok = true
        for i in 0..<s.moduli.length() {
          ok = ok && congruent(x, s.residues[i], s.moduli[i])
        }
        if ok {
          expected = Some(x)
          break
        }
      }
      match (@crt.solve(s.residues, s.moduli), expected) {
        (None, None) => true
        (Some((x, m)), Some(e)) => x == e && m == lcm
        _ => false
      }
    },
    count=500,
    seed=52,
  )
}

///|
test "qc: solve rejects empty, mismatched and non-positive-modulus input" {
  @quickcheck.check(
    (p : (Array[Int64], Array[Int64])) => {
      let (residues, moduli) = p
      let invalid = residues.length() != moduli.length() ||
        residues.length() == 0 ||
        moduli.any(m => m <= 0L)
      !invalid || @crt.solve(residues, moduli) is None
    },
    count=300,
    seed=53,
  )
}

///|
test "regression: merge with large moduli (lcm < 2^62)" {
  // (diff / g mod m2g) * p overflowed Int64 once m2 / g exceeded ~3 * 10^9.
  let (r1, m1) = (29048632L, 50594867L)
  let (r2, m2) = (365007164796592L, 375767370039302L)
  match @crt.merge(r1, m1, r2, m2) {
    Some((x, m)) => {
      @debug.assert_eq(m, m1 / gcd64(m1, m2) * m2)
      @debug.assert_eq(congruent(x, r1, m1) && congruent(x, r2, m2), true)
      @debug.assert_eq(0L <= x && x < m, true)
    }
    None => @debug.assert_eq(true, false)
  }
}

///|
test "regression: merge and solve with residues near Int64 extrema" {
  // r2 - r1 overflowed for residues far outside [0, m).
  let min = -9223372036854775808L
  let max = 9223372036854775807L
  match @crt.merge(max, 10L, min, 7L) {
    Some((x, m)) => {
      @debug.assert_eq(m, 70L)
      @debug.assert_eq(congruent(x, max, 10L) && congruent(x, min, 7L), true)
    }
    None => @debug.assert_eq(true, false)
  }
  match @crt.solve([3L, min], [5L, 7L]) {
    Some((x, m)) => {
      @debug.assert_eq(m, 35L)
      @debug.assert_eq(congruent(x, 3L, 5L) && congruent(x, min, 7L), true)
    }
    None => @debug.assert_eq(true, false)
  }
}
