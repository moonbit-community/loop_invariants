// ============================================================================
// Probabilistic and Randomized Algorithm Examples
// Loop invariants for algorithms with probabilistic guarantees
// ============================================================================

// ============================================================================
// Example P1: Reservoir Sampling
// Select k items uniformly at random from a stream of unknown length
// ============================================================================

///|
/// Simple linear congruential generator for demonstration.
/// NOT cryptographically secure - for educational purposes only.
priv struct RNG {
  mut seed : Int64
}

///|
fn make_rng(seed : Int64) -> RNG {
  { seed, }
}

///|
fn next_int(rng : RNG, bound : Int) -> Int {
  // LCG parameters (same as java.util.Random)
  rng.seed = (rng.seed * 0x5DEECE66DL + 0xBL) & ((1L << 48) - 1L)
  let value = (rng.seed >> 17).to_int()
  let result = if value < 0 { -value } else { value }
  result % bound
}

///|
/// Reservoir sampling: select exactly k items uniformly at random
/// from a stream of n items (where n may be unknown ahead of time).
#warnings("+missing_invariant+missing_reasoning")
fn reservoir_sample(stream : ArrayView[Int], k : Int, rng : RNG) -> Array[Int] {
  guard k > 0 && k <= stream.length() else { return [] }

  // Initialize reservoir with first k elements
  let reservoir : Array[Int] = []
  for i in 0..<k {
    reservoir.push(stream[i])
  }

  // Process remaining elements
  for i = k {
    if i >= stream.length() {
      break reservoir
    } else {
      // With probability k/i, replace a random element in reservoir
      let j = next_int(rng, i + 1)
      if j < k {
        reservoir[j] = stream[i]
      }
      continue i + 1
    }
  } where {
    invariant: i >= k && i <= stream.length(),
    reasoning: (
      #|INVARIANT (Uniform sampling):
      #|After processing i elements (i ≥ k), each of the first i elements
      #|has equal probability k/i of being in the reservoir.
      #|
      #|PROOF BY INDUCTION:
      #|
      #|Base case (i = k):
      #|The reservoir contains exactly the first k elements.
      #|Each has probability 1 = k/k of being in reservoir. ✓
      #|
      #|Inductive step (i → i+1):
      #|Assume each of first i elements has probability k/i of being in reservoir.
      #|
      #|For element i+1 (the new element):
      #|  We include it with probability k/(i+1) (when j < k).
      #|  P(element i+1 in reservoir) = k/(i+1). ✓
      #|
      #|For any previous element e (one of the first i):
      #|  P(e in reservoir after step i+1)
      #|    = P(e was in reservoir) × P(e not replaced)
      #|    = (k/i) × (1 - P(e replaced))
      #|    = (k/i) × (1 - P(i+1 included) × P(e's position chosen))
      #|    = (k/i) × (1 - (k/(i+1)) × (1/k))
      #|    = (k/i) × (1 - 1/(i+1))
      #|    = (k/i) × (i/(i+1))
      #|    = k/(i+1). ✓
      #|
      #|Therefore, after processing all n elements, each element has
      #|probability k/n of being in the final reservoir.
      #|
      #|SPACE COMPLEXITY: O(k) - perfect for streaming scenarios
      #|where we can't store all n elements.
      #|
      #|APPLICATIONS:
      #|  - Random sampling from large datasets
      #|  - A/B testing with unknown population size
      #|  - Stream processing and online algorithms
      #|MAINTENANCE:
      #|Each new element i is included with probability k/(i+1), preserving
      #|uniform sampling of the prefix.
      #|TERMINATION:
      #|At i = stream.length(), the reservoir is a uniform k-sample.
    ),
  }
}

