// ============================================================================
// ONLINE MEDIAN - Two-heap streaming median
// ============================================================================
//
// PROBLEM
//
// Given a stream of integers x_0, x_1, x_2, ..., maintain the median of
// the multiset { x_0, ..., x_n } after each insertion in O(log n) time
// per update and O(1) per query.
//
// THE TRICK
//
// Split the multiset into two halves:
//
//   lo : a max-heap holding the smaller half
//   hi : a min-heap holding the larger half
//
// We use two `@priority_queue.PriorityQueue` instances (which are
// max-heaps). For `hi`, we store *negated* values so the maximum of the
// negated set is the minimum of the original.
//
// INVARIANTS (maintained between `add` calls):
//
//   I1.  max(lo)  <=  min(hi)                  (lo is entirely below hi)
//   I2.  |lo.size  -  hi.size|  <=  1          (sizes differ by at most one)
//   I3.  lo.size  >=  hi.size                  (lo holds the extra when odd)
//
// MEDIAN COMPUTATION
//
// If lo.size > hi.size, the median is the single middle element max(lo).
// Otherwise the size is even and the median is (max(lo) + min(hi)) / 2.
//
// TIME COMPLEXITY  : O(log n) per `add`, O(1) per `median`
// SPACE COMPLEXITY : O(n) total (one slot per item across the two heaps)

///|
/// An online-median tracker for an Int stream.
///
/// `lo` is the max-heap of the smaller half; `hi` stores the *negated*
/// values of the larger half, so its max-heap peek gives the min of the
/// larger half.
pub struct OnlineMedian {
  lo : @priority_queue.PriorityQueue[Int]
  hi : @priority_queue.PriorityQueue[Int]
}

///|
/// Create an empty online-median tracker.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let m = @online_median.new()
///   m.add(3)
///   m.add(1)
///   m.add(2)
///   // sorted: [1, 2, 3], median = 2.
///   assert_eq(m.lower_median(), Some(2))
/// }
/// ```
pub fn new() -> OnlineMedian {
  { lo: PriorityQueue([]), hi: PriorityQueue([]) }
}

///|
/// Insert one element from the stream and re-establish the
/// two-heap invariants.
///
/// ## Routing
///
/// New `x` goes to `lo` if it is `<= max(lo)`, else to `hi`. After
/// routing, at most one transfer between the heaps restores the size
/// invariant.
pub fn OnlineMedian::add(self : OnlineMedian, x : Int) -> Unit {
  // Step 1: route x to the heap it belongs to.
  match self.lo.peek() {
    None => self.lo.push(x)
    Some(top_lo) => if x <= top_lo { self.lo.push(x) } else { self.hi.push(-x) }
  }
  // Step 2: rebalance. After step 1 the two heaps differ in size by
  // at most 2. A single transfer restores the (|lo - hi| <= 1, lo >=
  // hi) invariant.
  if self.lo.length() > self.hi.length() + 1 {
    // lo is too heavy; move max(lo) to hi (negated).
    match self.lo.pop() {
      Some(top) => self.hi.push(-top)
      None => ()
    }
  } else if self.hi.length() > self.lo.length() {
    // hi is heavier; move min(hi) to lo (un-negated).
    match self.hi.pop() {
      Some(neg_top) => self.lo.push(-neg_top)
      None => ()
    }
  }
}

///|
/// Current count of elements added so far.
pub fn OnlineMedian::size(self : OnlineMedian) -> Int {
  self.lo.length() + self.hi.length()
}

///|
/// The **lower median** of the stream so far: when the count is odd,
/// the unique middle element; when the count is even, the smaller of
/// the two middle elements. Returns `None` on an empty stream.
///
/// Use this when the stream is integer-valued and you want to avoid
/// floating-point arithmetic.
pub fn OnlineMedian::lower_median(self : OnlineMedian) -> Int? {
  self.lo.peek()
}

