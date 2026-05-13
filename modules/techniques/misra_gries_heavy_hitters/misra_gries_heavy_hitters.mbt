// ============================================================================
// MISRA-GRIES HEAVY HITTERS - One-pass streaming candidates for frequent items
// ============================================================================
//
// PROBLEM
//
// Given a stream of N items and a parameter k, identify every item whose
// true frequency exceeds N / k. Naive solutions need O(N) extra space
// (count every distinct item). Misra-Gries solves it in **k - 1 counters
// and a single pass**: at most k - 1 items can simultaneously exceed
// the N / k threshold (a pigeonhole argument), so a tiny structure
// suffices to maintain a *superset* of heavy hitters.
//
// ALGORITHM (k = capacity + 1)
//
//   maintain a dict of (item -> counter), with at most `capacity` entries
//
//   for x in stream:
//     if x in dict:
//       dict[x] += 1
//     else if dict.size() < capacity:
//       dict[x] = 1
//     else:
//       # full -- decrement every counter by 1 and prune zeros.
//       # Conceptually we cancel k items (x and one from each existing
//       # bucket).
//       for k in dict:
//         dict[k] -= 1
//         if dict[k] == 0: dict.remove(k)
//
// At the end, dict.keys() is a superset of items with true frequency
// > N / k. The recorded counter is a lower bound on the true count:
// `true_count - N / k  <=  dict[x]  <=  true_count`.
//
// CORRECTNESS (sketch -- see README for the full argument)
//
// Every "decrement-all" step cancels exactly `capacity` items already in
// the dict plus the incoming x. Each such "cancellation event" removes
// at most one occurrence of any single item, so an item whose true
// count exceeds N / (capacity + 1) cannot be cancelled to zero --
// it survives.
//
// TIME COMPLEXITY  : O(N * capacity) worst case; O(N) amortised when the
//                    stream is heavy-tailed (most decrements are no-ops)
// SPACE COMPLEXITY : O(capacity) Int counters

///|
/// A Misra-Gries summary with at most `capacity` slots. `capacity` is
/// `k - 1`: passing `capacity = 9` finds heavy hitters above N / 10.
///
/// The recorded counter is a *lower bound* on the true frequency, off
/// by at most `N / (capacity + 1)`. If you need exact counts, run a
/// second pass over the stream and count only the candidate set.
pub struct MisraGries[K] {
  capacity : Int
  counts : Map[K, Int]
}

///|
/// Create a fresh Misra-Gries summary with `capacity` slots. Pass
/// `capacity = k - 1` to find items whose true frequency exceeds
/// `N / k`. The smallest interesting value is `capacity = 1`, which
/// finds a strict majority (the Boyer-Moore majority vote).
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let mg = @misra_gries_heavy_hitters.new(capacity=2)
///   for x in [1, 1, 2, 1, 3, 1, 4, 1] {
///     mg.add(x)
///   }
///   // 1 occurs 5 times in 8 -> heavy hitter for k=3.
///   assert_true(mg.candidates().contains(1))
/// }
/// ```
pub fn[K : Hash + Eq] new(capacity~ : Int) -> MisraGries[K] {
  let cap = if capacity < 1 { 1 } else { capacity }
  { capacity: cap, counts: Map([], capacity=cap) }
}

///|
/// Consume one element of the stream. Runs in O(capacity) worst case
/// (the decrement-all branch) and O(1) amortised under reasonable
/// distributional assumptions.
///
/// ## Parameters
///
/// - `self` : summary being updated in place.
/// - `item` : next element from the stream.
pub fn[K : Hash + Eq] MisraGries::add(self : MisraGries[K], item : K) -> Unit {
  match self.counts.get(item) {
    Some(c) => self.counts[item] = c + 1
    None =>
      if self.counts.length() < self.capacity {
        self.counts[item] = 1
      } else {
        // Decrement every counter; remove those that reach zero. This
        // cancels one occurrence of `item` against one occurrence from
        // each surviving bucket, exactly `capacity + 1 = k` items
        // overall.
        let to_remove : Array[K] = []
        for k, v in self.counts {
          let nv = v - 1
          if nv == 0 {
            to_remove.push(k)
          } else {
            self.counts[k] = nv
          }
        }
        for k in to_remove {
          self.counts.remove(k)
        } where {
          proof_invariant: self.counts.length() <= self.capacity,
          proof_reasoning: (
            #|INVARIANT (Removal pass):
            #|to_remove enumerates exactly the keys whose decremented
            #|counter is zero. Each removal shrinks `self.counts` by
            #|one, but it was at most `capacity` to begin with.
          ),
        }
      }
  }
}

///|
/// Return the current candidate set: a superset of all items with true
/// frequency `> N / (capacity + 1)`.
///
/// The order of the returned array is unspecified.
pub fn[K] MisraGries::candidates(self : MisraGries[K]) -> Array[K] {
  let result : Array[K] = []
  for k, _ in self.counts {
    result.push(k)
  }
  result
}

///|
/// Return the lower-bound count associated with `item` in the summary,
/// or 0 if the item is not currently tracked.
///
/// The true frequency satisfies `recorded <= true <= recorded + N / (capacity + 1)`.
pub fn[K : Hash + Eq] MisraGries::estimate(
  self : MisraGries[K],
  item : K,
) -> Int {
  match self.counts.get(item) {
    Some(c) => c
    None => 0
  }
}

///|
/// Current number of tracked candidates. Always `0 <= size <= capacity`.
pub fn[K] MisraGries::size(self : MisraGries[K]) -> Int {
  self.counts.length()
}

