// ============================================================================
// Challenge: Persistent Patricia Trie (Okasaki, Big-Endian)
// Compressed binary trie over Int keys, path-copying inserts
// ============================================================================
//
// A Patricia trie is a binary trie that compresses unary chains: instead of
// allocating one level per key bit, each `Branch` node records exactly the
// bit position where its two subtrees first disagree. Looking up a 32-bit
// key therefore visits at most one node per *distinguishing* bit, which is
// `O(min(k, log n))` in practice.
//
// This implementation follows Okasaki's "Big-Endian Patricia" formulation:
// the most significant differing bit is at the root, and bits become less
// significant as one descends. Branching is encoded by two integers:
//
//   - `mask`   : a single-bit Int (a power of two) identifying the bit
//                position where left and right disagree.
//   - `prefix` : the common bits of every key in the subtree, with the
//                bits at and below `mask` zeroed.
//
// Operations are non-destructive: `insert` returns a fresh trie that shares
// every off-path subtree with its input.

///|
/// Okasaki Patricia trie: a binary trie over Int keys where each branch
/// node stores a *branching bit* (the position where its left and right
/// subtrees disagree). Compared to a plain binary trie this skips empty
/// internal levels, giving O(k) lookup and insert where k is the key bit
/// width (32 for Int).
///
/// Each `Branch(prefix, mask, left, right)` invariant: `mask` is a single
/// set bit; `prefix` has all bits at or below `mask` cleared; `left`
/// contains keys whose `mask` bit is `0`, `right` keys whose `mask` bit
/// is `1`. `Leaf(key)` is the single-element trie. See `empty`, `insert`,
/// `contains`, `size`, and `from_array`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let t = @challenge_persistent_patricia_trie.from_array([4, 1, 5, 7][:])
///   @debug.assert_eq(@challenge_persistent_patricia_trie.contains(t, 4), true)
///   @debug.assert_eq(@challenge_persistent_patricia_trie.contains(t, 6), false)
///   @debug.assert_eq(@challenge_persistent_patricia_trie.size(t), 4)
/// }
/// ```
pub enum Trie {
  Empty
  Leaf(key~ : Int)
  Branch(prefix~ : Int, mask~ : Int, left~ : Trie, right~ : Trie)
} derive(Debug)

///|
/// Create an empty Patricia trie.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let t = @challenge_persistent_patricia_trie.empty()
///   @debug.assert_eq(@challenge_persistent_patricia_trie.size(t), 0)
/// }
/// ```
pub fn empty() -> Trie {
  Empty
}

///|
/// Return the number of keys stored in the trie.
///
/// Patricia tries are full binary trees in which every interior `Branch`
/// has exactly two non-empty subtrees, so this counts the leaves directly.
pub fn size(t : Trie) -> Int {
  match t {
    Empty => 0
    Leaf(key=_) => 1
    Branch(prefix=_, mask=_, left~, right~) => size(left) + size(right)
  }
}

///|
/// Is the bit selected by `mask` zero in `key`? Used to decide which side
/// of a `Branch` a key belongs on.
fn zero_bit(key : Int, mask : Int) -> Bool {
  (key & mask) == 0
}

///|
/// Zero out all bits at or below `mask` in `key`, leaving just the prefix
/// shared with the rest of the subtree.
///
/// `mask - 1` produces a mask covering the bits strictly below the
/// branching bit; OR-ing in `mask` itself extends the cover to include the
/// branching bit too. We then AND with the bitwise complement to strip
/// those bits from `key`.
fn mask_key(key : Int, mask : Int) -> Int {
  key & ((mask - 1) | mask).lnot()
}

///|
/// Does `key` agree with `prefix` on all bits above the branching bit
/// `mask`? When this fails we must `join` rather than recurse.
fn match_prefix(key : Int, prefix : Int, mask : Int) -> Bool {
  mask_key(key, mask) == prefix
}

///|
/// Highest-set-bit position in `p1 XOR p2`, returned as a single-bit Int.
///
/// `p1` and `p2` must differ (otherwise no branching bit exists); callers
/// only invoke this with distinct prefixes.
///
/// We scan bit positions `31 .. 0` from most significant to least and
/// return the first position where the XOR has a `1`. The loop is bounded
/// by 32 iterations.
fn branching_bit(p1 : Int, p2 : Int) -> Int {
  let x = p1 ^ p2
  for b = 31 {
    if b == 0 || (x & (1 << b)) != 0 {
      break 1 << b
    }
    continue b - 1
  } where {
    proof_invariant: b >= 0 && b <= 31,
    proof_reasoning: (
      #|INVARIANT (highest-bit scan):
      #|`b` ranges over candidate bit positions 31 down to 0. All strictly
      #|higher bits (b+1 .. 31) have already been checked and were zero in
      #|`x`, so the current `b` is the highest still-possible answer.
      #|MAINTENANCE:
      #|If bit `b` is set in `x` we return `1 << b`; otherwise we decrement
      #|`b` by one, preserving the "no higher set bit" property.
      #|TERMINATION:
      #|Either we find a set bit and break, or we reach `b == 0` and break
      #|with `1`. The loop runs at most 32 iterations.
    ),
  }
}

