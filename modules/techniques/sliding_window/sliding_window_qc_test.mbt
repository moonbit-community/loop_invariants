// Property-based tests for the sliding-window package: fixed-size window
// max / min / sum against naive per-window scans, and the two-pointer
// variable windows against O(n^2) references on non-negative `Int64` input
// (the documented precondition), including values near `Int64::MAX_VALUE`.

///|
const LMAX : Int64 = 9223372036854775807L

///|
const LMIN : Int64 = -9223372036854775808L

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// `Int64` arrays whose elements come from one of three regimes: a tiny range
/// (many duplicates), full-range `Int64` (hits the extrema), or a per-element
/// mix of small values and `Int64` extrema.
priv struct I64s {
  xs : Array[Int64]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for I64s with fn arbitrary(size, rs) {
  let len = rint(rs, 0, size)
  let mode = rint(rs, 0, 3)
  let xs = Array::makei(len, _ => {
    match mode {
      0 | 1 => rint(rs, -3, 3).to_int64()
      2 => @quickcheck.Arbitrary::arbitrary(size, rs)
      _ =>
        if rint(rs, 0, 3) == 0 {
          [LMAX, LMIN, 0L, LMAX - 1L][rint(rs, 0, 3)]
        } else {
          rint(rs, -3, 3).to_int64()
        }
    }
  })
  { xs, }
}

///|
impl @quickcheck.Shrink for I64s with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.xs).map(xs => { xs, })
}

///|
/// Maps negative values onto non-negative ones (`lnot` sends `LMIN` to
/// `LMAX`), preserving the extremes.
fn nonneg(xs : Array[Int64]) -> Array[Int64] {
  xs.map(x => if x < 0L { x.lnot() } else { x })
}

///|
priv struct Win {
  xs : Array[Int64]
  k : Int
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Win with fn arbitrary(size, rs) {
  let a : I64s = @quickcheck.Arbitrary::arbitrary(size, rs)
  let n = a.xs.length()
  let k = match rint(rs, 0, 9) {
    0 => rint(rs, -2, 0)
    1 => n + rint(rs, 0, 3)
    _ => rint(rs, 1, if n < 1 { 1 } else { n })
  }
  { xs: a.xs, k, }
}

///|
impl @quickcheck.Shrink for Win with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.xs, self.k)).map(p => { xs: p.0, k: p.1, })
}

///|
/// Naive fold over every window of size `k`; `k >= n` yields one window over
/// the whole array (the documented behaviour of max / min).
fn naive_windows(
  xs : Array[Int64],
  k : Int,
  f : (Int64, Int64) -> Int64,
) -> Array[Int64] {
  let n = xs.length()
  if n == 0 || k <= 0 {
    return []
  }
  let k = if k > n { n } else { k }
  Array::makei(n - k + 1, j => {
    let mut acc = xs[j]
    for i in (j + 1)..<(j + k) {
      acc = f(acc, xs[i])
    }
    acc
  })
}

///|
test "qc: sliding_window_max matches a per-window scan" {
  @quickcheck.check(
    (w : Win) => {
      @sliding_window.sliding_window_max(w.xs, w.k) ==
      naive_windows(w.xs, w.k, (a, b) => if b > a { b } else { a })
    },
    count=300,
    max_size=50,
    max_shrinks=1000,
    seed=41,
    observe=w => {
      let n = w.xs.length()
      [
        @quickcheck.classify(w.k <= 0, "k <= 0"),
        @quickcheck.classify(w.k >= n && n > 0, "k >= n > 0"),
        @quickcheck.classify(w.k > 0 && w.k < n, "0 < k < n"),
        @quickcheck.classify(w.k == 1, "k == 1"),
      ]
    },
  )
}

///|
test "qc: sliding_window_min matches a per-window scan" {
  @quickcheck.check(
    (w : Win) => {
      @sliding_window.sliding_window_min(w.xs, w.k) ==
      naive_windows(w.xs, w.k, (a, b) => if b < a { b } else { a })
    },
    count=300,
    max_size=50,
    max_shrinks=1000,
    seed=42,
  )
}

