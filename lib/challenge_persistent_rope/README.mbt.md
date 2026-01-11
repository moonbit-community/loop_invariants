# Persistent Rope

Immutable concatenation tree for strings.

## Example

```mbt check
///|
test "persistent rope" {
  let r1 = @challenge_persistent_rope.leaf("hello")
  let r2 = @challenge_persistent_rope.leaf(" ")
  let r3 = @challenge_persistent_rope.leaf("world")
  let rope = @challenge_persistent_rope.concat_many([r1, r2, r3][:])
  inspect(@challenge_persistent_rope.to_string(rope), content="hello world")
  inspect(@challenge_persistent_rope.length(rope), content="11")
}
```