///|
/// Build a `Branch` whose two children carry prefixes `p1` and `p2`. The
/// branching bit is the highest bit on which `p1` and `p2` differ; the
/// resulting node's `prefix` is their common upper bits.
///
/// ```
///                            Branch(prefix, mask)
///       p1, t1     +-->        /          \
///                  |       zero_bit(p1)  zero_bit(p1)
///       p2, t2 ----+        is true?      is false?
///                                |             |
///                               t1            t2     (swapped otherwise)
/// ```
fn join(p1 : Int, t1 : Trie, p2 : Int, t2 : Trie) -> Trie {
  let m = branching_bit(p1, p2)
  let p = mask_key(p1, m)
  if zero_bit(p1, m) {
    Branch(prefix=p, mask=m, left=t1, right=t2)
  } else {
    Branch(prefix=p, mask=m, left=t2, right=t1)
  }
}

///|
/// Insert `key` and return a new Patricia trie. The original is preserved
/// and shares every off-path subtree with the result.
///
/// At each `Branch` we either match the prefix and recurse into the
/// appropriate child, or `join` the new leaf with the existing subtree at
/// their highest disagreeing bit. Duplicates are ignored (set semantics).
///
/// Time and extra memory: `O(min(k, log n))`, where `k = 32` is the key
/// bit width.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let t = @challenge_persistent_patricia_trie.empty()
///   let t = @challenge_persistent_patricia_trie.insert(t, 4)
///   let t = @challenge_persistent_patricia_trie.insert(t, 1)
///   @debug.assert_eq(@challenge_persistent_patricia_trie.contains(t, 4), true)
/// }
/// ```
pub fn insert(t : Trie, key : Int) -> Trie {
  match t {
    Empty => Leaf(key~)
    Leaf(key=k) =>
      if k == key {
        t
      } else {
        join(key, Leaf(key~), k, Leaf(key=k))
      }
    Branch(prefix~, mask~, left~, right~) =>
      if match_prefix(key, prefix, mask) {
        if zero_bit(key, mask) {
          Branch(prefix~, mask~, left=insert(left, key), right~)
        } else {
          Branch(prefix~, mask~, left~, right=insert(right, key))
        }
      } else {
        join(key, Leaf(key~), prefix, t)
      }
  }
}

///|
/// Membership test for `key`. Descends from the root, choosing left or
/// right based on the branching bit at each `Branch`. Runs in
/// `O(min(k, log n))` time.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let t = @challenge_persistent_patricia_trie.from_array([3, 1, 4][:])
///   @debug.assert_eq(@challenge_persistent_patricia_trie.contains(t, 4), true)
///   @debug.assert_eq(@challenge_persistent_patricia_trie.contains(t, 9), false)
/// }
/// ```
pub fn contains(t : Trie, key : Int) -> Bool {
  match t {
    Empty => false
    Leaf(key=k) => k == key
    Branch(prefix=_, mask~, left~, right~) =>
      if zero_bit(key, mask) {
        contains(left, key)
      } else {
        contains(right, key)
      }
  }
}

///|
/// Build a Patricia trie by inserting each element of `arr` in order.
///
/// Duplicates are ignored (set semantics): inserting the same key twice
/// leaves the trie unchanged. The returned trie contains exactly the
/// distinct elements of `arr`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let t = @challenge_persistent_patricia_trie.from_array([4, 1, 5, 7][:])
///   @debug.assert_eq(@challenge_persistent_patricia_trie.size(t), 4)
/// }
/// ```
pub fn from_array(arr : ArrayView[Int]) -> Trie {
  let n = arr.length()
  for i in 0..<n; t = Empty {
    continue insert(t, arr[i])
  } nobreak {
    t
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_invariant: size(t) <= i,
    proof_reasoning: (
      #|INVARIANT (Patricia build):
      #|t is a valid Patricia trie containing exactly the distinct keys
      #|among arr[0..i). Its size is at most i (equal when all arr[0..i)
      #|are distinct).
      #|MAINTENANCE:
      #|insert(t, arr[i]) returns a trie containing every key of t plus
      #|arr[i]; size grows by one if arr[i] is new and stays the same
      #|otherwise, so size(t) <= i + 1 after the step.
      #|TERMINATION:
      #|At i = n every element has been inserted; the final trie contains
      #|exactly the distinct values in arr.
    ),
  }
}

