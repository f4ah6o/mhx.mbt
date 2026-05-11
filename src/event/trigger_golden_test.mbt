///|
fn parse_trigger_result(
  input : String,
) -> Result[Array[@trigger.TriggerDef], @parser.ParseError] {
  try? @parser.parse_trigger(input)
}

///|
fn parse_trigger_error_fixture(
  input : String,
) -> (String, Result[Array[@trigger.TriggerDef], @parser.ParseError]) {
  (input, parse_trigger_result(input))
}

///|
test "trigger golden supported issue examples" {
  json_inspect(parse_trigger_result("click"), content={
    "Ok": [{ "event": "click", "modifiers": [] }],
  })
  json_inspect(parse_trigger_result("click once"), content={
    "Ok": [{ "event": "click", "modifiers": [{ "type": "once" }] }],
  })
  json_inspect(parse_trigger_result("input changed debounce:300ms"), content={
    "Ok": [
      {
        "event": "input",
        "modifiers": [{ "type": "changed" }, { "type": "debounce", "ms": 300 }],
      },
    ],
  })
  json_inspect(parse_trigger_result("click[ctrlKey] delay:500ms"), content={
    "Ok": [
      {
        "event": "click",
        "modifiers": [
          { "type": "filter", "expr": "ctrlKey" },
          { "type": "delay", "ms": 500 },
        ],
      },
    ],
  })
  json_inspect(parse_trigger_result("submit prevent queue:last"), content={
    "Ok": [
      {
        "event": "submit",
        "modifiers": [
          { "type": "prevent" },
          { "type": "queue", "mode": "last" },
        ],
      },
    ],
  })
  json_inspect(parse_trigger_result("intersect once"), content={
    "Ok": [{ "event": "intersect", "modifiers": [{ "type": "once" }] }],
  })
}

///|
test "trigger golden supported lifecycle events" {
  json_inspect(parse_trigger_result("load"), content={
    "Ok": [{ "event": "load", "modifiers": [] }],
  })
  json_inspect(parse_trigger_result("revealed"), content={
    "Ok": [{ "event": "revealed", "modifiers": [] }],
  })
  json_inspect(parse_trigger_result("intersect once"), content={
    "Ok": [{ "event": "intersect", "modifiers": [{ "type": "once" }] }],
  })
}

///|
test "trigger golden supported modifiers" {
  json_inspect(
    parse_trigger_result(
      "click[ctrlKey] changed once consume prevent delay:500ms throttle:1s debounce:300ms queue:all",
    ),
    content={
      "Ok": [
        {
          "event": "click",
          "modifiers": [
            { "type": "filter", "expr": "ctrlKey" },
            { "type": "changed" },
            { "type": "once" },
            { "type": "consume" },
            { "type": "prevent" },
            { "type": "delay", "ms": 500 },
            { "type": "throttle", "ms": 1000 },
            { "type": "debounce", "ms": 300 },
            { "type": "queue", "mode": "all" },
          ],
        },
      ],
    },
  )
  json_inspect(parse_trigger_result("click from:body target:#result"), content={
    "Ok": [
      {
        "event": "click",
        "modifiers": [
          { "type": "from", "selector": "body" },
          { "type": "target", "selector": { "css": "#result" } },
        ],
      },
    ],
  })
  json_inspect(
    parse_trigger_result("click from:closest .item target:find .result"),
    content={
      "Ok": [
        {
          "event": "click",
          "modifiers": [
            { "type": "from", "selector": { "closest": ".item" } },
            { "type": "target", "selector": { "find": ".result" } },
          ],
        },
      ],
    },
  )
  json_inspect(
    parse_trigger_result("click from:next .row target:previous .message"),
    content={
      "Ok": [
        {
          "event": "click",
          "modifiers": [
            { "type": "from", "selector": { "next": ".row" } },
            { "type": "target", "selector": { "previous": ".message" } },
          ],
        },
      ],
    },
  )
  json_inspect(parse_trigger_result("click from:window target:document"), content={
    "Ok": [
      {
        "event": "click",
        "modifiers": [
          { "type": "from", "selector": "window" },
          { "type": "target", "selector": "document" },
        ],
      },
    ],
  })
  json_inspect(parse_trigger_result("click from:this target:this"), content={
    "Ok": [
      {
        "event": "click",
        "modifiers": [
          { "type": "from", "selector": "this" },
          { "type": "target", "selector": "this" },
        ],
      },
    ],
  })
}

///|
test "trigger golden supported queue modes" {
  json_inspect(parse_trigger_result("submit queue:drop"), content={
    "Ok": [
      { "event": "submit", "modifiers": [{ "type": "queue", "mode": "drop" }] },
    ],
  })
  json_inspect(parse_trigger_result("submit queue:replace"), content={
    "Ok": [
      {
        "event": "submit",
        "modifiers": [{ "type": "queue", "mode": "replace" }],
      },
    ],
  })
  json_inspect(parse_trigger_result("submit queue:first"), content={
    "Ok": [
      { "event": "submit", "modifiers": [{ "type": "queue", "mode": "first" }] },
    ],
  })
  json_inspect(parse_trigger_result("submit queue:last"), content={
    "Ok": [
      { "event": "submit", "modifiers": [{ "type": "queue", "mode": "last" }] },
    ],
  })
  json_inspect(parse_trigger_result("submit queue:all"), content={
    "Ok": [
      { "event": "submit", "modifiers": [{ "type": "queue", "mode": "all" }] },
    ],
  })
}

///|
test "trigger golden supported multiple triggers" {
  json_inspect(
    parse_trigger_result("load, click once, input changed debounce:300ms"),
    content={
      "Ok": [
        { "event": "load", "modifiers": [] },
        { "event": "click", "modifiers": [{ "type": "once" }] },
        {
          "event": "input",
          "modifiers": [
            { "type": "changed" },
            { "type": "debounce", "ms": 300 },
          ],
        },
      ],
    },
  )
}

///|
test "trigger golden parse errors include input and position" {
  inspect(
    parse_trigger_error_fixture("click delay"),
    content=(
      #|("click delay", Err(UnexpectedEnd(pos={offset: 11, char: '\u{00}'}, expected=":")))
    ),
  )
  inspect(
    parse_trigger_error_fixture("click delay:abc"),
    content=(
      #|("click delay:abc", Err(InvalidNumber(pos={offset: 12, char: 'a'}, value="")))
    ),
  )
  inspect(
    parse_trigger_error_fixture("click queue:middle"),
    content=(
      #|("click queue:middle", Err(InvalidModifier(pos={offset: 18, char: '\u{00}'}, name="queue:middle")))
    ),
  )
  inspect(
    parse_trigger_error_fixture("click[ctrlKey"),
    content=(
      #|("click[ctrlKey", Err(UnexpectedEnd(pos={offset: 13, char: '\u{00}'}, expected="]")))
    ),
  )
  inspect(
    parse_trigger_error_fixture("[ctrlKey]"),
    content=(
      #|("[ctrlKey]", Err(UnexpectedChar(pos={offset: 0, char: '['}, expected="event name (identifier)")))
    ),
  )
}
