// ============================================================================
// LRU CACHE  -  O(1) hashmap + doubly linked list
// ============================================================================
//
// PROBLEM
//
// Bounded-size key-value store that **evicts** the **least recently
// used** entry on insertion overflow. Supports `get`, `put` in `O(1)`
// amortised, plus `size`, `capacity`, `keys`.
//
// THE STRUCTURE
//
// Doubly linked list of (key, value) nodes ordered by recency: head is
// most recent, tail is least recent. A hashmap `key -> node` gives
// `O(1)` lookup. Each `get` / `put` moves the touched node to the
// head; once `size > capacity`, the tail node is removed.
//
// In MoonBit, we use array-backed indices instead of pointers because
// the standard library makes that simpler than mutable doubly linked
// structures: a free-list of slots keeps reuse cheap.
//
// COMPLEXITY
//
//   get(k) : O(1) amortised
//   put(k, v) : O(1) amortised
//   size  : O(1)
//
// THE INVARIANT
//
//   "At any time, the linked list visits exactly the keys present in
//    the hashmap, in most-recent-first order. The hashmap value for
//    key k is the index of k's node."

///|
struct Slot {
  mut key : Int64
  mut value : Int64
  mut prev : Int
  mut next : Int
}

///|
/// Bounded LRU cache mapping `Int64` keys to `Int64` values.
pub struct LruCache {
  capacity : Int
  slots : Array[Slot]
  mut head : Int // most-recent
  mut tail : Int // least-recent
  mut size : Int
  map : Map[Int64, Int]
  free : Array[Int]
}

///|
/// Create a new LRU cache with at most `capacity` entries. `capacity`
/// must be positive; otherwise treated as `1`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let c = @lru_cache.new(2)
///   c.put(1L, 10L)
///   c.put(2L, 20L)
///   @debug.assert_eq(c.get(1L), Some(10L))
///   c.put(3L, 30L) // evicts key 2
///   @debug.assert_eq(c.get(2L), None)
/// }
/// ```
pub fn new(capacity : Int) -> LruCache {
  let cap = if capacity < 1 { 1 } else { capacity }
  let slots = Array::makei(cap, _ => ({
    key: 0L,
    value: 0L,
    prev: -1,
    next: -1,
  } : Slot))
  let free : Array[Int] = []
  let mut i = cap - 1
  while i >= 0 {
    free.push(i)
    i = i - 1
  }
  {
    capacity: cap,
    slots,
    head: -1,
    tail: -1,
    size: 0,
    map: Map([], capacity=cap),
    free,
  }
}

///|
fn LruCache::detach(self : LruCache, idx : Int) -> Unit {
  let s = self.slots[idx]
  let pv = s.prev
  let nx = s.next
  if pv != -1 {
    self.slots[pv].next = nx
  } else {
    self.head = nx
  }
  if nx != -1 {
    self.slots[nx].prev = pv
  } else {
    self.tail = pv
  }
  s.prev = -1
  s.next = -1
}

///|
fn LruCache::attach_head(self : LruCache, idx : Int) -> Unit {
  let s = self.slots[idx]
  s.prev = -1
  s.next = self.head
  if self.head != -1 {
    self.slots[self.head].prev = idx
  }
  self.head = idx
  if self.tail == -1 {
    self.tail = idx
  }
}

///|
/// Look up a key. Returns `Some(v)` if present (and marks it as most
/// recently used), or `None` otherwise.
pub fn LruCache::get(self : LruCache, key : Int64) -> Int64? {
  match self.map.get(key) {
    None => None
    Some(idx) => {
      let v = self.slots[idx].value
      self.detach(idx)
      self.attach_head(idx)
      Some(v)
    }
  }
}

///|
/// Insert or update a key-value pair. Evicts the least recently used
/// entry if the cache exceeds its capacity.
pub fn LruCache::put(self : LruCache, key : Int64, value : Int64) -> Unit {
  match self.map.get(key) {
    Some(idx) => {
      self.slots[idx].value = value
      self.detach(idx)
      self.attach_head(idx)
    }
    None => {
      let idx = if self.free.length() > 0 {
        let i = self.free[self.free.length() - 1]
        self.free.pop() |> ignore
        i
      } else {
        // Evict least-recent.
        let evict_idx = self.tail
        let evict_key = self.slots[evict_idx].key
        self.map.remove(evict_key)
        self.detach(evict_idx)
        self.size = self.size - 1
        evict_idx
      }
      self.slots[idx].key = key
      self.slots[idx].value = value
      self.attach_head(idx)
      self.map[key] = idx
      self.size = self.size + 1
    }
  }
}

