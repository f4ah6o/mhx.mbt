///|
test "TriggerDef::simple creates trigger with no modifiers" {
  let t = TriggerDef::simple("click")
  inspect(t.event_name, content="click")
  inspect(t.modifiers.length(), content="0")
}

///|
test "TriggerDef::new creates trigger with modifiers" {
  let t = TriggerDef::new("click", [Once, Delay(500)])
  inspect(t.event_name, content="click")
  inspect(t.modifiers.length(), content="2")
}

///|
test "TriggerDef modifier accessors" {
  let t = TriggerDef::new(
    "click",
    [
      Once,
      Delay(500),
      Throttle(100),
      Debounce(200),
      From(Body),
      Target(Css("#target")),
      Filter("ctrlKey"),
      Consume,
      Prevent,
      Queue(Replace),
    ],
  )
  inspect(t.is_once(), content="true")
  inspect(t.get_delay(), content="Some(500)")
  inspect(t.get_throttle(), content="Some(100)")
  inspect(t.get_debounce(), content="Some(200)")
  inspect(t.get_from(), content="Some(Body)")
  inspect(t.get_target(), content="Some(Css(\"#target\"))")
  inspect(t.get_filter(), content="Some(\"ctrlKey\")")
  inspect(t.should_consume(), content="true")
  inspect(t.should_prevent(), content="true")
  inspect(t.get_queue_mode(), content="Replace")
}

///|
test "TriggerDef default queue mode is Drop" {
  let t = TriggerDef::simple("click")
  inspect(t.get_queue_mode(), content="Drop")
}

///|
test "Selector variants" {
  let selectors : Array[Selector] = [
    This,
    Body,
    Window,
    Document,
    Closest(".parent"),
    Find(".child"),
    Next(".sibling"),
    Previous(".prev"),
    Css("#my-id"),
  ]
  inspect(selectors.length(), content="9")
}

///|
test "TriggerDef to_json" {
  let t = TriggerDef::new("click", [Delay(500), Once])
  @json.inspect(
    t,
    content={
      "event": "click",
      "modifiers": [{ "type": "delay", "ms": 500 }, { "type": "once" }],
    },
  )
}
