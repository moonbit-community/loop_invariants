// ============================================================================
// Challenge: Floyd-Warshall (All-Pairs Shortest Paths)
// ============================================================================

///|
/// Compute all-pairs shortest paths for a weighted graph.
/// matrix[i][j] is edge weight or inf if no edge.
#warnings("+missing_invariant+missing_reasoning")
pub fn floyd_warshall(
  matrix : Array[Array[Int]],
  inf : Int,
) -> Array[Array[Int]] {
  let n = matrix.length()
  let dist = matrix.map(row => row.copy())
  for k = 0; k < n; k = k + 1 {
    for i = 0; i < n; i = i + 1 {
      for j = 0; j < n; j = j + 1 {
        let dik = dist[i][k]
        let dkj = dist[k][j]
        if dik < inf && dkj < inf {
          let via = dik + dkj
          if via < dist[i][j] {
            dist[i][j] = via
          }
        }
      } where {
        invariant: j >= 0 && j <= n,
        reasoning: (
          #|INVARIANT (Row update):
          #|For fixed i,k, columns < j have been relaxed through k.
          #|MAINTENANCE:
          #|Check path i -> k -> j and update dist[i][j] if shorter.
          #|TERMINATION:
          #|At j = n, row i is fully relaxed for this k.
        ),
      }
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (All rows for k):
        #|All rows < i are fully relaxed using intermediate k.
        #|MAINTENANCE:
        #|Relax row i across all columns, then advance i.
        #|TERMINATION:
        #|At i = n, all rows are relaxed for this k.
      ),
    }
  } where {
    invariant: k >= 0 && k <= n,
    reasoning: (
      #|INVARIANT (Intermediate set):
      #|After processing k, dist[i][j] is the shortest path using intermediates
      #|from the set {0..k}.
      #|MAINTENANCE:
      #|Relaxing through vertex k adds it to the allowed intermediate set.
      #|TERMINATION:
      #|At k = n, all vertices are allowed and dist is optimal.
    ),
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
