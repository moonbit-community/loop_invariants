// ============================================================================
// CONVEX HULL TRICK - Monotone slopes, monotone queries (maximum)
// ============================================================================
//
// Maintain lines y = m*x + b with slopes added in increasing order. Queries
// must provide x in non-decreasing order. The structure returns the maximum
// value for each query.
//
// UPPER ENVELOPE (what this structure tracks):
// ```
//   y
//   |              /  L3: y = 3x - 1  (steepest)
//   |             /
//   |            / /  L2: y = 2x + 1
//   |           / /
//   |      ****/ /
//   |     *   * /
//   |    *   /* /
//   |   *   /*/       L1: y = x
//   |  *   /*/ *
//   | *   / /   *
//   |*   / /     *
//   |   / /
//   +--+--+----------> x
//      ^  ^
//      |  |
//   x=0.5 x=2   <- breakpoints between best lines
//
//   The "****" path traces the upper envelope:
//   x < 0.5  -> L1 is best
//   0.5..2   -> L2 is best
//   x > 2    -> L3 is best
// ```
//
// TIME COMPLEXITY:
//   add_line: O(1) amortized (each line removed at most once)
//   query:    O(1) amortized (head pointer only moves forward)
//
// SPACE COMPLEXITY: O(n)
//
// REQUIREMENTS:
//   - Lines must be added with strictly increasing slopes (m values)
//   - Query x values must be non-decreasing across calls

///|
/// A linear function y = m*x + b, where `m` is the slope and `b` is the
/// y-intercept.
///
/// Both fields are `Int64` to allow large coordinate values without overflow.
pub struct Line {
  m : Int64
  b : Int64
}

///|
/// Evaluate the line at a given x-coordinate, returning m*x + b.
fn Line::value(self : Line, x : Int64) -> Int64 {
  self.m * x + self.b
}

///|
/// Return true when the middle line `l2` is dominated and can be removed from
/// the upper envelope.
///
/// Given three consecutive lines l1, l2, l3 (with l1.m <= l2.m <= l3.m), l2
/// is "bad" (never the unique maximum for any x) when the intersection of l1
/// and l3 is at or before the intersection of l1 and l2. Geometrically this
/// means l2 is entirely below the envelope formed by l1 and l3.
///
/// The check avoids division by using cross-multiplication:
///
/// ```
/// intersection(l1, l2): x12 = (l2.b - l1.b) / (l1.m - l2.m)
/// intersection(l2, l3): x23 = (l3.b - l2.b) / (l2.m - l3.m)
///
/// l2 is bad when x12 >= x23, rewritten without division as:
/// (l2.b - l1.b) * (l2.m - l3.m) >= (l3.b - l2.b) * (l1.m - l2.m)
/// ```
fn is_bad(l1 : Line, l2 : Line, l3 : Line) -> Bool {
  (l2.b - l1.b) * (l2.m - l3.m) >= (l3.b - l2.b) * (l1.m - l2.m)
}

///|
/// A data structure that maintains a set of linear functions y = m*x + b and
/// answers "what is the maximum y at coordinate x?" queries efficiently.
///
/// This is the **monotone** variant of the Convex Hull Trick. It requires:
/// - Lines inserted in **non-decreasing slope** order.
/// - Query x values given in **non-decreasing** order.
///
/// Under these constraints both insertion and query run in O(1) amortized time,
/// making it substantially faster than a Li Chao tree when the monotonicity
/// conditions are satisfied.
///
/// Internal layout:
/// ```
///   lines:  dynamic array acting as a deque; only the tail is ever pruned.
///   head:   index of the first live line (the pointer that advances on query).
///
///   [head]  [head+1]  ...  [lines.length-1]
///     ^                          ^
///     |                          |
///  current best             most recently
///  for ongoing queries      added line
/// ```
pub struct ConvexHullTrick {
  lines : Array[Line]
  mut head : Int
}

///|
/// Create an empty `ConvexHullTrick`.
///
/// Lines must subsequently be added with `add_line` in non-decreasing slope
/// order, and queries must be made with `query` in non-decreasing x order.
///
/// ```moonbit
/// let cht = ConvexHullTrick::new()
/// ```
pub fn ConvexHullTrick::new() -> ConvexHullTrick {
  { lines: [], head: 0 }
}

///|
/// Insert the line y = `m`*x + `b` into the upper envelope.
///
/// Slopes must be provided in non-decreasing order across all calls. Adding a
/// line with a slope smaller than the previous slope is undefined behaviour and
/// will silently produce wrong query results.
///
/// The function prunes lines from the tail of the internal array that have
/// become dominated — i.e. lines that are never the maximum for any x.
/// Each line is pushed and popped at most once, so the total work across all
/// `add_line` calls is O(n).
///
/// Example (continuing from previous calls):
/// ```moonbit
/// let cht = ConvexHullTrick::new()
/// cht.add_line(1L, 0L)   // y = x
/// cht.add_line(2L, 1L)   // y = 2x + 1  (slope increased)
/// cht.add_line(3L, -1L)  // y = 3x - 1  (slope increased again)
/// ```
pub fn ConvexHullTrick::add_line(
  self : ConvexHullTrick,
  m : Int64,
  b : Int64,
) -> Unit {
  let line = { m, b }
  for prune_next = self.lines.length() - self.head >= 2; prune_next; {
    let l1 = self.lines[self.lines.length() - 2]
    let l2 = self.lines[self.lines.length() - 1]
    if is_bad(l1, l2, line) {
      let _ = self.lines.pop()
      continue self.lines.length() - self.head >= 2
    } else {
      break
    }
  }
  self.lines.push(line)
}

///|
/// Return the maximum value of any inserted line evaluated at `x`.
///
/// Query x values must be provided in non-decreasing order across all calls.
/// Querying at an x smaller than a previous query is undefined behaviour and
/// may return a wrong answer.
///
/// The function advances the internal `head` pointer past any line that is no
/// longer optimal. Because `head` only moves forward and never exceeds the
/// array length, the total work across all `query` calls is O(q) amortised.
///
/// ```moonbit
/// let cht = ConvexHullTrick::new()
/// cht.add_line(1L, 0L)
/// cht.add_line(2L, 1L)
/// cht.add_line(3L, -1L)
/// // Queries must be non-decreasing:
/// let v0 = cht.query(0L)  // returns 1  (line y=2x+1 wins at x=0)
/// let v1 = cht.query(1L)  // returns 3  (line y=2x+1 wins at x=1)
/// let v3 = cht.query(3L)  // returns 8  (line y=3x-1 wins at x=3)
/// ```
pub fn ConvexHullTrick::query(self : ConvexHullTrick, x : Int64) -> Int64 {
  for advance_next = self.lines.length() - self.head >= 2; advance_next; {
    let l1 = self.lines[self.head]
    let l2 = self.lines[self.head + 1]
    if l2.value(x) >= l1.value(x) {
      self.head = self.head + 1
      continue self.lines.length() - self.head >= 2
    } else {
      break
    }
  }
  self.lines[self.head].value(x)
}
