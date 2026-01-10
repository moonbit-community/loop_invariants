// ============================================================================
// 2-SAT - Boolean Satisfiability with 2 Literals per Clause
// ============================================================================
//
// 2-SAT solves boolean satisfiability where each clause has exactly 2 literals.
// Unlike general SAT (NP-complete), 2-SAT is solvable in linear time O(n + m).
//
// KEY INSIGHT: Each clause (a ∨ b) is equivalent to two implications:
// (¬a → b) and (¬b → a)
//
// IMPLICATION GRAPH:
// - 2n nodes: for each variable x, we have nodes x and ¬x
// - For clause (a ∨ b), add edges (¬a → b) and (¬b → a)
//
// ALGORITHM:
// 1. Build implication graph from clauses
// 2. Find strongly connected components (SCCs) using Kosaraju or Tarjan
// 3. If any variable x and ¬x are in the same SCC, unsatisfiable
// 4. Otherwise, assign values based on topological order of SCCs:
//    - Process SCCs in reverse topological order
//    - For each unassigned variable, assign true if x's SCC comes after ¬x's SCC
//
// WHY IT WORKS:
// - If x and ¬x are in same SCC: x → ... → ¬x → ... → x, contradiction
// - Topological assignment: if (a → b) and a is true, then b must be true
//   Since we process in reverse topo order, we assign b before a, ensuring consistency
//
// EXAMPLE: (x₁ ∨ x₂) ∧ (¬x₁ ∨ x₃) ∧ (¬x₂ ∨ ¬x₃)
// Implications:
// ¬x₁ → x₂, ¬x₂ → x₁
// x₁ → x₃, ¬x₃ → ¬x₁
// x₂ → ¬x₃, x₃ → ¬x₂
//
// INVARIANTS:
// 1. Implication graph encodes all logical constraints
// 2. Variables in same SCC must have same truth value
// 3. If SCC(x) comes before SCC(¬x) in topo order, x should be false
//
// TIME COMPLEXITY: O(n + m) where n = variables, m = clauses
// SPACE COMPLEXITY: O(n + m)

///|
priv struct TwoSat {
  n : Int // Number of variables (0 to n-1)
  adj : Array[Array[Int]] // Implication graph: adj[node] = list of implied nodes
  radj : Array[Array[Int]] // Reverse graph for Kosaraju
}

///|
/// Create a 2-SAT instance with n boolean variables
fn TwoSat::new(n : Int) -> TwoSat {
  let adj = Array::make(2 * n, [])
  let radj = Array::make(2 * n, [])
  for i = 0; i < 2 * n; i = i + 1 {
    adj[i] = []
    radj[i] = []
  } where {
    invariant: i >= 0 && i <= 2 * n,
    reasoning: "I: adj, radj contain empty default. M: Initialize each position with fresh empty array to avoid aliasing. T: After i = 2n, all adjacency lists are independent empty arrays.",
  }
  { n, adj, radj }
}

///|
/// Get node index for literal: v -> 2*v, ¬v -> 2*v + 1
fn literal_to_node(v : Int, negated : Bool) -> Int {
  2 * v + (if negated { 1 } else { 0 })
}

///|
/// Get negation of a node
fn negate_node(node : Int) -> Int {
  node.lxor(1) // Flip last bit: 2k <-> 2k+1
}

///|
/// Add clause (a ∨ b) where a = (var_a, neg_a), b = (var_b, neg_b)
/// neg_a/neg_b = true means the variable is negated in the clause
fn TwoSat::add_clause(
  self : TwoSat,
  var_a : Int,
  neg_a : Bool,
  var_b : Int,
  neg_b : Bool
) -> Unit {
  // (a ∨ b) ≡ (¬a → b) ∧ (¬b → a)
  let node_a = literal_to_node(var_a, neg_a)
  let node_b = literal_to_node(var_b, neg_b)
  let not_a = negate_node(node_a)
  let not_b = negate_node(node_b)

  // Add implication ¬a → b
  self.adj[not_a].push(node_b)
  self.radj[node_b].push(not_a)

  // Add implication ¬b → a
  self.adj[not_b].push(node_a)
  self.radj[node_a].push(not_b)
}

///|
/// Add implication (a → b)
fn TwoSat::add_implication(
  self : TwoSat,
  var_a : Int,
  neg_a : Bool,
  var_b : Int,
  neg_b : Bool
) -> Unit {
  // a → b is equivalent to (¬a ∨ b)
  let not_neg_a = if neg_a { false } else { true }
  self.add_clause(var_a, not_neg_a, var_b, neg_b)
}

