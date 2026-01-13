///|
test "subset convolution small" {
  let f : Array[Int64] = [1L, 2L, 3L, 4L]
  let g : Array[Int64] = [5L, 6L, 7L, 8L]
  let h = @subset_convolution.subset_convolution(f[:], g[:])
  inspect(h, content="[5, 16, 22, 60]")
}
