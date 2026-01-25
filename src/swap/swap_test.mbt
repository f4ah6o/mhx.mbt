///|
test "Strategy::from_string parses valid strategies" {
  assert_eq(Strategy::from_string("innerHTML"), Strategy::InnerHTML)
  assert_eq(Strategy::from_string("outerHTML"), Strategy::OuterHTML)
  assert_eq(Strategy::from_string("beforebegin"), Strategy::BeforeBegin)
  assert_eq(Strategy::from_string("afterbegin"), Strategy::AfterBegin)
  assert_eq(Strategy::from_string("beforeend"), Strategy::BeforeEnd)
  assert_eq(Strategy::from_string("afterend"), Strategy::AfterEnd)
  assert_eq(Strategy::from_string("delete"), Strategy::Delete)
  assert_eq(Strategy::from_string("none"), Strategy::None_)
}

///|
test "Strategy::from_string is case-insensitive" {
  assert_eq(Strategy::from_string("INNERHTML"), Strategy::InnerHTML)
  assert_eq(Strategy::from_string("InnerHTML"), Strategy::InnerHTML)
  assert_eq(Strategy::from_string("OUTERHTML"), Strategy::OuterHTML)
}

///|
test "Strategy::from_string defaults to innerHTML" {
  assert_eq(Strategy::from_string("unknown"), Strategy::InnerHTML)
  assert_eq(Strategy::from_string(""), Strategy::InnerHTML)
}

///|
test "SwapOptions::default has correct values" {
  let opts = SwapOptions::default()
  assert_eq(opts.strategy, Strategy::InnerHTML)
  assert_eq(opts.swap_delay, 0)
  assert_eq(opts.settle_delay, 20)
  assert_eq(opts.scroll, "")
  assert_eq(opts.focus_scroll, false)
}

///|
test "SwapOptions::parse parses simple strategy" {
  let opts = SwapOptions::parse("outerHTML")
  assert_eq(opts.strategy, Strategy::OuterHTML)
}

///|
test "SwapOptions::parse parses swap delay in ms" {
  let opts = SwapOptions::parse("innerHTML swap:500ms")
  assert_eq(opts.swap_delay, 500)
}

///|
test "SwapOptions::parse parses swap delay in seconds" {
  let opts = SwapOptions::parse("innerHTML swap:2s")
  assert_eq(opts.swap_delay, 2000)
}

///|
test "SwapOptions::parse parses fractional seconds" {
  let opts = SwapOptions::parse("innerHTML swap:1.5s")
  assert_eq(opts.swap_delay, 1500)
}

///|
test "SwapOptions::parse parses settle delay" {
  let opts = SwapOptions::parse("innerHTML settle:100ms")
  assert_eq(opts.settle_delay, 100)
}

///|
test "SwapOptions::parse parses scroll modifier" {
  let opts = SwapOptions::parse("innerHTML scroll:top")
  assert_eq(opts.scroll, "top")
}

///|
test "SwapOptions::parse parses multiple modifiers" {
  let opts = SwapOptions::parse(
    "outerHTML swap:200ms settle:50ms scroll:bottom",
  )
  assert_eq(opts.strategy, Strategy::OuterHTML)
  assert_eq(opts.swap_delay, 200)
  assert_eq(opts.settle_delay, 50)
  assert_eq(opts.scroll, "bottom")
}

///|
test "SwapOptions::parse handles empty string" {
  let opts = SwapOptions::parse("")
  assert_eq(opts.strategy, Strategy::InnerHTML)
}

///|
test "SwapOptions::parse ignores unknown modifiers" {
  let opts = SwapOptions::parse("innerHTML unknown:value")
  assert_eq(opts.strategy, Strategy::InnerHTML)
  // Should not crash, just ignore
}

///|
test "parse_time_ms handles various formats" {
  // Test via SwapOptions::parse
  let opts1 = SwapOptions::parse("innerHTML swap:500")
  assert_eq(opts1.swap_delay, 500)
  let opts2 = SwapOptions::parse("innerHTML swap:500ms")
  assert_eq(opts2.swap_delay, 500)
  let opts3 = SwapOptions::parse("innerHTML swap:1s")
  assert_eq(opts3.swap_delay, 1000)
}
