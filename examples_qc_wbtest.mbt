// Property-based tests for the root examples (examples*.mbt).
//
// The functions under test are private teaching examples, so these are
// white-box tests. Each property compares an invariant-annotated loop against
// a naive reference model or states a law that follows from its contract.

// ---------------------------------------------------------------------------
// Generators
// ---------------------------------------------------------------------------

///|
/// Integers biased towards small values (duplicates, zero, signs) while still
/// reaching overflow-prone boundaries.
fn gen_int_mixed() -> @quickcheck.Generator[Int] {
  @quickcheck.frequency([
    (4, @quickcheck.int_range(-8, 9)),
    (2, @quickcheck.int_range(-1000, 1001)),
    (
      1,
      @quickcheck.elements([
        @int.MAX_VALUE,
        @int.MAX_VALUE - 1,
        @int.MIN_VALUE,
        @int.MIN_VALUE + 1,
        46340,
        46341,
        -46341,
        65536,
      ]),
    ),
    (2, @quickcheck.spawn()),
  ])
}

///|
fn gen_array(
  elem : @quickcheck.Generator[Int],
  max_len : Int,
) -> @quickcheck.Generator[Array[Int]] {
  @quickcheck.sized(size => {
    let hi = if size < max_len { size } else { max_len }
    @quickcheck.int_range(0, hi + 1).flat_map(n => elem.array_with_size(n))
  })
}

///|
/// Arrays mixing small values (many duplicates) with extreme values.
priv struct Ints(Array[Int]) derive(Debug)

///|
impl @quickcheck.Arbitrary for Ints with fn arbitrary(size, rs) {
  Ints(gen_array(gen_int_mixed(), 40).run(size, rs))
}

///|
impl @quickcheck.Shrink for Ints with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).map(xs => Ints(xs))
}

///|
/// Arrays whose sums cannot overflow `Int` (|x| <= 10^6, length <= 60).
priv struct Bounded(Array[Int]) derive(Debug)

///|
impl @quickcheck.Arbitrary for Bounded with fn arbitrary(size, rs) {
  let elem = @quickcheck.frequency([
    (3, @quickcheck.int_range(-5, 6)),
    (1, @quickcheck.int_range(-1000000, 1000001)),
  ])
  Bounded(gen_array(elem, 60).run(size, rs))
}

///|
impl @quickcheck.Shrink for Bounded with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).map(xs => Bounded(xs))
}

///|
/// Non-negative integers: small values, values around perfect squares and the
/// 32-bit overflow boundaries, and uniformly random non-negative values.
priv struct NonNeg(Int) derive(Debug)

///|
fn gen_nonneg() -> @quickcheck.Generator[Int] {
  @quickcheck.frequency([
    (3, @quickcheck.int_range(0, 50)),
    (2, @quickcheck.int_range(0, 1000000)),
    (
      2,
      @quickcheck.int_range(1, 46341).flat_map(r => {
        @quickcheck.int_range(-1, 2).map(d => r * r + d)
      }),
    ),
    (
      1,
      @quickcheck.elements([
        @int.MAX_VALUE,
        @int.MAX_VALUE - 1,
        2147395599, // 46340^2 - 1
        2147395600, // 46340^2
        92681,
        92682,
        1 << 30,
      ]),
    ),
    (2, @quickcheck.int_range(0, @int.MAX_VALUE)),
  ])
}

///|
impl @quickcheck.Arbitrary for NonNeg with fn arbitrary(size, rs) {
  NonNeg(gen_nonneg().run(size, rs))
}

///|
impl @quickcheck.Shrink for NonNeg with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).filter(x => x >= 0).map(x => NonNeg(x))
}

///|
/// Modulus in [2, Int max], biased towards large moduli where
/// `b * b` overflows 32-bit arithmetic.
priv struct Modulus(Int) derive(Debug)

