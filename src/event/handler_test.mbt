///|
test "parse_element_config captures sync and vals" {
  inspect(@sync.parse_sync_strategy("queue all"), content="Queue(All)")
  inspect(@sync.parse_sync_strategy("drop"), content="Drop")
}
