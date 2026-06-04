// ============================================================================
// LINEAR DIOPHANTINE EQUATION  -  ax + by = c
// ============================================================================
//
// PROBLEM
//
// Given integers `a, b, c`, decide whether `a x + b y = c` has integer
// solutions, and if so describe the entire solution set.
//
// EXISTENCE
//
// Bezout's identity: integer solutions exist iff `gcd(a, b) | c`. The
// extended Euclidean algorithm produces a particular pair `(x_0, y_0)`
// with `a x_0 + b y_0 = g = gcd(a, b)`. Scaling by `c / g` gives a
// particular solution to the original equation.
//
// GENERAL SOLUTION FAMILY
//
// Once `(x_0, y_0)` solves it, the complete solution set is
//
//   x = x_0 + (b / g) t
//   y = y_0 - (a / g) t        t in Z
//
// because changing `t` adds `b/g * a - a/g * b = 0` to the left side.
//
// COMPLEXITY
//
//   solve(a, b, c) : O(log min(|a|, |b|))
//
// THE INVARIANT
//
//   "After completion, (x, y) satisfies a x + b y = c and (b/g, -a/g)
//    is the generator of the kernel of the corresponding linear map."

///|
/// Solution of `a x + b y = c`.
///
/// - `solution` : `Some((x_0, y_0))` if a solution exists; `None` otherwise.
/// - `period`   : the step `(dx, dy)` such that adding `(t * dx, t * dy)`
///                to `(x_0, y_0)` for any integer `t` yields another
///                solution. `(0, 0)` when no solution exists or both
///                `a` and `b` are zero.
pub(all) struct DiophantineResult {
  solution : (Int64, Int64)?
  period : (Int64, Int64)
}

///|
fn abs64(x : Int64) -> Int64 {
  if x < 0L {
    -x
  } else {
    x
  }
}

///|
fn ext_gcd(a : Int64, b : Int64) -> (Int64, Int64, Int64) {
  // Iterative extended Euclidean algorithm.  Maintains the invariant
  //   old_r = a * old_s + b * old_t
  //   r     = a * s     + b * t
  // until r == 0, at which point old_r == gcd(a, b).
  let mut old_r = a
  let mut r = b
  let mut old_s = 1L
  let mut s = 0L
  while r != 0L {
    let q = old_r / r
    let new_r = old_r - q * r
    old_r = r
    r = new_r
    let new_s = old_s - q * s
    old_s = s
    s = new_s
  }
  // Recover the second Bezout coefficient from the identity.
  let t = if b == 0L { 0L } else { (old_r - a * old_s) / b }
  (old_r, old_s, t)
}

///|
/// Solve `a x + b y = c`. Both coefficients may be negative or zero.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // 3 x + 6 y = 9 has solutions; one of them is (3, 0).
///   let r = @linear_diophantine.solve(3L, 6L, 9L)
///   match r.solution {
///     Some((x, y)) => @debug.assert_eq(3L * x + 6L * y, 9L)
///     None => @debug.assert_eq(true, false)
///   }
/// }
/// ```
pub fn solve(a : Int64, b : Int64, c : Int64) -> DiophantineResult {
  if a == 0L && b == 0L {
    if c == 0L {
      return { solution: Some((0L, 0L)), period: (0L, 0L) }
    }
    return { solution: None, period: (0L, 0L) }
  }
  if a == 0L {
    // b y = c
    if c % b != 0L {
      return { solution: None, period: (0L, 0L) }
    }
    return { solution: Some((0L, c / b)), period: (1L, 0L) }
  }
  if b == 0L {
    if c % a != 0L {
      return { solution: None, period: (0L, 0L) }
    }
    return { solution: Some((c / a, 0L)), period: (0L, 1L) }
  }
  let (g0, x0, y0) = ext_gcd(abs64(a), abs64(b))
  if c % g0 != 0L {
    return { solution: None, period: (0L, 0L) }
  }
  // Correct signs from absolute values.
  let mut xs = x0
  let mut ys = y0
  if a < 0L {
    xs = -xs
  }
  if b < 0L {
    ys = -ys
  }
  let scale = c / g0
  let x = xs * scale
  let y = ys * scale
  let period_dx = b / g0
  let period_dy = -(a / g0)
  { solution: Some((x, y)), period: (period_dx, period_dy) }
}

