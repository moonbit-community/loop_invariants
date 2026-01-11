// Mo's Algorithm and Square Root Decomposition Techniques
// with rigorous loop invariants and mathematical reasoning

///|
/// Compute integer square root for Mo's algorithm
fn mo_isqrt(n : Int) -> Int {
  if n <= 0 {
    return 1
  }
  for x = n {
    let next = (x + n / x) / 2
    if next >= x {
      break x
    }
    continue next
  } where {
    invariant: x > 0,
    reasoning: (
      #|INVARIANT (integer sqrt):
      #|x is a positive estimate for sqrt(n); the sequence stays positive and
      #|moves toward a fixed point.
      #|MAINTENANCE:
      #|next = (x + n / x) / 2 shrinks the estimate when it's above sqrt(n),
      #|so the sequence is non-increasing after a few steps.
      #|TERMINATION:
      #|When next >= x, x is the stable integer estimate and equals floor(sqrt(n)).
    ),
  }
}

///|
/// Mo's Algorithm for Range Sum Queries (Simplified)
///
/// MATHEMATICAL FOUNDATION:
/// Mo's algorithm answers range queries offline by reordering them to minimize
/// the total number of add/remove operations on endpoints.
///
/// KEY INSIGHT:
/// Divide array into √n blocks. Sort queries by:
/// 1. Block of left endpoint
/// 2. Right endpoint (within same block)
///
/// TIME COMPLEXITY: O((n + q) × √n) for q queries on array of size n
fn mos_algorithm_range_sum(
  arr : ArrayView[Int],
  queries : Array[(Int, Int)],
) -> Array[Int] {
  let n = arr.length()
  let q = queries.length()
  if n == 0 || q == 0 {
    return Array::make(q, 0)
  }
  let block_size = mo_isqrt(n)

  // Create and sort query indices using bubble sort
  let query_order = Array::makei(q, i => i)
  for i = 0; i < q - 1; i = i + 1 {
    let last = q - 1 - i
    for j = 0; j < last; j = j + 1 {
      let idx1 = query_order[j]
      let idx2 = query_order[j + 1]
      let (l1, r1) = queries[idx1]
      let (l2, r2) = queries[idx2]
      let block1 = l1 / block_size
      let block2 = l2 / block_size
      let should_swap = if block1 != block2 { block1 > block2 } else { r1 > r2 }
      if should_swap {
        query_order[j] = idx2
        query_order[j + 1] = idx1
      }
    } where {
      invariant: j >= 0 && j <= last,
      reasoning: (
        #|INVARIANT (bubble inner):
        #|After j steps, the largest query (by Mo ordering) among positions
        #|[0..j] is at index j.
        #|MAINTENANCE:
        #|Compare adjacent queries and swap if out of order, pushing the
        #|largest element one step to the right.
        #|TERMINATION:
        #|At j == last, the maximum of the unsorted prefix is fixed at last.
      ),
    }
  } where {
    invariant: i >= 0 && i <= q - 1,
    reasoning: (
      #|INVARIANT (bubble outer):
      #|After i passes, the last i positions are fixed in Mo ordering.
      #|MAINTENANCE:
      #|The inner pass moves the next-largest remaining query into position
      #|q - 1 - i.
      #|TERMINATION:
      #|At i == q - 1, the entire order is sorted.
    ),
  }
  let results : Array[Int] = Array::make(q, 0)
  for i = 0, curr_l = 0, curr_r = 0, curr_sum = 0; i < q; {
    let query_idx = query_order[i]
    let (ql, qr) = queries[query_idx]

    // Expand right
    let (curr_r2, sum2) = for r = curr_r, s = curr_sum; r < qr; {
      continue r + 1, s + arr[r]
    } else {
      (r, s)
    } where {
      invariant: r >= curr_r && r <= qr,
      reasoning: (
        #|INVARIANT (expand right):
        #|s equals sum(arr[curr_l..r)); the range grows to the right.
        #|MAINTENANCE:
        #|Add arr[r] and advance r, preserving s as the sum of the extended range.
        #|TERMINATION:
        #|At r == qr, the right boundary matches the query.
      ),
    }

    // Shrink right
    let (curr_r3, sum3) = for r = curr_r2, s = sum2; r > qr; {
      continue r - 1, s - arr[r - 1]
    } else {
      (r, s)
    } where {
      invariant: r >= qr && r <= curr_r2,
      reasoning: (
        #|INVARIANT (shrink right):
        #|s equals sum(arr[curr_l..r)); the range shrinks from the right.
        #|MAINTENANCE:
        #|Subtract arr[r-1] and decrement r to remove the last element.
        #|TERMINATION:
        #|At r == qr, the right boundary matches the query.
      ),
    }

    // Shrink left
    let (curr_l2, sum4) = for l = curr_l, s = sum3; l < ql; {
      continue l + 1, s - arr[l]
    } else {
      (l, s)
    } where {
      invariant: l >= curr_l && l <= ql,
      reasoning: (
        #|INVARIANT (shrink left):
        #|s equals sum(arr[l..curr_r3)); the range shrinks from the left.
        #|MAINTENANCE:
        #|Subtract arr[l] and advance l to drop the leftmost element.
        #|TERMINATION:
        #|At l == ql, the left boundary matches the query.
      ),
    }

    // Expand left
    let (curr_l3, sum5) = for l = curr_l2, s = sum4; l > ql; {
      continue l - 1, s + arr[l - 1]
    } else {
      (l, s)
    } where {
      invariant: l >= ql && l <= curr_l2,
      reasoning: (
        #|INVARIANT (expand left):
        #|s equals sum(arr[l..curr_r3)); the range grows to the left.
        #|MAINTENANCE:
        #|Decrement l and add arr[l-1] to include the new leftmost element.
        #|TERMINATION:
        #|At l == ql, the left boundary matches the query.
      ),
    }
    results[query_idx] = sum5
    continue i + 1, curr_l3, curr_r3, sum5
  } else {
    ()
  } where {
    invariant: i >= 0 && i <= q,
    reasoning: (
      #|INVARIANT (mo main loop):
      #|curr_sum = sum(arr[curr_l..curr_r)) and results are filled for all
      #|queries in query_order[0..i).
      #|MAINTENANCE:
      #|Adjust curr_l/curr_r to the next query and record the resulting sum.
      #|TERMINATION:
      #|At i == q, all queries have been answered.
    ),
  }
  results
}

