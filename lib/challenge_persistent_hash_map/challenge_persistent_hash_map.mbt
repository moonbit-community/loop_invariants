// ============================================================================
// Challenge: Persistent Hash Map (Int -> Int)
// Buckets as immutable lists with path-copying updates
// ============================================================================

///|
enum Bucket[K, V] {
  Nil
  Cons(key~ : K, value~ : V, tail~ : Bucket[K, V])
} derive(Show)

///|
pub struct HashMap[K, V] {
  buckets : Array[Bucket[K, V]]
  size : Int
} derive(Show)

///|
fn[K, V] bucket_size(b : Bucket[K, V]) -> Int {
  match b {
    Bucket::Nil => 0
    Bucket::Cons(key=_, value=_, tail~) => 1 + bucket_size(tail)
  }
}

///|
fn[K : Eq, V] bucket_no_key(b : Bucket[K, V], key : K) -> Bool {
  match b {
    Bucket::Nil => true
    Bucket::Cons(key=k, value=_, tail=t) => key != k && bucket_no_key(t, key)
  }
}

///|
fn[K, V] reverse_append(
  rev : Bucket[K, V],
  tail : Bucket[K, V],
) -> Bucket[K, V] {
  match rev {
    Bucket::Nil => tail
    Bucket::Cons(key=k, value=v, tail=t) =>
      reverse_append(t, Bucket::Cons(key=k, value=v, tail~))
  }
}

///|
/// Create an empty hash map with the given capacity (min 1).
pub fn[K, V] make(capacity : Int) -> HashMap[K, V] {
  let cap = if capacity <= 0 { 1 } else { capacity }
  { buckets: Array::make(cap, Bucket::Nil), size: 0 }
}

///|
fn[K : Hash] index_for(key : K, cap : Int) -> Int {
  let m = key.hash() % cap
  if m < 0 {
    m + cap
  } else {
    m
  }
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn[K : Eq, V] bucket_get(bucket : Bucket[K, V], key : K) -> V? {
  for cur = bucket, scanned = 0 {
    match cur {
      Bucket::Nil => break None
      Bucket::Cons(key=k, value=v, tail=t) =>
        if k == key {
          break Some(v)
        } else {
          continue t, scanned + 1
        }
    }
  } where {
    invariant: scanned >= 0 && scanned + bucket_size(cur) == bucket_size(bucket),
    reasoning: (
      #|INVARIANT (Bucket scan):
      #|cur is the unscanned suffix; any match must appear in cur.
      #|MAINTENANCE:
      #|Advance to tail when key does not match.
      #|TERMINATION:
      #|At Nil, the key is absent; otherwise return its value.
    ),
  }
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn[K : Eq, V] bucket_insert(
  bucket : Bucket[K, V],
  key : K,
  value : V,
) -> (Bucket[K, V], Bool) {
  for cur = bucket, rev = Bucket::Nil {
    match cur {
      Bucket::Nil => {
        let updated = Bucket::Cons(key~, value~, tail=Bucket::Nil)
        break (reverse_append(rev, updated), true)
      }
      Bucket::Cons(key=k, value=v, tail=t) =>
        if k == key {
          let updated = Bucket::Cons(key~, value~, tail=t)
          break (reverse_append(rev, updated), false)
        } else {
          continue t, Bucket::Cons(key=k, value=v, tail=rev)
        }
    }
  } where {
    invariant: bucket_size(rev) + bucket_size(cur) == bucket_size(bucket),
    invariant: bucket_no_key(rev, key),
    reasoning: (
      #|INVARIANT (Bucket rebuild):
      #|rev is the reversed prefix with no matching key; cur is the remainder.
      #|MAINTENANCE:
      #|Move one node to rev when the key does not match.
      #|TERMINATION:
      #|Reconstruct the bucket with an inserted or updated node.
    ),
  }
}

///|
/// Return the number of entries in the map.
pub fn[K, V] size(map : HashMap[K, V]) -> Int {
  map.size
}

///|
/// Return the number of buckets in the map.
pub fn[K, V] capacity(map : HashMap[K, V]) -> Int {
  map.buckets.length()
}

///|
/// Lookup key and return its value if present.
pub fn[K : Hash + Eq, V] get(map : HashMap[K, V], key : K) -> V? {
  let idx = index_for(key, map.buckets.length())
  bucket_get(map.buckets[idx], key)
}

///|
/// Insert or update a key/value pair and return the new map.
pub fn[K : Hash + Eq, V] put(
  map : HashMap[K, V],
  key : K,
  value : V,
) -> HashMap[K, V] {
  let idx = index_for(key, map.buckets.length())
  let bucket = map.buckets[idx]
  let (new_bucket, added) = bucket_insert(bucket, key, value)
  let new_buckets = map.buckets.copy()
  new_buckets[idx] = new_bucket
  let new_size = if added { map.size + 1 } else { map.size }
  { buckets: new_buckets, size: new_size }
}