///|
impl @quickcheck.Arbitrary for Modulus with fn arbitrary(size, rs) {
  let g = @quickcheck.frequency([
    (2, @quickcheck.int_range(2, 50)),
    (1, @quickcheck.int_range(2, 46341)),
    (
      2,
      @quickcheck.elements([1000000007, 998244353, @int.MAX_VALUE, 46341, 65536]),
    ),
    (2, @quickcheck.int_range(2, @int.MAX_VALUE)),
  ])
  Modulus(g.run(size, rs))
}

///|
impl @quickcheck.Shrink for Modulus with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).filter(m => m >= 2).map(m => Modulus(m))
}

///|
/// Character arrays over the parenthesis alphabet plus one neutral letter.
priv struct Parens(Array[Char]) derive(Debug)

///|
impl @quickcheck.Arbitrary for Parens with fn arbitrary(size, rs) {
  let elem = @quickcheck.elements(['(', ')', '*', 'a'])
  let n = @quickcheck.int_range(0, (if size < 12 { size } else { 12 }) + 1).run(
    size, rs,
  )
  Parens(elem.array_with_size(n).run(size, rs))
}

///|
impl @quickcheck.Shrink for Parens with fn shrink(self) {
  // Only shrink by dropping characters so the alphabet is preserved.
  let xs = self.0
  (0)
  .until(xs.length())
  .map(i => {
    let ys = xs.copy()
    ys.remove(i) |> ignore
    Parens(ys)
  })
}

// ---------------------------------------------------------------------------
// Reference models
// ---------------------------------------------------------------------------

///|
/// Non-negative remainder (safe for Int::min_value, unlike `abs() % m`).
fn umod(x : Int, m : Int) -> Int {
  let r = x % m
  if r < 0 {
    r + m
  } else {
    r
  }
}

///|
fn sorted_copy(xs : Array[Int]) -> Array[Int] {
  let ys = xs.copy()
  ys.sort()
  ys
}

///|
fn naive_gcd(a : Int, b : Int) -> Int {
  // Largest d dividing both (a, b >= 0, not both 0 → gcd(0, 0) = 0).
  if a == 0 {
    return b
  }
  if b == 0 {
    return a
  }
  let m = if a < b { a } else { b }
  for d = m; d >= 1; d = d - 1 {
    if a % d == 0 && b % d == 0 {
      return d
    }
  }
  1
}

///|
fn naive_is_prime(n : Int) -> Bool {
  if n < 2 {
    return false
  }
  for d = 2; d * d <= n; d = d + 1 {
    if n % d == 0 {
      return false
    }
  }
  true
}

///|
fn lex_less(a : Array[Int], b : Array[Int]) -> Bool {
  for i in 0..<a.length() {
    if a[i] != b[i] {
      return a[i] < b[i]
    }
  }
  false
}

///|
/// All distinct permutations of `xs`, in lexicographic order.
fn all_distinct_perms(xs : Array[Int]) -> Array[Array[Int]] {
  let out : Array[Array[Int]] = []
  fn go(prefix : Array[Int], rest : Array[Int]) -> Unit {
    if rest.is_empty() {
      out.push(prefix.copy())
      return
    }
    let seen : Array[Int] = []
    for i in 0..<rest.length() {
      if seen.contains(rest[i]) {
        continue
      }
      seen.push(rest[i])
      let rest2 = rest.copy()
      rest2.remove(i) |> ignore
      prefix.push(rest[i])
      go(prefix, rest2)
      prefix.pop() |> ignore
    }
  }

  go([], sorted_copy(xs))
  out
}

///|
fn star_balanced_brute(cs : Array[Char]) -> Bool {
  // Try every replacement of '*' by '(', ')' or empty.
  fn go(i : Int, bal : Int) -> Bool {
    if bal < 0 {
      return false
    }
    if i == cs.length() {
      return bal == 0
    }
    match cs[i] {
      '(' => go(i + 1, bal + 1)
      ')' => go(i + 1, bal - 1)
      '*' => go(i + 1, bal) || go(i + 1, bal + 1) || go(i + 1, bal - 1)
      _ => go(i + 1, bal)
    }
  }

  go(0, 0)
}