///|
test "mos algorithm range sum" {
  let arr = [1, 2, 3, 4, 5]
  let queries = [(0, 3), (1, 4), (0, 5)]
  let results = mos_algorithm_range_sum(arr[:], queries)
  assert_eq(results[0], 6) // 1+2+3 = 6
  assert_eq(results[1], 9) // 2+3+4 = 9
  assert_eq(results[2], 15) // 1+2+3+4+5 = 15
}

///|
/// Square Root Decomposition for Range Minimum Query
///
/// MATHEMATICAL FOUNDATION:
/// Divide array into √n blocks, precompute minimum for each block.
/// Query: check partial blocks directly + full blocks from precomputed values.
///
/// TIME: O(√n) per query, O(n) preprocessing
priv struct SqrtDecomposition {
  arr : Array[Int]
  block_mins : Array[Int]
  block_size : Int
}

///|
fn SqrtDecomposition::new(arr : Array[Int]) -> SqrtDecomposition {
  let n = arr.length()
  if n == 0 {
    return { arr, block_mins: [], block_size: 1 }
  }
  let block_size = mo_isqrt(n)
  let num_blocks = (n + block_size - 1) / block_size
  let block_mins : Array[Int] = Array::make(num_blocks, 2147483647)
  for i = 0; i < n; i = i + 1 {
    let block_idx = i / block_size
    if arr[i] < block_mins[block_idx] {
      block_mins[block_idx] = arr[i]
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (build block mins):
      #|For every fully processed block, block_mins stores the minimum of its
      #|elements; the current block is minimized over its processed prefix.
      #|MAINTENANCE:
      #|Update block_mins[block_idx] with arr[i] when smaller.
      #|TERMINATION:
      #|At i == n, all block minimums are computed.
    ),
  }
  { arr, block_mins, block_size }
}

