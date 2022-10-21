# drawing lots for choosing a subnet
resource "random_integer" "az" {
  min = 0
  max = length(var.azs) - 1
}
