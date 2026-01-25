///|
/// Parser for mx-trigger attribute values
/// Converts DSL strings to typed TriggerDef structures

///|
/// Parse a complete trigger specification
/// e.g., "click", "click delay:500ms", "click, keyup"
pub fn parse_trigger(
  input : String,
) -> Array[@trigger.TriggerDef] raise ParseError {
  let scanner = Scanner::new(input)
  let triggers : Array[@trigger.TriggerDef] = []
  scanner.skip_whitespace()
  while not(scanner.is_eof()) {
    let trigger = parse_single_trigger(scanner)
    triggers.push(trigger)
    scanner.skip_whitespace()
    // Check for comma separator
    if scanner.try_consume(',') {
      scanner.skip_whitespace()
    }
  }
  triggers
}

///|
/// Parse a single trigger definition
fn parse_single_trigger(
  scanner : Scanner,
) -> @trigger.TriggerDef raise ParseError {
  // Parse event name
  let event_name = scanner.scan_identifier()
  if event_name.is_empty() {
    raise UnexpectedChar(
      pos=scanner.make_position(),
      expected="event name (identifier)",
    )
  }
  // Parse modifiers
  let modifiers = parse_modifiers(scanner)
  @trigger.TriggerDef::new(event_name, modifiers)
}

///|
/// Parse modifiers following an event name
fn parse_modifiers(
  scanner : Scanner,
) -> Array[@trigger.Modifier] raise ParseError {
  let modifiers : Array[@trigger.Modifier] = []
  while not(scanner.is_eof()) && not(scanner.check(',')) {
    scanner.skip_whitespace()
    if scanner.is_eof() || scanner.check(',') {
      break
    }
    // Filter condition: [expression]
    if scanner.check('[') {
      let expr = scanner.scan_bracketed()
      modifiers.push(@trigger.Modifier::Filter(expr))
      continue
    }
    // Named modifiers: name or name:value
    let name = scanner.scan_identifier()
    if name.is_empty() {
      break
    }
    let modifier = parse_modifier_by_name(scanner, name)
    modifiers.push(modifier)
  }
  modifiers
}

///|
/// Parse a modifier by its name
fn parse_modifier_by_name(
  scanner : Scanner,
  name : String,
) -> @trigger.Modifier raise ParseError {
  match name {
    "once" => @trigger.Modifier::Once
    "changed" => @trigger.Modifier::Changed
    "consume" => @trigger.Modifier::Consume
    "prevent" => @trigger.Modifier::Prevent
    "delay" => {
      scanner.skip_whitespace()
      scanner.expect(':')
      scanner.skip_whitespace()
      let ms = parse_time_value(scanner)
      @trigger.Modifier::Delay(ms)
    }
    "throttle" => {
      scanner.skip_whitespace()
      scanner.expect(':')
      scanner.skip_whitespace()
      let ms = parse_time_value(scanner)
      @trigger.Modifier::Throttle(ms)
    }
    "debounce" => {
      scanner.skip_whitespace()
      scanner.expect(':')
      scanner.skip_whitespace()
      let ms = parse_time_value(scanner)
      @trigger.Modifier::Debounce(ms)
    }
    "from" => {
      scanner.skip_whitespace()
      scanner.expect(':')
      scanner.skip_whitespace()
      let selector = parse_selector(scanner)
      @trigger.Modifier::From(selector)
    }
    "target" => {
      scanner.skip_whitespace()
      scanner.expect(':')
      scanner.skip_whitespace()
      let selector = parse_selector(scanner)
      @trigger.Modifier::Target(selector)
    }
    "queue" => {
      scanner.skip_whitespace()
      scanner.expect(':')
      scanner.skip_whitespace()
      let mode = parse_queue_mode(scanner)
      @trigger.Modifier::Queue(mode)
    }
    _ => raise InvalidModifier(pos=scanner.make_position(), name~)
  }
}

///|
/// Parse a time value (number with optional ms/s suffix)
fn parse_time_value(scanner : Scanner) -> Int raise ParseError {
  let value = scanner.scan_int()
  // Check for time unit suffix
  let unit = scanner.scan_identifier()
  match unit {
    "" | "ms" => value
    "s" => value * 1000
    _ => value // Assume ms if unknown
  }
}

///|
/// Parse a selector value
fn parse_selector(scanner : Scanner) -> @trigger.Selector {
  let value = scanner.scan_selector_value()
  match value {
    "this" => @trigger.Selector::This
    "body" => @trigger.Selector::Body
    "window" => @trigger.Selector::Window
    "document" => @trigger.Selector::Document
    _ =>
      if value.has_prefix("closest ") {
        let sel = (try! value[8:].to_string()).trim().to_string()
        @trigger.Selector::Closest(sel)
      } else if value.has_prefix("find ") {
        let sel = (try! value[5:].to_string()).trim().to_string()
        @trigger.Selector::Find(sel)
      } else if value.has_prefix("next ") {
        let sel = (try! value[5:].to_string()).trim().to_string()
        @trigger.Selector::Next(sel)
      } else if value.has_prefix("previous ") {
        let sel = (try! value[9:].to_string()).trim().to_string()
        @trigger.Selector::Previous(sel)
      } else {
        // Treat as CSS selector
        @trigger.Selector::Css(value)
      }
  }
}

///|
/// Parse queue mode
fn parse_queue_mode(scanner : Scanner) -> @trigger.QueueMode raise ParseError {
  let value = scanner.scan_identifier()
  match value {
    "drop" => @trigger.QueueMode::Drop
    "replace" => @trigger.QueueMode::Replace
    "first" => @trigger.QueueMode::QueueFirst
    "last" => @trigger.QueueMode::QueueLast
    "all" => @trigger.QueueMode::QueueAll
    _ =>
      raise InvalidModifier(pos=scanner.make_position(), name="queue:" + value)
  }
}