///|
fn SqrtDecomposition::query_min(
  self : SqrtDecomposition,
  l : Int,
  r : Int,
) -> Int {
  if l >= r || l < 0 || r > self.arr.length() {
    return 2147483647
  }
  for i = l, result = 2147483647; i < r; {
    let block_idx = i / self.block_size
    let block_end = @cmp.minimum((block_idx + 1) * self.block_size, r)
    if i == block_idx * self.block_size &&
      block_end == (block_idx + 1) * self.block_size {
      // Full block
      let new_result = @cmp.minimum(result, self.block_mins[block_idx])
      continue block_end, new_result
    } else {
      // Partial block
      let new_result = @cmp.minimum(result, self.arr[i])
      continue i + 1, new_result
    }
  } else {
    result
  } where {
    invariant: i >= l && i <= r,
    reasoning: (
      #|INVARIANT (range min):
      #|result = min(arr[l..i)); indices [i..r) remain to be processed.
      #|MAINTENANCE:
      #|If i aligns with a full block, use block_mins and jump; otherwise scan
      #|element-by-element and advance i.
      #|TERMINATION:
      #|At i == r, result is the minimum over arr[l..r).
    ),
  }
}

///|
fn SqrtDecomposition::update_sqrt(
  self : SqrtDecomposition,
  idx : Int,
  val : Int,
) -> Unit {
  if idx < 0 || idx >= self.arr.length() {
    return
  }
  self.arr[idx] = val
  let block_idx = idx / self.block_size
  let block_start = block_idx * self.block_size
  let block_end = @cmp.minimum(block_start + self.block_size, self.arr.length())
  self.block_mins[block_idx] = 2147483647
  for i = block_start; i < block_end; i = i + 1 {
    if self.arr[i] < self.block_mins[block_idx] {
      self.block_mins[block_idx] = self.arr[i]
    }
  } where {
    invariant: i >= block_start && i <= block_end,
    reasoning: (
      #|INVARIANT (recompute block min):
      #|block_mins[block_idx] is the minimum of arr[block_start..i).
      #|MAINTENANCE:
      #|Compare arr[i] to the current minimum and update if smaller.
      #|TERMINATION:
      #|At i == block_end, block_mins[block_idx] is fully recomputed.
    ),
  }
}

///|
test "sqrt decomposition rmq" {
  let arr = [3, 1, 4, 1, 5, 9, 2, 6]
  let sd = SqrtDecomposition::new(arr)
  assert_eq(sd.query_min(0, 4), 1)
  assert_eq(sd.query_min(4, 8), 2)
  assert_eq(sd.query_min(2, 6), 1)
  sd.update_sqrt(1, 10)
  assert_eq(sd.query_min(0, 4), 1)
  sd.update_sqrt(3, 10)
  assert_eq(sd.query_min(0, 4), 3)
}

///|
/// Range Mode Query (Most Frequent Element)
///
/// Simplified version using direct counting per query.
fn range_mode(arr : ArrayView[Int], queries : Array[(Int, Int)]) -> Array[Int] {
  let n = arr.length()
  let q = queries.length()
  if n == 0 || q == 0 {
    return Array::make(q, 0)
  }
  let results : Array[Int] = Array::make(q, 0)
  let max_val = 1000
  let freq : Array[Int] = Array::make(max_val + 1, 0)
  for qi = 0; qi < q; qi = qi + 1 {
    let (l, r) = queries[qi]

    // Reset frequencies
    for i = 0; i <= max_val; i = i + 1 {
      freq[i] = 0
    } where {
      invariant: i >= 0 && i <= max_val,
      reasoning: (
        #|INVARIANT (reset freq):
        #|freq[0..i) has been reset to zero for the new query.
        #|MAINTENANCE:
        #|Set freq[i] = 0 and advance i.
        #|TERMINATION:
        #|At i == max_val, all frequencies are cleared.
      ),
    }

    // Count frequencies
    for i = l; i < r; i = i + 1 {
      let val = arr[i]
      if val >= 0 && val <= max_val {
        freq[val] = freq[val] + 1
      }
    } where {
      invariant: i >= l && i <= r,
      reasoning: (
        #|INVARIANT (count freq):
        #|freq reflects counts for arr[l..i); indices [i..r) remain.
        #|MAINTENANCE:
        #|Increment freq[val] for arr[i] when in range and advance i.
        #|TERMINATION:
        #|At i == r, freq holds counts for the full query range.
      ),
    }

    // Find mode
    let mode = for i = 0, best = 0, best_freq = 0; i <= max_val; {
      if freq[i] > best_freq {
        continue i + 1, i, freq[i]
      }
      continue i + 1, best, best_freq
    } else {
      best
    } where {
      invariant: i >= 0 && i <= max_val + 1,
      reasoning: (
        #|INVARIANT (find mode):
        #|best/best_freq is the most frequent value in [0..i).
        #|MAINTENANCE:
        #|Compare freq[i] to best_freq and update if larger.
        #|TERMINATION:
        #|At i == max_val + 1, best is the mode.
      ),
    }
    results[qi] = mode
  } where {
    invariant: qi >= 0 && qi <= q,
    reasoning: (
      #|INVARIANT (range mode):
      #|results[0..qi) have been computed for previous queries.
      #|MAINTENANCE:
      #|Reset freq, count occurrences, compute mode, and store results[qi].
      #|TERMINATION:
      #|At qi == q, all modes are computed.
    ),
  }
  results
}

