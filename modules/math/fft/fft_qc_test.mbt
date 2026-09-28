///|
fn norm(v : Int64) -> Int64 {
  let r = v % @fft.NTT_MOD
  if r < 0L {
    r + @fft.NTT_MOD
  } else {
    r
  }
}

///|
/// Schoolbook convolution mod NTT_MOD on big integers (no overflow for any
/// Int64 coefficients).
fn naive_conv(a : Array[Int64], b : Array[Int64]) -> Array[Int64] {
  if a.length() == 0 || b.length() == 0 {
    return []
  }
  let m = @bigint.BigInt::from_int64(@fft.NTT_MOD)
  let res = Array::make(a.length() + b.length() - 1, 0N)
  for i, x in a {
    for j, y in b {
      res[i + j] = res[i + j] +
        @bigint.BigInt::from_int64(x) * @bigint.BigInt::from_int64(y)
    }
  }
  res.map(v => norm((v % m).to_int64()))
}

///|
/// A polynomial with coefficients either reduced (in `[0, NTT_MOD)`,
/// often `NTT_MOD - 1`) or raw Int64 values (negative, huge, extrema).
priv struct Poly {
  coeffs : Array[Int64]
} derive(Debug)

///|
fn reduced_poly(size : Int, rs : @quickcheck.RandomState) -> Array[Int64] {
  let len = if rs.next_uint(limit=10) == 0 {
    rs.next_uint(limit=300).reinterpret_as_int()
  } else {
    rs.next_uint(limit=(size + 2).reinterpret_as_uint()).reinterpret_as_int()
  }
  Array::makei(len, _ => {
    match rs.next_uint(limit=4) {
      0 => @fft.NTT_MOD - 1L
      1 => rs.next_uint64(limit=10UL).reinterpret_as_int64()
      _ =>
        rs
        .next_uint64(limit=@fft.NTT_MOD.reinterpret_as_uint64())
        .reinterpret_as_int64()
    }
  })
}

///|
impl @quickcheck.Arbitrary for Poly with fn arbitrary(size, rs) {
  { coeffs: reduced_poly(size, rs), }
}

///|
impl @quickcheck.Shrink for Poly with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.coeffs)
  .filter(c => c.all(v => v >= 0L && v < @fft.NTT_MOD))
  .map(coeffs => { coeffs, })
}

///|
test "qc: ntt_convolution equals the schoolbook product mod NTT_MOD" {
  @quickcheck.check(
    (p : (Poly, Poly)) => {
      let (a, b) = (p.0.coeffs, p.1.coeffs)
      @fft.ntt_convolution(a[:], b[:]) == naive_conv(a, b)
    },
    count=200,
    max_size=40,
    seed=81,
    observe=p => {
      let n = p.0.coeffs.length() + p.1.coeffs.length()
      [
        @quickcheck.classify(
          p.0.coeffs.length() == 0 || p.1.coeffs.length() == 0,
          "empty operand",
        ),
        @quickcheck.classify(n > 64, "result length > 64"),
      ]
    },
  )
}

///|
test "qc: ntt_convolution is commutative" {
  @quickcheck.check(
    (p : (Poly, Poly)) => {
      let (a, b) = (p.0.coeffs, p.1.coeffs)
      @fft.ntt_convolution(a[:], b[:]) == @fft.ntt_convolution(b[:], a[:])
    },
    count=100,
    max_size=40,
    seed=82,
  )
}

///|
test "qc: raw Int64 coefficients give a result congruent to the product" {
  // The README asks callers to normalise negative coefficients, so only
  // congruence mod NTT_MOD (not the range of the output) is asserted.
  @quickcheck.check(
    (p : (Array[Int64], Array[Int64])) => {
      let (a, b) = p
      let got = @fft.ntt_convolution(a[:], b[:])
      got.map(norm) == naive_conv(a, b)
    },
    count=200,
    max_size=30,
    seed=83,
  )
}