///|
test "patricia empty" {
  let t : Trie = empty()
  @debug.assert_eq(size(t), 0)
  @debug.assert_eq(contains(t, 0), false)
  @debug.assert_eq(contains(t, 42), false)
  @debug.assert_eq(contains(t, -1), false)
}

///|
test "patricia insert and contains" {
  let t = empty()
  let t = insert(t, 4)
  let t = insert(t, 1)
  let t = insert(t, 5)
  let t = insert(t, 7)
  @debug.assert_eq(size(t), 4)
  assert_true(contains(t, 4))
  assert_true(contains(t, 1))
  assert_true(contains(t, 5))
  assert_true(contains(t, 7))
  @debug.assert_eq(contains(t, 0), false)
  @debug.assert_eq(contains(t, 2), false)
  @debug.assert_eq(contains(t, 6), false)
}

///|
test "patricia duplicate inserts" {
  let t0 = empty()
  let t1 = insert(t0, 10)
  let t2 = insert(t1, 10)
  let t3 = insert(t2, 10)
  @debug.assert_eq(size(t1), 1)
  @debug.assert_eq(size(t2), 1)
  @debug.assert_eq(size(t3), 1)
  assert_true(contains(t3, 10))
}

///|
test "patricia mixed positive and negative" {
  let arr = [3, -1, 0, -5, 7, -100, 100]
  let t = from_array(arr[:])
  @debug.assert_eq(size(t), 7)
  for x in arr {
    assert_true(contains(t, x))
  }
  @debug.assert_eq(contains(t, -2), false)
  @debug.assert_eq(contains(t, 1), false)
  @debug.assert_eq(contains(t, 99), false)
}

///|
test "patricia sequential 0..20" {
  let t = for k in 0..<20; tree = (Empty : Trie) {
    continue insert(tree, k)
  } nobreak {
    tree
  } where {
    proof_invariant: k >= 0 && k <= 20,
    proof_invariant: size(tree) == k,
    proof_reasoning: (
      #|INVARIANT:
      #|tree is a valid Patricia trie containing exactly the keys 0..k,
      #|all of which are distinct so size(tree) == k.
      #|MAINTENANCE:
      #|insert(tree, k) adds a new key, incrementing size by one.
      #|TERMINATION:
      #|At k = 20 the trie contains 0..20 inclusive of 0 and exclusive of
      #|20, i.e. 20 distinct elements.
    ),
  }
  @debug.assert_eq(size(t), 20)
  for k in 0..<20 {
    assert_true(contains(t, k))
  }
  @debug.assert_eq(contains(t, 20), false)
  @debug.assert_eq(contains(t, -1), false)
}

///|
test "patricia persistence: old versions unaffected" {
  let t0 = empty()
  let t1 = insert(t0, 5)
  let t2 = insert(t1, 2)
  let t3 = insert(t2, 8)
  let t4 = insert(t3, 13)
  // Old versions are independent of newer inserts.
  @debug.assert_eq(size(t0), 0)
  @debug.assert_eq(size(t1), 1)
  @debug.assert_eq(size(t2), 2)
  @debug.assert_eq(size(t3), 3)
  @debug.assert_eq(size(t4), 4)
  @debug.assert_eq(contains(t0, 5), false)
  @debug.assert_eq(contains(t1, 2), false)
  @debug.assert_eq(contains(t2, 8), false)
  @debug.assert_eq(contains(t3, 13), false)
  assert_true(contains(t4, 13))
  // t1 still has only 5
  assert_true(contains(t1, 5))
  @debug.assert_eq(contains(t1, 8), false)
}

///|
test "patricia from_array with duplicates" {
  let t = from_array([3, 1, 4, 1, 5, 9, 2, 6, 5, 3][:])
  @debug.assert_eq(size(t), 7)
  for x in [3, 1, 4, 5, 9, 2, 6] {
    assert_true(contains(t, x))
  }
  @debug.assert_eq(contains(t, 0), false)
  @debug.assert_eq(contains(t, 7), false)
}

///|
test "patricia single leaf" {
  let t = insert(empty(), 42)
  match t {
    Leaf(key~) => @debug.assert_eq(key, 42)
    _ => abort("expected single Leaf node")
  }
}