///|
test "range mode query" {
  let arr = [1, 2, 1, 1, 2, 3, 2, 2]
  let queries = [(0, 4), (4, 8), (0, 8)]
  let results = range_mode(arr[:], queries)
  assert_eq(results[0], 1) // [1,2,1,1] -> mode is 1
  assert_eq(results[1], 2) // [2,3,2,2] -> mode is 2
  assert_eq(results[2], 2) // full array -> mode is 2
}

///|
/// Block Decomposition for Range Sum with Updates
///
/// O(√n) for both query and update.
priv struct BlockSum {
  arr : Array[Int]
  block_sums : Array[Int]
  block_size : Int
}

///|
fn BlockSum::new(arr : Array[Int]) -> BlockSum {
  let n = arr.length()
  if n == 0 {
    return { arr, block_sums: [], block_size: 1 }
  }
  let block_size = mo_isqrt(n)
  let num_blocks = (n + block_size - 1) / block_size
  let block_sums : Array[Int] = Array::make(num_blocks, 0)
  for i = 0; i < n; i = i + 1 {
    block_sums[i / block_size] = block_sums[i / block_size] + arr[i]
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (build block sums):
      #|block_sums for blocks fully covered in arr[0..i) are correct.
      #|MAINTENANCE:
      #|Add arr[i] to its block sum and advance i.
      #|TERMINATION:
      #|At i == n, all block sums are computed.
    ),
  }
  { arr, block_sums, block_size }
}

///|
fn BlockSum::query_sum(self : BlockSum, l : Int, r : Int) -> Int {
  if l >= r || l < 0 || r > self.arr.length() {
    return 0
  }
  for i = l, result = 0; i < r; {
    let block_idx = i / self.block_size
    let block_start = block_idx * self.block_size
    let block_end = @cmp.minimum(block_start + self.block_size, r)
    if i == block_start &&
      block_end == block_start + self.block_size &&
      block_end <= r {
      // Full block
      continue block_end, result + self.block_sums[block_idx]
    } else {
      // Partial
      continue i + 1, result + self.arr[i]
    }
  } else {
    result
  } where {
    invariant: i >= l && i <= r,
    reasoning: (
      #|INVARIANT (range sum):
      #|result = sum(arr[l..i)); indices [i..r) remain.
      #|MAINTENANCE:
      #|If i aligns to a full block, add its sum and jump; otherwise add arr[i]
      #|and advance i.
      #|TERMINATION:
      #|At i == r, result equals sum(arr[l..r)).
    ),
  }
}

///|
fn BlockSum::update_block_sum(self : BlockSum, idx : Int, val : Int) -> Unit {
  if idx < 0 || idx >= self.arr.length() {
    return
  }
  let diff = val - self.arr[idx]
  self.arr[idx] = val
  self.block_sums[idx / self.block_size] = self.block_sums[idx / self.block_size] +
    diff
}

