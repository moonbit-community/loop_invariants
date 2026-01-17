# Challenge: Binary Search on Answer

Binary search on answer is a common technique for problems that ask:

"Find the smallest value X such that a condition is true."

The key requirement is that the condition is **monotone**:

- if X works, any larger value also works
- if X fails, any smaller value also fails

This package uses a shipping-capacity example to demonstrate the pattern.

## Problem statement (shipping capacity)

You are given:

- an array of package weights (in order)
- a number of days

Each day you can ship a consecutive prefix of the remaining packages, as long
as the total weight for that day does not exceed the chosen capacity.

Goal: **find the smallest capacity** that allows shipping all packages within
the given number of days.

## Why it is monotone

If capacity C is enough to ship in `days` days, then any capacity C+1 also
works, because you only get more room. So the predicate:

```
feasible(C) = "can ship within days"
```

is monotone.

## Diagram intuition

Imagine weights laid out in order:

```
weights: 3  2  2  4  1  4
capacity = 6

Day 1: 3 + 2 = 5
Day 2: 2 + 4 = 6
Day 3: 1 + 4 = 5
```

Capacity 6 works in 3 days. Capacity 5 does not.

## Algorithm outline

1. Lower bound = max weight (a day must fit the heaviest package).
2. Upper bound = sum of weights (ship all in one day).
3. Binary search that range using `can_ship` as the predicate.

Pseudocode:

```mbt nocheck
low = max(weights)
high = sum(weights)

while low < high:
  mid = (low + high) / 2
  if feasible(mid):
    high = mid
  else:
    low = mid + 1
return low
```

## Examples

### Example 1: basic case

```mbt check
///|
test "capacity for 1..10" {
  let weights : Array[Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  let ans = @challenge_binary_search_answer.min_capacity(weights[:], 5)
  inspect(ans, content="15")
}
```

One valid partition with capacity 15:

```
Day 1: 1+2+3+4+5 = 15
Day 2: 6+7 = 13
Day 3: 8
Day 4: 9
Day 5: 10
```

### Example 2: feasibility check

```mbt check
///|
test "feasibility check" {
  let weights : Array[Int] = [3, 2, 2, 4, 1, 4]
  inspect(
    @challenge_binary_search_answer.can_ship(weights[:], 3, 6),
    content="true",
  )
  inspect(
    @challenge_binary_search_answer.can_ship(weights[:], 3, 5),
    content="false",
  )
}
```

### Example 3: days equals number of packages

If you have at least as many days as packages, the minimum capacity is just
`max(weights)`.

```mbt check
///|
test "days equals packages" {
  let weights : Array[Int] = [2, 8, 3]
  let ans = @challenge_binary_search_answer.min_capacity(weights[:], 3)
  inspect(ans, content="8")
}
```

### Example 4: only one day

If you have only one day, the capacity must be the sum.

```mbt check
///|
test "one day" {
  let weights : Array[Int] = [2, 8, 3]
  let ans = @challenge_binary_search_answer.min_capacity(weights[:], 1)
  inspect(ans, content="13")
}
```

## Complexity

Let `R` be the search range (upper bound - lower bound).

- Each feasibility check: O(n)
- Binary search steps: O(log R)
- Total: O(n log R)

## Practical notes and pitfalls

- Always compute the lower bound as `max(weights)`, not 0.
- The order of packages is fixed; you cannot reorder them.
- The predicate must be monotone, or binary search gives wrong answers.
