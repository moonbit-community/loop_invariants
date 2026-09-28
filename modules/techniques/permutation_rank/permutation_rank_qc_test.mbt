// Property-based tests for Lehmer-code rank / unrank: round trips, the
// lexicographic enumeration of all n! permutations, and the documented
// empty-array / zero results outside the supported range.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
fn fact(n : Int) -> Int64 {
  let mut r = 1L
  for i in 2..<=n {
    r = r * i.to_int64()
  }
  r
}

///|
/// A uniformly random permutation of `{0, ..., n-1}`, `n` in `[0, 20]`
/// (sometimes forced to the largest supported size).
priv struct Perm {
  p : Array[Int]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Perm with fn arbitrary(size, rs) {
  let n = if rint(rs, 0, 4) == 0 {
    20
  } else {
    rint(rs, 0, if size < 20 { size } else { 20 })
  }
  let p = Array::makei(n, i => i)
  for i = n - 1; i > 0; i = i - 1 {
    let j = rint(rs, 0, i)
    let t = p[i]
    p[i] = p[j]
    p[j] = t
  }
  { p, }
}

///|
/// Shrinking would break the permutation invariant, so none is offered.
impl @quickcheck.Shrink for Perm

///|
fn is_perm(p : Array[Int], n : Int) -> Bool {
  if p.length() != n {
    return false
  }
  let seen = Array::make(n, false)
  for x in p {
    if x < 0 || x >= n || seen[x] {
      return false
    }
    seen[x] = true
  }
  true
}

///|
/// Lexicographic `<` on equal-length arrays.
fn lex_less(a : Array[Int], b : Array[Int]) -> Bool {
  for i in 0..<a.length() {
    if a[i] != b[i] {
      return a[i] < b[i]
    }
  }
  false
}

///|
test "qc: unrank(n, rank(p)) == p and 0 <= rank(p) < n!" {
  @quickcheck.check(
    (perm : Perm) => {
      let n = perm.p.length()
      let r = @permutation_rank.rank(perm.p)
      if n == 0 {
        // Documented: rank of the empty permutation is 0; unrank(0, _) is [].
        r == 0L && @permutation_rank.unrank(0, r) == []
      } else {
        r >= 0L && r < fact(n) && @permutation_rank.unrank(n, r) == perm.p
      }
    },
    count=300,
    max_size=20,
    seed=81,
    observe=perm => {
      let n = perm.p.length()
      [
        @quickcheck.classify(n == 20, "n == 20 (n! near Int64 limit)"),
        @quickcheck.classify(n <= 1, "n <= 1"),
      ]
    },
  )
}

///|
test "qc: rank(unrank(n, r)) == r for random r in [0, n!)" {
  @quickcheck.check(
    (input : (Int, UInt64)) => {
      let n = (input.0 % 20).abs() + 1
      let r = (input.1 % fact(n).reinterpret_as_uint64()).reinterpret_as_int64()
      let p = @permutation_rank.unrank(n, r)
      is_perm(p, n) && @permutation_rank.rank(p) == r
    },
    count=300,
    seed=82,
  )
}

///|
test "qc: unrank enumerates all n! permutations in lexicographic order" {
  @quickcheck.check(
    (k : Int) => {
      let n = (k % 7).abs() + 1
      let total = fact(n)
      let mut prev : Array[Int] = []
      for r = 0L; r < total; r = r + 1L {
        let p = @permutation_rank.unrank(n, r)
        if !is_perm(p, n) || (r > 0L && !lex_less(prev, p)) {
          return false
        }
        prev = p
      }
      // First is the identity, last is the reversal.
      @permutation_rank.unrank(n, 0L) == Array::makei(n, i => i) &&
      prev == Array::makei(n, i => n - 1 - i)
    },
    count=20,
    seed=83,
  )
}

///|
test "qc: unrank returns [] outside n in [1, 20] or r in [0, n!)" {
  @quickcheck.check(
    (input : (Int, Int64)) => {
      let (n, r) = input
      let in_range = n >= 1 && n <= 20 && r >= 0L && r < fact(n)
      let p = @permutation_rank.unrank(n, r)
      if in_range {
        is_perm(p, n)
      } else {
        p == []
      }
    },
    count=300,
    seed=84,
  )
}