///|
test "block sum" {
  let arr = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  let bs = BlockSum::new(arr)
  assert_eq(bs.query_sum(0, 5), 15) // 1+2+3+4+5
  assert_eq(bs.query_sum(3, 7), 22) // 4+5+6+7
  bs.update_block_sum(4, 10) // Change 5 to 10
  assert_eq(bs.query_sum(0, 5), 20) // 1+2+3+4+10
}

///|
/// Union-Find with Path Compression (renamed to avoid conflict)
///
/// MATHEMATICAL FOUNDATION:
/// Amortized O(α(n)) per operation where α is inverse Ackermann function.
priv struct MoUnionFind {
  parent : Array[Int]
  rank : Array[Int]
}

///|
fn MoUnionFind::new(n : Int) -> MoUnionFind {
  let parent = Array::makei(n, i => i)
  let rank : Array[Int] = Array::make(n, 0)
  { parent, rank }
}

///|
fn MoUnionFind::find_mo(self : MoUnionFind, x : Int) -> Int {
  for curr = x; curr != self.parent[curr]; {
    let grandparent = self.parent[self.parent[curr]]
    self.parent[curr] = grandparent
    continue grandparent
  } else {
    curr
  } where {
    invariant: curr >= 0 && curr < self.parent.length(),
    reasoning: (
      #|INVARIANT (find with compression):
      #|curr is on the path from x to the root; parent pointers remain valid.
      #|MAINTENANCE:
      #|Jump to grandparent and compress the path, shortening future finds.
      #|TERMINATION:
      #|When curr is a root, return it as the representative.
    ),
  }
}

///|
fn MoUnionFind::union_mo(self : MoUnionFind, x : Int, y : Int) -> Bool {
  let px = self.find_mo(x)
  let py = self.find_mo(y)
  if px == py {
    return false
  }
  if self.rank[px] < self.rank[py] {
    self.parent[px] = py
  } else if self.rank[px] > self.rank[py] {
    self.parent[py] = px
  } else {
    self.parent[py] = px
    self.rank[px] = self.rank[px] + 1
  }
  true
}

///|
test "mo union find" {
  let uf = MoUnionFind::new(5)
  assert_true(uf.union_mo(0, 1))
  assert_true(uf.union_mo(2, 3))
  assert_eq(uf.find_mo(0), uf.find_mo(1))
  assert_true(uf.find_mo(0) != uf.find_mo(2))
  assert_true(uf.union_mo(1, 3))
  assert_eq(uf.find_mo(0), uf.find_mo(3))
  assert_false(uf.union_mo(0, 2)) // Already connected
}

///|
/// Offline LCA using naive approach
///
/// Process queries offline during DFS traversal.
fn offline_lca_simple(
  adj : Array[Array[Int]],
  queries : Array[(Int, Int)],
  root : Int,
) -> Array[Int] {
  let n = adj.length()
  let q = queries.length()
  let results : Array[Int] = Array::make(q, -1)
  let parent : Array[Int] = Array::make(n, -1)
  let depth : Array[Int] = Array::make(n, 0)

  // BFS to compute parent and depth
  let queue : Array[Int] = []
  let visited : Array[Bool] = Array::make(n, false)
  queue.push(root)
  visited[root] = true
  for front = 0; front < queue.length(); front = front + 1 {
    let node = queue[front]
    for idx = 0; idx < adj[node].length(); idx = idx + 1 {
      let child = adj[node][idx]
      if not(visited[child]) {
        visited[child] = true
        parent[child] = node
        depth[child] = depth[node] + 1
        queue.push(child)
      }
    } where {
      invariant: idx >= 0 && idx <= adj[node].length(),
      reasoning: (
        #|INVARIANT (BFS neighbors):
        #|Neighbors adj[node][0..idx) have been scanned; any newly discovered
        #|node has parent/depth set and is enqueued.
        #|MAINTENANCE:
        #|If child is unvisited, mark it, record parent/depth, and enqueue it.
        #|TERMINATION:
        #|At idx == degree, all neighbors of node are processed.
      ),
    }
  } where {
    invariant: front >= 0 && front <= queue.length(),
    reasoning: (
      #|INVARIANT (BFS queue):
      #|queue[0..front) nodes are fully expanded; queue[front..] are discovered
      #|but not processed. parent/depth are correct for visited nodes.
      #|MAINTENANCE:
      #|Expand queue[front] and enqueue its undiscovered neighbors.
      #|TERMINATION:
      #|At front == queue.length(), all reachable nodes are expanded.
    ),
  }

  // Answer queries
  for qi = 0; qi < q; qi = qi + 1 {
    let (u, v) = queries[qi]
    let mut u_curr = u
    let mut v_curr = v
    while depth[u_curr] > depth[v_curr] {
      u_curr = parent[u_curr]
    }
    while depth[v_curr] > depth[u_curr] {
      v_curr = parent[v_curr]
    }
    while u_curr != v_curr {
      u_curr = parent[u_curr]
      v_curr = parent[v_curr]
    }
    results[qi] = u_curr
  } where {
    invariant: qi >= 0 && qi <= q,
    reasoning: (
      #|INVARIANT (offline LCA):
      #|results[0..qi) contains correct LCAs for processed queries.
      #|MAINTENANCE:
      #|Lift deeper node, then move both up until they meet; store the meeting
      #|node as LCA in results[qi].
      #|TERMINATION:
      #|At qi == q, all queries have their LCAs.
    ),
  }
  results
}

