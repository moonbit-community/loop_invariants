// Property-based tests for `Treap[Int]` as a sorted multiset: operation
// sequences are replayed against a sorted `Array[Int]` model (duplicates
// allowed, `delete` removes one copy, `kth_element` is 0-indexed).

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Keys from a narrow range (many duplicates) with occasional Int extrema.
fn gen_key(rs : @quickcheck.RandomState) -> Int {
  match rint(rs, 0, 15) {
    0 => [2147483647, -2147483648][rint(rs, 0, 1)]
    _ => rint(rs, -8, 8)
  }
}

///|
priv enum Op {
  Insert(Int)
  Delete(Int)
  Contains(Int)
  Kth(Int)
  CountLess(Int)
  MinMax
} derive(Debug)

///|
impl @quickcheck.Shrink for Op

///|
priv struct Ops(Array[Op]) derive(Debug)

///|
impl @quickcheck.Arbitrary for Ops with fn arbitrary(size, rs) {
  Ops(
    Array::makei(rint(rs, 0, size * 2), _ => {
      match rint(rs, 0, 7) {
        0 | 1 | 2 => Insert(gen_key(rs))
        3 => Delete(gen_key(rs))
        4 => Contains(gen_key(rs))
        5 => Kth(rint(rs, -2, 20))
        6 => CountLess(gen_key(rs))
        _ => MinMax
      }
    }),
  )
}

///|
impl @quickcheck.Shrink for Ops with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).map(x => Ops(x))
}

///|
fn run_ops(ops : Ops) -> Bool {
  let t : @treap.Treap[Int] = Treap()
  let model : Array[Int] = []
  for op in ops.0 {
    match op {
      Insert(k) => {
        t.insert(k)
        model.push(k)
        model.sort()
      }
      Delete(k) => {
        let expected = match model.search(k) {
          Some(i) => {
            model.remove(i) |> ignore
            true
          }
          None => false
        }
        if t.delete(k) != expected {
          return false
        }
      }
      Contains(k) => if t.contains(k) != model.contains(k) { return false }
      Kth(i) => {
        let expected = if i >= 0 && i < model.length() {
          Some(model[i])
        } else {
          None
        }
        if t.kth_element(i) != expected {
          return false
        }
      }
      CountLess(k) =>
        if t.count_less_than(k) != model.iter().filter(x => x < k).count() {
          return false
        }
      MinMax => {
        let n = model.length()
        let (mn, mx) = if n == 0 {
          (None, None)
        } else {
          (Some(model[0]), Some(model[n - 1]))
        }
        if t.min() != mn || t.max() != mx {
          return false
        }
      }
    }
    if t.size() != model.length() {
      return false
    }
  }
  t.to_array() == model
}

///|
test "qc: treap agrees with sorted multiset model" {
  @quickcheck.check(run_ops, seed=0x7EA_0001, count=300, observe=ops => {
    let model : Map[Int, Int] = Map([])
    let mut dup = false
    let mut del_hit = false
    for op in ops.0 {
      match op {
        Insert(k) => {
          let c = model.get_or_default(k, 0)
          dup = dup || c > 0
          model[k] = c + 1
        }
        Delete(k) =>
          if model.get_or_default(k, 0) > 0 {
            del_hit = true
            model[k] = model.get_or_default(k, 0) - 1
          }
        _ => ()
      }
    }
    [
      @quickcheck.classify(dup, "duplicate insert"),
      @quickcheck.classify(del_hit, "successful delete"),
      @quickcheck.classify(ops.0.length() == 0, "no ops"),
    ]
  })
}