///|
/// Force variable to be true or false
fn TwoSat::set_value(self : TwoSat, v : Int, value : Bool) -> Unit {
  // To force v = true: add clause (v ∨ v)
  // To force v = false: add clause (¬v ∨ ¬v)
  let not_value = if value { false } else { true }
  self.add_clause(v, not_value, v, not_value)
}

///|
/// Solve the 2-SAT instance
/// Returns Some(assignment) if satisfiable, None otherwise
fn TwoSat::solve(self : TwoSat) -> Array[Bool]? {
  let num_nodes = 2 * self.n
  if num_nodes == 0 {
    return Some([])
  }

  // Kosaraju's algorithm for SCCs
  let visited = Array::make(num_nodes, false)
  let order : Array[Int] = []

  // First DFS: compute finish order
  for i = 0; i < num_nodes; i = i + 1 {
    if not(visited[i]) {
      dfs1(self.adj, visited, order, i)
    }
  } where {
    invariant: i >= 0 && i <= num_nodes,
    reasoning: "I: All nodes unvisited. M: For each unvisited node, run DFS and add nodes to order in post-order (finish time). T: After i = num_nodes, order contains all nodes sorted by decreasing finish time.",
  }

  // Second DFS: find SCCs in reverse finish order
  let comp = Array::make(num_nodes, -1)
  let mut num_scc = 0
  for i = num_nodes - 1; i >= 0; i = i - 1 {
    let node = order[i]
    if comp[node] < 0 {
      dfs2(self.radj, comp, num_scc, node)
      num_scc = num_scc + 1
    }
  } where {
    invariant: i >= -1 && i <= num_nodes - 1,
    reasoning: "I: All nodes unassigned (comp = -1). M: Process nodes in reverse finish order. For each unassigned node, DFS on reverse graph assigns same SCC id to all reachable nodes. This correctly identifies SCCs because in reverse graph, we can only reach nodes in same or earlier SCCs. T: After i = -1, each node has SCC id in comp[], and num_scc is total SCC count.",
  }

  // Check satisfiability: x and ¬x must be in different SCCs
  let assignment = Array::make(self.n, false)
  for i = 0; i < self.n; i = i + 1 {
    let node_true = 2 * i
    let node_false = 2 * i + 1
    if comp[node_true] == comp[node_false] {
      return None // Contradiction: x ↔ ¬x
    }
    // Assign based on SCC order: if comp[x] > comp[¬x], then x = true
    // Higher SCC number = earlier in reverse topo order = should be true
    assignment[i] = comp[node_true] > comp[node_false]
  } where {
    invariant: i >= 0 && i <= self.n,
    reasoning: "I: assignment uninitialized. M: For each variable i, check if x_i and ¬x_i are in same SCC (contradiction). If not, assign x_i = true iff SCC(x_i) has higher number than SCC(¬x_i). Higher SCC numbers correspond to later discovery in second DFS, meaning earlier in topological order. By implication semantics, if a → b and a is true, b must be true; processing in reverse topo ensures b is assigned before a. T: After i = n, either contradiction found or valid assignment computed.",
  }

  Some(assignment)
}

///|
fn dfs1(adj : Array[Array[Int]], visited : Array[Bool], order : Array[Int], u : Int) -> Unit {
  visited[u] = true
  for i = 0; i < adj[u].length(); i = i + 1 {
    let v = adj[u][i]
    if not(visited[v]) {
      dfs1(adj, visited, order, v)
    }
  } where {
    invariant: i >= 0 && i <= adj[u].length(),
    reasoning: (
      #|All neighbors adj[u][0..i) have been processed; any unvisited neighbor
      #|has been fully explored and added to order before returning.
    ),
  }
  order.push(u) // Post-order
}

///|
fn dfs2(radj : Array[Array[Int]], comp : Array[Int], scc_id : Int, u : Int) -> Unit {
  comp[u] = scc_id
  for i = 0; i < radj[u].length(); i = i + 1 {
    let v = radj[u][i]
    if comp[v] < 0 {
      dfs2(radj, comp, scc_id, v)
    }
  } where {
    invariant: i >= 0 && i <= radj[u].length(),
    reasoning: (
      #|All reverse edges radj[u][0..i) have been explored for this SCC.
    ),
  }
}