///|
test "offline lca simple" {
  let adj : Array[Array[Int]] = [[1, 2], [0, 3, 4], [0], [1], [1]]
  let queries = [(3, 4), (3, 2), (1, 2)]
  let results = offline_lca_simple(adj, queries, 0)
  assert_eq(results[0], 1) // LCA(3,4) = 1
  assert_eq(results[1], 0) // LCA(3,2) = 0
  assert_eq(results[2], 0) // LCA(1,2) = 0
}

///|
/// Centroid of a Tree
///
/// A centroid is a node whose removal creates subtrees each with ≤ n/2 nodes.
fn find_tree_centroid(adj : Array[Array[Int]], root : Int) -> Int {
  let n = adj.length()
  let subtree_size : Array[Int] = Array::make(n, 0)
  let parent : Array[Int] = Array::make(n, -1)
  let stack : Array[(Int, Int)] = []
  let order : Array[Int] = []
  stack.push((root, -1))
  while stack.length() > 0 {
    let (node, par) = stack.pop().unwrap()
    parent[node] = par
    order.push(node)
    for idx = 0; idx < adj[node].length(); idx = idx + 1 {
      let child = adj[node][idx]
      if child != par {
        stack.push((child, node))
      }
    } where {
      invariant: idx >= 0 && idx <= adj[node].length(),
      reasoning: (
        #|INVARIANT (centroid DFS):
        #|Neighbors adj[node][0..idx) have been examined; non-parent children
        #|have been pushed to the stack.
        #|MAINTENANCE:
        #|If a neighbor is not the parent, push it for DFS.
        #|TERMINATION:
        #|At idx == degree, all neighbors of node are processed.
      ),
    }
  }
  for i = order.length() - 1; i >= 0; i = i - 1 {
    let node = order[i]
    subtree_size[node] = 1
    for idx = 0; idx < adj[node].length(); idx = idx + 1 {
      let child = adj[node][idx]
      if child != parent[node] {
        subtree_size[node] = subtree_size[node] + subtree_size[child]
      }
    } where {
      invariant: idx >= 0 && idx <= adj[node].length(),
      reasoning: (
        #|INVARIANT (subtree size):
        #|subtree_size[node] equals 1 plus sizes of processed child subtrees.
        #|MAINTENANCE:
        #|Add subtree_size[child] for each non-parent neighbor.
        #|TERMINATION:
        #|At idx == degree, subtree_size[node] is complete.
      ),
    }
  } where {
    invariant: i >= -1 && i < order.length(),
    reasoning: (
      #|INVARIANT (post-order):
      #|For nodes in order[i+1..], subtree_size is fully computed.
      #|MAINTENANCE:
      #|Process order[i] after its children to accumulate subtree sizes.
      #|TERMINATION:
      #|At i == -1, subtree_size is computed for all nodes.
    ),
  }
  let tree_size = subtree_size[root]
  for i = 0, centroid = root; i < n; {
    let node = order[i]
    let mut is_centroid = true
    for idx = 0; idx < adj[node].length(); idx = idx + 1 {
      let neighbor = adj[node][idx]
      let subtree = if neighbor == parent[node] {
        tree_size - subtree_size[node]
      } else {
        subtree_size[neighbor]
      }
      if subtree > tree_size / 2 {
        is_centroid = false
      }
    } where {
      invariant: idx >= 0 && idx <= adj[node].length(),
      reasoning: (
        #|INVARIANT (centroid check):
        #|is_centroid remains true iff all processed neighbor subtrees are <= n/2.
        #|MAINTENANCE:
        #|Compute the neighbor subtree size and invalidate if it exceeds n/2.
        #|TERMINATION:
        #|At idx == degree, is_centroid reflects the full condition.
      ),
    }
    if is_centroid {
      continue n, node
    }
    continue i + 1, centroid
  } else {
    centroid
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (find centroid):
      #|All nodes in order[0..i) have been checked; centroid holds any found.
      #|MAINTENANCE:
      #|Check order[i] and return it if all neighbor subtrees are <= n/2.
      #|TERMINATION:
      #|At i == n, a centroid has been found (tree always has one).
    ),
  }
}

