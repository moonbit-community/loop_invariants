///|
/// A non-negative decimal integer in canonical form (no leading zeros).
/// Mixes random digit strings with carry-heavy shapes (all nines, powers
/// of ten, limb-boundary lengths) and sizes past the Karatsuba cutoff.
priv struct Nat {
  digits : String
} derive(Debug)

///|
fn gen_digits(size : Int, rs : @quickcheck.RandomState) -> String {
  let len = match rs.next_uint(limit=6) {
    0 => rs.next_uint(limit=20).reinterpret_as_int()
    1 => 9 * (1 + rs.next_uint(limit=80).reinterpret_as_int()) // limb boundary
    2 => 280 + rs.next_uint(limit=600).reinterpret_as_int() // > 32 limbs
    _ =>
      rs
      .next_uint(limit=(size * 12 + 2).reinterpret_as_uint())
      .reinterpret_as_int()
  }
  if len == 0 {
    return "0"
  }
  let shape = rs.next_uint(limit=5)
  let sb = StringBuilder()
  for i in 0..<len {
    let d = match shape {
      0 => 9 // 99...9
      1 => if i == 0 { 1 } else { 0 } // 10...0
      _ =>
        if i == 0 {
          1 + rs.next_uint(limit=9).reinterpret_as_int()
        } else {
          rs.next_uint(limit=10).reinterpret_as_int()
        }
    }
    sb.write_char(Int::unsafe_to_char('0'.to_int() + d))
  }
  sb.to_string()
}

///|
impl @quickcheck.Arbitrary for Nat with fn arbitrary(size, rs) {
  { digits: gen_digits(size, rs), }
}

///|
impl @quickcheck.Shrink for Nat with fn shrink(self) {
  // Drop trailing digits (keeps the value canonical and non-empty).
  let n = self.digits.length()
  let out = []
  if n > 1 {
    out.push({ digits: self.digits.view(end_offset=n / 2).to_owned(), })
    out.push({ digits: self.digits.view(end_offset=n - 1).to_owned(), })
  }
  out.iter()
}

///|
fn to_big(n : Nat) -> @bigint.BigInt {
  @bigint.BigInt::from_string(n.digits)
}

///|
/// Canonical: every limb in [0, 10^9) and no leading zero limb (except [0]).
fn canonical(x : Array[Int64]) -> Bool {
  x.length() >= 1 &&
  x.all(l => l >= 0L && l < 1000000000L) &&
  (x.length() == 1 || x[x.length() - 1] != 0L)
}

///|
test "qc: to_string(from_string(s)) == s for canonical decimal strings" {
  @quickcheck.check(
    (n : Nat) => {
      let limbs = @karatsuba.from_string(n.digits)
      canonical(limbs) && @karatsuba.to_string(limbs) == n.digits
    },
    count=300,
    seed=91,
  )
}

///|
test "qc: from_string ignores leading zeros" {
  @quickcheck.check(
    (p : (Nat, Int)) => {
      let (n, k) = p
      let pad = "0".repeat((k % 20).abs())
      @karatsuba.from_string(pad + n.digits) == @karatsuba.from_string(n.digits)
    },
    count=200,
    seed=92,
  )
}

///|
test "qc: mul agrees with BigInt and with mul_naive" {
  @quickcheck.check(
    (p : (Nat, Nat)) => {
      let a = @karatsuba.from_string(p.0.digits)
      let b = @karatsuba.from_string(p.1.digits)
      let got = @karatsuba.mul(a, b)
      canonical(got) &&
      @karatsuba.to_string(got) == (to_big(p.0) * to_big(p.1)).to_string() &&
      got == @karatsuba.mul_naive(a, b)
    },
    count=200,
    seed=93,
    observe=p => {
      let la = @karatsuba.from_string(p.0.digits).length()
      let lb = @karatsuba.from_string(p.1.digits).length()
      [
        @quickcheck.classify(la >= 32 && lb >= 32, "karatsuba path"),
        @quickcheck.classify(
          p.0.digits == "0" || p.1.digits == "0",
          "zero operand",
        ),
      ]
    },
  )
}

///|
test "qc: add agrees with BigInt and is commutative" {
  @quickcheck.check(
    (p : (Nat, Nat)) => {
      let a = @karatsuba.from_string(p.0.digits)
      let b = @karatsuba.from_string(p.1.digits)
      let s = @karatsuba.add(a, b)
      canonical(s) &&
      @karatsuba.to_string(s) == (to_big(p.0) + to_big(p.1)).to_string() &&
      s == @karatsuba.add(b, a)
    },
    count=300,
    seed=94,
  )
}

///|
test "qc: sub(a, b) agrees with BigInt when a >= b, and inverts add" {
  @quickcheck.check(
    (p : (Nat, Nat)) => {
      let (x, y) = if to_big(p.0) >= to_big(p.1) { p } else { (p.1, p.0) }
      let a = @karatsuba.from_string(x.digits)
      let b = @karatsuba.from_string(y.digits)
      let d = @karatsuba.sub(a, b)
      canonical(d) &&
      @karatsuba.to_string(d) == (to_big(x) - to_big(y)).to_string() &&
      @karatsuba.sub(@karatsuba.add(a, b), b) == a
    },
    count=300,
    seed=95,
  )
}