///|
/// Verify that an assignment satisfies all implications
fn TwoSat::verify(self : TwoSat, assignment : Array[Bool]) -> Bool {
  for u = 0; u < 2 * self.n; u = u + 1 {
    let var_u = u / 2
    let neg_u = u % 2 == 1
    let val_u = if neg_u { not(assignment[var_u]) } else { assignment[var_u] }

    if val_u {
      // If u is true, all nodes reachable from u must be true
      for i = 0; i < self.adj[u].length(); i = i + 1 {
        let v = self.adj[u][i]
        let var_v = v / 2
        let neg_v = v % 2 == 1
        let val_v = if neg_v { not(assignment[var_v]) } else { assignment[var_v] }
        if not(val_v) {
          return false
        }
      } where {
        invariant: i >= 0 && i <= self.adj[u].length(),
        reasoning: (
          #|All implications from u to adj[u][0..i) are satisfied by assignment.
        ),
      }
    }
  } where {
    invariant: u >= 0 && u <= 2 * self.n,
    reasoning: (
      #|All implication nodes in [0..u) have been validated against assignment.
    ),
  }
  true
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "two sat basic satisfiable" {
  let sat = TwoSat::new(2)
  // (x0 ∨ x1) ∧ (¬x0 ∨ x1)
  // Solution: x1 = true
  sat.add_clause(0, false, 1, false) // x0 ∨ x1
  sat.add_clause(0, true, 1, false) // ¬x0 ∨ x1

  match sat.solve() {
    Some(assignment) => {
      inspect(assignment[1], content="true") // x1 must be true
      inspect(sat.verify(assignment), content="true")
    }
    None => inspect(false, content="true") // Should be satisfiable
  }
}

///|
test "two sat unsatisfiable" {
  let sat = TwoSat::new(1)
  // (x0) ∧ (¬x0)
  sat.add_clause(0, false, 0, false) // x0 ∨ x0 = x0
  sat.add_clause(0, true, 0, true) // ¬x0 ∨ ¬x0 = ¬x0

  match sat.solve() {
    Some(_) => inspect(false, content="true") // Should be unsatisfiable
    None => inspect(true, content="true")
  }
}

///|
test "two sat three variables" {
  let sat = TwoSat::new(3)
  // (x0 ∨ x1) ∧ (¬x1 ∨ x2) ∧ (¬x0 ∨ ¬x2)
  sat.add_clause(0, false, 1, false) // x0 ∨ x1
  sat.add_clause(1, true, 2, false) // ¬x1 ∨ x2
  sat.add_clause(0, true, 2, true) // ¬x0 ∨ ¬x2

  match sat.solve() {
    Some(assignment) => {
      inspect(sat.verify(assignment), content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "two sat set value" {
  let sat = TwoSat::new(2)
  sat.set_value(0, true) // Force x0 = true
  sat.add_clause(0, false, 1, false) // x0 ∨ x1

  match sat.solve() {
    Some(assignment) => {
      inspect(assignment[0], content="true")
      inspect(sat.verify(assignment), content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "two sat implication" {
  let sat = TwoSat::new(2)
  sat.add_implication(0, false, 1, false) // x0 → x1
  sat.set_value(0, true) // x0 = true

  match sat.solve() {
    Some(assignment) => {
      inspect(assignment[0], content="true")
      inspect(assignment[1], content="true") // Must be true due to implication
      inspect(sat.verify(assignment), content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "two sat empty" {
  let sat = TwoSat::new(0)
  match sat.solve() {
    Some(assignment) => inspect(assignment.length(), content="0")
    None => inspect(false, content="true")
  }
}

///|
test "two sat complex" {
  let sat = TwoSat::new(4)
  // (x0 ∨ x1) ∧ (x1 ∨ x2) ∧ (x2 ∨ x3) ∧ (¬x0 ∨ ¬x3)
  sat.add_clause(0, false, 1, false)
  sat.add_clause(1, false, 2, false)
  sat.add_clause(2, false, 3, false)
  sat.add_clause(0, true, 3, true)

  match sat.solve() {
    Some(assignment) => {
      inspect(sat.verify(assignment), content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "two sat chain contradiction" {
  let sat = TwoSat::new(3)
  // x0 → x1 → x2 → ¬x0
  sat.add_implication(0, false, 1, false) // x0 → x1
  sat.add_implication(1, false, 2, false) // x1 → x2
  sat.add_implication(2, false, 0, true) // x2 → ¬x0
  sat.set_value(0, true) // x0 = true

  // This creates x0 → x1 → x2 → ¬x0, contradiction
  match sat.solve() {
    Some(_) => inspect(false, content="true")
    None => inspect(true, content="true")
  }
}
