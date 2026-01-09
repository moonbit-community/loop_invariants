// ============================================================================
// FENWICK TREE (BINARY INDEXED TREE) EXAMPLES WITH LOOP INVARIANTS
// ============================================================================
//
// The Fenwick Tree (also called Binary Indexed Tree or BIT) is an elegant
// data structure that supports both point updates and prefix sum queries
// in O(log n) time, using only O(n) space.
//
// THE KEY INSIGHT:
// The structure exploits the binary representation of indices. Each node i
// stores the sum of elements in a range whose size is determined by the
// lowest set bit of i.
//
// If lowbit(i) = i & (-i) (the lowest set bit), then:
//   tree[i] = sum of arr[i - lowbit(i) + 1 ... i]
//
// This creates a beautiful invariant: traversing indices by adding/removing
// the lowest set bit walks through exactly log(n) nodes.

// ============================================================================
// CORE OPERATIONS
// ============================================================================

///|
/// Get the lowest set bit of a number.
/// This is the key operation that makes Fenwick trees work.
///
/// MATHEMATICAL INSIGHT:
/// In two's complement, -x = ~x + 1.
/// When we AND x with -x, only the lowest set bit survives.
///
/// Example: x = 12 = 1100₂
///         -x = 0100₂ (in 4-bit two's complement: ~1100 + 1 = 0011 + 1 = 0100)
///         x & -x = 0100₂ = 4
fn lowbit(x : Int) -> Int {
  x & (-x)
}

///|
/// Fenwick Tree structure.
/// tree[i] stores partial sum for range ending at i.
struct FenwickTree {
  tree : Array[Int]
  n : Int
}

///|
/// Create a new Fenwick tree of size n+1 (1-indexed).
fn FenwickTree::new(n : Int) -> FenwickTree {
  { tree: Array::make(n + 1, 0), n }
}

///|
/// Update: add delta to position i (1-indexed).
///
/// ALGORITHM:
/// Starting from i, we update all nodes that include position i in their range.
/// These are exactly the nodes at indices i, i + lowbit(i), i + lowbit(i + lowbit(i)), ...
///
/// INVARIANT: Every ancestor of i (in the Fenwick tree sense) gets updated.
#warnings("+missing_invariant+missing_reasoning")
fn FenwickTree::update(self : FenwickTree, i : Int, delta : Int) -> Unit {
  for idx = i {
    if idx > self.n {
      break
    } else {
      self.tree[idx] = self.tree[idx] + delta
      continue idx + lowbit(idx)
    }
  } where {
    invariant: idx >= i,
    reasoning: (
      #|INVARIANT: idx traverses through all positions whose ranges include i.
      #|
      #|PROOF OF RANGE COVERAGE:
      #|For any j > i, position j's range includes i iff:
      #|  j - lowbit(j) < i ≤ j
      #|
      #|The sequence i, i + lowbit(i), i + lowbit(i + lowbit(i)), ...
      #|visits exactly those j that satisfy this condition.
      #|
      #|WHY THIS WORKS:
      #|Each step adds lowbit(idx), which flips the lowest set bit to 0
      #|and sets the next higher bit to 1 (with possible carry).
      #|This guarantees we eventually exceed n after O(log n) steps.
      #|
      #|Example: i = 3 = 011₂
      #|  idx = 3:  lowbit(3) = 1, next = 4
      #|  idx = 4:  lowbit(4) = 4, next = 8
      #|  idx = 8:  lowbit(8) = 8, next = 16 > n (if n < 16)
    ),
  }
}

///|
/// Query: compute prefix sum from 1 to i (1-indexed).
///
/// ALGORITHM:
/// Starting from i, we sum tree values at indices i, i - lowbit(i), ...
/// until we reach 0.
///
/// INVARIANT: We accumulate the sum of arr[1..i] by summing disjoint ranges.
#warnings("+missing_invariant+missing_reasoning")
fn FenwickTree::prefix_sum(self : FenwickTree, i : Int) -> Int {
  for idx = i, sum = 0 {
    if idx <= 0 {
      break sum
    } else {
      continue idx - lowbit(idx), sum + self.tree[idx]
    }
  } where {
    invariant: idx >= 0 && idx <= i,
    reasoning: (
      #|INVARIANT: sum = arr[idx+1] + arr[idx+2] + ... + arr[i]
      #|          (sum of elements from idx+1 to i)
      #|
      #|INITIALIZATION: idx = i, sum = 0
      #|  The range (i, i] is empty, so sum = 0 is correct.
      #|
      #|MAINTENANCE:
      #|  Before: sum = arr[idx+1] + ... + arr[i]
      #|  We add tree[idx] = arr[idx - lowbit(idx) + 1] + ... + arr[idx]
      #|  New sum = arr[idx - lowbit(idx) + 1] + ... + arr[i]
      #|  New idx = idx - lowbit(idx)
      #|  So the invariant holds with the new range.
      #|
      #|TERMINATION: When idx = 0, we have summed arr[1..i].
      #|
      #|WHY O(log n): Each step clears the lowest set bit.
      #|A number with k bits has at most k set bits.
    ),
  }
}

