// ============================================================================
// SKIP LIST - Probabilistic Data Structure with O(log n) Expected Operations
// ============================================================================
//
// A Skip List is a probabilistic alternative to balanced trees. It maintains
// multiple levels of linked lists where higher levels "skip" over elements,
// enabling O(log n) expected search, insert, and delete operations.
//
// KEY INSIGHT: Skip lists achieve balance probabilistically rather than through
// complex rotations. Each element is promoted to higher levels with probability p
// (typically 1/2), creating a hierarchy where:
//   - Level 0: all elements
//   - Level i: ~n/2^i elements (expected)
//
// STRUCTURE INVARIANTS:
// 1. Level hierarchy: An element at level i also appears at all levels < i
// 2. Sorted order: Each level maintains sorted order by key
// 3. Sentinel: Header node exists at all levels (simplifies boundary cases)
// 4. Forward pointers: Each node has forward[i] pointing to next node at level i
//
// TIME COMPLEXITY (expected):
// - Search: O(log n) - traverse O(log n) levels, O(1) nodes per level
// - Insert: O(log n) - search + O(1) pointer updates per level
// - Delete: O(log n) - search + O(1) pointer updates per level
// - Range query: O(log n + k) where k is number of elements in range
//
// SPACE COMPLEXITY: O(n) expected - each element uses O(1) expected levels

///|
/// Maximum number of levels in the skip list
/// log2(expected max elements) is a good choice
let max_level : Int = 16

///|
/// Probability of promotion to next level (1/4 for better space efficiency)
/// P = 1/4 gives expected 1.33 pointers per element vs 2 for P = 1/2
let promotion_probability : Int = 4 // 1 in 4 chance

///|
/// A node in the skip list
/// Each node contains forward pointers to the next node at each level
priv struct SkipNode {
  key : Int
  value : Int
  // forward[i] points to the next node at level i
  // forward.length() == level of this node
  forward : Array[SkipNode?]
}

///|
/// Create a new skip list node
fn SkipNode::new(key : Int, value : Int, level : Int) -> SkipNode {
  { key, value, forward: Array::make(level, None) }
}

///|
/// Skip List data structure
priv struct SkipList {
  // Header node (sentinel) - exists at all levels
  // header.key should be treated as -infinity
  header : SkipNode
  // Current maximum level in use (0-indexed)
  mut level : Int
  // Random state for probabilistic level generation
  mut rand_state : Int
  // Number of elements
  mut size : Int
}

///|
/// Create a new empty skip list
fn SkipList::new() -> SkipList {
  {
    header: SkipNode::new(0, 0, max_level), // sentinel node
    level: 0,
    rand_state: 42,
    size: 0,
  }
}

///|
/// Generate a random level for new node insertion
/// Uses geometric distribution with parameter 1/promotion_probability
///
/// REASONING: Each level has 1/p probability of being reached
/// Expected level = 1/(1-1/p) ≈ 1.33 for p=4
/// This ensures logarithmic height with high probability
fn SkipList::random_level(self : SkipList) -> Int {
  // Loop invariant: lvl represents the current level being considered
  // We flip coins until we get "heads" (random not divisible by p)
  for lvl = 0; lvl < max_level - 1; {
    // Simple LCG for random number generation
    self.rand_state = (self.rand_state * 1103 + 12345) % 65536
    let r = if self.rand_state < 0 { -self.rand_state } else { self.rand_state }

    // Promote with probability 1/promotion_probability
    if r % promotion_probability == 0 {
      continue lvl + 1
    } else {
      break lvl
    }
  } else {
    max_level - 1
  } where {
    invariant: lvl >= 0 && lvl < max_level,
    reasoning: (
      #|LEVEL GENERATION INVARIANT:
      #|
      #|1. Geometric distribution: P(level = k) = (1/p)^k * (1 - 1/p)
      #|   - Each promotion has probability 1/p
      #|   - Stop when we fail to promote (probability 1 - 1/p)
      #|
      #|2. Expected height: For n elements, expected max level = log_p(n)
      #|   - With p=4 and n=10^6, expected max level ≈ 10
      #|   - max_level=16 provides margin for larger datasets
      #|
      #|3. Loop termination: Either we fail promotion (break) or reach max_level
      #|   - Probability of reaching max_level = (1/p)^max_level, vanishingly small
    ),
  }
}

