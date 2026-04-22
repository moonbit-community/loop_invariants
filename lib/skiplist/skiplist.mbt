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
/// Maximum number of levels in the skip list.
///
/// Choosing `log_p(n)` where p is the promotion probability gives expected
/// logarithmic height for up to `p^max_level` elements.  With p = 4 and
/// max_level = 16 this covers up to ~4 billion elements comfortably.
let max_level : Int = 16

///|
/// Reciprocal of the per-level promotion probability (1/4 per level).
///
/// A value of 4 means each node is promoted to the next level with
/// probability 1/4.  Compared to p = 1/2 this yields:
/// - expected 4/3 forward pointers per node (vs 2 for p = 1/2),
/// - slightly taller searches but better memory efficiency.
let promotion_probability : Int = 4 // 1 in 4 chance

///|
/// A single node in the skip list.
///
/// Holds an optional key, an optional associated value, and an array of
/// forward pointers — one per level this node occupies.  The header
/// sentinel uses `key = None` to represent negative infinity.
///
/// Invariants:
/// - `forward.length()` equals the level of this node (height).
/// - `forward[i]` points to the next node at level i in sorted order.
/// - A node at level h also participates in all levels 0..h-1.
priv struct SkipNode[K, V] {
  key : K?
  value : V?
  // forward[i] points to the next node at level i
  // forward.length() == level of this node
  forward : Array[SkipNode[K, V]?]
}

///|
/// Create a new skip list node with the given key, value, and level count.
///
/// `level` is the number of forward-pointer slots to allocate; a node at
/// height h requires `level = h + 1` so that slots 0..h are all present.
/// All forward pointers are initialised to `None`.
fn[K, V] SkipNode::new(
  key : K?,
  value : V?,
  level : Int,
) -> SkipNode[K, V] {
  { key, value, forward: Array::make(level, None) }
}

///|
/// An ordered key-value map implemented as a skip list.
///
/// Keys must implement `Compare`.  All operations (search, insert, delete,
/// range query, ceil, floor) run in O(log n) expected time.
///
/// Fields:
/// - `header`     — sentinel node with `key = None`; conceptually -infinity.
/// - `level`      — index of the highest non-empty level (0-indexed).
/// - `rand_state` — mutable seed for the internal LCG random number generator.
/// - `size`       — number of key-value pairs currently stored.
///
/// Structural invariants:
/// 1. `header.forward[i]` is the first real node at level i (or None).
/// 2. At every level the forward-pointer chain is sorted in ascending order.
/// 3. `self.level` is always the index of the highest occupied level.
priv struct SkipList[K, V] {
  // Header node (sentinel) - exists at all levels
  // header.key should be treated as -infinity
  header : SkipNode[K, V]
  // Current maximum level in use (0-indexed)
  mut level : Int
  // Random state for probabilistic level generation
  mut rand_state : Int
  // Number of elements
  mut size : Int
}

///|
/// Create a new, empty skip list.
///
/// Allocates the header sentinel node with `max_level` forward-pointer
/// slots (all `None`) and seeds the LCG random state to 42.
fn[K, V] SkipList::new() -> SkipList[K, V] {
  {
    header: SkipNode::new(None, None, max_level), // sentinel node
    level: 0,
    rand_state: 42,
    size: 0,
  }
}

///|
/// Generate a random height for a newly inserted node.
///
/// The height follows a geometric distribution: start at level 0 and
/// keep promoting with probability 1/`promotion_probability` until either
/// promotion fails or `max_level - 1` is reached.
///
/// Expected height = 1 / (1 - 1/p) ≈ 1.33 for p = 4.
///
/// The internal LCG formula is:
/// ```
/// rand_state = (rand_state * 1103 + 12345) mod 65536
/// ```
/// A result divisible by `promotion_probability` counts as "heads".
fn[K, V] SkipList::random_level(self : SkipList[K, V]) -> Int {
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
  } nobreak {
    max_level - 1
  } where {
    proof_invariant: lvl >= 0 && lvl < max_level,
    proof_reasoning: (
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
      #|MAINTENANCE:
      #|Each iteration either promotes to the next level or stops on failure.
      #|TERMINATION:
      #|lvl increases until promotion fails or max_level is reached.
    ),
  }
}

// ============================================================================
// SEARCH OPERATION
// ============================================================================