///|
/// Range sum query: compute sum from l to r (inclusive, 1-indexed).
fn FenwickTree::range_sum(self : FenwickTree, l : Int, r : Int) -> Int {
  self.prefix_sum(r) - self.prefix_sum(l - 1)
}

///|
test "fenwick_basic" {
  let ft = FenwickTree::new(8)
  // Add values: [3, 1, 4, 1, 5, 9, 2, 6] at positions 1-8
  ft.update(1, 3)
  ft.update(2, 1)
  ft.update(3, 4)
  ft.update(4, 1)
  ft.update(5, 5)
  ft.update(6, 9)
  ft.update(7, 2)
  ft.update(8, 6)
  // Test prefix sums
  assert_eq!(ft.prefix_sum(1), 3) // 3
  assert_eq!(ft.prefix_sum(2), 4) // 3 + 1
  assert_eq!(ft.prefix_sum(3), 8) // 3 + 1 + 4
  assert_eq!(ft.prefix_sum(4), 9) // 3 + 1 + 4 + 1
  assert_eq!(ft.prefix_sum(8), 31) // 3 + 1 + 4 + 1 + 5 + 9 + 2 + 6
  // Test range sums
  assert_eq!(ft.range_sum(2, 5), 11) // 1 + 4 + 1 + 5
  assert_eq!(ft.range_sum(3, 7), 21) // 4 + 1 + 5 + 9 + 2
}

// ============================================================================
// BUILD FROM ARRAY (O(n) construction)
// ============================================================================
//
// Instead of n updates (O(n log n)), we can build the tree in O(n)
// by exploiting the parent-child relationship.
//
// INSIGHT: After setting tree[i] = arr[i], we propagate to parent i + lowbit(i).

///|
/// Build Fenwick tree from array in O(n) time.
#warnings("+missing_invariant+missing_reasoning")
fn FenwickTree::from_array(arr : ArrayView[Int]) -> FenwickTree {
  let n = arr.length()
  let tree : Array[Int] = Array::make(n + 1, 0)
  // First, copy values (1-indexed)
  for i = 0 {
    if i >= n {
      break
    } else {
      tree[i + 1] = arr[i]
      continue i + 1
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|Copying array values to 1-indexed tree positions.
    ),
  }
  // Then propagate to parents
  for i = 1 {
    if i > n {
      break
    } else {
      let parent = i + lowbit(i)
      if parent <= n {
        tree[parent] = tree[parent] + tree[i]
      }
      continue i + 1
    }
  } where {
    invariant: i >= 1 && i <= n + 1,
    reasoning: (
      #|INVARIANT: After processing index i, tree[j] for j ≤ i contains
      #|the correct partial sum for its range (considering only indices ≤ i).
      #|
      #|PROOF:
      #|Initially tree[i] = arr[i-1] (the single element).
      #|When we process i, we add tree[i] to tree[parent].
      #|Parent's range extends from parent - lowbit(parent) + 1 to parent.
      #|Since i < parent and i is in parent's range, this correctly adds
      #|i's contribution to parent's sum.
      #|
      #|By processing in order 1, 2, ..., n, each node receives contributions
      #|from all its children before being propagated to its parent.
      #|
      #|TIME: O(n) because each index is touched at most twice.
    ),
  }
  { tree, n }
}

///|
test "fenwick_from_array" {
  let arr : Array[Int] = [3, 1, 4, 1, 5, 9, 2, 6]
  let ft = FenwickTree::from_array(arr[:])
  assert_eq!(ft.prefix_sum(4), 9)
  assert_eq!(ft.prefix_sum(8), 31)
  assert_eq!(ft.range_sum(2, 5), 11)
}

