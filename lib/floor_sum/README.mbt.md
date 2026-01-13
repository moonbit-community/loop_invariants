# Floor Sum

## Overview

Compute the sum:

```
S = sum_{i=0}^{n-1} floor((a*i + b) / m)
```

This uses the classic Euclidean reduction from AtCoder Library.

- **Time**: O(log m + log a)
- **Space**: O(1)

## Example

```mbt check
///|
test "floor sum example" {
  inspect(@floor_sum.floor_sum(4L, 5L, 3L, 2L), content="4")
}
```