///|
test "find tree centroid" {
  let adj : Array[Array[Int]] = [[1], [0, 2], [1, 3], [2, 4], [3]]
  let centroid = find_tree_centroid(adj, 0)
  assert_eq(centroid, 2) // Middle node
}

///|
/// Euler Tour for Subtree Queries
///
/// Maps tree to array: subtree[v] = arr[enter[v]..exit[v]]
priv struct EulerTour {
  enter : Array[Int]
  exit : Array[Int]
  tour : Array[Int]
}

///|
fn build_euler_tour(adj : Array[Array[Int]], root : Int) -> EulerTour {
  let n = adj.length()
  let enter : Array[Int] = Array::make(n, 0)
  let exit : Array[Int] = Array::make(n, 0)
  let tour : Array[Int] = []
  let stack : Array[(Int, Int, Int)] = []
  stack.push((root, -1, 0))
  let time = Array::make(1, 0)
  while stack.length() > 0 {
    let (node, par, state) = stack.pop().unwrap()
    if state == 0 {
      enter[node] = time[0]
      tour.push(node)
      time[0] = time[0] + 1
      stack.push((node, par, 1))
      for i = adj[node].length() - 1; i >= 0; i = i - 1 {
        let child = adj[node][i]
        if child != par {
          stack.push((child, node, 0))
        }
      } where {
        invariant: i >= -1 && i < adj[node].length(),
        reasoning: (
          #|INVARIANT (euler push order):
          #|Children adj[node][i+1..] have been pushed to the stack.
          #|MAINTENANCE:
          #|Push child i so the stack processes children in original order.
          #|TERMINATION:
          #|At i == -1, all children are scheduled for DFS.
        ),
      }
    } else {
      exit[node] = time[0]
    }
  }
  { enter, exit, tour }
}

///|
test "euler tour" {
  let adj : Array[Array[Int]] = [[1, 2], [0, 3], [0], [1]]
  let et = build_euler_tour(adj, 0)
  assert_true(et.enter[1] < et.enter[3])
  assert_true(et.enter[3] < et.exit[1])
  assert_eq(et.tour.length(), adj.length())
}

///|
/// Binary Lifting for LCA in O(log n)
///
/// Precompute 2^k ancestors for each node.
priv struct BinaryLifting {
  up : Array[Array[Int]]
  depth : Array[Int]
  log_n : Int
}

