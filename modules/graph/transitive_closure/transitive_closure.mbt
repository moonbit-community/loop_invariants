// ============================================================================
// TRANSITIVE CLOSURE  -  Warshall 1962
// ============================================================================
//
// PROBLEM
//
// Given a directed graph `G = (V, E)`, compute the **reachability
// relation**: the boolean matrix `R[i][j] = true` iff there is a
// directed path from `i` to `j`.
//
// THE DP (Warshall's algorithm, dual of Floyd's APSP)
//
//   R[i][j] = R[i][j] OR (R[i][k] AND R[k][j])     for every k = 1..n
//
// in place. Runs in `O(n^3)` boolean operations, which is exactly the
// boolean cost of Floyd-Warshall.
//
// COMPLEXITY
//
//   Time : O(n^3) boolean OPs
//   Space: O(n^2) for the matrix
//
// BIT-PACKING
//
// On a machine with `W`-bit words, packing rows reduces the inner loop
// to `O(n / W)` bit operations per `(i, k)` pair, yielding
// `O(n^3 / W)`. We provide a 64-bit-packed implementation too.
//
// THE INVARIANT
//
//   "After iteration k of the outer loop, R[i][j] = true iff a path
//    from i to j exists using only intermediates in {0, ..., k}."

///|
/// Transitive closure of an adjacency matrix.
/// `adj[i][j] = true` iff `(i, j)` is an edge. Reflexive closure
/// (paths of length 0 allowed) is *not* added unless `adj[i][i]` was
/// already true.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // 0 -> 1 -> 2: reachability matrix marks 0->2 reachable.
///   let adj = [[false, true, false], [false, false, true], [false, false, false]]
///   let r = @transitive_closure.closure(adj)
///   @debug.assert_eq(r[0][2], true)
/// }
/// ```
pub fn closure(adj : Array[Array[Bool]]) -> Array[Array[Bool]] {
  let n = adj.length()
  let r = Array::makei(n, i => Array::makei(n, j => adj[i][j]))
  for k in 0..<n {
    for i in 0..<n {
      if r[i][k] {
        for j in 0..<n {
          if r[k][j] && !r[i][j] {
            r[i][j] = true
          }
        }
      }
    }
  }
  r
}

///|
/// Bit-packed transitive closure. Each row is stored as a packed
/// `Array[Int64]` with bit `j` of word `j / 64` representing whether
/// `(i, j)` is reachable. Total cost `O(n^3 / 64)`.
///
/// `adj_rows[i]` must have at least `(n + 63) / 64` words, with bit `j`
/// of the right word giving the edge `(i, j)`. Returns the closure in
/// the same packed format.
pub fn closure_bitpacked(
  n : Int,
  adj_rows : Array[Array[Int64]],
) -> Array[Array[Int64]] {
  let words = (n + 63) / 64
  let r = Array::makei(n, i => {
    let row = Array::make(words, 0L)
    for w in 0..<words {
      row[w] = adj_rows[i][w]
    }
    row
  })
  for k in 0..<n {
    let kw = k / 64
    let kb = k % 64
    for i in 0..<n {
      if ((r[i][kw] >> kb) & 1L) == 1L {
        for w in 0..<words {
          r[i][w] = r[i][w] | r[k][w]
        }
      }
    }
  }
  r
}

///|
/// Convert an `Array[Array[Bool]]` adjacency matrix into the bit-packed
/// row layout used by `closure_bitpacked`.
pub fn pack_rows(adj : Array[Array[Bool]]) -> Array[Array[Int64]] {
  let n = adj.length()
  let words = (n + 63) / 64
  Array::makei(n, i => {
    let row = Array::make(words, 0L)
    for j in 0..<n {
      if adj[i][j] {
        row[j / 64] = row[j / 64] | (1L << (j % 64))
      }
    }
    row
  })
}

///|
/// Reverse of `pack_rows`.
pub fn unpack_rows(n : Int, packed : Array[Array[Int64]]) -> Array[Array[Bool]] {
  Array::makei(n, i => {
    Array::makei(n, j => ((packed[i][j / 64] >> (j % 64)) & 1L) == 1L)
  })
}

///|
test "closure path graph" {
  // 0 -> 1 -> 2 -> 3
  let adj = [
    [false, true, false, false],
    [false, false, true, false],
    [false, false, false, true],
    [false, false, false, false],
  ]
  let r = closure(adj)
  // All pairs (i, j) with i < j should be reachable.
  for i in 0..<4 {
    for j in 0..<4 {
      @debug.assert_eq(r[i][j], i < j)
    }
  }
}

///|
test "closure cycle is strongly connected" {
  // 0 -> 1 -> 2 -> 0
  let adj = [[false, true, false], [false, false, true], [true, false, false]]
  let r = closure(adj)
  for i in 0..<3 {
    for j in 0..<3 {
      @debug.assert_eq(r[i][j], true)
    }
  }
}

///|
test "closure self loops preserved if present" {
  let adj = [[true, false], [false, false]]
  let r = closure(adj)
  @debug.assert_eq(r[0][0], true)
  @debug.assert_eq(r[1][1], false) // no path from 1 to itself
}

///|
test "closure empty graph" {
  let r : Array[Array[Bool]] = closure([])
  @debug.assert_eq(r.length(), 0)
}

///|
test "closure disconnected components" {
  // {0 -> 1} and {2 -> 3}: no cross-reachability.
  let adj = [
    [false, true, false, false],
    [false, false, false, false],
    [false, false, false, true],
    [false, false, false, false],
  ]
  let r = closure(adj)
  @debug.assert_eq(r[0][3], false)
  @debug.assert_eq(r[2][1], false)
  @debug.assert_eq(r[0][1], true)
  @debug.assert_eq(r[2][3], true)
}

///|
test "closure bitpacked matches naive" {
  let adj = [
    [false, true, false, false, false],
    [false, false, true, false, false],
    [false, false, false, true, true],
    [false, false, false, false, false],
    [false, false, false, false, false],
  ]
  let naive = closure(adj)
  let packed_in = pack_rows(adj)
  let packed_out = closure_bitpacked(5, packed_in)
  let result = unpack_rows(5, packed_out)
  for i in 0..<5 {
    for j in 0..<5 {
      @debug.assert_eq(result[i][j], naive[i][j])
    }
  }
}

///|
test "closure transitive property" {
  // If R[i][j] and R[j][k] then R[i][k].
  let adj = [
    [false, true, false, false],
    [false, false, true, false],
    [false, false, false, true],
    [true, false, false, false],
  ]
  let r = closure(adj)
  for i in 0..<4 {
    for j in 0..<4 {
      for k in 0..<4 {
        if r[i][j] && r[j][k] {
          @debug.assert_eq(r[i][k], true)
        }
      }
    }
  }
}