///|
/// The **upper median**: when the count is odd, the unique middle
/// element; when the count is even, the larger of the two middle
/// elements. Returns `None` on an empty stream.
pub fn OnlineMedian::upper_median(self : OnlineMedian) -> Int? {
  if self.lo.length() > self.hi.length() {
    // Odd count -- lower and upper medians coincide.
    self.lo.peek()
  } else if self.hi.is_empty() {
    None
  } else {
    match self.hi.peek() {
      Some(neg_top) => Some(-neg_top)
      None => None
    }
  }
}

///|
/// The **true median** as a `Double`: average of the two middle
/// elements when the count is even, the single middle element when
/// odd. Returns `None` on an empty stream.
pub fn OnlineMedian::median(self : OnlineMedian) -> Double? {
  let total = self.size()
  if total == 0 {
    return None
  }
  let lo_top = self.lo.peek()
  if self.lo.length() > self.hi.length() {
    match lo_top {
      Some(v) => Some(v.to_double())
      None => None
    }
  } else {
    // Equal sizes (>= 1 each)
    let hi_top = self.hi.peek()
    match (lo_top, hi_top) {
      (Some(a), Some(neg_b)) =>
        Some((a.to_double() + (-neg_b).to_double()) / 2.0)
      _ => None
    }
  }
}

///|
test "online median empty" {
  let m = new()
  @debug.assert_eq(m.median(), None)
  @debug.assert_eq(m.lower_median(), None)
  @debug.assert_eq(m.upper_median(), None)
  @debug.assert_eq(m.size(), 0)
}

///|
test "online median single element" {
  let m = new()
  m.add(7)
  @debug.assert_eq(m.lower_median(), Some(7))
  @debug.assert_eq(m.upper_median(), Some(7))
  @debug.assert_eq(m.median(), Some(7.0))
}

///|
test "online median two elements averages" {
  let m = new()
  m.add(1)
  m.add(3)
  @debug.assert_eq(m.lower_median(), Some(1))
  @debug.assert_eq(m.upper_median(), Some(3))
  @debug.assert_eq(m.median(), Some(2.0))
}

///|
test "online median sorted insertion" {
  let m = new()
  for x in [1, 2, 3, 4, 5] {
    m.add(x)
  }
  // sorted: [1,2,3,4,5]; median = 3.
  @debug.assert_eq(m.lower_median(), Some(3))
  @debug.assert_eq(m.median(), Some(3.0))
}

///|
test "online median reverse insertion" {
  // Insertion order shouldn't matter for the median.
  let m = new()
  for x in [5, 4, 3, 2, 1] {
    m.add(x)
  }
  @debug.assert_eq(m.lower_median(), Some(3))
  @debug.assert_eq(m.median(), Some(3.0))
}

///|
test "online median interleaved" {
  let m = new()
  for x in [3, 1, 4, 1, 5, 9, 2, 6, 5, 3] {
    m.add(x)
  }
  // Sorted: [1, 1, 2, 3, 3, 4, 5, 5, 6, 9]; middle = (3 + 4) / 2 = 3.5.
  @debug.assert_eq(m.median(), Some(3.5))
  @debug.assert_eq(m.lower_median(), Some(3))
  @debug.assert_eq(m.upper_median(), Some(4))
}

///|
test "online median agrees with sort for many insertions" {
  // For each prefix of a length-20 stream, the online median should
  // agree with the ground-truth median computed by sorting.
  let stream = [8, 2, 5, 1, 9, 7, 3, 4, 6, 0, 5, 5, 2, 8, 8, 1, 9, 4, 7, 3]
  let seen : Array[Int] = []
  let m = new()
  for x in stream {
    m.add(x)
    seen.push(x)
    let sorted = seen.copy()
    sorted.sort()
    let n = sorted.length()
    let truth_lower = sorted[(n - 1) / 2]
    @debug.assert_eq(m.lower_median(), Some(truth_lower))
  }
}

///|
test "online median negatives and duplicates" {
  let m = new()
  for x in [-3, -3, 0, 5, -1, -1, 2] {
    m.add(x)
  }
  // sorted: [-3, -3, -1, -1, 0, 2, 5]; median = -1.
  @debug.assert_eq(m.lower_median(), Some(-1))
  @debug.assert_eq(m.median(), Some(-1.0))
}
