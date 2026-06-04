// ============================================================================
// RUN-LENGTH ENCODING (RLE)
// ============================================================================
//
// PROBLEM
//
// Replace each maximal "run" of identical consecutive elements by a
// `(value, count)` pair. Reverses to recover the original sequence.
//
// Useful as a building block in lossless compression (PCX, BMP/RLE,
// ITU-T fax encoding) and as a quick way to compress sparse-pattern
// data.
//
// COMPLEXITY
//
//   encode : O(n)
//   decode : O(total decoded length)
//
// THE INVARIANT
//
//   "After processing element i, the encoded array's last pair
//    (v, c) describes a contiguous run ending at index i with
//    arr[i - c + 1 .. i] all equal to v."

///|
/// Encode a sequence as a sequence of `(value, count)` pairs.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let arr = "aaabbbccdaa".to_array().map(c => c.to_int())
///   let rle = @run_length_encoding.encode(arr)
///   @debug.assert_eq(rle.length(), 5)
/// }
/// ```
pub fn encode(arr : Array[Int]) -> Array[(Int, Int)] {
  let res : Array[(Int, Int)] = []
  let n = arr.length()
  if n == 0 {
    return res
  }
  let mut prev = arr[0]
  let mut count = 1
  for i in 1..<n {
    if arr[i] == prev {
      count = count + 1
    } else {
      res.push((prev, count))
      prev = arr[i]
      count = 1
    }
  }
  res.push((prev, count))
  res
}

///|
/// Decode an RLE pair list back to the original sequence.
pub fn decode(rle : Array[(Int, Int)]) -> Array[Int] {
  let res : Array[Int] = []
  for p in rle {
    let (v, c) = p
    for _ in 0..<c {
      res.push(v)
    }
  }
  res
}

///|
/// Length of the original sequence given its RLE.
pub fn decoded_length(rle : Array[(Int, Int)]) -> Int {
  let mut total = 0
  for p in rle {
    total = total + p.1
  }
  total
}

///|
/// Encode into a single packed `Int64` stream where each pair becomes
/// two `Int64` values `(value, count)`. Convenient when you want a flat
/// representation for further serialisation.
pub fn encode_flat(arr : Array[Int]) -> Array[Int64] {
  let pairs = encode(arr)
  let out = Array::make(pairs.length() * 2, 0L)
  for i in 0..<pairs.length() {
    out[2 * i] = pairs[i].0.to_int64()
    out[2 * i + 1] = pairs[i].1.to_int64()
  }
  out
}

///|
/// Decode a flat `Array[Int64]` produced by `encode_flat`.
pub fn decode_flat(flat : Array[Int64]) -> Array[Int] {
  let res : Array[Int] = []
  let mut i = 0
  while i + 1 < flat.length() {
    let v = flat[i].to_int()
    let c = flat[i + 1].to_int()
    for _ in 0..<c {
      res.push(v)
    }
    i = i + 2
  }
  res
}

///|
fn s(str : String) -> Array[Int] {
  let r : Array[Int] = []
  for c in str {
    r.push(c.to_int())
  }
  r
}

///|
test "encode basic" {
  let arr = s("aaabbbccdaa")
  let rle = encode(arr)
  // Expect pairs ('a', 3), ('b', 3), ('c', 2), ('d', 1), ('a', 2).
  @debug.assert_eq(rle.length(), 5)
  @debug.assert_eq(rle[0].1, 3)
  @debug.assert_eq(rle[1].1, 3)
  @debug.assert_eq(rle[2].1, 2)
  @debug.assert_eq(rle[3].1, 1)
  @debug.assert_eq(rle[4].1, 2)
}

///|
test "encode no repeats" {
  let arr = s("abcdef")
  let rle = encode(arr)
  @debug.assert_eq(rle.length(), 6)
  for p in rle {
    @debug.assert_eq(p.1, 1)
  }
}

///|
test "encode empty" {
  let rle : Array[(Int, Int)] = encode([])
  @debug.assert_eq(rle, [])
}

///|
test "encode single value" {
  let arr = Array::make(100, 7)
  let rle = encode(arr)
  @debug.assert_eq(rle.length(), 1)
  @debug.assert_eq(rle[0], (7, 100))
}

///|
test "decode roundtrip" {
  let cases : ReadOnlyArray[String] = [
    "aaabbbccdaa", "", "abcdef", "aaaaaaa", "ababab", "WWWWWBWWBBBB",
  ]
  for c in cases {
    let arr = s(c)
    let rle = encode(arr)
    @debug.assert_eq(decode(rle), arr)
  }
}

///|
test "flat encode decode roundtrip" {
  let arr = s("hello world!!")
  let flat = encode_flat(arr)
  @debug.assert_eq(decode_flat(flat), arr)
}

///|
test "decoded_length matches" {
  for c in [s("aaabbbccdaa"), s("abcdef"), s("")] {
    let rle = encode(c)
    @debug.assert_eq(decoded_length(rle), c.length())
  }
}