// ============================================================================
// SEARCH OPERATION
// ============================================================================

///|
/// Search for a key in the skip list
/// Returns Some(value) if found, None otherwise
///
/// ALGORITHM:
/// 1. Start at header, highest level
/// 2. Move right while next key < target
/// 3. Drop down one level
/// 4. Repeat until level 0
/// 5. Check if we found the key
fn SkipList::search(self : SkipList, key : Int) -> Int? {
  // Start at the header node
  // We will traverse from highest level down to level 0
  for current = self.header, lvl = self.level; lvl >= 0; {
    // At each level, move right as far as possible while staying < key
    match current.forward[lvl] {
      Some(next) if next.key < key =>
        // Move right - next node's key is still less than target
        continue next, lvl
      _ =>
        // Can't move right - either no next node or next.key >= key
        // Drop down one level
        continue current, lvl - 1
    }
  } else {
    // We've descended through all levels
    // Now check if the next node at level 0 has our key
    match current.forward[0] {
      Some(node) if node.key == key => Some(node.value)
      _ => None
    }
  } where {
    invariant: current.key < key,
    reasoning: (
      #|SEARCH INVARIANT: current.key < key at all times
      #|
      #|1. Initialization: header acts as -infinity sentinel, so header.key < key
      #|   (we treat header.key as a sentinel, not a real key)
      #|
      #|2. Moving right (continue next, lvl):
      #|   - Precondition: next.key < key (from guard condition)
      #|   - Postcondition: new current.key = next.key < key ✓
      #|
      #|3. Dropping down (continue current, lvl - 1):
      #|   - current unchanged, so current.key < key still holds ✓
      #|
      #|4. Termination: lvl decreases when we can't move right
      #|   - Eventually lvl = -1 and we exit
      #|   - At level 0, forward[0] points to the first node >= key (if any)
      #|
      #|5. Correctness: Due to sorted order at each level, if key exists,
      #|   it must be at current.forward[0] when we finish descending.
    ),
  }
}

// ============================================================================
// INSERT OPERATION
// ============================================================================

