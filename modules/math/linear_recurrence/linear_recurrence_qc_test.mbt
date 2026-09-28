///|
/// A recurrence of order k (0..6) with modulus m in [1, 3037000499] (so
/// a product of two residues fits in Int64), coefficients and initial
/// values in (-m, m) (negative values exercise the normalisation), and an
/// index n that is either small or huge.
priv struct Rec {
  coeffs : Array[Int64]
  initial : Array[Int64]
  m : Int64
  n : Int64
} derive(Debug)

///|
fn below(rs : @quickcheck.RandomState, hi : Int64) -> Int64 {
  rs.next_uint64(limit=hi.reinterpret_as_uint64()).reinterpret_as_int64()
}

///|
impl @quickcheck.Arbitrary for Rec with fn arbitrary(size, rs) {
  let k = rs.next_uint(limit=7).reinterpret_as_int()
  let m = match rs.next_uint(limit=4) {
    0 => 1L + below(rs, 10L)
    1 =>
      [998244353L, 1000000007L, 2147483647L, 3037000499L][rs
      .next_uint(limit=4)
      .reinterpret_as_int()]
    _ => 1L + below(rs, 3037000499L)
  }
  let value = fn() {
    match rs.next_uint(limit=4) {
      0 => below(rs, 3L) - 1L
      1 => m - 1L
      _ => below(rs, 2L * m - 1L) - (m - 1L)
    }
  }
  let coeffs = Array::makei(k, _ => value())
  let initial = Array::makei(k, _ => value())
  let n = match rs.next_uint(limit=3) {
    0 => below(rs, 400L)
    _ => {
      let v : Int64 = @quickcheck.Arbitrary::arbitrary(size, rs)
      if v < 0L {
        -(v + 1L)
      } else {
        v
      }
    }
  }
  { coeffs, initial, m, n, }
}

///|
impl @quickcheck.Shrink for Rec with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.n)
  .filter(n => n >= 0L)
  .map(n => { ..self, n, })
}

///|
fn norm(x : @bigint.BigInt, m : Int64) -> Int64 {
  let bm = @bigint.BigInt::from_int64(m)
  let r = x % bm
  (if r < 0N { r + bm } else { r }).to_int64()
}

///|
fn nth(r : Rec, n : Int64) -> Int64 {
  @linear_recurrence.linear_recurrence_nth(r.coeffs[:], r.initial[:], n, r.m)
}

///|
test "qc: linear_recurrence_nth agrees with direct iteration for n < 400" {
  @quickcheck.check(
    (r : Rec) => {
      let k = r.coeffs.length()
      let n = r.n % 400L
      let expected = if k == 0 {
        0L
      } else {
        let f = r.initial.map(v => @bigint.BigInt::from_int64(v))
        for i = k.to_int64(); i <= n; i = i + 1L {
          let mut s = 0N
          for j in 0..<k {
            s = s +
              @bigint.BigInt::from_int64(r.coeffs[j]) * f[f.length() - 1 - j]
          }
          f.push(@bigint.BigInt::from_int64(norm(s, r.m)))
        }
        norm(f[n.to_int()], r.m)
      }
      nth(r, n) == expected
    },
    count=400,
    seed=191,
    observe=r => {
      [
        @quickcheck.classify(r.coeffs.length() == 0, "k = 0"),
        @quickcheck.classify(r.coeffs.length() == 1, "k = 1"),
        @quickcheck.classify(r.coeffs.any(c => c < 0L), "negative coefficient"),
      ]
    },
  )
}

///|
test "qc: for huge n the result is in [0, m) and satisfies the recurrence" {
  @quickcheck.check(
    (r : Rec) => {
      let k = r.coeffs.length()
      let n = r.n
      let v = nth(r, n)
      let mut s = 0N
      for j in 0..<k {
        s = s +
          @bigint.BigInt::from_int64(r.coeffs[j]) *
          @bigint.BigInt::from_int64(nth(r, n - 1L - j.to_int64()))
      }
      v >= 0L && v < r.m && (k == 0 || v == norm(s, r.m))
    },
    filter=r => r.n >= r.coeffs.length().to_int64(),
    count=200,
    seed=192,
  )
}

///|
test "regression: order-1 recurrence with a negative initial value" {
  // f(n) = 3 * f(n - 1), f(0) = -1: f(2) = -9 ≡ 1 (mod 10), not -9.
  @debug.assert_eq(
    @linear_recurrence.linear_recurrence_nth([3L][:], [-1L][:], 2L, 10L),
    1L,
  )
  @debug.assert_eq(
    @linear_recurrence.linear_recurrence_nth(
      [344345989L][:],
      [-343218237L][:],
      1L,
      2147483647L,
    ),
    norm(-343218237N * 344345989N, 2147483647L),
  )
}
