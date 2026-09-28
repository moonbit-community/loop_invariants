// Property-based tests for `ImplicitTreap` as a sequence: operation sequences
// are replayed against a plain `Array[Int64]` model. Range operations use
// half-open ranges `[l, r)`; invalid ranges give 0 / `None` / no-op, and
// out-of-bounds positions give `None` / no-op. Sums wrap like Int64.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Mostly small values (so sums are readable), sometimes full-range values and
/// the Int64 extrema.
fn gen_val(rs : @quickcheck.RandomState) -> Int64 {
  match rint(rs, 0, 9) {
    0 => @quickcheck.Arbitrary::arbitrary(0, rs)
    1 => [9223372036854775807L, -9223372036854775808L, 0L][rint(rs, 0, 2)]
    _ => rint(rs, -20, 20).to_int64()
  }
}

///|
/// Positions are stored raw and resolved against the current length at run
/// time: `raw % (len + 3) - 1`, i.e. in `[-1, len + 1]`.
priv enum Op {
  Insert(Int, Int64)
  Delete(Int)
  Get(Int)
  Set(Int, Int64)
  PushBack(Int64)
  PushFront(Int64)
  PopBack
  PopFront
  RangeSum(Int, Int)
  RangeMin(Int, Int)
  RangeMax(Int, Int)
  Reverse(Int, Int)
} derive(Debug)

///|
impl @quickcheck.Shrink for Op

///|
priv struct Case {
  init : Array[Int64]
  ops : Array[Op]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Case with fn arbitrary(size, rs) {
  let small = rint(rs, 0, 1) == 0
  let v = () => if small { rint(rs, -5, 5).to_int64() } else { gen_val(rs) }
  let p = () => rint(rs, 0, 10000)
  let init = Array::makei(rint(rs, 0, size), _ => v())
  let ops = Array::makei(rint(rs, 0, size), _ => {
    match rint(rs, 0, 13) {
      0 | 1 => Insert(p(), v())
      2 => Delete(p())
      3 => Get(p())
      4 => Set(p(), v())
      5 => PushBack(v())
      6 => PushFront(v())
      7 => PopBack
      8 => PopFront
      9 => RangeSum(p(), p())
      10 => RangeMin(p(), p())
      11 => RangeMax(p(), p())
      _ => Reverse(p(), p())
    }
  })
  { init, ops, }
}

///|
impl @quickcheck.Shrink for Case with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.init, self.ops)).map(p => {
    init: p.0,
    ops: p.1,
  })
}

///|
fn run_case(c : Case) -> Bool {
  let t = @implicit_treap.ImplicitTreap::from_array(c.init.copy())
  let model = c.init.copy()
  let pos = (raw : Int) => raw % (model.length() + 3) - 1
  let valid_range = (l : Int, r : Int) => l >= 0 && l < r && r <= model.length()
  for op in c.ops {
    match op {
      Insert(raw, x) => {
        // Only in-bounds insert positions `[0, len]` have a defined meaning.
        let i = raw % (model.length() + 1)
        t.insert(i, x)
        model.insert(i, x)
      }
      Delete(raw) => {
        let i = pos(raw)
        let expected = if i >= 0 && i < model.length() {
          Some(model.remove(i))
        } else {
          None
        }
        if t.delete(i) != expected {
          return false
        }
      }
      Get(raw) => {
        let i = pos(raw)
        let expected = if i >= 0 && i < model.length() {
          Some(model[i])
        } else {
          None
        }
        if t.get(i) != expected {
          return false
        }
      }
      Set(raw, x) => {
        let i = pos(raw)
        t.set(i, x)
        if i >= 0 && i < model.length() {
          model[i] = x
        }
      }
      PushBack(x) => {
        t.push_back(x)
        model.push(x)
      }
      PushFront(x) => {
        t.push_front(x)
        model.insert(0, x)
      }
      PopBack => if t.pop_back() != model.pop() { return false }
      PopFront => {
        let expected = if model.length() == 0 {
          None
        } else {
          Some(model.remove(0))
        }
        if t.pop_front() != expected {
          return false
        }
      }
      RangeSum(a, b) => {
        let (l, r) = (pos(a), pos(b))
        let mut s = 0L
        if valid_range(l, r) {
          for i in l..<r {
            s = s + model[i]
          }
        }
        if t.range_sum(l, r) != s {
          return false
        }
      }
      RangeMin(a, b) => {
        let (l, r) = (pos(a), pos(b))
        let expected = if valid_range(l, r) {
          Some(
            model[l:r]
            .iter()
            .fold(init=model[l], (m, x) => if x < m { x } else { m }),
          )
        } else {
          None
        }
        if t.range_min(l, r) != expected {
          return false
        }
      }
      RangeMax(a, b) => {
        let (l, r) = (pos(a), pos(b))
        let expected = if valid_range(l, r) {
          Some(
            model[l:r]
            .iter()
            .fold(init=model[l], (m, x) => if x > m { x } else { m }),
          )
        } else {
          None
        }
        if t.range_max(l, r) != expected {
          return false
        }
      }
      Reverse(a, b) => {
        let (l, r) = (pos(a), pos(b))
        t.reverse(l, r)
        if valid_range(l, r) {
          for i = l, j = r - 1; i < j; i = i + 1, j = j - 1 {
            let tmp = model[i]
            model[i] = model[j]
            model[j] = tmp
          }
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
test "qc: implicit treap agrees with array model" {
  @quickcheck.check(run_case, seed=0x1AA_7EA9, count=300, observe=c => {
    let reverses = c.ops.iter().filter(op => op is Reverse(_, _)).count()
    [
      @quickcheck.classify(reverses >= 2, ">= 2 reverses"),
      @quickcheck.classify(c.init.length() >= 20, "initial length >= 20"),
      @quickcheck.classify(
        c.init
        .iter()
        .any(x => x == -9223372036854775808L || x == 9223372036854775807L),
        "initial Int64 extremum",
      ),
    ]
  })
}

///|
/// The empty-subtree identity for `max` was `-9223372036854775807`
/// (Int64::MIN + 1), so a range whose maximum is Int64::MIN reported MIN + 1.
test "regression: implicit treap range_max of Int64::MIN" {
  let t = @implicit_treap.ImplicitTreap::from_array([
    -9223372036854775808L, -9223372036854775808L,
  ])
  debug_inspect(t.range_max(0, 1), content="Some(-9223372036854775808)")
  debug_inspect(t.range_max(0, 2), content="Some(-9223372036854775808)")
  debug_inspect(t.range_min(0, 2), content="Some(-9223372036854775808)")
}