// ============================================================================
// FINDING K-TH ELEMENT (using Fenwick tree for frequency counts)
// ============================================================================
//
// If tree stores frequency counts, we can find the smallest i such that
// prefix_sum(i) >= k in O(log n) time using binary lifting.
//
// This is more elegant than binary search because we directly use the
// tree structure.

///|
/// Find smallest index i such that prefix_sum(i) >= k.
/// Assumes tree stores non-negative values (frequency counts).
/// Returns 0 if no such index exists or if k <= 0.
#warnings("+missing_invariant+missing_reasoning")
fn FenwickTree::find_kth(self : FenwickTree, k : Int) -> Int {
  if k <= 0 {
    return 0
  }
  // Find the highest power of 2 <= n
  let mut max_bit = 1
  while max_bit * 2 <= self.n {
    max_bit = max_bit * 2
  }
  for pos = 0, remaining = k, bit = max_bit {
    if bit == 0 {
      // pos is the largest index with prefix_sum(pos) < k
      // so pos + 1 is the smallest with prefix_sum >= k
      let result = pos + 1
      break if result <= self.n { result } else { 0 }
    } else {
      let next_pos = pos + bit
      if next_pos <= self.n && self.tree[next_pos] < remaining {
        // Include this subtree in our path
        continue next_pos, remaining - self.tree[next_pos], bit / 2
      } else {
        // Skip this subtree
        continue pos, remaining, bit / 2
      }
    }
  } where {
    invariant: bit >= 0 && pos >= 0 && pos <= self.n,
    reasoning: (
      #|INVARIANT: pos is the largest index such that prefix_sum(pos) < remaining + already_consumed.
      #|
      #|At each step:
      #|  - pos represents the rightmost position we've confirmed has sum < k
      #|  - remaining = k - prefix_sum(pos) (the amount still needed)
      #|  - bit is the current step size (power of 2)
      #|
      #|If tree[pos + bit] < remaining:
      #|  The sum up to pos + bit is still less than k, so we advance pos.
      #|  We subtract tree[pos + bit] from remaining because we're moving
      #|  past this range.
      #|
      #|Otherwise:
      #|  The answer is ≤ pos + bit, so we don't advance pos but try
      #|  smaller bits.
      #|
      #|TERMINATION:
      #|  When bit = 0, pos is the largest index with prefix_sum(pos) < k.
      #|  Therefore pos + 1 is the smallest index with prefix_sum >= k.
      #|
      #|TIME: O(log n) - we halve bit each iteration.
    ),
  }
}

///|
test "fenwick_find_kth" {
  // Use as frequency array: 2 ones, 3 twos, 1 three, 4 fours
  // Positions represent values, counts represent frequencies
  let ft = FenwickTree::new(4)
  ft.update(1, 2) // 2 copies of value 1
  ft.update(2, 3) // 3 copies of value 2
  ft.update(3, 1) // 1 copy of value 3
  ft.update(4, 4) // 4 copies of value 4
  // Total: 10 elements
  // Sorted: 1, 1, 2, 2, 2, 3, 4, 4, 4, 4
  // 1st element: 1
  assert_eq!(ft.find_kth(1), 1)
  // 2nd element: 1
  assert_eq!(ft.find_kth(2), 1)
  // 3rd element: 2
  assert_eq!(ft.find_kth(3), 2)
  // 5th element: 2
  assert_eq!(ft.find_kth(5), 2)
  // 6th element: 3
  assert_eq!(ft.find_kth(6), 3)
  // 7th element: 4
  assert_eq!(ft.find_kth(7), 4)
}

// ============================================================================
// 2D FENWICK TREE
// ============================================================================
//
// The Fenwick tree naturally extends to 2D for rectangle sum queries.
// Update and query both become O(log n × log m).
//
// Each dimension uses the same lowbit traversal independently.

///|
struct FenwickTree2D {
  tree : Array[Int]
  n : Int
  m : Int
}

