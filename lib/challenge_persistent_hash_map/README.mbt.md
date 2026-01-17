# Challenge: Persistent Hash Map

A **persistent hash map** stores key/value pairs and returns a new map after
updates, while old versions stay valid. This implementation uses a fixed array
of buckets, where each bucket is an immutable linked list.

This package provides:

- `make(capacity)` to create a map with a fixed number of buckets
- `get(map, key)` to look up a key
- `put(map, key, value)` to insert or update a key
- `size(map)` to count entries
- `capacity(map)` to read bucket count

---

## Hash map basics

A hash map stores items in buckets chosen by a hash:

```
index = hash(key) mod capacity
```

If multiple keys land in the same bucket, we keep them in a small list:

```
Bucket 0: (k1 -> v1) -> (k2 -> v2)
Bucket 1: empty
Bucket 2: (k3 -> v3)
```

This is called **separate chaining**.

---

## Persistence (path copying)

When you `put` a key:

- Only the **bucket list** for that key is rebuilt.
- All other buckets are shared with the old version.

```
Old map:                     New map:

b0 -> list A                 b0 -> list A'   (rebuilt)
b1 -> list B        put      b1 -> list B    (shared)
b2 -> list C                 b2 -> list C    (shared)
```

Because buckets are immutable lists, rebuilding a bucket just copies the nodes
along the path and reuses the rest.

---

## Updating vs inserting

- If the key already exists, its value is updated and `size` stays the same.
- If the key is new, a node is added and `size` increases by 1.

Duplicates are ignored beyond updating the stored value.

---

## Capacity and performance

This implementation **does not resize**. The capacity you pass to `make` is
fixed, so choose it based on expected size.

- Average `get` and `put` are **O(1)** with a good hash and reasonable load.
- Worst-case is **O(n)** if many keys collide into one bucket.

---

## Reference implementation

```mbt
///| pub fn[K, V] make(capacity : Int) -> HashMap[K, V]

///| pub fn[K : Hash + Eq, V] get(map : HashMap[K, V], key : K) -> V?

///| pub fn[K : Hash + Eq, V] put(map : HashMap[K, V], key : K, value : V) -> HashMap[K, V]

///| pub fn[K, V] size(map : HashMap[K, V]) -> Int

///| pub fn[K, V] capacity(map : HashMap[K, V]) -> Int
```

---

## Tests and examples

### Basic usage

```mbt check
///|
test "persistent hash map" {
  let map0 = @challenge_persistent_hash_map.make(4)
  let map1 = @challenge_persistent_hash_map.put(map0, 1, 10)
  let map2 = @challenge_persistent_hash_map.put(map1, 5, 50)
  let map3 = @challenge_persistent_hash_map.put(map2, 1, 11)
  inspect(@challenge_persistent_hash_map.get(map3, 1), content="Some(11)")
  inspect(@challenge_persistent_hash_map.get(map3, 5), content="Some(50)")
  inspect(@challenge_persistent_hash_map.get(map1, 5), content="None")
  inspect(@challenge_persistent_hash_map.size(map3), content="2")
}
```

### Collisions in a small table

```mbt check
///|
test "persistent hash map collisions" {
  let map0 = @challenge_persistent_hash_map.make(1)
  let map1 = @challenge_persistent_hash_map.put(map0, 2, 20)
  let map2 = @challenge_persistent_hash_map.put(map1, 4, 40)
  let map3 = @challenge_persistent_hash_map.put(map2, 6, 60)
  inspect(@challenge_persistent_hash_map.get(map3, 4), content="Some(40)")
  inspect(@challenge_persistent_hash_map.size(map3), content="3")
}
```

### Updating a value does not change size

```mbt check
///|
test "persistent hash map update" {
  let map0 = @challenge_persistent_hash_map.make(2)
  let map1 = @challenge_persistent_hash_map.put(map0, 7, 70)
  let map2 = @challenge_persistent_hash_map.put(map1, 7, 71)
  inspect(@challenge_persistent_hash_map.get(map2, 7), content="Some(71)")
  inspect(@challenge_persistent_hash_map.size(map2), content="1")
}
```

---

## Complexity

Let `n` be the number of items, `b` the number of buckets, and `L` the bucket
length for a key.

- `get`: `O(L)`
- `put`: `O(L)` (rebuilds the bucket list)
- Average `L` is small when the hash function spreads keys well.

---

## Takeaways

- A persistent hash map rebuilds only one bucket per update.
- Collisions are handled with immutable linked lists.
- Fixed capacity means performance depends on the load factor.