///|
fn build_binary_lifting(adj : Array[Array[Int]], root : Int) -> BinaryLifting {
  let n = adj.length()
  let log_n = 20
  let up = Array::makei(n, _ => Array::make(log_n, -1))
  let depth : Array[Int] = Array::make(n, 0)
  let queue : Array[Int] = []
  let visited : Array[Bool] = Array::make(n, false)
  queue.push(root)
  visited[root] = true
  up[root][0] = root
  for front = 0; front < queue.length(); front = front + 1 {
    let node = queue[front]
    for idx = 0; idx < adj[node].length(); idx = idx + 1 {
      let child = adj[node][idx]
      if not(visited[child]) {
        visited[child] = true
        depth[child] = depth[node] + 1
        up[child][0] = node
        queue.push(child)
      }
    } where {
      invariant: idx >= 0 && idx <= adj[node].length(),
      reasoning: (
        #|INVARIANT (binary lifting BFS neighbors):
        #|Neighbors adj[node][0..idx) are processed; discovered nodes have
        #|depth and up[][0] set.
        #|MAINTENANCE:
        #|When discovering a child, record parent/depth and enqueue it.
        #|TERMINATION:
        #|At idx == degree, all neighbors are handled.
      ),
    }
  } where {
    invariant: front >= 0 && front <= queue.length(),
    reasoning: (
      #|INVARIANT (binary lifting BFS):
      #|queue[0..front) nodes have depth and up[][0] set; queue[front..] are
      #|discovered but not processed.
      #|MAINTENANCE:
      #|Expand queue[front] and enqueue newly discovered neighbors.
      #|TERMINATION:
      #|At front == queue.length(), depth and up[][0] are filled.
    ),
  }
  for k = 1; k < log_n; k = k + 1 {
    for v = 0; v < n; v = v + 1 {
      let half_ancestor = up[v][k - 1]
      if half_ancestor >= 0 {
        up[v][k] = up[half_ancestor][k - 1]
      }
    } where {
      invariant: v >= 0 && v <= n,
      reasoning: (
        #|INVARIANT (lift table row):
        #|For fixed k, up[0..v) have their 2^k ancestors computed.
        #|MAINTENANCE:
        #|Compute up[v][k] from the 2^(k-1) ancestor when it exists.
        #|TERMINATION:
        #|At v == n, the k-th column is complete.
      ),
    }
  } where {
    invariant: k >= 1 && k <= log_n,
    reasoning: (
      #|INVARIANT (lift table columns):
      #|For all j < k, up[v][j] stores the 2^j ancestor of v.
      #|MAINTENANCE:
      #|Use up[v][k] = up[up[v][k-1]][k-1] to build the next column.
      #|TERMINATION:
      #|At k == log_n, the binary lifting table is complete.
    ),
  }
  { up, depth, log_n }
}

///|
fn BinaryLifting::lca_binary_lifting(
  self : BinaryLifting,
  u_in : Int,
  v_in : Int,
) -> Int {
  let mut u = u_in
  let mut v = v_in
  if self.depth[u] < self.depth[v] {
    let temp = u
    u = v
    v = temp
  }
  let diff = self.depth[u] - self.depth[v]
  for k = 0; k < self.log_n; k = k + 1 {
    if ((diff >> k) & 1) == 1 {
      u = self.up[u][k]
    }
  } where {
    invariant: k >= 0 && k <= self.log_n,
    reasoning: (
      #|INVARIANT (lift to depth):
      #|After processing bits < k, u has been lifted by those bits of diff.
      #|MAINTENANCE:
      #|If bit k is set, jump u to its 2^k ancestor.
      #|TERMINATION:
      #|At k == log_n, u and v are at the same depth.
    ),
  }
  if u == v {
    return u
  }
  for k = self.log_n - 1; k >= 0; k = k - 1 {
    if self.up[u][k] != self.up[v][k] {
      u = self.up[u][k]
      v = self.up[v][k]
    }
  } where {
    invariant: k >= -1 && k < self.log_n,
    reasoning: (
      #|INVARIANT (lift to LCA):
      #|LCA is an ancestor of both u and v; u and v stay at equal depth.
      #|MAINTENANCE:
      #|If ancestors differ at 2^k, lift both nodes up by 2^k.
      #|TERMINATION:
      #|After the loop, u and v are children of the LCA.
    ),
  }
  self.up[u][0]
}

///|
test "binary lifting lca" {
  let adj : Array[Array[Int]] = [[1, 2], [0, 3, 4], [0], [1], [1]]
  let bl = build_binary_lifting(adj, 0)
  assert_eq(bl.lca_binary_lifting(3, 4), 1)
  assert_eq(bl.lca_binary_lifting(3, 2), 0)
  assert_eq(bl.lca_binary_lifting(1, 2), 0)
  assert_eq(bl.lca_binary_lifting(3, 1), 1)
}
