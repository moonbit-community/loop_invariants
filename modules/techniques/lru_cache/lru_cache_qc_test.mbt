// Model-based property tests for `LruCache`: random `put` / `get` /
// `contains` sequences are replayed against a naive most-recent-first list.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Keys from a tiny range so hits, updates and evictions are all common, plus
/// occasional `Int64` extrema.
fn gen_key(rs : @quickcheck.RandomState) -> Int64 {
  match rint(rs, 0, 9) {
    0 => [9223372036854775807L, -9223372036854775808L][rint(rs, 0, 1)]
    _ => rint(rs, 0, 5).to_int64()
  }
}

///|
priv enum Op {
  Put(Int64, Int64)
  Get(Int64)
  Contains(Int64)
} derive(Debug)

///|
impl @quickcheck.Shrink for Op

///|
priv struct Script {
  capacity : Int
  ops : Array[Op]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Script with fn arbitrary(size, rs) {
  let capacity = [-1, 0, 1, 1, 2, 3, 4, 6][rint(rs, 0, 7)]
  let ops = Array::makei(rint(rs, 0, size), _ => {
    match rint(rs, 0, 4) {
      0 | 1 => Put(gen_key(rs), rint(rs, -100, 100).to_int64())
      2 | 3 => Get(gen_key(rs))
      _ => Contains(gen_key(rs))
    }
  })
  { capacity, ops, }
}

///|
impl @quickcheck.Shrink for Script with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.ops).map(ops => { ..self, ops, })
}

///|
/// Naive model: entries most-recent first.
priv struct Model {
  cap : Int
  entries : Array[(Int64, Int64)]
}

///|
fn Model::find(self : Model, k : Int64) -> Int? {
  for i, e in self.entries {
    if e.0 == k {
      return Some(i)
    }
  }
  None
}

///|
fn Model::get(self : Model, k : Int64) -> Int64? {
  match self.find(k) {
    None => None
    Some(i) => {
      let e = self.entries.remove(i)
      self.entries.insert(0, e)
      Some(e.1)
    }
  }
}

///|
fn Model::put(self : Model, k : Int64, v : Int64) -> Unit {
  match self.find(k) {
    Some(i) => self.entries.remove(i) |> ignore
    None => ()
  }
  self.entries.insert(0, (k, v))
  if self.entries.length() > self.cap {
    self.entries.pop() |> ignore
  }
}

///|
fn run_script(s : Script) -> Bool {
  let c = @lru_cache.new(s.capacity)
  let m : Model = {
    cap: if s.capacity < 1 {
      1
    } else {
      s.capacity
    },
    entries: [],
  }
  if c.cap() != m.cap {
    return false
  }
  for op in s.ops {
    match op {
      Put(k, v) => {
        c.put(k, v)
        m.put(k, v)
      }
      Get(k) => if c.get(k) != m.get(k) { return false }
      Contains(k) => if c.contains(k) != (m.find(k) is Some(_)) { return false }
    }
    if c.length() != m.entries.length() ||
      c.keys_mru() != m.entries.map(e => e.0) {
      return false
    }
  }
  true
}

///|
test "qc: LruCache behaves like a most-recent-first list model" {
  @quickcheck.check(
    run_script,
    count=500,
    max_size=60,
    max_shrinks=2000,
    seed=61,
    observe=s => {
      let cap = if s.capacity < 1 { 1 } else { s.capacity }
      // Count evictions in the model.
      let m : Model = { cap, entries: [], }
      let mut evictions = 0
      for op in s.ops {
        if op is Put(k, v) {
          if m.find(k) is None && m.entries.length() == cap {
            evictions = evictions + 1
          }
          m.put(k, v)
        }
      }
      [
        @quickcheck.classify(s.capacity < 1, "capacity <= 0 (clamped to 1)"),
        @quickcheck.classify(evictions > 0, "some eviction"),
        @quickcheck.classify(evictions >= 5, ">= 5 evictions"),
      ]
    },
  )
}

///|
test "qc: contains does not change recency" {
  @quickcheck.check(
    (s : Script) => {
      let c = @lru_cache.new(s.capacity)
      for op in s.ops {
        match op {
          Put(k, v) => c.put(k, v)
          Get(k) => c.get(k) |> ignore
          Contains(k) => {
            let before = c.keys_mru()
            c.contains(k) |> ignore
            if c.keys_mru() != before {
              return false
            }
          }
        }
      }
      true
    },
    seed=62,
  )
}
