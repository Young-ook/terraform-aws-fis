# drawing lots for choosing an item from list
resource "random_integer" "roulette" {
  min = 0
  max = length(var.items) - 1
}