///|
/// Number of entries currently stored.
pub fn LruCache::length(self : LruCache) -> Int {
  self.size
}

///|
/// Maximum entries.
pub fn LruCache::cap(self : LruCache) -> Int {
  self.capacity
}

///|
/// Whether the cache contains the key without affecting recency.
pub fn LruCache::contains(self : LruCache, key : Int64) -> Bool {
  match self.map.get(key) {
    Some(_) => true
    None => false
  }
}

///|
/// Keys from most-recent to least-recent.
pub fn LruCache::keys_mru(self : LruCache) -> Array[Int64] {
  let res : Array[Int64] = []
  let mut p = self.head
  while p != -1 {
    res.push(self.slots[p].key)
    p = self.slots[p].next
  }
  res
}

///|
test "lru basic put/get" {
  let c = new(3)
  c.put(1L, 10L)
  c.put(2L, 20L)
  c.put(3L, 30L)
  @debug.assert_eq(c.get(1L), Some(10L))
  @debug.assert_eq(c.get(2L), Some(20L))
  @debug.assert_eq(c.get(3L), Some(30L))
  @debug.assert_eq(c.get(4L), None)
  @debug.assert_eq(c.length(), 3)
}

///|
test "lru eviction" {
  let c = new(2)
  c.put(1L, 10L)
  c.put(2L, 20L)
  // Touch 1 -> 1 is MRU, 2 is LRU.
  let _ = c.get(1L)
  // Insert 3 -> evicts 2.
  c.put(3L, 30L)
  @debug.assert_eq(c.get(2L), None)
  @debug.assert_eq(c.get(1L), Some(10L))
  @debug.assert_eq(c.get(3L), Some(30L))
}

///|
test "lru update existing key" {
  let c = new(2)
  c.put(1L, 10L)
  c.put(1L, 11L) // update
  @debug.assert_eq(c.get(1L), Some(11L))
  @debug.assert_eq(c.length(), 1)
}

///|
test "lru order tracking" {
  let c = new(4)
  c.put(1L, 1L)
  c.put(2L, 2L)
  c.put(3L, 3L)
  c.put(4L, 4L)
  // MRU order: 4, 3, 2, 1
  @debug.assert_eq(c.keys_mru(), [4L, 3L, 2L, 1L])
  let _ = c.get(2L)
  // Now: 2, 4, 3, 1
  @debug.assert_eq(c.keys_mru(), [2L, 4L, 3L, 1L])
}

///|
test "lru capacity 1" {
  let c = new(1)
  c.put(1L, 100L)
  c.put(2L, 200L) // evicts 1
  @debug.assert_eq(c.get(1L), None)
  @debug.assert_eq(c.get(2L), Some(200L))
  @debug.assert_eq(c.length(), 1)
}

///|
test "lru zero capacity treated as one" {
  let c = new(0)
  @debug.assert_eq(c.cap(), 1)
  c.put(1L, 10L)
  c.put(2L, 20L)
  @debug.assert_eq(c.get(1L), None)
  @debug.assert_eq(c.get(2L), Some(20L))
}

///|
test "lru contains" {
  let c = new(2)
  c.put(1L, 1L)
  @debug.assert_eq(c.contains(1L), true)
  @debug.assert_eq(c.contains(2L), false)
}

///|
test "lru leetcode 146 example" {
  // From LeetCode 146.
  let c = new(2)
  c.put(1L, 1L)
  c.put(2L, 2L)
  @debug.assert_eq(c.get(1L), Some(1L))
  c.put(3L, 3L) // evicts 2
  @debug.assert_eq(c.get(2L), None)
  c.put(4L, 4L) // evicts 1
  @debug.assert_eq(c.get(1L), None)
  @debug.assert_eq(c.get(3L), Some(3L))
  @debug.assert_eq(c.get(4L), Some(4L))
}