// ---------------------------------------------------------------------------
// Numeric properties
// ---------------------------------------------------------------------------

///|
fn is_floor_sqrt(n : Int, r : Int) -> Bool {
  let n64 = n.to_int64()
  let r64 = r.to_int64()
  r64 >= 0L && r64 * r64 <= n64 && (r64 + 1L) * (r64 + 1L) > n64
}

///|
test "qc: isqrt returns floor(sqrt(n)) for every non-negative Int" {
  @quickcheck.check(
    (x : NonNeg) => is_floor_sqrt(x.0, isqrt(x.0)),
    observe=x => {
      [
        @quickcheck.classify(x.0 > 92681, "mid*mid would overflow"),
        @quickcheck.classify(
          is_floor_sqrt(x.0, isqrt(x.0)) &&
          x.0 > 0 &&
          isqrt(x.0) * isqrt(x.0) == x.0,
          "perfect square",
        ),
      ]
    },
    count=2000,
    seed=20260928,
  )
}

///|
test "qc: isqrt_newton returns floor(sqrt(n)) for every non-negative Int" {
  @quickcheck.check(
    (x : NonNeg) => is_floor_sqrt(x.0, isqrt_newton(x.0)),
    count=2000,
    seed=20260929,
  )
}

///|
test "regression: isqrt overflow for large n" {
  // Previously mid * mid wrapped around and n + 1 overflowed.
  @debug.assert_eq(isqrt(100000), 316)
  @debug.assert_eq(isqrt(92681), 304)
  @debug.assert_eq(isqrt(2147395600), 46340)
  @debug.assert_eq(isqrt(@int.MAX_VALUE), 46340)
}

///|
test "regression: isqrt_newton overflow at Int max" {
  // Previously x + n / x overflowed on the first step.
  @debug.assert_eq(isqrt_newton(@int.MAX_VALUE), 46340)
  @debug.assert_eq(isqrt_newton(@int.MAX_VALUE - 1), 46340)
}

///|
test "qc: gcd_loop agrees with the divisor-search definition (small inputs)" {
  @quickcheck.check(
    (p : (Int, Int)) => {
      let a = umod(p.0, 500)
      let b = umod(p.1, 500)
      gcd_loop(a, b) == naive_gcd(a, b) && gcd_loop(a, b) == gcd_rec(a, b)
    },
    count=500,
    seed=11,
  )
}

///|
test "qc: gcd_loop divides both and leaves coprime cofactors" {
  @quickcheck.check(
    (p : (NonNeg, NonNeg)) => {
      let a = p.0.0
      let b = p.1.0
      let g = gcd_loop(a, b)
      if a == 0 && b == 0 {
        g == 0
      } else {
        g > 0 && a % g == 0 && b % g == 0 && gcd_loop(a / g, b / g) == 1
      }
    },
    count=1000,
    seed=12,
  )
}

///|
test "qc: extended_gcd satisfies Bezout's identity" {
  @quickcheck.check(
    (p : (NonNeg, NonNeg)) => {
      let a = p.0.0
      let b = p.1.0
      let (g, x, y) = extended_gcd(a, b)
      let lhs = a.to_int64() * x.to_int64() + b.to_int64() * y.to_int64()
      g == gcd_loop(a, b) && lhs == g.to_int64()
    },
    count=1000,
    seed=13,
  )
}

///|
test "qc: pow_loop agrees with pow_rec and repeated multiplication" {
  @quickcheck.check(
    (p : (Int, Int)) => {
      let base = p.0
      let exp = umod(p.1, 70)
      let naive = for i = 0, acc = 1; i < exp; {
        continue i + 1, acc * base
      } nobreak {
        acc
      }
      pow_loop(base, exp) == naive && pow_rec(base, exp) == naive
    },
    count=500,
    seed=14,
  )
}

