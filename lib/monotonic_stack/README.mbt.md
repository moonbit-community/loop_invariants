# Monotonic Stack

This package is a **tutorial** package (no exported functions). It explains
how to use a **monotonic stack** to solve "nearest greater/smaller" problems
in linear time.

A monotonic stack stores indices so the values are always in sorted order:

- **Decreasing stack**: values strictly decrease from bottom to top.
  Useful for "next greater".
- **Increasing stack**: values strictly increase from bottom to top.
  Useful for "next smaller".

---

## 1. The basic idea

Suppose we scan the array from left to right. When we see a new value, we can
decide answers for some earlier indices, because the new value is the first
value to the right that is larger/smaller.

The stack holds **indices that are still waiting for an answer**.

If we need "next greater to the right":

- Keep a **decreasing** stack of values.
- When we see a bigger value, it resolves all smaller ones on the top.

---

## 2. A small picture

Array: `[4, 5, 2, 10, 8]`

```
index:  0  1  2  3  4
value:  4  5  2 10  8

stack holds indices (top at the right)
```

Step-by-step:

```
i=0 (4):  stack []        -> push 0      stack [0]        values [4]
i=1 (5):  5 > 4 -> pop 0  -> answer[0]=5 -> push 1        stack [1] values [5]
i=2 (2):  2 > 5? no       -> push 2      stack [1,2]      values [5,2]
i=3 (10): 10 > 2 pop 2    -> answer[2]=10
           10 > 5 pop 1   -> answer[1]=10
           push 3         -> stack [3]   values [10]
i=4 (8):  8 > 10? no      -> push 4      stack [3,4]      values [10,8]

remaining indices 3 and 4 have no next greater -> answer = -1
```

Final answer: `[5, 10, 10, -1, -1]`.

---

## 3. Example 1: next greater element (to the right)

```mbt check
///|
fn next_greater_right(a : ArrayView[Int]) -> Array[Int] {
  let n = a.length()
  let ans = Array::make(n, -1)
  let stack : Array[Int] = []
  for i in 0..<n {
    let ai = a[i]
    while stack.length() > 0 && a[stack[stack.length() - 1]] < ai {
      let top = stack[stack.length() - 1]
      let _ = stack.pop()
      ans[top] = ai
    }
    stack.push(i)
  }
  ans
}

///|
test "next greater to the right" {
  let a : Array[Int] = [4, 5, 2, 10, 8]
  inspect(next_greater_right(a[:]), content="[5, 10, 10, -1, -1]")
}
```

---

## 4. Example 2: previous smaller element (to the left)

This time we want the **nearest smaller** on the left.
We keep an **increasing** stack.

```mbt check
///|
fn prev_smaller_left(a : ArrayView[Int]) -> Array[Int] {
  let n = a.length()
  let ans = Array::make(n, -1)
  let stack : Array[Int] = []
  for i in 0..<n {
    let ai = a[i]
    while stack.length() > 0 && a[stack[stack.length() - 1]] >= ai {
      let _ = stack.pop()
    }
    if stack.length() > 0 {
      let top = stack[stack.length() - 1]
      ans[i] = a[top]
    }
    stack.push(i)
  }
  ans
}

///|
test "previous smaller to the left" {
  let a : Array[Int] = [3, 5, 2, 7, 6]
  inspect(prev_smaller_left(a[:]), content="[-1, 3, -1, 2, 2]")
}
```

---

## 5. Example 3: stock span

Stock span asks: for each day, how many consecutive days (including today)
have price <= today's price.

```
prices: [100, 80, 60, 70, 60, 75, 85]
span:   [  1,  1,  1,  2,  1,  4,  6]
```

This is the **distance to the previous greater element**.

```mbt check
///|
fn stock_span(prices : ArrayView[Int]) -> Array[Int] {
  let n = prices.length()
  let span = Array::make(n, 0)
  let stack : Array[Int] = []
  for i in 0..<n {
    let p = prices[i]
    while stack.length() > 0 && prices[stack[stack.length() - 1]] <= p {
      let _ = stack.pop()
    }
    if stack.length() == 0 {
      span[i] = i + 1
    } else {
      let top = stack[stack.length() - 1]
      span[i] = i - top
    }
    stack.push(i)
  }
  span
}

///|
test "stock span" {
  let prices : Array[Int] = [100, 80, 60, 70, 60, 75, 85]
  inspect(stock_span(prices[:]), content="[1, 1, 1, 2, 1, 4, 6]")
}
```

---

## 6. Example 4: largest rectangle in a histogram

The classic histogram problem:

```
heights = [2, 1, 5, 6, 2, 3]

index:   0  1  2  3  4  5
height:  2  1  5  6  2  3

largest area = 10  (height 5, width 2)
```

Key idea:

- For each bar i, find:
  - nearest smaller to the left (L)
  - nearest smaller to the right (R)
- Then the max rectangle using bar i is:

```
area[i] = height[i] * (R - L - 1)
```

We can compute L and R with two monotonic stacks.

Diagram (the rectangle of height 5):

```
index:   0  1  2  3  4  5
height:  2  1  5  6  2  3
                 _
                | |
            _   | |
           | |  | |
           | |  | |
           | |__| |
           |______|
            width=2
```

---

## 7. Example 5: trapping rain water

Another common use:

```
heights = [0,1,0,2,1,0,1,3,2,1,2,1]
water   = 6
```

Using a monotonic **decreasing** stack of indices:

- When we see a bar taller than the stack top, we can trap water.
- The trapped water is bounded by:
  - the new bar (right boundary)
  - the bar below the popped top (left boundary)

ASCII picture:

```
height: 0 1 0 2 1 0 1 3 2 1 2 1
water :   ~ ~   ~ ~ ~
```

---

## 8. Variants cheat sheet

```
Goal                     Stack order   Scan
------------------------------------------------
Next greater to right    decreasing    left -> right
Next smaller to right    increasing    left -> right
Prev greater to left     decreasing    left -> right
Prev smaller to left     increasing    left -> right
```

Tip for duplicates:

- If equal values should count as "greater", use `<=` when popping.
- If equal values should not count, use `<` when popping.

---

## 9. Why it is O(n)

Each index:

- is pushed once
- is popped at most once

So total operations are bounded by `2n`.

---

## 10. Practical tips

1. **Store indices, not values**. This lets you compute distances and ranges.
2. **Keep the invariant simple**: decide whether the stack should be strictly
   increasing or decreasing, then never violate it.
3. **Choose your comparison carefully** (`<` vs `<=`) when duplicates exist.
4. **Use arrays as stacks**: `push`, `pop`, and `last` are enough.

---

## 11. Summary

A monotonic stack is a small but powerful trick:

- It turns many "nearest greater/smaller" problems into linear scans.
- It is the backbone of stock span, histogram area, rain water, and more.
- The only real work is choosing the correct comparison direction.
