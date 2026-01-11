# Persistent Li Chao Tree

Line container supporting min queries over a fixed integer domain.

## Example

```mbt check
///|
test "persistent li chao" {
  let lines = [
    @challenge_persistent_li_chao_tree.Line::{ m: 1, b: 0 },
    @challenge_persistent_li_chao_tree.Line::{ m: -1, b: 10 },
    @challenge_persistent_li_chao_tree.Line::{ m: 2, b: -5 },
  ]
  let tree = @challenge_persistent_li_chao_tree.from_array(lines[:], 0, 10)
  inspect(
    @challenge_persistent_li_chao_tree.query(tree, 0, 0, 10),
    content="-5",
  )
  inspect(@challenge_persistent_li_chao_tree.query(tree, 5, 0, 10), content="5")
  inspect(@challenge_persistent_li_chao_tree.query(tree, 9, 0, 10), content="1")
  inspect(@challenge_persistent_li_chao_tree.size(tree), content="3")
}
```