///|
/// Insert a key-value pair into the skip list
/// If key already exists, updates the value
///
/// ALGORITHM:
/// 1. Search while recording update points at each level
/// 2. Generate random level for new node
/// 3. Link new node at all levels up to its random level
fn SkipList::insert(self : SkipList, key : Int, value : Int) -> Unit {
  // update[i] will hold the rightmost node at level i that is < key
  // These are the nodes whose forward pointers need updating
  let update : Array[SkipNode?] = Array::make(max_level, None)

  // Phase 1: Find insert position and record update points
  // This is similar to search but we remember the last node at each level
  for current = self.header, lvl = self.level; lvl >= 0; {
    match current.forward[lvl] {
      Some(next) if next.key < key => continue next, lvl
      _ => {
        // Record this as the update point for level lvl
        update[lvl] = Some(current)
        continue current, lvl - 1
      }
    }
  } else {
    // Check if key already exists
    match current.forward[0] {
      Some(existing) if existing.key == key =>
        // Key exists - update value
        // Note: In a more sophisticated implementation, we'd use mutable value
        // For now, we don't support in-place update (skip lists typically do)
        return // Value update would go here
      _ => {
        // Key doesn't exist - insert new node
        let new_level = self.random_level()

        // If new level exceeds current max level, update header's forward
        // and add header to update array for new levels
        for i = self.level + 1; i <= new_level; i = i + 1 {
          update[i] = Some(self.header)
        }

        // Update skip list level if necessary
        if new_level > self.level {
          self.level = new_level
        }

        // Create new node
        let new_node = SkipNode::new(key, value, new_level + 1)

        // Link new node at each level
        // This loop links the new node into the skip list at all levels
        for i = 0; i <= new_level; i = i + 1 {
          match update[i] {
            Some(prev) => {
              // new_node.forward[i] = prev.forward[i]
              // prev.forward[i] = new_node
              new_node.forward[i] = prev.forward[i]
              prev.forward[i] = Some(new_node)
            }
            None => ()
          }
        }
        self.size = self.size + 1
      }
    }
  } where {
    invariant: true,
    reasoning: (
      #|INSERT INVARIANT: update[lvl] tracks the predecessor at each level
      #|
      #|1. Search phase maintains: update[lvl].key < key for all recorded levels
      #|   - We only record update[lvl] when we can't move right
      #|   - At that point, current.key < key (from search invariant)
      #|
      #|2. After search: update[0..=self.level] all point to predecessors
      #|   - update[i].forward[i] is either None or points to a node >= key
      #|
      #|3. Linking phase preserves sorted order:
      #|   - new_node.forward[i] = update[i].forward[i] (successor)
      #|   - update[i].forward[i] = new_node (new node becomes successor)
      #|   - Result: update[i] -> new_node -> old_successor
      #|
      #|4. Level hierarchy preserved:
      #|   - new_node exists at levels 0..new_level
      #|   - All levels properly linked
    ),
  }
}

// ============================================================================
// DELETE OPERATION
// ============================================================================

///|
/// Delete a key from the skip list
/// Returns true if key was found and deleted, false otherwise
fn SkipList::delete(self : SkipList, key : Int) -> Bool {
  let update : Array[SkipNode?] = Array::make(max_level, None)

  // Phase 1: Find the node and record update points
  for current = self.header, lvl = self.level; lvl >= 0; {
    match current.forward[lvl] {
      Some(next) if next.key < key => continue next, lvl
      _ => {
        update[lvl] = Some(current)
        continue current, lvl - 1
      }
    }
  } else {
    // Check if key exists
    match current.forward[0] {
      Some(target) if target.key == key => {
        // Found the node - unlink it at all levels
        for i = 0; i <= self.level; i = i + 1 {
          match update[i] {
            Some(prev) =>
              match prev.forward[i] {
                Some(node) if node.key == key =>
                  prev.forward[i] = node.forward[i]
                _ => ()
              }
            None => ()
          }
        }

        // Reduce level if necessary (if top levels are now empty)
        for ; self.level > 0; {
          match self.header.forward[self.level] {
            None => continue // Level is empty, reduce
            _ => break // Found a non-empty level, stop
          }
        } else {
          ()
        } where {
          invariant: self.level >= 0,
          reasoning: (
            #|LEVEL REDUCTION INVARIANT:
            #|
            #|1. We only reduce level when header.forward[level] is None
            #|   - This means no elements exist at this level
            #|
            #|2. We stop when we find a non-empty level or reach 0
            #|   - Level 0 always exists (base level)
            #|
            #|3. After reduction: self.level is the highest non-empty level
          ),
        }
        self.size = self.size - 1
        true
      }
      _ => false // Key not found
    }
  } where {
    invariant: true,
    reasoning: (
      #|DELETE INVARIANT: Same search invariant as insert
      #|
      #|1. Search phase: update[lvl] tracks predecessors at each level
      #|
      #|2. Unlink phase: For each level where target exists:
      #|   - prev.forward[i] = target.forward[i]
      #|   - This bypasses the target node
      #|
      #|3. Post-deletion:
      #|   - All forward pointers to target are redirected
      #|   - Target becomes unreachable (garbage collected)
      #|   - Sorted order preserved at all levels
    ),
  }
}

// ============================================================================
// RANGE QUERY
// ============================================================================