///|
test "qc: sliding_window_sum matches per-window (wrapping) sums" {
  // Both sides use wrapping `Int64` addition, so the sliding update must
  // agree exactly with the direct sum even when it overflows.
  @quickcheck.check(
    (w : Win) => {
      let expected = if w.k > w.xs.length() {
        []
      } else {
        naive_windows(w.xs, w.k, (a, b) => a + b)
      }
      @sliding_window.sliding_window_sum(w.xs, w.k) == expected
    },
    count=300,
    max_size=50,
    max_shrinks=1000,
    seed=43,
  )
}

///|
/// O(n^2) reference; sums are compared as `x > target - s` (with
/// `0 <= s <= target`) so the reference itself never overflows.
fn ref_longest_le(xs : Array[Int64], target : Int64) -> Int {
  if target < 0L {
    return 0
  }
  let mut best = 0
  for i in 0..<xs.length() {
    let mut s = 0L
    for j in i..<xs.length() {
      if xs[j] > target - s {
        break
      }
      s = s + xs[j]
      if j - i + 1 > best {
        best = j - i + 1
      }
    }
  }
  best
}

///|
/// O(n^2) reference; `s < target` holds before each extension, so
/// `target - s > 0` never overflows.
fn ref_min_ge(xs : Array[Int64], target : Int64) -> Int {
  let n = xs.length()
  if n > 0 && target <= 0L {
    return 1
  }
  let mut best = 0
  for i in 0..<n {
    let mut s = 0L
    for j in i..<n {
      if xs[j] >= target - s {
        if best == 0 || j - i + 1 < best {
          best = j - i + 1
        }
        break
      }
      s = s + xs[j]
    }
  }
  best
}

///|
/// Picks a target that is small, a prefix/window sum-like value, or extreme.
fn pick_target(xs : Array[Int64], t : Int64) -> Int64 {
  match (t % 4L).abs() {
    0L => (t % 10L).abs()
    1L if xs.length() > 0 =>
      xs[(t / 4L % xs.length().to_int64()).abs().to_int()]
    2L => [LMAX, 0L, -1L, LMAX - 1L][(t / 4L % 4L).abs().to_int()]
    _ => t
  }
}

///|
test "qc: longest_subarray_with_sum_le matches O(n^2) on non-negative input" {
  @quickcheck.check(
    (input : (I64s, Int64)) => {
      let xs = nonneg(input.0.xs)
      let target = pick_target(xs, input.1)
      @sliding_window.longest_subarray_with_sum_le(xs, target) ==
      ref_longest_le(xs, target)
    },
    count=400,
    max_size=40,
    max_shrinks=1000,
    seed=44,
    observe=input => {
      let xs = nonneg(input.0.xs)
      let target = pick_target(xs, input.1)
      let r = ref_longest_le(xs, target)
      [
        @quickcheck.classify(r == 0, "answer 0"),
        @quickcheck.classify(r > 0 && r == xs.length(), "whole array"),
        @quickcheck.classify(r > 0 && r < xs.length(), "proper subarray"),
        @quickcheck.classify(xs.contains(LMAX), "contains Int64 max"),
      ]
    },
  )
}

///|
test "qc: min_subarray_with_sum_ge matches O(n^2) on non-negative input" {
  @quickcheck.check(
    (input : (I64s, Int64)) => {
      let xs = nonneg(input.0.xs)
      let target = pick_target(xs, input.1)
      @sliding_window.min_subarray_with_sum_ge(xs, target) ==
      ref_min_ge(xs, target)
    },
    count=400,
    max_size=40,
    max_shrinks=1000,
    seed=45,
  )
}

///|
test "regression: longest_subarray_with_sum_le Int64 overflow" {
  // 1 + Int64::MAX_VALUE used to wrap negative and count as `<= 1`.
  inspect(
    @sliding_window.longest_subarray_with_sum_le([1L, LMAX], 1L),
    content="1",
  )
  inspect(
    @sliding_window.longest_subarray_with_sum_le([LMAX, LMAX], LMAX),
    content="1",
  )
}

///|
test "regression: min_subarray_with_sum_ge Int64 overflow" {
  // 2 + (Int64::MAX_VALUE - 1) used to wrap negative and look `< target`.
  inspect(
    @sliding_window.min_subarray_with_sum_ge([2L, LMAX - 1L], LMAX),
    content="2",
  )
  inspect(
    @sliding_window.min_subarray_with_sum_ge([1L, LMAX], LMAX),
    content="1",
  )
}
