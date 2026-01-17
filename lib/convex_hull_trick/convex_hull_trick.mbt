// ============================================================================
// CONVEX HULL TRICK - Monotone slopes, monotone queries (maximum)
// ============================================================================
//
// Maintain lines y = m*x + b with slopes added in increasing order. Queries
// must provide x in non-decreasing order. The structure returns the maximum
// value for each query.
//
// TIME COMPLEXITY:
// - add_line: O(1) amortized
// - query: O(1) amortized
//
// SPACE COMPLEXITY: O(n)

///|
pub struct Line {
  m : Int64
  b : Int64
}

///|
fn Line::value(self : Line, x : Int64) -> Int64 {
  self.m * x + self.b
}

///|
fn is_bad(l1 : Line, l2 : Line, l3 : Line) -> Bool {
  (l2.b - l1.b) * (l2.m - l3.m) >= (l3.b - l2.b) * (l1.m - l2.m)
}

///|
pub struct ConvexHullTrick {
  lines : Array[Line]
  mut head : Int
}

///|
/// Create an empty hull. Lines must be added with increasing slopes.
pub fn ConvexHullTrick::new() -> ConvexHullTrick {
  { lines: [], head: 0 }
}

///|
/// Add a line y = m*x + b. Slopes must be added in increasing order.
pub fn ConvexHullTrick::add_line(
  self : ConvexHullTrick,
  m : Int64,
  b : Int64,
) -> Unit {
  let line = { m, b }
  while self.lines.length() - self.head >= 2 {
    let l1 = self.lines[self.lines.length() - 2]
    let l2 = self.lines[self.lines.length() - 1]
    if is_bad(l1, l2, line) {
      let _ = self.lines.pop()

    } else {
      break
    }
  }
  self.lines.push(line)
}

///|
/// Query maximum at x. x must be non-decreasing across calls.
pub fn ConvexHullTrick::query(self : ConvexHullTrick, x : Int64) -> Int64 {
  while self.lines.length() - self.head >= 2 {
    let l1 = self.lines[self.head]
    let l2 = self.lines[self.head + 1]
    if l2.value(x) >= l1.value(x) {
      self.head = self.head + 1
    } else {
      break
    }
  }
  self.lines[self.head].value(x)
}