///|
fn FenwickTree2D::new(n : Int, m : Int) -> FenwickTree2D {
  { tree: Array::make((n + 1) * (m + 1), 0), n, m }
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn FenwickTree2D::update(self : FenwickTree2D, i : Int, j : Int, delta : Int) -> Unit {
  for x = i {
    if x > self.n {
      break
    } else {
      for y = j {
        if y > self.m {
          break
        } else {
          let idx = x * (self.m + 1) + y
          self.tree[idx] = self.tree[idx] + delta
          continue y + lowbit(y)
        }
      } where {
        invariant: y >= j,
        reasoning: (
          #|Inner loop traverses column indices in Fenwick tree order.
        ),
      }
      continue x + lowbit(x)
    }
  } where {
    invariant: x >= i,
    reasoning: (
      #|INVARIANT: We update all cells (x, y) whose 2D ranges include (i, j).
      #|
      #|The 2D Fenwick tree has the property that tree[x][y] stores:
      #|  sum of arr[x - lowbit(x) + 1 .. x][y - lowbit(y) + 1 .. y]
      #|
      #|To update (i, j), we must update all (x, y) where:
      #|  x - lowbit(x) < i ≤ x  AND  y - lowbit(y) < j ≤ y
      #|
      #|This is exactly the Cartesian product of the 1D Fenwick ancestors.
    ),
  }
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn FenwickTree2D::prefix_sum(self : FenwickTree2D, i : Int, j : Int) -> Int {
  for x = i, sum = 0 {
    if x <= 0 {
      break sum
    } else {
      let inner_sum = for y = j, acc = 0 {
        if y <= 0 {
          break acc
        } else {
          let idx = x * (self.m + 1) + y
          continue y - lowbit(y), acc + self.tree[idx]
        }
      } where {
        invariant: y >= 0,
        reasoning: (
          #|Inner loop: standard 1D Fenwick prefix sum for column.
        ),
      }
      continue x - lowbit(x), sum + inner_sum
    }
  } where {
    invariant: x >= 0,
    reasoning: (
      #|INVARIANT: sum accumulates the 2D prefix sum for rectangle (1,1) to (i,j).
      #|
      #|The 2D query is the sum of independent 1D queries:
      #|  For each x-ancestor, we do a 1D column query.
      #|
      #|COMPLEXITY: O(log n × log m) - product of dimensions.
    ),
  }
}

///|
/// Query sum in rectangle (r1, c1) to (r2, c2) inclusive.
fn FenwickTree2D::range_sum(
  self : FenwickTree2D,
  r1 : Int,
  c1 : Int,
  r2 : Int,
  c2 : Int
) -> Int {
  // Inclusion-exclusion principle
  self.prefix_sum(r2, c2) - self.prefix_sum(r1 - 1, c2) - self.prefix_sum(
    r2, c1 - 1,
  ) + self.prefix_sum(r1 - 1, c1 - 1)
}

///|
test "fenwick_2d" {
  let ft = FenwickTree2D::new(3, 4)
  // Create a 3x4 grid:
  // 1 2 3 4
  // 5 6 7 8
  // 9 10 11 12
  ft.update(1, 1, 1)
  ft.update(1, 2, 2)
  ft.update(1, 3, 3)
  ft.update(1, 4, 4)
  ft.update(2, 1, 5)
  ft.update(2, 2, 6)
  ft.update(2, 3, 7)
  ft.update(2, 4, 8)
  ft.update(3, 1, 9)
  ft.update(3, 2, 10)
  ft.update(3, 3, 11)
  ft.update(3, 4, 12)
  // Test prefix sums
  assert_eq!(ft.prefix_sum(1, 1), 1)
  assert_eq!(ft.prefix_sum(1, 4), 10) // 1+2+3+4
  assert_eq!(ft.prefix_sum(2, 2), 14) // 1+2+5+6
  assert_eq!(ft.prefix_sum(3, 4), 78) // sum of all
  // Test range sums
  assert_eq!(ft.range_sum(2, 2, 3, 3), 34) // 6+7+10+11
  assert_eq!(ft.range_sum(1, 1, 3, 4), 78) // all
}

// ============================================================================
// RANGE UPDATE, POINT QUERY
// ============================================================================
//
// By storing differences instead of values, we can support:
// - Range update: add delta to all elements in [l, r]
// - Point query: get value at position i
//
// INSIGHT: If D[i] = A[i] - A[i-1] (difference array),
// then A[i] = D[1] + D[2] + ... + D[i] = prefix_sum of D.
//
// To add delta to A[l..r]:
//   D[l] += delta   (start of increase)
//   D[r+1] -= delta (end of increase)

///|
struct FenwickTreeRangeUpdate {
  diff : FenwickTree // Stores differences
}

///|
fn FenwickTreeRangeUpdate::new(n : Int) -> FenwickTreeRangeUpdate {
  { diff: FenwickTree::new(n) }
}

///|
/// Add delta to all elements in range [l, r].
fn FenwickTreeRangeUpdate::range_add(
  self : FenwickTreeRangeUpdate,
  l : Int,
  r : Int,
  delta : Int
) -> Unit {
  self.diff.update(l, delta)
  if r + 1 <= self.diff.n {
    self.diff.update(r + 1, -delta)
  }
}

///|
/// Query value at position i.
fn FenwickTreeRangeUpdate::point_query(
  self : FenwickTreeRangeUpdate,
  i : Int
) -> Int {
  self.diff.prefix_sum(i)
}

///|
test "fenwick_range_update" {
  let ft = FenwickTreeRangeUpdate::new(8)
  // Add 5 to positions 2-5
  ft.range_add(2, 5, 5)
  assert_eq!(ft.point_query(1), 0)
  assert_eq!(ft.point_query(2), 5)
  assert_eq!(ft.point_query(5), 5)
  assert_eq!(ft.point_query(6), 0)
  // Add 3 to positions 4-7
  ft.range_add(4, 7, 3)
  assert_eq!(ft.point_query(3), 5)
  assert_eq!(ft.point_query(4), 8) // 5 + 3
  assert_eq!(ft.point_query(6), 3)
  assert_eq!(ft.point_query(8), 0)
}

// ============================================================================
// RANGE UPDATE, RANGE QUERY (Advanced)
// ============================================================================
//
// To support both range updates AND range queries, we need TWO Fenwick trees.
//
// MATHEMATICAL DERIVATION:
// Let A[i] be the original array (initially 0).
// After range update [l, r] += delta:
//   A[i] = delta × max(0, min(i, r) - l + 1)  for l ≤ i
//        = delta × (i - l + 1)  for l ≤ i ≤ r
//        = delta × (r - l + 1)  for i > r
//
// For prefix sum up to i after updates:
//   sum(1, i) = Σⱼ A[j]
//
// Using difference array D[i] = A[i] - A[i-1]:
//   A[i] = D[1] + ... + D[i]
//   sum(1, i) = Σⱼ (D[1] + ... + D[j])
//             = i×D[1] + (i-1)×D[2] + ... + 1×D[i]
//             = (i+1) × (D[1] + ... + D[i]) - (1×D[1] + 2×D[2] + ... + i×D[i])
//             = (i+1) × prefix_D(i) - prefix_iD(i)
//
// We maintain two Fenwick trees:
//   tree1: stores D[i]
//   tree2: stores i × D[i]

///|
struct FenwickTreeRangeRange {
  tree1 : FenwickTree // D[i]
  tree2 : FenwickTree // i * D[i]
  n : Int
}

///|
fn FenwickTreeRangeRange::new(n : Int) -> FenwickTreeRangeRange {
  { tree1: FenwickTree::new(n), tree2: FenwickTree::new(n), n }
}

///|
/// Add delta to all elements in range [l, r].
fn FenwickTreeRangeRange::range_add(
  self : FenwickTreeRangeRange,
  l : Int,
  r : Int,
  delta : Int
) -> Unit {
  // Update D[l] += delta
  self.tree1.update(l, delta)
  self.tree2.update(l, l * delta)
  // Update D[r+1] -= delta
  if r + 1 <= self.n {
    self.tree1.update(r + 1, -delta)
    self.tree2.update(r + 1, -(r + 1) * delta)
  }
}

///|
/// Query prefix sum from 1 to i.
fn FenwickTreeRangeRange::prefix_sum(self : FenwickTreeRangeRange, i : Int) -> Int {
  // sum(1, i) = (i+1) × prefix_D(i) - prefix_iD(i)
  (i + 1) * self.tree1.prefix_sum(i) - self.tree2.prefix_sum(i)
}

///|
/// Query sum in range [l, r].
fn FenwickTreeRangeRange::range_sum(
  self : FenwickTreeRangeRange,
  l : Int,
  r : Int
) -> Int {
  self.prefix_sum(r) - self.prefix_sum(l - 1)
}

///|
test "fenwick_range_range" {
  let ft = FenwickTreeRangeRange::new(8)
  // Add 2 to positions 1-4
  ft.range_add(1, 4, 2)
  // Array: [2, 2, 2, 2, 0, 0, 0, 0]
  assert_eq!(ft.range_sum(1, 4), 8)
  assert_eq!(ft.range_sum(1, 8), 8)
  assert_eq!(ft.range_sum(3, 5), 4) // 2 + 2 + 0
  // Add 3 to positions 3-6
  ft.range_add(3, 6, 3)
  // Array: [2, 2, 5, 5, 3, 3, 0, 0]
  assert_eq!(ft.range_sum(1, 8), 20)
  assert_eq!(ft.range_sum(3, 4), 10) // 5 + 5
  assert_eq!(ft.range_sum(5, 6), 6) // 3 + 3
}

// ============================================================================
// INVERSION COUNT (Classic Application)
// ============================================================================
//
// Count inversions: pairs (i, j) where i < j but arr[i] > arr[j].
//
// ALGORITHM:
// Process elements from right to left. For each element, count how many
// smaller elements are to its right (already processed).
// Use Fenwick tree as a frequency counter.
//
// INVARIANT: After processing position i, tree[v] = count of value v in arr[i+1..n].

///|
/// Count inversions in an array.
/// Values should be in range [1, max_val].
#warnings("+missing_invariant+missing_reasoning")
fn count_inversions(arr : ArrayView[Int], max_val : Int) -> Int {
  let ft = FenwickTree::new(max_val)
  let n = arr.length()
  for i = n - 1, count = 0 {
    if i < 0 {
      break count
    } else {
      // Count elements smaller than arr[i] that are to its right
      let smaller = ft.prefix_sum(arr[i] - 1)
      ft.update(arr[i], 1)
      continue i - 1, count + smaller
    }
  } where {
    invariant: i >= -1 && i < n,
    reasoning: (
      #|INVARIANT: After processing index i:
      #|  - tree[v] = frequency of value v in arr[i+1..n-1]
      #|  - count = number of inversions involving indices > i
      #|
      #|MAINTENANCE:
      #|  For each arr[i], we query prefix_sum(arr[i] - 1).
      #|  This counts values < arr[i] in positions > i.
      #|  Each such pair (i, j) is an inversion since i < j but arr[i] > arr[j].
      #|
      #|  Then we update tree[arr[i]]++ to include this element for
      #|  future queries (elements to the left of i).
      #|
      #|TERMINATION:
      #|  When i < 0, we've processed all elements.
      #|  count holds the total inversion count.
      #|
      #|COMPLEXITY: O(n log(max_val))
    ),
  }
}

///|
test "count_inversions" {
  // [3, 1, 2]: inversions are (3,1), (3,2) = 2
  let arr1 : Array[Int] = [3, 1, 2]
  assert_eq!(count_inversions(arr1[:], 3), 2)
  // [1, 2, 3, 4]: no inversions
  let arr2 : Array[Int] = [1, 2, 3, 4]
  assert_eq!(count_inversions(arr2[:], 4), 0)
  // [4, 3, 2, 1]: all pairs are inversions = 4×3/2 = 6
  let arr3 : Array[Int] = [4, 3, 2, 1]
  assert_eq!(count_inversions(arr3[:], 4), 6)
  // [2, 4, 1, 3, 5]: inversions (2,1), (4,1), (4,3) = 3
  let arr4 : Array[Int] = [2, 4, 1, 3, 5]
  assert_eq!(count_inversions(arr4[:], 5), 3)
}

// ============================================================================
// WHY FENWICK TREE WORKS: BINARY REPRESENTATION INSIGHT
// ============================================================================
//
// The magic of Fenwick trees comes from binary representation:
//
// OBSERVATION 1: i & (-i) isolates the lowest set bit.
//   Example: 12 = 1100₂, -12 = 0100₂ (in 2's complement)
//            12 & (-12) = 0100₂ = 4
//
// OBSERVATION 2: Subtracting the lowest bit moves to disjoint ranges.
//   12 → 8 → 0: covers ranges [9,12], [1,8]
//   These are exactly the ranges stored in tree[12] and tree[8].
//
// OBSERVATION 3: Adding the lowest bit moves to parent.
//   3 → 4 → 8 → 16: each step "merges" into a larger range.
//
// VISUALIZATION (n = 8):
//
//   tree[1] covers [1,1]
//   tree[2] covers [1,2]
//   tree[3] covers [3,3]
//   tree[4] covers [1,4]
//   tree[5] covers [5,5]
//   tree[6] covers [5,6]
//   tree[7] covers [7,7]
//   tree[8] covers [1,8]
//
// Query for prefix_sum(7): tree[7] + tree[6] + tree[4]
//   = [7,7] + [5,6] + [1,4] = [1,7] ✓
//
// Update at position 5: tree[5], tree[6], tree[8]
//   = [5,5], [5,6], [1,8] ✓ (all contain position 5)
