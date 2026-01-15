// ============================================================================
// 2-SAT SOLVER USING SCC
// ============================================================================
//
// 2-SAT (2-Satisfiability) is a special case of boolean satisfiability
// where each clause has exactly 2 literals.
//
// REDUCTION TO SCC:
// ```
//   Each clause (a OR b) is equivalent to two implications:
//     (NOT a) => b
//     (NOT b) => a
//
//   Build an "implication graph" with 2n vertices:
//     - Vertices 0..n-1 represent x₀..xₙ₋₁
//     - Vertices n..2n-1 represent NOT x₀..NOT xₙ₋₁
//
//   Add edges for each implication.
// ```
//
// SATISFIABILITY CHECK:
// ```
//   The formula is satisfiable iff for all i:
//     xᵢ and NOT xᵢ are in different SCCs
//
//   Why? If xᵢ and NOT xᵢ are in the same SCC, then:
//     xᵢ => ... => NOT xᵢ => ... => xᵢ
//   This creates a contradiction.
// ```
//
// FINDING ASSIGNMENT:
// ```
//   Use the SCC numbering (topological order):
//     - If SCC(xᵢ) > SCC(NOT xᵢ): set xᵢ = true
//     - If SCC(xᵢ) < SCC(NOT xᵢ): set xᵢ = false
//
//   Why this works:
//     If xᵢ = true leads to contradiction, then there's a path
//     xᵢ => ... => NOT xᵢ, meaning SCC(xᵢ) ≤ SCC(NOT xᵢ).
//     By choosing the one with higher SCC number, we avoid the
//     implication chain leading to contradiction.
// ```
//
// EXAMPLE:
// ```
//   Formula: (x₀ OR x₁) AND (NOT x₀ OR x₁) AND (x₀ OR NOT x₁)
//
//   Implications:
//     NOT x₀ => x₁, NOT x₁ => x₀
//     x₀ => x₁, NOT x₁ => NOT x₀
//     NOT x₀ => NOT x₁, x₁ => x₀
//
//   Implication graph has paths:
//     NOT x₀ => x₁ => x₀ (so NOT x₀ => x₀, meaning x₀ must be true)
//     NOT x₁ => NOT x₀ => NOT x₁ (cycle, same SCC)
//     x₁ => x₀ => ... (eventually x₁)
//
//   Result: x₀ = true, x₁ = true (or both false depending on SCC order)
// ```

///|
/// 2-SAT problem structure.
///
/// VERTEX ENCODING:
/// ```
///   Variable xᵢ (positive):  vertex i
///   Variable ¬xᵢ (negated):  vertex i + n
///
///   n total variables, 2n total vertices in implication graph.
/// ```
pub(all) struct TwoSAT {
  n : Int
  adj : Array[Array[Int]]
}

///|
/// Create a new 2-SAT instance with n boolean variables.
pub fn TwoSAT::new(n : Int) -> TwoSAT {
  // Use makei to create 2n adjacency lists (n vars + n negated vars)
  let adj : Array[Array[Int]] = Array::makei(2 * n, _ => [])
  { n, adj }
}

///|
/// Convert variable and sign to vertex index.
///
/// PARAMETERS:
///   - n: number of variables
///   - x: variable index (0 to n-1)
///   - neg: true if negated
///
/// RETURNS:
///   Vertex index in implication graph
fn var_to_vertex(n : Int, x : Int, neg : Bool) -> Int {
  if neg {
    x + n // Negated variables are in second half
  } else {
    x // Positive variables in first half
  }
}

///|
/// Add clause (a OR b) to the 2-SAT formula.
///
/// IMPLEMENTATION:
/// ```
///   (a OR b) is equivalent to:
///     (NOT a) => b   (if a is false, b must be true)
///     (NOT b) => a   (if b is false, a must be true)
///
///   We add both implications as edges in the graph.
/// ```
///
/// PARAMETERS:
///   - self: the 2-SAT instance
///   - a: first variable index
///   - neg_a: true if first literal is negated
///   - b: second variable index
///   - neg_b: true if second literal is negated
pub fn TwoSAT::add_clause(
  self : TwoSAT,
  a : Int,
  neg_a : Bool,
  b : Int,
  neg_b : Bool,
) -> Unit {
  // Implication 1: (NOT a) => b
  let from_a = var_to_vertex(self.n, a, not(neg_a))
  let to_b = var_to_vertex(self.n, b, neg_b)
  self.adj[from_a].push(to_b)

  // Implication 2: (NOT b) => a
  let from_b = var_to_vertex(self.n, b, not(neg_b))
  let to_a = var_to_vertex(self.n, a, neg_a)
  self.adj[from_b].push(to_a)
}

///|
/// Solve the 2-SAT formula.
///
/// ALGORITHM:
/// ```
///   1. Find SCCs of implication graph
///   2. Check: for each i, xᵢ and ¬xᵢ must be in different SCCs
///   3. Assign: xᵢ = true if SCC(xᵢ) > SCC(¬xᵢ)
/// ```
///
/// RETURNS:
///   Some(assignment) if satisfiable, None otherwise.
///   assignment[i] = value of variable i.
pub fn TwoSAT::solve(self : TwoSAT) -> Array[Bool]? {
  let result = find_sccs(2 * self.n, self.adj)

  // Check satisfiability
  for x in 0..<self.n {
    if result.component[x] == result.component[x + self.n] {
      return None // x and NOT x in same SCC → contradiction
    }
  }

  // Assign values based on SCC ordering
  // Tarjan numbers SCCs in reverse topological order
  // Higher SCC number = earlier in topological order = "stronger"
  let assignment = Array::make(self.n, false)
  for x in 0..<self.n {
    // If SCC(x) > SCC(NOT x), then x implies NOT x would be
    // going against topological order, so x = true is safe
    assignment[x] = result.component[x] > result.component[x + self.n]
  }
  Some(assignment)
}