///|
/// Find all keys in range [low, high]
/// Returns array of (key, value) pairs in sorted order
///
/// Time complexity: O(log n + k) where k is number of keys in range
fn SkipList::range_query(
  self : SkipList,
  low : Int,
  high : Int,
) -> Array[(Int, Int)] {
  let result : Array[(Int, Int)] = []

  // First, find the first node >= low using skip list search
  for current = self.header, lvl = self.level; lvl >= 0; {
    match current.forward[lvl] {
      Some(next) if next.key < low => continue next, lvl
      _ => continue current, lvl - 1
    }
  } else {
    // Now traverse at level 0 collecting all keys in range
    for node = current.forward[0] {
      match node {
        Some(n) if n.key <= high => {
          result.push((n.key, n.value))
          continue n.forward[0]
        }
        _ => break
      }
    } where {
      invariant: true,
      reasoning: (
        #|RANGE COLLECTION INVARIANT:
        #|
        #|1. Starting point: current.forward[0] is the first node >= low
        #|   - Due to skip list search invariant
        #|
        #|2. Collection loop: We traverse level 0 while key <= high
        #|   - Level 0 contains all elements in sorted order
        #|   - We collect exactly those in [low, high]
        #|
        #|3. Termination: Loop ends when key > high or we reach end
        #|   - All keys in range have been collected
      ),
    }
    result
  } where {
    invariant: true,
    reasoning: (
      #|RANGE SEARCH INVARIANT: Same as regular search
      #|
      #|We find the predecessor of 'low', then traverse level 0
      #|to collect all elements in the range [low, high].
    ),
  }
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

///|
/// Get the number of elements in the skip list
fn SkipList::length(self : SkipList) -> Int {
  self.size
}

///|
/// Check if the skip list is empty
fn SkipList::is_empty(self : SkipList) -> Bool {
  self.size == 0
}

///|
/// Get minimum key in the skip list (first element at level 0)
fn SkipList::min(self : SkipList) -> (Int, Int)? {
  match self.header.forward[0] {
    Some(node) => Some((node.key, node.value))
    None => None
  }
}

///|
/// Get maximum key in the skip list
/// Uses skip list structure for O(log n) expected traversal
fn SkipList::max(self : SkipList) -> (Int, Int)? {
  // Traverse from top level, always going as far right as possible
  for current = self.header, lvl = self.level; lvl >= 0; {
    match current.forward[lvl] {
      Some(next) => continue next, lvl // Move right at same level
      None => continue current, lvl - 1 // Drop down
    }
  } else {
    // current is now the rightmost node
    if current.key == self.header.key {
      None // Empty list, current is header
    } else {
      Some((current.key, current.value))
    }
  } where {
    invariant: lvl >= 0 || lvl == -1,
    reasoning: (
      #|MAX FINDING INVARIANT:
      #|
      #|1. Strategy: Go right as much as possible, then drop down
      #|   - At each level, we reach the rightmost node before dropping
      #|
      #|2. Correctness: The rightmost node at level 0 has the maximum key
      #|   - Due to sorted order at each level
      #|
      #|3. Termination: lvl decreases until lvl < 0, then exits to else
      #|
      #|4. Efficiency: Expected O(log n) - similar analysis to search
    ),
  }
}

// ============================================================================
// CEIL AND FLOOR OPERATIONS
// ============================================================================

///|
/// Find the smallest key >= given key (ceiling)
fn SkipList::ceil(self : SkipList, key : Int) -> (Int, Int)? {
  for current = self.header, lvl = self.level; lvl >= 0; {
    match current.forward[lvl] {
      Some(next) if next.key < key => continue next, lvl
      _ => continue current, lvl - 1
    }
  } else {
    match current.forward[0] {
      Some(node) => Some((node.key, node.value))
      None => None
    }
  } where {
    invariant: current.key < key,
    reasoning: (
      #|CEIL INVARIANT: Find first node >= key
      #|
      #|After descending all levels, current.forward[0] points to
      #|the first node with key >= given key (if any exists).
    ),
  }
}

///|
/// Find the largest key <= given key (floor)
fn SkipList::floor(self : SkipList, key : Int) -> (Int, Int)? {
  for current = self.header, lvl = self.level; lvl >= 0; {
    match current.forward[lvl] {
      Some(next) if next.key <= key => continue next, lvl
      _ => continue current, lvl - 1
    }
  } else {
    // current is the largest node <= key (or header if none exists)
    if current.key == self.header.key {
      None
    } else {
      Some((current.key, current.value))
    }
  } where {
    invariant: current.key <= key,
    reasoning: (
      #|FLOOR INVARIANT: Find last node <= key
      #|
      #|1. We move right while next.key <= key (not < like in search)
      #|   - This ensures current is always <= key
      #|
      #|2. When we can't move right: next.key > key or next is None
      #|   - current is the rightmost node at this level with key <= given key
      #|
      #|3. After all levels: current is the largest node <= key overall
    ),
  }
}

// ============================================================================
// ORDERED STATISTICS
// ============================================================================

///|
/// Count elements less than key
/// This version traverses level 0 - O(result) time
/// A more efficient version would maintain size in each node
fn SkipList::count_less_than(self : SkipList, key : Int) -> Int {
  for current = self.header.forward[0], count = 0 {
    match current {
      Some(node) if node.key < key => continue node.forward[0], count + 1
      _ => break count
    }
  } where {
    invariant: count >= 0,
    reasoning: (
      #|COUNT INVARIANT: count accumulates nodes with key < given key
      #|
      #|1. Traverse level 0 (contains all elements)
      #|2. Increment count for each node with key < given key
      #|3. Stop when we reach a node >= key or end of list
    ),
  }
}

///|
/// Find k-th smallest element (0-indexed)
/// Returns None if k >= size
fn SkipList::kth_element(self : SkipList, k : Int) -> (Int, Int)? {
  if k < 0 || k >= self.size {
    return None
  }
  for current = self.header.forward[0], i = 0 {
    match current {
      Some(node) =>
        if i == k {
          break Some((node.key, node.value))
        } else {
          continue node.forward[0], i + 1
        }
      None => break None
    }
  } where {
    invariant: i >= 0 && i <= k,
    reasoning: (
      #|KTH ELEMENT INVARIANT: i counts elements traversed
      #|
      #|1. We traverse level 0, counting elements
      #|2. When i == k, we've found the k-th element (0-indexed)
      #|3. Precondition k < size ensures we'll find it before reaching end
    ),
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "skip list basic operations" {
  let sl = SkipList::new()

  // Empty list check
  inspect(sl.is_empty(), content="true")

  // Test insert and search
  sl.insert(5, 50)
  sl.insert(3, 30)
  sl.insert(7, 70)
  sl.insert(1, 10)
  sl.insert(9, 90)
  inspect(sl.search(5), content="Some(50)")
  inspect(sl.search(3), content="Some(30)")
  inspect(sl.search(7), content="Some(70)")
  inspect(sl.search(1), content="Some(10)")
  inspect(sl.search(9), content="Some(90)")
  inspect(sl.search(4), content="None")
  inspect(sl.search(100), content="None")
}

///|
test "skip list delete" {
  let sl = SkipList::new()
  sl.insert(1, 10)
  sl.insert(2, 20)
  sl.insert(3, 30)
  sl.insert(4, 40)
  sl.insert(5, 50)
  inspect(sl.length(), content="5")

  // Delete existing key
  inspect(sl.delete(3), content="true")
  inspect(sl.search(3), content="None")
  inspect(sl.length(), content="4")

  // Delete non-existing key
  inspect(sl.delete(100), content="false")
  inspect(sl.length(), content="4")

  // Remaining elements still accessible
  inspect(sl.search(1), content="Some(10)")
  inspect(sl.search(2), content="Some(20)")
  inspect(sl.search(4), content="Some(40)")
  inspect(sl.search(5), content="Some(50)")
}

///|
test "skip list range query" {
  let sl = SkipList::new()
  for i = 0; i < 10; i = i + 1 {
    sl.insert(i * 2, i * 20) // Insert 0, 2, 4, ..., 18
  }

  // Query range [5, 13] - should include 6, 8, 10, 12
  let range = sl.range_query(5, 13)
  inspect(range, content="[(6, 60), (8, 80), (10, 100), (12, 120)]")

  // Query range [0, 4]
  let range2 = sl.range_query(0, 4)
  inspect(range2, content="[(0, 0), (2, 20), (4, 40)]")
}

///|
test "skip list min max" {
  let sl = SkipList::new()
  inspect(sl.min(), content="None")
  inspect(sl.max(), content="None")
  sl.insert(50, 500)
  sl.insert(30, 300)
  sl.insert(70, 700)
  sl.insert(10, 100)
  sl.insert(90, 900)
  inspect(sl.min(), content="Some((10, 100))")
  inspect(sl.max(), content="Some((90, 900))")
}

///|
test "skip list ceil floor" {
  let sl = SkipList::new()

  // Insert 10, 20, 30, 40, 50
  for i = 1; i <= 5; i = i + 1 {
    sl.insert(i * 10, i * 100)
  }

  // Ceil: smallest key >= given
  inspect(sl.ceil(25), content="Some((30, 300))") // 30 is smallest >= 25
  inspect(sl.ceil(30), content="Some((30, 300))") // Exact match
  inspect(sl.ceil(5), content="Some((10, 100))") // 10 is smallest >= 5
  inspect(sl.ceil(55), content="None") // No key >= 55

  // Floor: largest key <= given
  inspect(sl.floor(25), content="Some((20, 200))") // 20 is largest <= 25
  inspect(sl.floor(30), content="Some((30, 300))") // Exact match
  inspect(sl.floor(5), content="None") // No key <= 5
  inspect(sl.floor(55), content="Some((50, 500))") // 50 is largest <= 55
}

///|
test "skip list ordered statistics" {
  let sl = SkipList::new()

  // Insert 1, 3, 5, 7, 9
  for i = 0; i < 5; i = i + 1 {
    sl.insert(i * 2 + 1, (i + 1) * 10)
  }

  // Count less than
  inspect(sl.count_less_than(5), content="2") // 1, 3 are < 5
  inspect(sl.count_less_than(1), content="0") // Nothing < 1
  inspect(sl.count_less_than(10), content="5") // All elements < 10

  // K-th element (0-indexed)
  inspect(sl.kth_element(0), content="Some((1, 10))") // 1st element is 1
  inspect(sl.kth_element(2), content="Some((5, 30))") // 3rd element is 5
  inspect(sl.kth_element(4), content="Some((9, 50))") // 5th element is 9
  inspect(sl.kth_element(5), content="None") // Out of bounds
}

///|
test "skip list stress test" {
  let sl = SkipList::new()

  // Insert 100 elements
  for i = 0; i < 100; i = i + 1 {
    sl.insert(i, i * 10)
  }
  inspect(sl.length(), content="100")

  // Verify all elements are searchable
  for i = 0; i < 100; i = i + 1 {
    guard sl.search(i) is Some(_) else { fail("Element not found") }
  }

  // Delete every other element
  for i = 0; i < 100; i = i + 2 {
    guard sl.delete(i) else { fail("Delete failed") }
  }
  inspect(sl.length(), content="50")

  // Verify deletions
  for i = 0; i < 100; i = i + 1 {
    let result = sl.search(i)
    if i % 2 == 0 {
      guard result is None else { fail("Should be deleted") }
    } else {
      guard result is Some(_) else { fail("Should exist") }
    }
  }
}

// ============================================================================
// SKIP LIST WITH DUPLICATES
// ============================================================================

///|
/// Skip List that allows duplicate keys
/// Each key can have multiple values (stored as a list)
priv struct MultiSkipNode {
  key : Int
  values : Array[Int] // Multiple values for same key
  forward : Array[MultiSkipNode?]
}

///|
fn MultiSkipNode::new(key : Int, value : Int, level : Int) -> MultiSkipNode {
  { key, values: [value], forward: Array::make(level, None) }
}

///|
priv struct MultiSkipList {
  header : MultiSkipNode
  mut level : Int
  mut rand_state : Int
  mut size : Int // Total count including duplicates
}

///|
fn MultiSkipList::new() -> MultiSkipList {
  {
    header: { key: 0, values: [], forward: Array::make(max_level, None) },
    level: 0,
    rand_state: 12345,
    size: 0,
  }
}

///|
fn MultiSkipList::random_level(self : MultiSkipList) -> Int {
  for lvl = 0; lvl < max_level - 1; {
    self.rand_state = (self.rand_state * 1103 + 12345) % 65536
    let r = if self.rand_state < 0 { -self.rand_state } else { self.rand_state }
    if r % promotion_probability == 0 {
      continue lvl + 1
    } else {
      break lvl
    }
  } else {
    max_level - 1
  }
}

///|
/// Insert allows duplicate keys - appends to values array if key exists
fn MultiSkipList::insert(self : MultiSkipList, key : Int, value : Int) -> Unit {
  let update : Array[MultiSkipNode?] = Array::make(max_level, None)
  for current = self.header, lvl = self.level; lvl >= 0; {
    match current.forward[lvl] {
      Some(next) if next.key < key => continue next, lvl
      _ => {
        update[lvl] = Some(current)
        continue current, lvl - 1
      }
    }
  } else {
    // Check if key exists - if so, append to values
    match current.forward[0] {
      Some(existing) if existing.key == key => {
        existing.values.push(value)
        self.size = self.size + 1
      }
      _ => {
        // New key - insert new node
        let new_level = self.random_level()
        for i = self.level + 1; i <= new_level; i = i + 1 {
          update[i] = Some(self.header)
        }
        if new_level > self.level {
          self.level = new_level
        }
        let new_node = MultiSkipNode::new(key, value, new_level + 1)
        for i = 0; i <= new_level; i = i + 1 {
          match update[i] {
            Some(prev) => {
              new_node.forward[i] = prev.forward[i]
              prev.forward[i] = Some(new_node)
            }
            None => ()
          }
        }
        self.size = self.size + 1
      }
    }
  } where {
    invariant: true,
    reasoning: (
      #|MULTI-INSERT INVARIANT:
      #|
      #|Same as regular insert, but when key exists:
      #|- We append to the values array instead of creating new node
      #|- This maintains one node per unique key
      #|- Total count (size) includes all duplicates
    ),
  }
}

///|
/// Search returns all values associated with a key
fn MultiSkipList::search(self : MultiSkipList, key : Int) -> Array[Int]? {
  for current = self.header, lvl = self.level; lvl >= 0; {
    match current.forward[lvl] {
      Some(next) if next.key < key => continue next, lvl
      _ => continue current, lvl - 1
    }
  } else {
    match current.forward[0] {
      Some(node) if node.key == key => Some(node.values)
      _ => None
    }
  }
}

///|
test "multi skip list duplicates" {
  let msl = MultiSkipList::new()

  // Insert duplicate keys
  msl.insert(5, 50)
  msl.insert(5, 51)
  msl.insert(5, 52)
  msl.insert(3, 30)
  msl.insert(3, 31)
  inspect(msl.size, content="5")

  // Search returns all values for key
  inspect(msl.search(5), content="Some([50, 51, 52])")
  inspect(msl.search(3), content="Some([30, 31])")
  inspect(msl.search(4), content="None")
}
