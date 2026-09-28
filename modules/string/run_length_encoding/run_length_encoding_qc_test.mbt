// Property-based tests for run-length encoding: round trips, maximality of
// the runs, and the flat encoding / decoded length helpers.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// An array built from runs, so long runs are common; symbols come from a
/// 3-letter alphabet or are arbitrary integers (including extremes).
priv struct Runs(Array[Int]) derive(Debug)

///|
impl @quickcheck.Arbitrary for Runs with fn arbitrary(size, rs) {
  let out : Array[Int] = []
  let wide = rint(rs, 0, 3) == 0
  for _ in 0..<rint(rs, 0, size) {
    let v = if wide {
      @quickcheck.Arbitrary::arbitrary(size, rs)
    } else {
      rint(rs, 0, 2)
    }
    for _ in 0..<rint(rs, 1, 5) {
      out.push(v)
    }
  }
  Runs(out)
}

///|
impl @quickcheck.Shrink for Runs with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).map(a => Runs(a))
}

///|
test "qc: decode(encode(x)) == x and the runs are maximal" {
  @quickcheck.check(
    (r : Runs) => {
      let x = r.0
      let rle = @run_length_encoding.encode(x)
      let maximal = for i in 0..<rle.length() {
        if rle[i].1 < 1 || (i > 0 && rle[i - 1].0 == rle[i].0) {
          break false
        }
      } nobreak {
        true
      }
      @run_length_encoding.decode(rle) == x &&
      maximal &&
      @run_length_encoding.decoded_length(rle) == x.length()
    },
    observe=r => {
      let rle = @run_length_encoding.encode(r.0)
      [
        @quickcheck.classify(rle.length() < r.0.length(), "compresses"),
        @quickcheck.classify(r.0.length() == 0, "empty"),
      ]
    },
    count=500,
    max_size=20,
    seed=0x71e0001,
  )
}

///|
test "qc: encode(decode(runs)) == runs for canonical run lists" {
  @quickcheck.check(
    (raw : Array[(Int, Int)]) => {
      // canonicalise: positive counts, adjacent values distinct
      let runs : Array[(Int, Int)] = []
      for p in raw {
        let v = p.0 % 4
        let c = (p.1 % 6).abs() + 1
        if runs.length() == 0 || runs[runs.length() - 1].0 != v {
          runs.push((v, c))
        }
      }
      let decoded = @run_length_encoding.decode(runs)
      @run_length_encoding.encode(decoded) == runs &&
      @run_length_encoding.decoded_length(runs) == decoded.length()
    },
    count=300,
    max_size=15,
    seed=0x71e0002,
  )
}

///|
test "qc: decode_flat(encode_flat(x)) == x and encode_flat flattens encode" {
  @quickcheck.check(
    (r : Runs) => {
      let x = r.0
      let flat = @run_length_encoding.encode_flat(x)
      let pairs = @run_length_encoding.encode(x)
      let same_layout = flat.length() == 2 * pairs.length() &&
        pairs
        .iter()
        .mapi((i, p) => {
          flat[2 * i] == p.0.to_int64() && flat[2 * i + 1] == p.1.to_int64()
        })
        .all(b => b)
      @run_length_encoding.decode_flat(flat) == x && same_layout
    },
    count=300,
    max_size=20,
    seed=0x71e0003,
  )
}
