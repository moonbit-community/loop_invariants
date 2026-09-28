// Property-based tests for distinct-subsequence counting against brute-force
// enumeration of all index subsets (n <= 12, tiny alphabets plus extremes).

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
fn letter(rs : @quickcheck.RandomState, k : Int) -> Int {
  if rint(rs, 0, 15) == 0 {
    [-2147483648, 2147483647][rint(rs, 0, 1)]
  } else {
    rint(rs, 0, k - 1)
  }
}

///|
/// `s` of length <= 12 and `t` of length <= 4 over an alphabet of 1-3
/// letters; `t` is often an actual subsequence of `s`.
priv struct Case {
  s : Array[Int]
  t : Array[Int]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Case with fn arbitrary(_, rs) {
  let k = rint(rs, 1, 3)
  let s = Array::makei(rint(rs, 0, 12), _ => letter(rs, k))
  let t = if s.length() > 0 && rint(rs, 0, 1) == 0 {
    let t : Array[Int] = []
    for x in s {
      if t.length() < 4 && rint(rs, 0, 2) == 0 {
        t.push(x)
      }
    }
    t
  } else {
    Array::makei(rint(rs, 0, 4), _ => letter(rs, k))
  }
  { s, t, }
}

///|
impl @quickcheck.Shrink for Case with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.s, self.t)).map(p => {
    s: p.0,
    t: if p.1.length() > 4 {
      p.1[:4].to_owned()
    } else {
      p.1
    },
  })
}

///|
fn subseq(s : Array[Int], mask : Int) -> Array[Int] {
  let out : Array[Int] = []
  for i in 0..<s.length() {
    if ((mask >> i) & 1) == 1 {
      out.push(s[i])
    }
  }
  out
}

///|
fn ref_equal_target(s : Array[Int], t : Array[Int]) -> Int64 {
  let mut c = 0L
  for mask in 0..<(1 << s.length()) {
    if subseq(s, mask) == t {
      c = c + 1L
    }
  }
  c
}

///|
fn ref_all_distinct(s : Array[Int]) -> Int64 {
  let seen : Map[String, Unit] = Map([])
  for mask in 1..<(1 << s.length()) {
    let key = StringBuilder()
    for x in subseq(s, mask) {
      key.write_string(x.to_string())
      key.write_char(',')
    }
    seen[key.to_string()] = ()
  }
  seen.length().to_int64()
}

///|
test "qc: count_equal_target counts matching index subsets" {
  @quickcheck.check(
    (c : Case) => {
      @distinct_subsequences.count_equal_target(c.s, c.t) ==
      ref_equal_target(c.s, c.t)
    },
    count=300,
    max_shrinks=1000,
    seed=301,
    observe=c => {
      let r = ref_equal_target(c.s, c.t)
      [
        @quickcheck.classify(c.t.length() == 0, "empty target"),
        @quickcheck.classify(r == 0L, "no occurrence"),
        @quickcheck.classify(r >= 3L, ">= 3 occurrences"),
        @quickcheck.classify(c.s.length() < c.t.length(), "|s| < |t|"),
      ]
    },
  )
}

///|
test "qc: count_all_subseq counts distinct non-empty subsequences" {
  @quickcheck.check(
    (c : Case) => {
      @distinct_subsequences.count_all_subseq(c.s) == ref_all_distinct(c.s)
    },
    count=300,
    max_shrinks=1000,
    seed=302,
    observe=c => [@quickcheck.collect(c.s.length() / 4 * 4)],
  )
}