///|
fn naive_mod_pow(base : Int, exp : Int, m : Int) -> Int {
  let m64 = m.to_int64()
  let r = base.to_int64() % m64
  let b = if r < 0L { r + m64 } else { r }
  for i = 0, acc = 1L % m64; i < exp; {
    continue i + 1, acc * b % m64
  } nobreak {
    acc.to_int()
  }
}

///|
test "qc: mod_pow agrees with repeated multiplication in Int64" {
  @quickcheck.check(
    (p : (Int, Int, Modulus)) => {
      let base = p.0
      let exp = umod(p.1, 200)
      let m = p.2.0
      mod_pow(base, exp, m) == naive_mod_pow(base, exp, m)
    },
    observe=p => {
      [
        @quickcheck.classify(p.2.0 > 46341, "modulus > 46341"),
        @quickcheck.classify(p.0 < 0, "negative base"),
      ]
    },
    count=1000,
    seed=15,
  )
}

///|
test "regression: mod_pow large modulus and negative base" {
  // 2^40 mod (10^9 + 7): b * b used to overflow Int.
  @debug.assert_eq(mod_pow(2, 40, 1000000007), 511620083)
  // (-2)^3 mod 7 = -8 mod 7 = 6: the result used to be -1.
  @debug.assert_eq(mod_pow(-2, 3, 7), 6)
  @debug.assert_eq(mod_pow(@int.MIN_VALUE, 1, @int.MAX_VALUE), 2147483646)
}

///|
test "qc: sieve lists exactly the primes up to n" {
  @quickcheck.check(
    (n : Int) => {
      let n = n % 3000
      let expected = Array::makei(if n < 0 { 0 } else { n + 1 }, i => i).filter(
        naive_is_prime,
      )
      sieve(n) == expected
    },
    count=200,
    seed=16,
  )
}

///|
test "qc: popcount counts all 32 bits" {
  @quickcheck.check(
    (n : Int) => {
      let naive = for i = 0, c = 0; i < 32; {
        continue i + 1, c + ((n >> i) & 1)
      } nobreak {
        c
      }
      popcount(n) == naive
    },
    count=1000,
    seed=17,
  )
}

///|
test "qc: fib_loop agrees with recursive fib" {
  @quickcheck.check(
    (n : Int) => {
      let n = umod(n, 26)
      fib_loop(n) == fib(n)
    },
    seed=18,
  )
}

///|
test "qc: div_mod_nonneg agrees with / and %" {
  @quickcheck.check(
    (p : (Int, Int)) => {
      let n = umod(p.0, 100000)
      let d = umod(p.1, 1000) + 1
      div_mod_nonneg(n, d) == (n / d, n % d)
    },
    count=300,
    seed=19,
  )
}

///|
test "qc: horner_eval agrees with the naive polynomial sum" {
  @quickcheck.check(
    (p : (Ints, Int)) => {
      let coeffs = p.0.0
      let x = p.1
      let n = coeffs.length()
      // sum of coeffs[i] * x^(n-1-i); Int arithmetic wraps in both.
      let mut naive = 0
      for i in 0..<n {
        let mut term = coeffs[i]
        for _ in 0..<(n - 1 - i) {
          term = term * x
        }
        naive = naive + term
      }
      horner_eval(coeffs, x) == naive
    },
    seed=20,
  )
}

// ---------------------------------------------------------------------------
// Searching
// ---------------------------------------------------------------------------