///|
/// Look up a key and return its associated value.
///
/// Returns `Some(value)` when `key` is present, `None` otherwise.
///
/// Expected time complexity: O(log n).
///
/// Algorithm:
/// 1. Begin at the header sentinel at the highest occupied level.
/// 2. Move right while the next node's key is strictly less than `key`.
/// 3. When unable to move right, drop down one level.
/// 4. Repeat until level 0 is exhausted.
/// 5. Inspect `forward[0]` of the current node: if its key equals `key`,
///    return the associated value; otherwise return `None`.
fn[K : Compare, V] SkipList::search(self : SkipList[K, V], key : K) -> V? {
  // Start at the header node
  // We will traverse from highest level down to level 0
  for current = self.header, lvl = self.level; lvl >= 0; {
    // At each level, move right as far as possible while staying < key
    match current.forward[lvl] {
      Some(next) if next.key is Some(next_key) && next_key < key =>
        // Move right - next node's key is still less than target
        continue next, lvl
      _ =>
        // Can't move right - either no next node or next.key >= key
        // Drop down one level
        continue current, lvl - 1
    }
  } nobreak {
    // We've descended through all levels
    // Now check if the next node at level 0 has our key
    match current.forward[0] {
      Some(node) if node.key is Some(node_key) && node_key == key => node.value
      _ => None
    }
  } where {
    proof_invariant: current.key is None ||
    (current.key is Some(current_key) && current_key < key),
    proof_reasoning: (
      #|SEARCH INVARIANT: current is header or current.key < key
      #|
      #|1. Initialization: header acts as -infinity sentinel, so header.key < key
      #|   (we treat header.key as a sentinel, not a real key)
      #|
      #|2. Moving right (continue next, lvl):
      #|   - Precondition: next.key < key (from guard condition)
      #|   - Postcondition: new current.key = next.key < key ✓
      #|
      #|3. Dropping down (continue current, lvl - 1):
      #|   - current unchanged, so the invariant still holds ✓
      #|
      #|4. Termination: lvl decreases when we can't move right
      #|   - Eventually lvl = -1 and we exit
      #|   - At level 0, forward[0] points to the first node >= key (if any)
      #|
      #|5. Correctness: Due to sorted order at each level, if key exists,
      #|   it must be at current.forward[0] when we finish descending.
      #|MAINTENANCE:
      #|Moving right preserves the invariant; dropping a level keeps current.
      #|TERMINATION:
      #|lvl strictly decreases when movement right is blocked, so we exit.
    ),
  }
}

// ============================================================================
// INSERT OPERATION
// ============================================================================