///|
test "reservoir_sample" {
  let stream : Array[Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  let rng = make_rng(42L)
  let sample = reservoir_sample(stream[:], 3, rng)
  assert_eq(sample.length(), 3)
  // Can't test randomness easily, just verify structure
}

// ============================================================================
// Example P2: Fisher-Yates Shuffle (Knuth Shuffle)
// Generate a uniformly random permutation in O(n) time
// ============================================================================

///|
/// Fisher-Yates shuffle: generate uniformly random permutation in-place.
#warnings("+missing_invariant+missing_reasoning")
fn fisher_yates_shuffle(arr : Array[Int], rng : RNG) -> Unit {
  let n = arr.length()
  guard n > 1 else { return }
  for i = n - 1 {
    if i <= 0 {
      break
    } else {
      // Pick random index from [0, i]
      let j = next_int(rng, i + 1)
      // Swap arr[i] and arr[j]
      let tmp = arr[i]
      arr[i] = arr[j]
      arr[j] = tmp
      continue i - 1
    }
  } where {
    invariant: i >= -1 && i < arr.length(),
    reasoning: (
      #|INVARIANT (Partial permutation):
      #|After processing position i, arr[i+1..n) is a uniformly random
      #|permutation of some i+1 elements from the original array, and
      #|arr[0..i+1) contains the remaining elements in some order.
      #|
      #|PROOF:
      #|
      #|Base (i = n-1):
      #|We pick j uniformly from [0, n-1] and swap arr[n-1] with arr[j].
      #|This places a uniformly random element at position n-1.
      #|P(any specific element at position n-1) = 1/n. ✓
      #|
      #|Inductive (i → i-1):
      #|By induction, arr[i+1..n) is uniformly random.
      #|We pick j uniformly from [0, i] and swap arr[i] with arr[j].
      #|
      #|For the element now at position i:
      #|  Each of the (i+1) elements in arr[0..i+1) had equal chance
      #|  of being selected (probability 1/(i+1)).
      #|
      #|For any permutation of elements in arr[i..n):
      #|  P(specific permutation)
      #|    = P(correct element at position i) × P(correct perm of rest)
      #|    = 1/(i+1) × (by induction, rest is uniform)
      #|
      #|After all swaps (i = 0):
      #|  P(any specific permutation) = ∏(1/k for k=n down to 1) = 1/n!
      #|
      #|Therefore, each of the n! permutations is equally likely. ✓
      #|
      #|TIME: O(n)
      #|SPACE: O(1) additional
      #|
      #|WARNING: Using a biased or predictable RNG will produce
      #|non-uniform permutations! Cryptographic applications need
      #|cryptographically secure random number generators.
      #|MAINTENANCE:
      #|Swapping arr[i] with a random arr[j] fixes position i uniformly.
      #|TERMINATION:
      #|At i = 0, all positions are fixed into a uniform permutation.
    ),
  }
}

///|
test "fisher_yates_shuffle" {
  let arr : Array[Int] = [1, 2, 3, 4, 5]
  let rng = make_rng(12345L)
  fisher_yates_shuffle(arr, rng)
  // Verify it's still a permutation (contains same elements)
  arr.sort_by_key(x => x)
  assert_eq(arr, [1, 2, 3, 4, 5])
}

// ============================================================================
// Example P3: Weighted Random Selection
// Select an item with probability proportional to its weight
// ============================================================================

///|
/// Select index with probability proportional to weights.
/// Uses prefix sum + binary search for O(log n) selection.
#warnings("+missing_invariant+missing_reasoning")
fn weighted_select(weights : ArrayView[Int], rng : RNG) -> Int {
  guard weights.length() > 0 else { return -1 }

  // Build prefix sums
  let prefix_sum : Array[Int] = Array::make(weights.length(), 0)
  for i = 0, sum = 0 {
    if i >= weights.length() {
      break
    } else {
      let new_sum = sum + weights[i]
      prefix_sum[i] = new_sum
      continue i + 1, new_sum
    }
  } where {
    invariant: i >= 0 && i <= weights.length() && sum >= 0,
    reasoning: (
      #|INVARIANT (Prefix sum construction):
      #|prefix_sum[j] = Σ(weights[0..j+1)) for all j < i.
      #|sum = Σ(weights[0..i)).
      #|
      #|This builds the cumulative distribution function (CDF).
      #|MAINTENANCE:
      #|Add weights[i] into sum and assign prefix_sum[i].
      #|TERMINATION:
      #|At i = weights.length(), the full CDF is built.
    ),
  }
  let total = prefix_sum[weights.length() - 1]
  guard total > 0 else { return 0 }

  // Generate random value in [0, total)
  let target = next_int(rng, total)

  // Binary search for the interval containing target
  for lo = 0, hi = weights.length() {
    if lo >= hi {
      break lo
    } else {
      let mid = lo + (hi - lo) / 2
      if prefix_sum[mid] <= target {
        continue mid + 1, hi
      } else {
        continue lo, mid
      }
    }
  } where {
    invariant: lo >= 0 && hi <= weights.length() && lo <= hi,
    reasoning: (
      #|INVARIANT (Weighted selection correctness):
      #|We're finding the smallest i such that prefix_sum[i] > target.
      #|
      #|This is equivalent to finding which "bucket" target falls into:
      #|  - Item 0's range: [0, weights[0])
      #|  - Item 1's range: [weights[0], weights[0]+weights[1])
      #|  - Item i's range: [prefix_sum[i-1], prefix_sum[i])
      #|
      #|Since target is uniform in [0, total), the probability of
      #|selecting item i is:
      #|  P(i) = (prefix_sum[i] - prefix_sum[i-1]) / total
      #|       = weights[i] / total
      #|
      #|This is exactly the weighted probability we want! ✓
      #|
      #|TIME: O(n) preprocessing, O(log n) per query
      #|For repeated queries, preprocessing is amortized.
      #|MAINTENANCE:
      #|Binary search keeps target within [lo, hi) while shrinking the window.
      #|TERMINATION:
      #|When lo == hi, lo is the selected index.
    ),
  }
}

///|
test "weighted_select" {
  // Weights: [1, 3, 2] → probabilities [1/6, 3/6, 2/6]
  let weights : Array[Int] = [1, 3, 2]
  let rng = make_rng(99L)
  let result = weighted_select(weights[:], rng)
  assert_true(result >= 0 && result < 3)
}

// ============================================================================
// Example P4: Approximate Counting (Morris Algorithm)
// Count up to n using only O(log log n) bits
// ============================================================================

///|
/// Morris counter: approximate counting with probabilistic increments.
/// Uses O(log log n) bits to approximately count up to n.
priv struct MorrisCounter {
  mut exponent : Int
  rng : RNG
}

///|
fn make_morris_counter(rng : RNG) -> MorrisCounter {
  { exponent: 0, rng }
}

///|
/// Increment the counter with probability 2^(-exponent).
fn morris_increment(counter : MorrisCounter) -> Unit {
  // Generate random number to decide if we increment
  let threshold = 1 << counter.exponent
  let r = next_int(counter.rng, threshold)
  if r == 0 {
    counter.exponent = counter.exponent + 1
  }
}

///|
/// Get approximate count: returns 2^exponent - 1.
fn morris_estimate(counter : MorrisCounter) -> Int {
  (1 << counter.exponent) - 1
}

///|
test "morris_counter" {
  let rng = make_rng(777L)
  let counter = make_morris_counter(rng)

  // Increment many times
  for _ in 0..<1000 {
    morris_increment(counter)
  }

  // Should give some positive estimate
  let estimate = morris_estimate(counter)
  assert_true(estimate > 0)
  // Note: The estimate is highly variable but E[estimate] ≈ true count
}

// ============================================================================
// Example P5: Bloom Filter Simulation
// Probabilistic set membership with no false negatives
// ============================================================================

///|
/// Simple hash functions for Bloom filter simulation.
fn hash1(x : Int, size : Int) -> Int {
  // Simple multiplicative hash
  let h = x * 31337 + 12345
  let result = if h < 0 { -h } else { h }
  if size == 0 {
    result
  } else {
    result % size
  }
}

///|
fn hash2(x : Int, size : Int) -> Int {
  let h = (x ^ (x >> 8)) * 65537
  let result = if h < 0 { -h } else { h }
  result % size
}

///|
fn hash3(x : Int, size : Int) -> Int {
  let h = x * 31 + 17
  let result = if h < 0 { -h } else { h }
  result % size
}

///|
/// Bloom filter: probabilistic set membership.
priv struct BloomFilter {
  bits : Array[Bool]
  size : Int
}

///|
fn make_bloom_filter(size : Int) -> BloomFilter {
  { bits: Array::make(size, false), size }
}

///|
fn bloom_add(bf : BloomFilter, x : Int) -> Unit {
  bf.bits[hash1(x, bf.size)] = true
  bf.bits[hash2(x, bf.size)] = true
  bf.bits[hash3(x, bf.size)] = true
}

///|
/// Check if element might be in set.
/// Returns true if possibly present (may be false positive).
/// Returns false if definitely absent (no false negatives).
#warnings("+missing_invariant+missing_reasoning")
fn bloom_maybe_contains(bf : BloomFilter, x : Int) -> Bool {
  bf.bits[hash1(x, bf.size)] &&
  bf.bits[hash2(x, bf.size)] &&
  bf.bits[hash3(x, bf.size)]
}

///|
test "bloom_filter" {
  let bf = make_bloom_filter(1000)

  // Add some elements
  bloom_add(bf, 42)
  bloom_add(bf, 123)
  bloom_add(bf, 456)

  // These should definitely be found (no false negatives)
  assert_true(bloom_maybe_contains(bf, 42))
  assert_true(bloom_maybe_contains(bf, 123))
  assert_true(bloom_maybe_contains(bf, 456))

  // Note: Some elements not added might still return true (false positives)
  // This is expected behavior for Bloom filters
}

// ============================================================================
// Example P6: HyperLogLog Cardinality Estimation (Simplified)
// Estimate number of unique elements using O(log log n) space
// ============================================================================

///|
/// Count leading zeros in a hash value.
fn count_leading_zeros(x : Int) -> Int {
  if x == 0 {
    32
  } else {
    for n = 0, val = x {
      if val < 0 {
        // Sign bit is set
        break n
      } else {
        continue n + 1, val << 1
      }
    } where {
      invariant: n >= 0 && val == x << n,
      reasoning: (
        #|INVARIANT (Shift tracking):
        #|val equals x shifted left by n positions, so each loop iteration
        #|advances the check to the next bit without losing prior progress.
        #|
        #|When val becomes negative, the sign bit is 1, meaning we have
        #|shifted past all leading zeros in the original x. The count n at
        #|that point is the number of leading zeros for a 32-bit value.
        #|MAINTENANCE:
        #|Shift left once and increment n, preserving val == x << n.
        #|TERMINATION:
        #|When val becomes negative, n is the leading-zero count.
      ),
    }
  }
}

///|
/// Simplified HyperLogLog: track maximum leading zeros seen.
/// True cardinality ≈ 2^(max_zeros).
priv struct SimpleHLL {
  mut max_zeros : Int
}

///|
fn make_simple_hll() -> SimpleHLL {
  { max_zeros: 0 }
}

///|
fn hll_add(hll : SimpleHLL, x : Int) -> Unit {
  let h = hash1(x, 0x7FFFFFFF)
  let zeros = count_leading_zeros(h)
  if zeros > hll.max_zeros {
    hll.max_zeros = zeros
  }
}

///|
fn hll_estimate(hll : SimpleHLL) -> Int {
  1 << hll.max_zeros
}

///|
test "simple_hll" {
  let hll = make_simple_hll()

  // Add many elements
  for i in 0..<1000 {
    hll_add(hll, i)
  }

  // Estimate should be in the right ballpark
  let estimate = hll_estimate(hll)
  assert_true(estimate > 0)
  // Note: Actual HyperLogLog uses multiple buckets for better accuracy
}

// ============================================================================
// Example P7: Skip List Search (Probabilistic Data Structure)
// Expected O(log n) search in a sorted linked list
// ============================================================================

///|
/// Skip list node with multiple forward pointers.
priv struct SkipNode {
  value : Int
  forward : Array[Int] // Indices of next nodes at each level (-1 = null)
}

///|
/// Skip list structure.
priv struct SkipList {
  nodes : Array[SkipNode]
  head : Int // Index of sentinel head node
  max_level : Int
}

///|
/// Search for value in skip list.
/// Returns index of node containing value, or -1 if not found.
#warnings("+missing_invariant+missing_reasoning")
fn skip_list_search(list : SkipList, target : Int) -> Int {
  guard list.nodes.length() > 0 else { return -1 }
  for level = list.max_level - 1, current = list.head {
    if level < 0 {
      break -1
    } else {
      // Move forward at current level while we can
      let next = for curr = current {
        let fwd = list.nodes[curr].forward
        if level < fwd.length() && fwd[level] != -1 {
          let next_idx = fwd[level]
          if list.nodes[next_idx].value < target {
            continue next_idx
          } else if list.nodes[next_idx].value == target {
            break next_idx // Found!
          } else {
            break curr // Can't advance, drop down
          }
        } else {
          break curr
        }
      } where {
        invariant: curr >= 0 && curr < list.nodes.length(),
        reasoning: (
          #|INVARIANT (Skip list search):
          #|curr is always a valid node index, and all nodes before curr
          #|at the current level have values < target.
          #|
          #|SKIP LIST STRUCTURE:
          #|A skip list is a layered linked list where:
          #|  - Level 0 contains all elements in sorted order
          #|  - Level i contains a random subset of level i-1 (coin flips)
          #|  - Expected height of a node with n elements: O(log n)
          #|
          #|SEARCH STRATEGY:
          #|Start at highest level, move forward until we'd overshoot,
          #|then drop down one level and repeat.
          #|
          #|Expected path length = O(log n):
          #|  - At each level, we traverse expected 1/(probability) = 2 nodes
          #|  - We have O(log n) levels
          #|  - Total: O(2 log n) = O(log n) comparisons
          #|
          #|This gives us O(log n) expected search time with a simple
          #|probabilistic structure (no complex rebalancing like AVL/Red-Black).
          #|MAINTENANCE:
          #|Advance curr while the next value is < target, otherwise stop.
          #|TERMINATION:
          #|When we can no longer advance, curr is the rightmost safe node.
        ),
      }
      if next != current && list.nodes[next].value == target {
        break next
      }
      continue level - 1, next
    }
  } where {
    invariant: level >= -1 &&
    level < list.max_level &&
    current >= 0 &&
    current < list.nodes.length(),
    reasoning: (
      #|INVARIANT (Level descent):
      #|Before processing level, current is the rightmost node we can reach
      #|at the next higher level whose value is still < target (or the head
      #|sentinel when none qualifies). This preserves the search window:
      #|any candidate equal to target must lie at current or to its right.
      #|
      #|We first walk forward at the current level until we would overshoot,
      #|then drop down one level and continue from that last safe position.
      #|This is the skip-list analog of staircase search in a matrix.
      #|MAINTENANCE:
      #|After scanning a level, decrement level and keep current as the last
      #|node with value < target.
      #|TERMINATION:
      #|At level < 0, target is not present and we return -1.
    ),
  }
}

///|
test "skip_list_search" {
  // Simple skip list: 1 -> 3 -> 5 -> 7
  let nodes : Array[SkipNode] = [
    { value: -1, forward: [1, 1] }, // Sentinel head
    { value: 1, forward: [2, 3] }, // 1 points to 3 at level 0, skips to 5 at level 1
    { value: 3, forward: [3, -1] }, // 3 points to 5
    { value: 5, forward: [4, -1] }, // 5 points to 7
    { value: 7, forward: [-1, -1] }, // 7 is last
  ]
  let list : SkipList = { nodes, head: 0, max_level: 2 }
  assert_eq(skip_list_search(list, 5), 3)
  assert_eq(skip_list_search(list, 1), 1)
  assert_eq(skip_list_search(list, 10), -1)
}
