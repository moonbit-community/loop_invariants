// ============================================================================
// Challenge: Floyd-Warshall (All-Pairs Shortest Paths)
// ============================================================================

///|
/// Compute all-pairs shortest paths for a weighted graph.
/// matrix[i][j] is edge weight or inf if no edge.
pub fn floyd_warshall(
  matrix : Array[Array[Int]],
  inf : Int,
) -> Array[Array[Int]] {
  let n = matrix.length()
  let dist = matrix.map(row => row.copy())
  for k in 0..<n {
    for i in 0..<n {
      for j in 0..<n {
        let dik = dist[i][k]
        let dkj = dist[k][j]
        if dik < inf && dkj < inf {
          let via = dik + dkj
          if via < dist[i][j] {
            dist[i][j] = via
          }
        }
      }
    }
  }
  dist
}

///|
test "floyd_warshall" {
  let inf = 1_000_000_000
  let matrix : Array[Array[Int]] = [
    [0, 1, 10, inf],
    [inf, 0, 2, inf],
    [inf, inf, 0, 3],
    [inf, inf, inf, 0],
  ]
  let dist = floyd_warshall(matrix, inf)
  assert_eq(dist[0][2], 3)
  assert_eq(dist[0][3], 6)
  assert_eq(dist[1][3], 5)
}