///|
/// `solve` plus a normalisation: the returned `x` is the smallest
/// non-negative integer (when `dx != 0`) such that `a x + b y = c`.
pub fn solve_min_x(a : Int64, b : Int64, c : Int64) -> DiophantineResult {
  let r = solve(a, b, c)
  match r.solution {
    None => r
    Some((x, y)) => {
      let (dx, dy) = r.period
      if dx == 0L {
        return r
      }
      let dx_abs = abs64(dx)
      let mut nx = x % dx_abs
      if nx < 0L {
        nx = nx + dx_abs
      }
      let t = (x - nx) / dx
      let ny = y - t * dy
      { solution: Some((nx, ny)), period: (dx, dy) }
    }
  }
}

///|
test "diophantine basic existence" {
  let r = solve(3L, 6L, 9L)
  match r.solution {
    Some((x, y)) => @debug.assert_eq(3L * x + 6L * y, 9L)
    None => @debug.assert_eq(true, false)
  }
}

///|
test "diophantine no solution" {
  // gcd(4, 6) = 2 does not divide 7.
  let r = solve(4L, 6L, 7L)
  @debug.assert_eq(r.solution, None)
}

///|
test "diophantine homogeneous" {
  // 0 x + 0 y = 0 has infinitely many solutions; we report (0, 0).
  let r = solve(0L, 0L, 0L)
  @debug.assert_eq(r.solution, Some((0L, 0L)))
  // 0 x + 0 y = 5 has none.
  let r2 = solve(0L, 0L, 5L)
  @debug.assert_eq(r2.solution, None)
}

///|
test "diophantine zero coefficient" {
  // 0 x + 4 y = 8 -> y = 2.
  let r = solve(0L, 4L, 8L)
  match r.solution {
    Some((_, y)) => @debug.assert_eq(y, 2L)
    None => @debug.assert_eq(true, false)
  }
  // 4 x + 0 y = 8 -> x = 2.
  let r2 = solve(4L, 0L, 8L)
  match r2.solution {
    Some((x, _)) => @debug.assert_eq(x, 2L)
    None => @debug.assert_eq(true, false)
  }
}

///|
test "diophantine period generates more solutions" {
  let r = solve(3L, 6L, 9L)
  match (r.solution, r.period) {
    (Some((x0, y0)), (dx, dy)) =>
      for t in -5L..<=5L {
        let x = x0 + t * dx
        let y = y0 + t * dy
        @debug.assert_eq(3L * x + 6L * y, 9L)
      }
    (None, _) => @debug.assert_eq(true, false)
  }
}

///|
test "diophantine negative coefficients" {
  // -3 x + 6 y = 9 -> e.g. (1, 2).
  let r = solve(-3L, 6L, 9L)
  match r.solution {
    Some((x, y)) => @debug.assert_eq(-3L * x + 6L * y, 9L)
    None => @debug.assert_eq(true, false)
  }
  // 3 x - 6 y = -9 -> swap roles.
  let r2 = solve(3L, -6L, -9L)
  match r2.solution {
    Some((x, y)) => @debug.assert_eq(3L * x - 6L * y, -9L)
    None => @debug.assert_eq(true, false)
  }
}

///|
test "diophantine min x normalised" {
  let r = solve_min_x(7L, 5L, 1L)
  match r.solution {
    Some((x, y)) => {
      @debug.assert_eq(7L * x + 5L * y, 1L)
      @debug.assert_eq(x >= 0L && x < 5L, true)
    }
    None => @debug.assert_eq(true, false)
  }
}

///|
test "diophantine sweep small" {
  for a in -5L..<=5L {
    for b in -5L..<=5L {
      for c in -10L..<=10L {
        let r = solve(a, b, c)
        match r.solution {
          Some((x, y)) => @debug.assert_eq(a * x + b * y, c)
          None => {
            // No solution: verify gcd(a, b) does not divide c.
            // gcd(0,0)=0; if a=b=0 and c=0 it would have a solution.
            // Just trust the existence check by re-deriving.
            let mut g = abs64(a)
            let mut t = abs64(b)
            while t != 0L {
              let r2 = g % t
              g = t
              t = r2
            }
            if g == 0L {
              @debug.assert_eq(c != 0L, true)
            } else {
              @debug.assert_eq(c % g != 0L, true)
            }
          }
        }
      }
    }
  }
}