///|
test "qc: binary_search agrees with linear scan on sorted arrays" {
  @quickcheck.check(
    (p : (Ints, Int, Bool)) => {
      let xs = sorted_copy(p.0.0)
      let target = if p.2 && xs.length() > 0 {
        xs[umod(p.1, xs.length())]
      } else {
        p.1
      }
      match binary_search(xs, target) {
        Some(i) => i >= 0 && i < xs.length() && xs[i] == target
        None => !xs.contains(target)
      }
    },
    observe=p => {
      [@quickcheck.classify(p.2 && p.0.0.length() > 0, "target present")]
    },
    count=1000,
    seed=21,
  )
}

///|
test "qc: lower_bound counts the elements smaller than target" {
  @quickcheck.check(
    (p : (Ints, Int)) => {
      let xs = sorted_copy(p.0.0)
      let t = p.1 % 10
      lower_bound(xs, xs.length(), t) == xs.filter(x => x < t).length()
    },
    count=500,
    seed=22,
  )
}

///|
test "qc: two_sum_sorted finds a pair iff one exists" {
  @quickcheck.check(
    (p : (Ints, Int, Bool)) => {
      let xs = sorted_copy(p.0.0)
      let n = xs.length()
      // Half the time aim for a sum that is attainable.
      let target = if p.2 && n >= 2 {
        let i = umod(p.1, n)
        let j = (i + 1 + umod(p.1 / 7, n - 1)) % n
        xs[i] + xs[j]
      } else {
        p.1
      }
      let t64 = target.to_int64()
      let exists = (0)
        .until(n)
        .any(i => {
          (i + 1).until(n).any(j => xs[i].to_int64() + xs[j].to_int64() == t64)
        })
      match two_sum_sorted(xs, target) {
        Some((i, j)) =>
          0 <= i && i < j && j < n && xs[i].to_int64() + xs[j].to_int64() == t64
        None => !exists
      }
    },
    count=1000,
    seed=23,
  )
}

///|
test "regression: two_sum_sorted with an overflowing pair sum" {
  // 1 + Int max used to wrap to a negative sum, so the left pointer skipped
  // past the real answer (1, 2).
  debug_inspect(
    two_sum_sorted([1, 2, @int.MAX_VALUE], 3),
    content="Some((0, 1))",
  )
  // Int max + 5 wraps to the target, but the true sum is not the target.
  debug_inspect(
    two_sum_sorted([5, @int.MAX_VALUE], @int.MAX_VALUE + 5),
    content="None",
  )
}

///|
test "qc: majority_element agrees with counting" {
  @quickcheck.check(
    (xs : Ints) => {
      let xs = xs.0.map(x => x % 3)
      let n = xs.length()
      let expected = xs
        .iter()
        .find_first(x => xs.filter(y => y == x).length() > n / 2)
      majority_element(xs) == expected
    },
    observe=xs => {
      let ys = xs.0.map(x => x % 3)
      let has = ys
        .iter()
        .any(x => ys.filter(y => y == x).length() * 2 > ys.length())
      [@quickcheck.classify(has, "has majority")]
    },
    count=500,
    seed=24,
  )
}

// ---------------------------------------------------------------------------
// Sequences and arrays
// ---------------------------------------------------------------------------

///|
test "qc: merge of sorted inputs equals the sorted concatenation" {
  @quickcheck.check(
    (p : (Ints, Ints)) => {
      let a = sorted_copy(p.0.0)
      let b = sorted_copy(p.1.0)
      merge(a, b) == sorted_copy(a + b)
    },
    seed=25,
  )
}

///|
test "qc: reverse_inplace equals Array::rev and is an involution" {
  @quickcheck.check(
    (xs : Ints) => {
      let a = xs.0.copy()
      reverse_inplace(a)
      let once = a.copy()
      reverse_inplace(a)
      once == xs.0.rev() && a == xs.0
    },
    seed=26,
  )
}

