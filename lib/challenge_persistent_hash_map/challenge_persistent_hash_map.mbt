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
fn[K : Eq, V] bucket_get(bucket : Bucket[K, V], key : K) -> V? {
  match bucket {
    Bucket::Nil => None
    Bucket::Cons(key=k, value=v, tail=t) =>
      if k == key {
        Some(v)
      } else {
        bucket_get(t, key)
      }
  }
}

///|
fn[K : Eq, V] bucket_insert(
  bucket : Bucket[K, V],
  key : K,
  value : V,
) -> (Bucket[K, V], Bool) {
  match bucket {
    Bucket::Nil => (Bucket::Cons(key~, value~, tail=Bucket::Nil), true)
    Bucket::Cons(key=k, value=v, tail=t) =>
      if k == key {
        (Bucket::Cons(key~, value~, tail=t), false)
      } else {
        let (new_tail, added) = bucket_insert(t, key, value)
        (Bucket::Cons(key=k, value=v, tail=new_tail), added)
      }
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
