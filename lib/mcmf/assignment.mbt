// ============================================================================
// ASSIGNMENT PROBLEM - MCMF Application
// ============================================================================
//
// The Assignment Problem: Given n workers and n tasks with cost matrix,
// assign each worker to exactly one task to minimize total cost.
//
// REDUCTION TO MCMF:
// ```
//   Create bipartite graph with flow network:
//
//   Source --1--> Workers --cost--> Tasks --1--> Sink
//      (0)     (1 to n)        (n+1 to 2n)    (2n+1)
//
//   Edge capacities: All edges have capacity 1
//   Edge costs:
//   - Source to workers: 0
//   - Workers to tasks: cost[worker][task]
//   - Tasks to sink: 0
//
//   Max flow = n (perfect matching exists)
//   Min cost = optimal assignment cost
// ```
//
// VISUAL (2x2 example):
// ```
//           cost[0][0]
//   Worker 0 ---------> Task 0
//          \ cost[0][1]    \
//   Source   ------->   --> Sink
//     |     / cost[1][0]   /
//   Worker 1 ---------> Task 1
//           cost[1][1]
// ```
//
// TIME COMPLEXITY: O(n^3) using MCMF
// (Hungarian algorithm achieves the same bound with better constants)

///|
/// Solve the minimum-cost perfect assignment problem for an n-by-n cost matrix.
///
/// Given `n` workers and `n` jobs, each worker must be assigned to exactly one
/// job and each job must be covered by exactly one worker. The cost of assigning
/// worker `i` to job `j` is `cost[i][j]`. The function returns the minimum
/// total cost over all perfect assignments.
///
/// The problem is modelled as a min-cost max-flow network:
/// - Vertex 0 is the source.
/// - Vertices `1..n` represent workers.
/// - Vertices `n+1..2n` represent jobs.
/// - Vertex `2n+1` is the sink.
/// - Source -> worker edges have capacity 1 and cost 0.
/// - Worker `i` -> job `j` edges have capacity 1 and cost `cost[i][j]`.
/// - Job -> sink edges have capacity 1 and cost 0.
///
/// A max flow of `n` through this network corresponds to a perfect matching;
/// MCMF minimises the total edge cost, which equals the assignment cost.
///
/// Parameters:
/// - `cost` - square matrix of size n x n where `cost[i][j]` is the cost of
///            assigning worker `i` to job `j`; all values may be any `Int64`
///
/// Returns the minimum total assignment cost.
///
/// Precondition: `cost` must be a square matrix (n rows, each with n columns).
/// An empty matrix returns 0.
pub fn solve_assignment(cost : Array[Array[Int64]]) -> Int64 {
  let n = cost.length()
  if n == 0 {
    return 0L
  }

  // Create bipartite flow network:
  // Vertices: 0=source, 1..n=workers, n+1..2n=tasks, 2n+1=sink
  let mcmf = MinCostMaxFlow::new(2 * n + 2)
  let source = 0
  let sink = 2 * n + 1

  // Source to workers (capacity 1, cost 0)
  for i in 0..<n {
    mcmf.add_edge(source, i + 1, 1L, 0L)
  }

  // Workers to tasks (capacity 1, cost = cost[worker][task])
  for i in 0..<n {
    for j in 0..<cost[i].length() {
      mcmf.add_edge(i + 1, n + 1 + j, 1L, cost[i][j])
    }
  }

  // Tasks to sink (capacity 1, cost 0)
  for j in 0..<n {
    mcmf.add_edge(n + 1 + j, sink, 1L, 0L)
  }

  // Compute min-cost max-flow
  let (_, min_cost) = mcmf.compute(source, sink)
  min_cost
}