///|
test "qc: dutch_flag produces a permutation split into <, ==, > regions" {
  @quickcheck.check(
    (p : (Ints, Int)) => {
      let xs = p.0.0.map(x => x % 4)
      let pivot = p.1 % 4
      let a = xs.copy()
      dutch_flag(a, pivot)
      let lt = xs.filter(x => x < pivot).length()
      let eq = xs.filter(x => x == pivot).length()
      sorted_copy(a) == sorted_copy(xs) &&
      (0)
      .until(a.length())
      .all(i => {
        let x = a[i]
        if i < lt {
          x < pivot
        } else if i < lt + eq {
          x == pivot
        } else {
          x > pivot
        }
      })
    },
    count=500,
    seed=27,
  )
}

///|
test "qc: next_permutation steps to the lexicographic successor" {
  @quickcheck.check(
    (xs : Ints) => {
      let xs = xs.0.map(x => x % 3)
      let xs = if xs.length() > 6 { xs[:6].to_owned() } else { xs }
      let perms = all_distinct_perms(xs)
      let idx = perms.search(xs).unwrap()
      let a = xs.copy()
      let advanced = next_permutation(a)
      if xs.length() < 2 {
        !advanced && a == xs
      } else if idx + 1 < perms.length() {
        advanced && a == perms[idx + 1] && lex_less(xs, a)
      } else {
        !advanced && a == perms[0]
      }
    },
    count=500,
    seed=28,
  )
}

///|
test "qc: lis_length agrees with the quadratic DP" {
  @quickcheck.check(
    (xs : Ints) => {
      let xs = xs.0
      let n = xs.length()
      let best = Array::make(n, 1)
      for i in 0..<n {
        for j in 0..<i {
          if xs[j] < xs[i] && best[j] + 1 > best[i] {
            best[i] = best[j] + 1
          }
        }
      }
      let expected = best.fold(init=0, (m, x) => if x > m { x } else { m })
      lis_length(xs) == expected
    },
    count=500,
    seed=29,
  )
}

///|
test "qc: kadane agrees with brute-force maximum subarray sum" {
  @quickcheck.check(
    (xs : Bounded) => {
      let xs = xs.0
      let n = xs.length()
      if n == 0 {
        return kadane(xs) == 0
      }
      let mut best = xs[0]
      for i in 0..<n {
        let mut s = 0
        for j in i..<n {
          s = s + xs[j]
          if s > best {
            best = s
          }
        }
      }
      kadane(xs) == best
    },
    count=500,
    seed=30,
  )
}

///|
test "qc: max_profit_single agrees with brute force over buy/sell pairs" {
  @quickcheck.check(
    (xs : Bounded) => {
      let xs = xs.0
      let mut best = 0
      for i in 0..<xs.length() {
        for j in (i + 1)..<xs.length() {
          if xs[j] - xs[i] > best {
            best = xs[j] - xs[i]
          }
        }
      }
      max_profit_single(xs) == best &&
      max_profit_prefix(xs, xs.length()) == best
    },
    count=300,
    seed=31,
  )
}

// ---------------------------------------------------------------------------
// Parentheses
// ---------------------------------------------------------------------------

///|
test "qc: is_balanced_parens agrees with the prefix-balance definition" {
  @quickcheck.check(
    (p : Parens) => {
      let cs = p.0.map(c => if c == '*' { ')' } else { c })
      let n = cs.length()
      let expected = balance_prefix(cs, n) == 0 &&
        (0).until(n + 1).all(i => balance_prefix(cs, i) >= 0)
      is_balanced_parens(cs) == expected
    },
    observe=p => {
      let cs = p.0.map(c => if c == '*' { ')' } else { c })
      [@quickcheck.classify(is_balanced_parens(cs), "balanced")]
    },
    count=1000,
    seed=32,
  )
}

///|
test "qc: is_balanced_parens_star agrees with trying every '*' replacement" {
  @quickcheck.check(
    (p : Parens) => is_balanced_parens_star(p.0) == star_balanced_brute(p.0),
    observe=p => [@quickcheck.classify(star_balanced_brute(p.0), "balanced")],
    count=1000,
    seed=33,
  )
}
