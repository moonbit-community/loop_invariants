// ============================================================================
// HUNGARIAN ALGORITHM - Assignment Problem
// ============================================================================
//
// Solves the assignment problem: Given n workers and n jobs with cost
// matrix C, find assignment minimizing total cost.
//
// KEY INSIGHT: Maintain potential function (labels) that satisfy:
// u[i] + v[j] <= cost[i][j] for all i,j
// Optimal assignment uses only tight edges (equality holds).
//
// INVARIANTS:
// 1. u[i] + v[j] <= cost[i][j] always
// 2. Current matching uses only tight edges
// 3. After n augmenting paths, we have optimal assignment
//
// TIME COMPLEXITY: O(n³)
// SPACE COMPLEXITY: O(n²)

///|
const HUNGARIAN_INF : Int = 1000000000

///|
priv struct Hungarian {
  n : Int
  cost : Array[Array[Int]]
}

///|
fn Hungarian::new(n : Int) -> Hungarian {
  let cost = Array::makei(n, fn(_) { Array::make(n, 0) })
  { n, cost }
}

///|
fn Hungarian::set_cost(self : Hungarian, i : Int, j : Int, c : Int) -> Unit {
  self.cost[i][j] = c
}

///|
/// Solve assignment problem, returns (min_cost, assignment)
/// assignment[i] = job assigned to worker i
fn Hungarian::solve(self : Hungarian) -> (Int, Array[Int]) {
  let n = self.n
  if n == 0 {
    return (0, [])
  }

  // Potentials (labels)
  let u = Array::make(n + 1, 0)
  let v = Array::make(n + 1, 0)

  // Matching: p[j] = worker assigned to job j (0 = unassigned)
  let p = Array::make(n + 1, 0)

  // way[j] = previous job in augmenting path
  let way = Array::make(n + 1, 0)

  // Process each worker
  for i = 1; i <= n; i = i + 1 {
    // Add worker i to matching
    p[0] = i
    let mut j0 = 0 // Current job (0 = virtual)

    let minv = Array::make(n + 1, HUNGARIAN_INF)
    let used = Array::make(n + 1, false)

    // Find augmenting path
    while p[j0] != 0 {
      used[j0] = true
      let i0 = p[j0]
      let mut delta = HUNGARIAN_INF
      let mut j1 = 0

      // Find minimum slack
      for j = 1; j <= n; j = j + 1 {
        if not(used[j]) {
          // Access cost with 0-indexed
          let cur = self.cost[i0 - 1][j - 1] - u[i0] - v[j]
          if cur < minv[j] {
            minv[j] = cur
            way[j] = j0
          }
          if minv[j] < delta {
            delta = minv[j]
            j1 = j
          }
        }
      }

      // Update potentials
      for j = 0; j <= n; j = j + 1 {
        if used[j] {
          u[p[j]] = u[p[j]] + delta
          v[j] = v[j] - delta
        } else {
          minv[j] = minv[j] - delta
        }
      }

      j0 = j1
    }

    // Update matching along augmenting path
    while j0 != 0 {
      let j1 = way[j0]
      p[j0] = p[j1]
      j0 = j1
    }
  }

  // Build result
  let assignment = Array::make(n, 0)
  for j = 1; j <= n; j = j + 1 {
    if p[j] != 0 {
      assignment[p[j] - 1] = j - 1
    }
  }

  // Compute total cost
  let total_cost = for i = 0, sum = 0; i < n; {
    continue i + 1, sum + self.cost[i][assignment[i]]
  } else {
    sum
  }

  (total_cost, assignment)
}

///|
/// Solve maximum weight assignment (negate costs)
fn Hungarian::solve_max(self : Hungarian) -> (Int, Array[Int]) {
  let n = self.n
  // Find max cost to negate
  let max_cost = for i = 0, m = 0; i < n; {
    for j = 0, mm = m; j < n; {
      continue j + 1, if self.cost[i][j] > mm { self.cost[i][j] } else { mm }
    } else {
      continue i + 1, mm
    }
  } else {
    m
  }

  // Create negated cost matrix
  let neg = Hungarian::new(n)
  for i = 0; i < n; i = i + 1 {
    for j = 0; j < n; j = j + 1 {
      neg.set_cost(i, j, max_cost - self.cost[i][j])
    }
  }

  let (min_cost, assignment) = neg.solve()
  (n * max_cost - min_cost, assignment)
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "hungarian simple" {
  // Cost matrix:
  // [1, 2]
  // [2, 1]
  // Optimal: worker 0 -> job 0, worker 1 -> job 1, cost = 2
  let h = Hungarian::new(2)
  h.set_cost(0, 0, 1)
  h.set_cost(0, 1, 2)
  h.set_cost(1, 0, 2)
  h.set_cost(1, 1, 1)

  let (cost, assignment) = h.solve()
  inspect(cost, content="2")
  inspect(assignment[0], content="0")
  inspect(assignment[1], content="1")
}

///|
test "hungarian 3x3" {
  // Cost matrix:
  // [10, 5, 13]
  // [3, 15, 8]
  // [7, 9, 6]
  // Optimal assignment: 0->1, 1->0, 2->2, cost = 5+3+6 = 14
  let h = Hungarian::new(3)
  h.set_cost(0, 0, 10)
  h.set_cost(0, 1, 5)
  h.set_cost(0, 2, 13)
  h.set_cost(1, 0, 3)
  h.set_cost(1, 1, 15)
  h.set_cost(1, 2, 8)
  h.set_cost(2, 0, 7)
  h.set_cost(2, 1, 9)
  h.set_cost(2, 2, 6)

  let (cost, _) = h.solve()
  inspect(cost, content="14")
}

///|
test "hungarian maximize" {
  // Profit matrix:
  // [3, 1]
  // [1, 3]
  // Max: worker 0 -> job 0, worker 1 -> job 1, profit = 6
  let h = Hungarian::new(2)
  h.set_cost(0, 0, 3)
  h.set_cost(0, 1, 1)
  h.set_cost(1, 0, 1)
  h.set_cost(1, 1, 3)

  let (profit, assignment) = h.solve_max()
  inspect(profit, content="6")
  inspect(assignment[0], content="0")
  inspect(assignment[1], content="1")
}

///|
test "hungarian single" {
  let h = Hungarian::new(1)
  h.set_cost(0, 0, 5)

  let (cost, assignment) = h.solve()
  inspect(cost, content="5")
  inspect(assignment[0], content="0")
}

///|
test "hungarian zero cost" {
  let h = Hungarian::new(2)
  h.set_cost(0, 0, 0)
  h.set_cost(0, 1, 0)
  h.set_cost(1, 0, 0)
  h.set_cost(1, 1, 0)

  let (cost, _) = h.solve()
  inspect(cost, content="0")
}

///|
test "hungarian empty" {
  let h = Hungarian::new(0)
  let (cost, assignment) = h.solve()
  inspect(cost, content="0")
  inspect(assignment.length(), content="0")
}

///|
test "hungarian uniform" {
  // All costs equal
  let h = Hungarian::new(3)
  for i = 0; i < 3; i = i + 1 {
    for j = 0; j < 3; j = j + 1 {
      h.set_cost(i, j, 7)
    }
  }

  let (cost, _) = h.solve()
  inspect(cost, content="21")
}
