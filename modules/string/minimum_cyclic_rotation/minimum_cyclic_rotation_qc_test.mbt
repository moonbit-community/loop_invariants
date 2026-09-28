// Property-based tests for the minimum cyclic rotation: the result is the
// lexicographically smallest rotation (by UTF-16 code units, the unit
// `String` indexing uses) and the index is the smallest one producing it.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Tiny alphabet so that matches and long borders are frequent.
let small_alpha : Array[Char] = ['a', 'b', 'c']

///|
/// Characters that tend to break implementations: sentinel-like symbols,
/// upper case, NUL, non-ASCII BMP and astral (surrogate pair) characters.
let spicy_alpha : Array[Char] = [
  'a', 'b', '$', '#', 'A', '0', 'é', '\u{0}', '\u{FFFF}', '😀',
]

///|
fn gen_str(
  rs : @quickcheck.RandomState,
  alpha : Array[Char],
  max_len : Int,
) -> String {
  let len = rint(rs, 0, max_len)
  let sb = StringBuilder()
  for _ in 0..<len {
    sb.write_char(alpha[rint(rs, 0, alpha.length() - 1)])
  }
  sb.to_string()
}

///|
fn gen_text(rs : @quickcheck.RandomState, size : Int) -> String {
  let k = rint(rs, 0, 9)
  if k < 5 {
    gen_str(rs, small_alpha, size)
  } else if k < 8 {
    gen_str(rs, spicy_alpha, size)
  } else {
    @quickcheck.Arbitrary::arbitrary(size, rs)
  }
}

///|
/// A single string drawn from the same distribution as search texts.
priv struct Str(String) derive(Debug)

///|
impl @quickcheck.Arbitrary for Str with fn arbitrary(size, rs) {
  Str(gen_text(rs, size))
}

///|
impl @quickcheck.Shrink for Str with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).map(s => Str(s))
}

///|
fn has_astral(s : String) -> Bool {
  for c in s {
    if c.to_int() > 0xFFFF {
      return true
    }
  }
  false
}

///|
/// Code units of the rotation of `s` starting at `k`.
fn rotation(s : String, k : Int) -> Array[UInt16] {
  let n = s.length()
  Array::makei(n, i => s[(k + i) % n])
}

///|
fn units(s : String) -> Array[UInt16] {
  Array::makei(s.length(), i => s[i])
}

///|
/// Lexicographic order on code-unit arrays of equal length.
fn less(a : Array[UInt16], b : Array[UInt16]) -> Bool {
  for i in 0..<a.length() {
    if a[i] != b[i] {
      return a[i] < b[i]
    }
  }
  false
}

///|
test "qc: min_cyclic_rotation is the least rotation, index is the first one" {
  @quickcheck.check(
    (s : Str) => {
      let str = s.0
      let n = str.length()
      // naive: first index of a least rotation
      let mut best = 0
      for k in 1..<n {
        if less(rotation(str, k), rotation(str, best)) {
          best = k
        }
      }
      let idx = @minimum_cyclic_rotation.min_cyclic_rotation_index(str)
      let rot = @minimum_cyclic_rotation.min_cyclic_rotation(str)
      idx == best &&
      units(rot) == (if n == 0 { [] } else { rotation(str, best) })
    },
    observe=s => {
      let n = s.0.length()
      let mut period = n
      for p in 1..<n {
        if n % p == 0 && rotation(s.0, p) == units(s.0) {
          period = p
          break
        }
      }
      [
        @quickcheck.classify(period < n, "periodic string"),
        @quickcheck.classify(has_astral(s.0), "astral chars"),
      ]
    },
    count=500,
    max_size=30,
    seed=0x3c0001,
  )
}

///|
test "qc: min_cyclic_rotation is invariant under rotating a (periodic) input" {
  @quickcheck.check(
    (c : (Str, Int, Int)) => {
      // repeat the base 1-3 times so periodic inputs are common
      let str = c.0.0.repeat((c.2 % 3).abs() + 1)
      let n = str.length()
      guard n > 0 else { return true }
      let k = (c.1 % n).abs()
      // rotate by code units through the doubled string
      let rotated = (str + str)
        .view(start_offset=k, end_offset=k + n)
        .to_owned()
      let expected = @minimum_cyclic_rotation.min_cyclic_rotation(str)
      units(@minimum_cyclic_rotation.min_cyclic_rotation(rotated)) ==
      units(expected) &&
      units(expected) ==
      rotation(str, @minimum_cyclic_rotation.min_cyclic_rotation_index(str))
    },
    observe=c => {
      [
        @quickcheck.classify(
          (c.2 % 3).abs() > 0 && c.0.0.length() > 0,
          "periodic input",
        ),
      ]
    },
    count=300,
    max_size=20,
    seed=0x3c0002,
  )
}