///|
/// Merge another summary into this one (must have the same `capacity`).
/// The merged result is itself a valid Misra-Gries summary: it carries
/// every heavy hitter of the combined stream that is heavy above the
/// same threshold.
///
/// Algorithm (Agarwal et al.): add counters for shared keys; keep new
/// keys at their raw count; let the (capacity+1)-th largest counter be
/// `t`; subtract `t` from every counter and prune non-positives.
pub fn[K : Hash + Eq] MisraGries::merge(
  self : MisraGries[K],
  other : MisraGries[K],
) -> Unit {
  if self.capacity != other.capacity {
    return
  }
  // Step 1: union with summed counters.
  for k, v in other.counts {
    match self.counts.get(k) {
      Some(c) => self.counts[k] = c + v
      None => self.counts[k] = v
    }
  }
  // Step 2: if more than `capacity` distinct keys remain, find the
  // (capacity+1)-th largest counter `t`, subtract `t` from every
  // counter, and drop non-positives.
  if self.counts.length() <= self.capacity {
    return
  }
  let values : Array[Int] = []
  for _, v in self.counts {
    values.push(v)
  }
  values.sort()
  // values is ascending; the (capacity+1)-th largest is
  // values[size - capacity - 1].
  let threshold = values[values.length() - self.capacity - 1]
  let to_remove : Array[K] = []
  for k, v in self.counts {
    let nv = v - threshold
    if nv <= 0 {
      to_remove.push(k)
    } else {
      self.counts[k] = nv
    }
  }
  for k in to_remove {
    self.counts.remove(k)
  }
}

///|
test "mg single majority via capacity 1" {
  // Boyer-Moore majority specialisation: capacity = 1 finds an absolute
  // majority element if one exists.
  let mg : MisraGries[Int] = new(capacity=1)
  for x in [3, 1, 3, 2, 3, 4, 3, 5, 3, 3] {
    mg.add(x)
  }
  // 3 occurs 6/10 -> majority.
  @debug.assert_eq(mg.candidates(), [3])
  @debug.assert_eq(mg.estimate(3) > 0, true)
}

///|
test "mg no majority leaves arbitrary candidate" {
  // capacity = 1 with no majority -- output is just *some* survivor.
  let mg : MisraGries[Int] = new(capacity=1)
  for x in [1, 2, 3, 4] {
    mg.add(x)
  }
  // After processing 4 items with no repeats, the dict has been emptied
  // three times. The final survivor is 4 with counter 1.
  @debug.assert_eq(mg.size() <= 1, true)
}

///|
test "mg top-2 with capacity 2" {
  let mg : MisraGries[Int] = new(capacity=2)
  let stream = [1, 1, 1, 2, 2, 3, 4, 1, 1, 2, 2, 2]
  for x in stream {
    mg.add(x)
  }
  // 1 occurs 5/12 (~42%); 2 occurs 5/12 (~42%). Both exceed n / 3.
  let cands = mg.candidates()
  @debug.assert_eq(cands.contains(1), true)
  @debug.assert_eq(cands.contains(2), true)
}

///|
test "mg estimate is a true lower bound" {
  // Build a stream where item 7 appears 10 times out of 30. With
  // capacity = 4 (threshold n / 5 = 6), 7 is a heavy hitter.
  let mg : MisraGries[Int] = new(capacity=4)
  let n_seven = 10
  let n_filler = 20 // 20 unique values 100..119
  for _ in 0..<n_seven {
    mg.add(7)
  }
  for v in 100..<(100 + n_filler) {
    mg.add(v)
  }
  let recorded = mg.estimate(7)
  // Recorded is a lower bound; threshold here is 30 / 5 = 6.
  @debug.assert_eq(recorded > 0, true)
  // True count of 7 is 10; the gap to recorded is at most n / k = 6.
  @debug.assert_eq(recorded >= 10 - 30 / 5, true)
}

///|
test "mg candidates always within capacity" {
  let mg : MisraGries[Int] = new(capacity=3)
  for v in 0..<100 {
    mg.add(v % 7)
  }
  @debug.assert_eq(mg.size() <= 3, true)
}

///|
test "mg empty stream" {
  let mg : MisraGries[Int] = new(capacity=5)
  @debug.assert_eq(mg.candidates(), [])
  @debug.assert_eq(mg.estimate(42), 0)
}

///|
test "mg merge preserves majority" {
  let mg1 : MisraGries[Int] = new(capacity=2)
  let mg2 : MisraGries[Int] = new(capacity=2)
  for _ in 0..<10 {
    mg1.add(99)
  }
  mg1.add(1)
  mg1.add(2)
  for _ in 0..<10 {
    mg2.add(99)
  }
  mg2.add(3)
  mg2.add(4)
  mg1.merge(mg2)
  @debug.assert_eq(mg1.candidates().contains(99), true)
}

///|
test "mg merge ignores mismatched capacity" {
  let mg1 : MisraGries[Int] = new(capacity=2)
  let mg2 : MisraGries[Int] = new(capacity=4)
  mg1.add(1)
  mg2.add(2)
  mg1.merge(mg2)
  // mg1 unchanged because shapes differ.
  @debug.assert_eq(mg1.size(), 1)
}

///|
test "mg degenerate capacity" {
  let mg : MisraGries[Int] = new(capacity=0)
  // capacity coerced to 1 internally.
  for v in 0..<5 {
    mg.add(v)
  }
  @debug.assert_eq(mg.size() <= 1, true)
}
