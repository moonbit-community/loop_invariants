# Challenge: Z-Algorithm

Linear-time prefix matching with a sliding Z-box.

## Example

```mbt check
///|
test "z search example" {
  let matches = @challenge_z_algorithm.z_search("ababa"[:], "aba"[:])
  inspect(matches, content="[0, 2]")
}
```
