// ============================================================================
// Challenge: BFS on Grid (Shortest Path)
// ============================================================================

///|
/// Compute shortest path length in a grid with 4-direction moves.
/// grid cells: 0 = open, 1 = blocked.
#warnings("+missing_invariant+missing_reasoning")
pub fn shortest_path_grid(
  grid : Array[Array[Int]],
  sx : Int,
  sy : Int,
  tx : Int,
  ty : Int,
) -> Int? {
  let n = grid.length()
  guard n > 0 else { return None }
  let m = grid[0].length()
  guard sx >= 0 && sx < n && sy >= 0 && sy < m else { return None }
  guard tx >= 0 && tx < n && ty >= 0 && ty < m else { return None }
  if grid[sx][sy] != 0 || grid[tx][ty] != 0 {
    return None
  }
  let dist : Array[Array[Int]] = Array::makei(n, _ => Array::make(m, -1))
  let queue : Array[(Int, Int)] = []
  dist[sx][sy] = 0
  queue.push((sx, sy))
  let dx : Array[Int] = [1, -1, 0, 0]
  let dy : Array[Int] = [0, 0, 1, -1]
  for head = 0; head < queue.length(); head = head + 1 {
    let (x, y) = queue[head]
    for d = 0; d < 4; d = d + 1 {
      let nx = x + dx[d]
      let ny = y + dy[d]
      if nx >= 0 && nx < n && ny >= 0 && ny < m {
        if grid[nx][ny] == 0 && dist[nx][ny] == -1 {
          dist[nx][ny] = dist[x][y] + 1
          queue.push((nx, ny))
        }
      }
    } where {
      invariant: d >= 0 && d <= 4,
      reasoning: (
        #|INVARIANT (Neighbor scan):
        #|All directions < d have been processed for (x, y).
        #|MAINTENANCE:
        #|Check direction d and enqueue unseen open neighbors.
        #|TERMINATION:
        #|At d = 4, all neighbors of (x, y) are considered.
      ),
    }
  } where {
    invariant: head >= 0 && head <= queue.length(),
    reasoning: (
      #|INVARIANT (BFS frontier):
      #|All positions with index < head have their shortest distance finalized.
      #|MAINTENANCE:
      #|Expanding queue[head] only discovers nodes at distance +1.
      #|TERMINATION:
      #|When head reaches queue.length(), all reachable nodes are processed.
    ),
  }
  if dist[tx][ty] >= 0 {
    Some(dist[tx][ty])
  } else {
    None
  }
}

///|
test "shortest_path_grid" {
  let grid : Array[Array[Int]] = [[0, 0, 0], [1, 1, 0], [0, 0, 0]]
  assert_eq(shortest_path_grid(grid, 0, 0, 2, 2), Some(4))
  assert_eq(shortest_path_grid(grid, 0, 0, 1, 0), None)
}
