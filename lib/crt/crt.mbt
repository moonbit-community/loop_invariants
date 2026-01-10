// ============================================================================
// CHINESE REMAINDER THEOREM - System of Modular Equations
// ============================================================================
//
// CRT finds x such that x ≡ a_i (mod m_i) for all i, where m_i are pairwise coprime.
//
// KEY INSIGHT: For coprime moduli m_1, ..., m_k with product M = m_1 * ... * m_k,
// x = Σ a_i * M_i * y_i (mod M)
// where M_i = M / m_i and y_i = M_i^(-1) (mod m_i)
//
// CONSTRUCTION:
// 1. Compute M = product of all moduli
// 2. For each i: M_i = M / m_i
// 3. Find y_i such that M_i * y_i ≡ 1 (mod m_i) using extended GCD
// 4. x = Σ a_i * M_i * y_i (mod M)
//
// GARNER'S ALGORITHM: More numerically stable alternative.
//
// INVARIANTS:
// 1. gcd(m_i, m_j) = 1 for all i ≠ j (coprime condition)
// 2. Solution is unique modulo M = product of moduli
// 3. x ≡ a_i (mod m_i) for all i
//
// TIME COMPLEXITY: O(n log M) where n is number of equations
// SPACE COMPLEXITY: O(n)

///|
/// Extended Euclidean algorithm: returns (gcd, x, y) where ax + by = gcd
fn extended_gcd(a : Int64, b : Int64) -> (Int64, Int64, Int64) {
  if b == 0L {
    return (a, 1L, 0L)
  }

  let (g, x1, y1) = extended_gcd(b, a % b)
  let x = y1
  let y = x1 - (a / b) * y1

  (g, x, y)
}

///|
/// Modular multiplicative inverse of a mod m (requires gcd(a, m) = 1)
fn mod_inverse_crt(a : Int64, m : Int64) -> Int64? {
  let (g, x, _) = extended_gcd(a, m)
  if g != 1L {
    return None // No inverse exists
  }
  Some(((x % m) + m) % m)
}

///|
/// Solve system of congruences using CRT
/// Returns x such that x ≡ remainders[i] (mod moduli[i])
fn chinese_remainder_theorem(
  remainders : Array[Int64],
  moduli : Array[Int64]
) -> Int64? {
  let n = remainders.length()
  if n == 0 || n != moduli.length() {
    return None
  }

  // Check for coprimality and compute M
  let mut m_product = 1L
  for i = 0; i < n; i = i + 1 {
    if moduli[i] <= 0L {
      return None
    }
    for j = i + 1; j < n; j = j + 1 {
      let (g, _, _) = extended_gcd(moduli[i], moduli[j])
      if g != 1L {
        return None // Not coprime
      }
    }
    m_product = m_product * moduli[i]
  }

  let mut result = 0L

  for i = 0; i < n; i = i + 1 {
    let m_i = m_product / moduli[i]
    match mod_inverse_crt(m_i, moduli[i]) {
      Some(y_i) => {
        // result += a_i * M_i * y_i
        let term = ((remainders[i] % m_product) * (m_i % m_product)) % m_product
        let term2 = (term * (y_i % m_product)) % m_product
        result = (result + term2) % m_product
      }
      None => return None
    }
  }

  Some(((result % m_product) + m_product) % m_product)
}

///|
/// CRT for two equations (simpler special case)
fn crt_two(a1 : Int64, m1 : Int64, a2 : Int64, m2 : Int64) -> Int64? {
  let (g, p, _) = extended_gcd(m1, m2)

  // Check if solution exists
  if (a2 - a1) % g != 0L {
    return None
  }

  let lcm = m1 / g * m2
  let diff = ((a2 - a1) % lcm + lcm) % lcm
  let x = (a1 + m1 * ((diff / g * p) % (m2 / g))) % lcm

  Some(((x % lcm) + lcm) % lcm)
}

///|
/// Garner's algorithm (more numerically stable for large moduli)
fn garner(remainders : Array[Int64], moduli : Array[Int64]) -> Int64? {
  let n = remainders.length()
  if n == 0 || n != moduli.length() {
    return None
  }

  // Coefficients for mixed radix representation
  let coeffs = Array::make(n, 0L)
  coeffs[0] = remainders[0] % moduli[0]

  for i = 1; i < n; i = i + 1 {
    // Compute coefficient[i]
    let mut sum = coeffs[0]
    let mut prod = 1L

    for j = 0; j < i; j = j + 1 {
      prod = prod * moduli[j] % moduli[i]
    }

    for j = 1; j < i; j = j + 1 {
      let mut p = 1L
      for k = j; k < i; k = k + 1 {
        p = p * moduli[k] % moduli[i]
      }
      sum = (sum + coeffs[j] * p) % moduli[i]
    }

    let diff = ((remainders[i] - sum) % moduli[i] + moduli[i]) % moduli[i]
    match mod_inverse_crt(prod, moduli[i]) {
      Some(inv) => coeffs[i] = diff * inv % moduli[i]
      None => return None
    }
  }

  // Reconstruct result from coefficients
  let mut result = coeffs[0]
  let mut prod = moduli[0]

  for i = 1; i < n; i = i + 1 {
    result = result + coeffs[i] * prod
    prod = prod * moduli[i]
  }

  Some(result)
}