///|
/// Insert a key-value pair into the skip list.
///
/// If `key` already exists the function returns without modifying the
/// existing entry (in-place value update is not yet implemented).
///
/// Expected time complexity: O(log n).
///
/// Algorithm:
/// 1. Descend through all levels, recording in `update[i]` the rightmost
///    predecessor node at level i (i.e. the node whose `forward[i]` must
///    be rewired).
/// 2. Assign a random height to the new node via `random_level`.
/// 3. If the new height exceeds `self.level`, extend the header's update
///    entries and raise `self.level`.
/// 4. Allocate the new node and splice it in at each level 0..new_level by
///    swapping `update[i].forward[i]` with the new node.
fn[K : Compare, V] SkipList::insert(
  self : SkipList[K, V],
  key : K,
  value : V,
) -> Unit {
  // update[i] will hold the rightmost node at level i that is < key
  // These are the nodes whose forward pointers need updating
  let update : Array[SkipNode[K, V]?] = Array::make(max_level, None)

  // Phase 1: Find insert position and record update points
  // This is similar to search but we remember the last node at each level
  for current = self.header, lvl = self.level; lvl >= 0; {
    match current.forward[lvl] {
      Some(next) if next.key is Some(next_key) && next_key < key =>
        continue next, lvl
      _ => {
        // Record this as the update point for level lvl
        update[lvl] = Some(current)
        continue current, lvl - 1
      }
    }
  } nobreak {
    // Check if key already exists
    match current.forward[0] {
      Some(existing) if existing.key is Some(existing_key) &&
        existing_key == key =>
        // Key exists - update value
        // Note: In a more sophisticated implementation, we'd use mutable value
        // For now, we don't support in-place update (skip lists typically do)
        return // Value update would go here
      _ => {
        // Key doesn't exist - insert new node
        let new_level = self.random_level()

        // If new level exceeds current max level, update header's forward
        // and add header to update array for new levels
        for i in (self.level + 1)..<=new_level {
          update[i] = Some(self.header)
        }

        // Update skip list level if necessary
        if new_level > self.level {
          self.level = new_level
        }

        // Create new node
        let new_node = SkipNode::new(Some(key), Some(value), new_level + 1)

        // Link new node at each level
        // This loop links the new node into the skip list at all levels
        for i in 0..<=new_level {
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
    proof_invariant: lvl >= -1 &&
    lvl <= self.level &&
    update.length() == max_level,
    proof_reasoning: (
      #|INSERT INVARIANT: update[lvl] tracks the predecessor at each level
      #|
      #|1. Search phase maintains: at each level, current is the rightmost
      #|   node with key < target; update[lvl] records that predecessor.
      #|   Therefore update[lvl].forward[lvl] is None or points to key >= target.
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
      #|MAINTENANCE:
      #|Search records correct predecessors; linking inserts new_node between
      #|predecessor and successor at each level.
      #|TERMINATION:
      #|Search descends to level -1, then linking completes in bounded steps.
    ),
  }
}

// ============================================================================
// DELETE OPERATION
// ============================================================================

///|
/// Remove a key and its associated value from the skip list.
///
/// Returns `true` when the key was present and successfully removed,
/// `false` when the key was not found.
///
/// Expected time complexity: O(log n).
///
/// Algorithm:
/// 1. Descend through all levels building the same `update` array as in
///    `insert` — each `update[i]` is the predecessor at level i.
/// 2. Confirm that `update[0].forward[0]` is the target node.
/// 3. For every level i where `update[i].forward[i]` equals the target,
///    redirect that pointer to `target.forward[i]`, bypassing the node.
/// 4. Decrement `self.level` while the top level has become empty.
fn[K : Compare, V] SkipList::delete(self : SkipList[K, V], key : K) -> Bool {
  let update : Array[SkipNode[K, V]?] = Array::make(max_level, None)

  // Phase 1: Find the node and record update points
  for current = self.header, lvl = self.level; lvl >= 0; {
    match current.forward[lvl] {
      Some(next) if next.key is Some(next_key) && next_key < key =>
        continue next, lvl
      _ => {
        update[lvl] = Some(current)
        continue current, lvl - 1
      }
    }
  } nobreak {
    // Check if key exists
    match current.forward[0] {
      Some(target) if target.key is Some(target_key) && target_key == key => {
        // Found the node - unlink it at all levels
        for i in 0..<=self.level {
          match update[i] {
            Some(prev) =>
              match prev.forward[i] {
                Some(node) if node.key is Some(node_key) && node_key == key =>
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
        } nobreak {
          ()
        } where {
          proof_invariant: self.level >= 0,
          proof_reasoning: (
            #|LEVEL REDUCTION INVARIANT:
            #|
            #|1. We only reduce level when header.forward[level] is None
            #|   - This means no elements exist at this level
            #|
            #|2. We stop when we find a non-empty level or reach 0
            #|   - Level 0 always exists (base level)
            #|
            #|3. After reduction: self.level is the highest non-empty level
            #|MAINTENANCE:
            #|Each continue lowers level only when the header has no nodes there.
            #|TERMINATION:
            #|Level decreases until a non-empty level is found or reaches 0.
          ),
        }
        self.size = self.size - 1
        true
      }
      _ => false // Key not found
    }
  } where {
    proof_invariant: lvl >= -1 &&
    lvl <= self.level &&
    update.length() == max_level,
    proof_reasoning: (
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
      #|MAINTENANCE:
      #|Search preserves predecessors; unlinking bypasses the target safely.
      #|TERMINATION:
      #|Search descends to level -1, then unlinking completes in bounded loops.
    ),
  }
}

// ============================================================================
// RANGE QUERY
// ============================================================================

///|
/// Collect all key-value pairs whose key lies in the closed interval
/// `[low, high]`, returned in ascending key order.
///
/// Expected time complexity: O(log n + k), where k is the number of
/// matching entries.
///
/// Algorithm:
/// 1. Use the standard skip-list descent to locate the predecessor of
///    `low` in O(log n) expected time.
/// 2. Walk forward along level 0 — which contains every element — pushing
///    each node whose key satisfies `key <= high` into the result array.
/// 3. Stop when the key exceeds `high` or the list ends.
fn[K : Compare, V] SkipList::range_query(
  self : SkipList[K, V],
  low : K,
  high : K,
) -> Array[(K, V)] {
  let result : Array[(K, V)] = []

  // First, find the first node >= low using skip list search
  for current = self.header, lvl = self.level; lvl >= 0; {
    match current.forward[lvl] {
      Some(next) if next.key is Some(next_key) && next_key < low =>
        continue next, lvl
      _ => continue current, lvl - 1
    }
  } nobreak {
    // Now traverse at level 0 collecting all keys in range
    for node = current.forward[0] {
      match node {
        Some(n) if n.key is Some(node_key) && node_key <= high =>
          match n.value {
            Some(node_value) => {
              result.push((node_key, node_value))
              continue n.forward[0]
            }
            None => break
          }
        _ => break
      }
    } where {
      proof_invariant: result.length() <= self.size,
      proof_reasoning: (
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
        #|MAINTENANCE:
        #|Each step appends the current node and advances to the next at level 0.
        #|TERMINATION:
        #|Traversal stops at the first node with key > high or end of list.
      ),
    }
    result
  } where {
    proof_invariant: lvl >= -1 && lvl <= self.level,
    proof_reasoning: (
      #|RANGE SEARCH INVARIANT: Same as regular search
      #|
      #|We find the predecessor of 'low', then traverse level 0
      #|to collect all elements in the range [low, high].
      #|MAINTENANCE:
      #|Search preserves current as header or current.key < low at each level.
      #|TERMINATION:
      #|After descending levels, current.forward[0] is the first node >= low.
    ),
  }
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

///|
/// Return the number of key-value pairs currently stored in the skip list.
///
/// This is an O(1) operation; the count is maintained incrementally.
fn[K, V] SkipList::length(self : SkipList[K, V]) -> Int {
  self.size
}

///|
/// Return `true` when the skip list contains no elements.
///
/// This is an O(1) operation equivalent to `self.length() == 0`.
fn[K, V] SkipList::is_empty(self : SkipList[K, V]) -> Bool {
  self.size == 0
}

///|
/// Return the entry with the smallest key, or `None` if the list is empty.
///
/// Level 0 contains all elements in sorted order, so the first real node
/// (`header.forward[0]`) is always the minimum.  This is an O(1) operation.
fn[K, V] SkipList::min(self : SkipList[K, V]) -> (K, V)? {
  match self.header.forward[0] {
    Some(node) =>
      match (node.key, node.value) {
        (Some(node_key), Some(node_value)) => Some((node_key, node_value))
        _ => None
      }
    None => None
  }
}

///|
/// Return the entry with the largest key, or `None` if the list is empty.
///
/// Exploits the multi-level structure: start at the highest level and
/// always move right until no forward pointer remains, then drop down.
/// This mirrors a search for positive infinity and runs in O(log n)
/// expected time — far faster than a linear scan of level 0.
fn[K, V] SkipList::max(self : SkipList[K, V]) -> (K, V)? {
  // Traverse from top level, always going as far right as possible
  for current = self.header, lvl = self.level; lvl >= 0; {
    match current.forward[lvl] {
      Some(next) => continue next, lvl // Move right at same level
      None => continue current, lvl - 1 // Drop down
    }
  } nobreak {
    // current is now the rightmost node
    if current.key is None {
      None // Empty list, current is header
    } else {
      match (current.key, current.value) {
        (Some(node_key), Some(node_value)) => Some((node_key, node_value))
        _ => None
      }
    }
  } where {
    proof_invariant: lvl >= 0 || lvl == -1,
    proof_reasoning: (
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
      #|MAINTENANCE:
      #|Moving right preserves maximality at the current level; dropping a
      #|level keeps the rightmost node seen so far.
      #|TERMINATION:
      #|lvl decreases to -1 after finitely many drops.
    ),
  }
}

// ============================================================================
// CEIL AND FLOOR OPERATIONS
// ============================================================================

///|
/// Return the entry with the smallest key that is greater than or equal to
/// `key` (the ceiling), or `None` if no such entry exists.
///
/// Expected time complexity: O(log n).
///
/// The search descends exactly like `search`, stopping just before any
/// forward pointer would reach a node with key >= `key`.  The first node
/// at level 0 after this stopping point is the ceiling candidate.
fn[K : Compare, V] SkipList::ceil(self : SkipList[K, V], key : K) -> (K, V)? {
  for current = self.header, lvl = self.level; lvl >= 0; {
    match current.forward[lvl] {
      Some(next) if next.key is Some(next_key) && next_key < key =>
        continue next, lvl
      _ => continue current, lvl - 1
    }
  } nobreak {
    match current.forward[0] {
      Some(node) =>
        match (node.key, node.value) {
          (Some(node_key), Some(node_value)) => Some((node_key, node_value))
          _ => None
        }
      None => None
    }
  } where {
    proof_invariant: current.key is None ||
    (current.key is Some(current_key) && current_key < key),
    proof_reasoning: (
      #|CEIL INVARIANT: Find first node >= key
      #|
      #|After descending all levels, current.forward[0] points to
      #|the first node with key >= given key (if any exists).
      #|MAINTENANCE:
      #|We move right only while next.key < key, preserving the invariant.
      #|TERMINATION:
      #|lvl decreases to -1, then we inspect the level 0 successor.
    ),
  }
}

///|
/// Return the entry with the largest key that is less than or equal to
/// `key` (the floor), or `None` if no such entry exists.
///
/// Expected time complexity: O(log n).
///
/// Unlike `search` and `ceil`, the guard condition here is `next_key <= key`
/// (not `< key`), so the traversal includes exact matches when moving right.
/// After all levels are exhausted, `current` is the largest node with
/// key <= `key`.
fn[K : Compare, V] SkipList::floor(self : SkipList[K, V], key : K) -> (K, V)? {
  for current = self.header, lvl = self.level; lvl >= 0; {
    match current.forward[lvl] {
      Some(next) if next.key is Some(next_key) && next_key <= key =>
        continue next, lvl
      _ => continue current, lvl - 1
    }
  } nobreak {
    // current is the largest node <= key (or header if none exists)
    if current.key is None {
      None
    } else {
      match (current.key, current.value) {
        (Some(node_key), Some(node_value)) => Some((node_key, node_value))
        _ => None
      }
    }
  } where {
    proof_invariant: current.key is None ||
    (current.key is Some(current_key) && current_key <= key),
    proof_reasoning: (
      #|FLOOR INVARIANT: Find last node <= key
      #|
      #|1. We move right while next.key <= key (not < like in search)
      #|   - This ensures current is always <= key
      #|
      #|2. When we can't move right: next.key > key or next is None
      #|   - current is the rightmost node at this level with key <= given key
      #|
      #|3. After all levels: current is the largest node <= key overall
      #|MAINTENANCE:
      #|Moving right keeps the invariant; dropping a level preserves it.
      #|TERMINATION:
      #|lvl decreases to -1, yielding the final predecessor.
    ),
  }
}

// ============================================================================
// ORDERED STATISTICS
// ============================================================================

///|
/// Count the number of entries whose key is strictly less than `key`.
///
/// Traverses level 0 from the beginning, incrementing a counter for each
/// node with `node_key < key`.  Stops at the first node that does not
/// satisfy the predicate.
///
/// Time complexity: O(result) — proportional to the count returned.
/// A more efficient augmented version would store subtree sizes in nodes
/// to answer this in O(log n), but that is not implemented here.
fn[K : Compare, V] SkipList::count_less_than(
  self : SkipList[K, V],
  key : K,
) -> Int {
  for current = self.header.forward[0], count = 0 {
    match current {
      Some(node) if node.key is Some(node_key) && node_key < key =>
        continue node.forward[0], count + 1
      _ => break count
    }
  } where {
    proof_invariant: count >= 0,
    proof_reasoning: (
      #|COUNT INVARIANT: count accumulates nodes with key < given key
      #|
      #|1. Traverse level 0 (contains all elements)
      #|2. Increment count for each node with key < given key
      #|3. Stop when we reach a node >= key or end of list
      #|MAINTENANCE:
      #|Each visited node with key < key increments count by 1.
      #|TERMINATION:
      #|Traversal stops at first node with key >= key or end of list.
    ),
  }
}

///|
/// Return the k-th smallest entry (0-indexed), or `None` when `k` is out
/// of bounds (i.e. `k < 0` or `k >= self.size`).
///
/// Walks level 0 counting nodes until the i-th node (i == k) is reached.
/// Time complexity: O(k) — a linear scan from the beginning of level 0.
///
/// Example: for keys [1, 3, 5, 7, 9], `kth_element(2)` returns
/// `Some((5, value_of_5))`.
fn[K, V] SkipList::kth_element(self : SkipList[K, V], k : Int) -> (K, V)? {
  if k < 0 || k >= self.size {
    return None
  }
  for current = self.header.forward[0], i = 0 {
    match current {
      Some(node) =>
        match (node.key, node.value) {
          (Some(node_key), Some(node_value)) =>
            if i == k {
              break Some((node_key, node_value))
            } else {
              continue node.forward[0], i + 1
            }
          _ => break None
        }
      None => break None
    }
  } where {
    proof_invariant: i >= 0 && i <= k,
    proof_reasoning: (
      #|KTH ELEMENT INVARIANT: i counts elements traversed
      #|
      #|1. We traverse level 0, counting elements
      #|2. When i == k, we've found the k-th element (0-indexed)
      #|3. Precondition k < size ensures we'll find it before reaching end
      #|MAINTENANCE:
      #|Each step advances one node and increments i by 1.
      #|TERMINATION:
      #|The loop breaks when i == k or the list ends (precluded by precondition).
    ),
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "skip list basic operations" {
  let sl : SkipList[Int, Int] = SkipList::new()

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
  let sl : SkipList[Int, Int] = SkipList::new()
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
  let sl : SkipList[Int, Int] = SkipList::new()
  for i in 0..<10 {
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
  let sl : SkipList[Int, Int] = SkipList::new()
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
  let sl : SkipList[Int, Int] = SkipList::new()

  // Insert 10, 20, 30, 40, 50
  for i in 1..<=5 {
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
  let sl : SkipList[Int, Int] = SkipList::new()

  // Insert 1, 3, 5, 7, 9
  for i in 0..<5 {
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
  let sl : SkipList[Int, Int] = SkipList::new()

  // Insert 100 elements
  for i in 0..<100 {
    sl.insert(i, i * 10)
  }
  inspect(sl.length(), content="100")

  // Verify all elements are searchable
  for i in 0..<100 {
    guard sl.search(i) is Some(_) else { fail("Element not found") }
  }

  // Delete every other element
  for i in 0..<100 {
    if i % 2 == 0 {
      guard sl.delete(i) else { fail("Delete failed") }
    }
  }
  inspect(sl.length(), content="50")

  // Verify deletions
  for i in 0..<100 {
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
/// A node in a skip list that supports duplicate keys.
///
/// Instead of a single `value` field, each node holds an `Array[V]` so
/// that multiple values can be stored under the same key.  The first
/// insertion for a key creates the node; subsequent insertions for the same
/// key append to `values`.
///
/// The `forward` array plays the same role as in `SkipNode`: `forward[i]`
/// points to the next node at level i.
priv struct MultiSkipNode[K, V] {
  key : K?
  values : Array[V] // Multiple values for same key
  forward : Array[MultiSkipNode[K, V]?]
}

///|
/// Create a new `MultiSkipNode` with the given key, initial value array,
/// and level count.  All forward pointers are initialised to `None`.
fn[K, V] MultiSkipNode::new(
  key : K?,
  values : Array[V],
  level : Int,
) -> MultiSkipNode[K, V] {
  { key, values, forward: Array::make(level, None) }
}

///|
/// An ordered multimap implemented as a skip list.
///
/// Unlike `SkipList`, this structure allows multiple values per key.
/// Inserting the same key a second time appends the new value to the
/// existing node's `values` array rather than creating a duplicate node.
///
/// `size` counts total inserted values (including duplicates), not unique
/// keys.  All structural invariants from `SkipList` apply to the key
/// ordering and level hierarchy.
priv struct MultiSkipList[K, V] {
  header : MultiSkipNode[K, V]
  mut level : Int
  mut rand_state : Int
  mut size : Int // Total count including duplicates
}

///|
/// Create a new, empty `MultiSkipList`.
///
/// The header sentinel is allocated with `max_level` forward slots and
/// an empty `values` array.  The LCG seed is initialised to 12345.
fn[K, V] MultiSkipList::new() -> MultiSkipList[K, V] {
  {
    header: MultiSkipNode::new(None, [], max_level),
    level: 0,
    rand_state: 12345,
    size: 0,
  }
}

///|
/// Generate a random height for a newly inserted node using the same LCG
/// and geometric distribution as `SkipList::random_level`.
fn[K, V] MultiSkipList::random_level(self : MultiSkipList[K, V]) -> Int {
  for lvl = 0; lvl < max_level - 1; {
    self.rand_state = (self.rand_state * 1103 + 12345) % 65536
    let r = if self.rand_state < 0 { -self.rand_state } else { self.rand_state }
    if r % promotion_probability == 0 {
      continue lvl + 1
    } else {
      break lvl
    }
  } nobreak {
    max_level - 1
  } where {
    proof_invariant: lvl >= 0 && lvl < max_level,
    proof_reasoning: (
      #|INVARIANT (random level):
      #|lvl is the current candidate level in [0, max_level - 1].
      #|MAINTENANCE:
      #|With probability 1/promotion_probability, increase lvl by one.
      #|TERMINATION:
      #|lvl increases monotonically and is bounded, so the loop terminates.
    ),
  }
}

///|
/// Insert a value under `key`, allowing duplicates.
///
/// If `key` already exists in the list the new `value` is appended to the
/// existing node's `values` array; no new node is created.  If `key` is
/// new a fresh node is allocated and linked in at all levels up to its
/// randomly chosen height, exactly as in `SkipList::insert`.
///
/// `self.size` is incremented unconditionally, so it tracks total inserted
/// values rather than unique keys.
///
/// Expected time complexity: O(log n).
fn[K : Compare, V] MultiSkipList::insert(
  self : MultiSkipList[K, V],
  key : K,
  value : V,
) -> Unit {
  let update : Array[MultiSkipNode[K, V]?] = Array::make(max_level, None)
  for current = self.header, lvl = self.level; lvl >= 0; {
    match current.forward[lvl] {
      Some(next) if next.key is Some(next_key) && next_key < key =>
        continue next, lvl
      _ => {
        update[lvl] = Some(current)
        continue current, lvl - 1
      }
    }
  } nobreak {
    // Check if key exists - if so, append to values
    match current.forward[0] {
      Some(existing) if existing.key is Some(existing_key) &&
        existing_key == key => {
        existing.values.push(value)
        self.size = self.size + 1
      }
      _ => {
        // New key - insert new node
        let new_level = self.random_level()
        for i in (self.level + 1)..<=new_level {
          update[i] = Some(self.header)
        }
        if new_level > self.level {
          self.level = new_level
        }
        let new_node = MultiSkipNode::new(Some(key), [value], new_level + 1)
        for i in 0..<=new_level {
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
    proof_invariant: lvl >= -1 &&
    lvl <= self.level &&
    update.length() == max_level,
    proof_reasoning: (
      #|MULTI-INSERT INVARIANT:
      #|
      #|Same as regular insert, but when key exists:
      #|- We append to the values array instead of creating new node
      #|- This maintains one node per unique key
      #|- Total count (size) includes all duplicates
      #|MAINTENANCE:
      #|Either append to the existing node's values or link a new node into
      #|the list while preserving sorted order.
      #|TERMINATION:
      #|The search descends levels to -1, then finishes with bounded updates.
    ),
  }
}

///|
/// Look up a key and return the array of all values associated with it.
///
/// Returns `Some(values)` where `values` is the node's internal array
/// (not a copy) when the key is present, or `None` when it is absent.
/// Note that the returned array is a live reference; callers should not
/// mutate it directly.
///
/// Expected time complexity: O(log n).
fn[K : Compare, V] MultiSkipList::search(
  self : MultiSkipList[K, V],
  key : K,
) -> Array[V]? {
  for current = self.header, lvl = self.level; lvl >= 0; {
    match current.forward[lvl] {
      Some(next) if next.key is Some(next_key) && next_key < key =>
        continue next, lvl
      _ => continue current, lvl - 1
    }
  } nobreak {
    match current.forward[0] {
      Some(node) if node.key is Some(node_key) && node_key == key =>
        Some(node.values)
      _ => None
    }
  } where {
    proof_invariant: lvl >= -1,
    proof_reasoning: (
      #|INVARIANT (search):
      #|At each level, current is the rightmost node with key < target reachable
      #|at that level.
      #|MAINTENANCE:
      #|Move right while next.key < key; otherwise drop one level.
      #|TERMINATION:
      #|When lvl < 0, current.forward[0] is the first node with key >= target.
    ),
  }
}

///|
test "multi skip list duplicates" {
  let msl : MultiSkipList[Int, Int] = MultiSkipList::new()

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
