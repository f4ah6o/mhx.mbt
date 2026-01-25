///|
test "parse simple event" {
  let triggers = @parser.parse_trigger("click")
  inspect(triggers.length(), content="1")
  inspect(triggers[0].event_name, content="click")
  inspect(triggers[0].modifiers.length(), content="0")
}

///|
test "parse event with once modifier" {
  let triggers = @parser.parse_trigger("click once")
  inspect(triggers.length(), content="1")
  inspect(triggers[0].event_name, content="click")
  inspect(triggers[0].is_once(), content="true")
}

///|
test "parse event with delay" {
  let triggers = @parser.parse_trigger("click delay:500ms")
  inspect(triggers.length(), content="1")
  inspect(triggers[0].get_delay(), content="Some(500)")
}

///|
test "parse event with delay in seconds" {
  let triggers = @parser.parse_trigger("click delay:2s")
  inspect(triggers.length(), content="1")
  inspect(triggers[0].get_delay(), content="Some(2000)")
}

///|
test "parse event with throttle" {
  let triggers = @parser.parse_trigger("scroll throttle:100ms")
  inspect(triggers.length(), content="1")
  inspect(triggers[0].get_throttle(), content="Some(100)")
}

///|
test "parse event with debounce" {
  let triggers = @parser.parse_trigger("input debounce:300ms")
  inspect(triggers.length(), content="1")
  inspect(triggers[0].get_debounce(), content="Some(300)")
}

///|
test "parse event with filter" {
  let triggers = @parser.parse_trigger("click[ctrlKey]")
  inspect(triggers.length(), content="1")
  inspect(triggers[0].get_filter(), content="Some(\"ctrlKey\")")
}

///|
test "parse event with complex filter" {
  let triggers = @parser.parse_trigger("keyup[key=='Enter']")
  inspect(triggers.length(), content="1")
  inspect(triggers[0].get_filter(), content="Some(\"key=='Enter'\")")
}

///|
test "parse event with from modifier" {
  let triggers = @parser.parse_trigger("click from:body")
  inspect(triggers.length(), content="1")
  inspect(triggers[0].get_from(), content="Some(Body)")
}

///|
test "parse event with from closest" {
  let triggers = @parser.parse_trigger("click from:closest .parent")
  inspect(triggers.length(), content="1")
  inspect(triggers[0].get_from(), content="Some(Closest(\".parent\"))")
}

///|
test "parse event with target css selector" {
  let triggers = @parser.parse_trigger("click target:#result")
  inspect(triggers.length(), content="1")
  inspect(triggers[0].get_target(), content="Some(Css(\"#result\"))")
}

///|
test "parse event with consume and prevent" {
  let triggers = @parser.parse_trigger("click consume prevent")
  inspect(triggers.length(), content="1")
  inspect(triggers[0].should_consume(), content="true")
  inspect(triggers[0].should_prevent(), content="true")
}

///|
test "parse event with queue mode" {
  let triggers = @parser.parse_trigger("click queue:replace")
  inspect(triggers.length(), content="1")
  inspect(triggers[0].get_queue_mode(), content="Replace")
}

///|
test "parse multiple events" {
  let triggers = @parser.parse_trigger("click, keyup")
  inspect(triggers.length(), content="2")
  inspect(triggers[0].event_name, content="click")
  inspect(triggers[1].event_name, content="keyup")
}

///|
test "parse complex trigger" {
  let triggers = @parser.parse_trigger(
    "click[ctrlKey] delay:500ms from:body once consume",
  )
  inspect(triggers.length(), content="1")
  let t = triggers[0]
  inspect(t.event_name, content="click")
  inspect(t.get_filter(), content="Some(\"ctrlKey\")")
  inspect(t.get_delay(), content="Some(500)")
  inspect(t.get_from(), content="Some(Body)")
  inspect(t.is_once(), content="true")
  inspect(t.should_consume(), content="true")
}

///|
test "parse trigger to_json" {
  let triggers = @parser.parse_trigger("click delay:500ms once")
  @json.inspect(triggers[0], content={
    "event": "click",
    "modifiers": [{ "type": "delay", "ms": 500 }, { "type": "once" }],
  })
}

///|
test "parse empty string" {
  let triggers = @parser.parse_trigger("")
  inspect(triggers.length(), content="0")
}

///|
test "parse whitespace only" {
  let triggers = @parser.parse_trigger("   ")
  inspect(triggers.length(), content="0")
}

///|
test "panic parse invalid modifier" {
  let result : Result[_, _] = try? @parser.parse_trigger(
    "click invalid_modifier:value",
  )
  inspect(
    result,
    content="Err(InvalidModifier(Position({ offset: 27, char: '\\x00' }), \"invalid_modifier\"))",
  )
}
