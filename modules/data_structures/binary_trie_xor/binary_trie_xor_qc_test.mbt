// Property-based tests for `BinaryTrie`: insert / remove / max_xor / min_xor
// are replayed against an `Array[Int64]` multiset model, for values in the
// documented domain `[0, 2^(max_bits + 1))`. An empty trie answers 0.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
priv enum Op {
  Insert(Int64)
  Remove(Int64)
  MaxXor(Int64)
  MinXor(Int64)
} derive(Debug)

///|
impl @quickcheck.Shrink for Op

///|
priv struct Case {
  max_bits : Int
  ops : Array[Op]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Case with fn arbitrary(size, rs) {
  let max_bits = match rint(rs, 0, 4) {
    0 => 62
    _ => rint(rs, 0, 6)
  }
  let v = () => {
    let limit = 1UL << (max_bits + 1)
    // Mix uniform values with the domain's extremes.
    match rint(rs, 0, 5) {
      0 => 0L
      1 => (limit - 1UL).reinterpret_as_int64()
      _ => rs.next_uint64(limit~).reinterpret_as_int64()
    }
  }
  let ops = Array::makei(rint(rs, 0, size), _ => {
    match rint(rs, 0, 5) {
      0 | 1 => Insert(v())
      2 => Remove(v())
      3 => MaxXor(v())
      _ => MinXor(v())
    }
  })
  { max_bits, ops, }
}

///|
impl @quickcheck.Shrink for Case with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.ops).map(ops => { ..self, ops, })
}

///|
fn run_case(c : Case) -> Bool {
  let t = @binary_trie_xor.BinaryTrie(c.max_bits)
  let model : Array[Int64] = []
  let best = (x : Int64, better : (Int64, Int64) -> Bool) => {
    let mut acc = model[0] ^ x
    for y in model {
      if better(y ^ x, acc) {
        acc = y ^ x
      }
    }
    acc
  }
  for op in c.ops {
    match op {
      Insert(x) => {
        t.insert(x)
        model.push(x)
      }
      Remove(x) => {
        let expected = match model.search(x) {
          Some(i) => {
            model.remove(i) |> ignore
            true
          }
          None => false
        }
        if t.remove(x) != expected {
          return false
        }
      }
      MaxXor(x) => {
        let expected = if model.length() == 0 {
          0L
        } else {
          best(x, (a, b) => a > b)
        }
        if t.max_xor(x) != expected {
          return false
        }
      }
      MinXor(x) => {
        let expected = if model.length() == 0 {
          0L
        } else {
          best(x, (a, b) => a < b)
        }
        if t.min_xor(x) != expected {
          return false
        }
      }
    }
    if t.size() != model.length() {
      return false
    }
  }
  true
}

///|
test "qc: binary trie agrees with multiset model" {
  @quickcheck.check(run_case, seed=0xB17_0001, count=300, observe=c => {
    [
      @quickcheck.classify(c.max_bits == 62, "max_bits = 62"),
      @quickcheck.classify(
        c.ops.iter().any(op => op is Remove(_)) &&
        c.ops.iter().any(op => op is MinXor(_)),
        "remove and min_xor",
      ),
    ]
  })
}