// ============================================================================
// APPLICATIONS
// ============================================================================

///|
/// Solve linear congruence ax ≡ b (mod m)
fn solve_linear_congruence(a : Int64, b : Int64, m : Int64) -> Array[Int64] {
  let (g, x, _) = extended_gcd(a, m)

  if b % g != 0L {
    return [] // No solution
  }

  let x0 = ((x * (b / g)) % m + m) % m
  let solutions : Array[Int64] = []
  let step = m / g

  let mut sol = x0
  for i = 0L; i < g; i = i + 1L {
    solutions.push(((sol % m) + m) % m)
    sol = sol + step
  }

  // Sort solutions
  for i = 0; i < solutions.length(); i = i + 1 {
    for j = i + 1; j < solutions.length(); j = j + 1 {
      if solutions[j] < solutions[i] {
        let tmp = solutions[i]
        solutions[i] = solutions[j]
        solutions[j] = tmp
      }
    }
  }

  solutions
}

///|
/// Check if system has solution (moduli may not be coprime)
fn has_solution(remainders : Array[Int64], moduli : Array[Int64]) -> Bool {
  let n = remainders.length()
  if n == 0 {
    return true
  }

  // Build up solution pairwise
  let mut a = remainders[0]
  let mut m = moduli[0]

  for i = 1; i < n; i = i + 1 {
    match crt_two(a, m, remainders[i], moduli[i]) {
      Some(new_a) => {
        let (g, _, _) = extended_gcd(m, moduli[i])
        a = new_a
        m = m / g * moduli[i]
      }
      None => return false
    }
  }

  true
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "extended_gcd" {
  let (g, x, y) = extended_gcd(35L, 15L)
  inspect(g, content="5")
  inspect(35L * x + 15L * y == 5L, content="true")
}

///|
test "mod_inverse" {
  match mod_inverse_crt(3L, 7L) {
    Some(inv) => inspect(3L * inv % 7L, content="1")
    None => fail("Expected inverse to exist")
  }
}

///|
test "crt basic" {
  // x ≡ 2 (mod 3), x ≡ 3 (mod 5), x ≡ 2 (mod 7)
  // Solution: x = 23
  let remainders : Array[Int64] = [2L, 3L, 2L]
  let moduli : Array[Int64] = [3L, 5L, 7L]

  match chinese_remainder_theorem(remainders, moduli) {
    Some(x) => {
      inspect(x % 3L, content="2")
      inspect(x % 5L, content="3")
      inspect(x % 7L, content="2")
    }
    None => fail("Expected solution")
  }
}

///|
test "crt_two" {
  // x ≡ 2 (mod 3), x ≡ 3 (mod 5)
  // Solution: x = 8 (mod 15)
  match crt_two(2L, 3L, 3L, 5L) {
    Some(x) => {
      inspect(x % 3L, content="2")
      inspect(x % 5L, content="3")
    }
    None => fail("Expected solution")
  }
}

///|
test "crt single" {
  let remainders : Array[Int64] = [5L]
  let moduli : Array[Int64] = [7L]

  match chinese_remainder_theorem(remainders, moduli) {
    Some(x) => inspect(x, content="5")
    None => fail("Expected solution")
  }
}

///|
test "garner" {
  // Test that garner gives a valid solution
  let remainders : Array[Int64] = [2L, 3L]
  let moduli : Array[Int64] = [3L, 5L]

  match garner(remainders, moduli) {
    Some(x) => {
      // Just check it's a valid solution
      inspect(x % 3L == 2L && x % 5L == 3L, content="true")
    }
    None => fail("Expected solution")
  }
}

///|
test "linear_congruence" {
  // 4x ≡ 2 (mod 6)
  // gcd(4, 6) = 2 divides 2, so solutions exist
  let solutions = solve_linear_congruence(4L, 2L, 6L)
  inspect(solutions.length(), content="2")
}

///|
test "linear_congruence no solution" {
  // 4x ≡ 3 (mod 6)
  // gcd(4, 6) = 2 does not divide 3, no solution
  let solutions = solve_linear_congruence(4L, 3L, 6L)
  inspect(solutions.length(), content="0")
}

///|
test "has_solution true" {
  let remainders : Array[Int64] = [2L, 3L]
  let moduli : Array[Int64] = [3L, 5L]
  inspect(has_solution(remainders, moduli), content="true")
}

///|
test "crt not coprime" {
  // Moduli 4 and 6 are not coprime
  let remainders : Array[Int64] = [1L, 1L]
  let moduli : Array[Int64] = [4L, 6L]

  inspect(chinese_remainder_theorem(remainders, moduli), content="None")
}

///|
test "mod_inverse none" {
  // 2 has no inverse mod 4 (gcd(2,4) = 2 ≠ 1)
  inspect(mod_inverse_crt(2L, 4L), content="None")
}
