///|
/// Error handling for mhx
/// Provides a structured error model for runtime and contract failures.

///|
pub(all) suberror MhxError {
  /// Strict parser error surfaced directly from mhx-spec.
  ParseError(@parser.ParseError)
  /// Network request error.
  NetworkError(url~ : String, message~ : String, source_element~ : String?)
  /// Network timeout error.
  TimeoutError(url~ : String, timeout_ms~ : Int, source_element~ : String?)
  /// Network abort error (request was cancelled).
  AbortError(url~ : String, source_element~ : String?)
  /// DOM operation error.
  DomError(element~ : String, operation~ : String, message~ : String)
  /// Configuration or validation error.
  ConfigError(
    code~ : String,
    attribute~ : String,
    message~ : String,
    position~ : @parser.Position?,
    source_element~ : String?
  )
  /// Selector resolution error.
  SelectorError(
    code~ : String,
    selector~ : String,
    message~ : String,
    source_element~ : String?
  )
  /// Swap operation error.
  SwapError(
    target~ : String,
    strategy~ : String,
    message~ : String,
    source_element~ : String?
  )
  /// JavaScript FFI bridge error.
  FfiError(operation~ : String, message~ : String)
  /// Internal runtime error.
  InternalError(code~ : String, message~ : String)
}

///|
fn parse_error_code(error : @parser.ParseError) -> String {
  match error {
    @parser.ParseError::UnexpectedChar(pos=_, expected=_) =>
      "MHX_PARSE_UNEXPECTED_CHAR"
    @parser.ParseError::UnexpectedEnd(pos=_, expected=_) =>
      "MHX_PARSE_UNEXPECTED_END"
    @parser.ParseError::InvalidNumber(pos=_, value=_) =>
      "MHX_PARSE_INVALID_NUMBER"
    @parser.ParseError::InvalidModifier(pos=_, name=_) =>
      "MHX_PARSE_INVALID_MODIFIER"
    @parser.ParseError::InvalidSelector(pos=_, value=_) =>
      "MHX_PARSE_INVALID_SELECTOR"
  }
}

///|
fn parse_error_message(error : @parser.ParseError) -> String {
  match error {
    @parser.ParseError::UnexpectedChar(pos=_, expected~) =>
      "Unexpected character while parsing; expected \{expected}"
    @parser.ParseError::UnexpectedEnd(pos=_, expected~) =>
      "Unexpected end of input; expected \{expected}"
    @parser.ParseError::InvalidNumber(pos=_, value~) =>
      "Invalid numeric literal `\{value}`"
    @parser.ParseError::InvalidModifier(pos=_, name~) =>
      "Unknown trigger modifier `\{name}`"
    @parser.ParseError::InvalidSelector(pos=_, value~) =>
      "Invalid selector `\{value}`"
  }
}

///|
fn parse_error_position(error : @parser.ParseError) -> @parser.Position {
  match error {
    @parser.ParseError::UnexpectedChar(pos~, expected=_) => pos
    @parser.ParseError::UnexpectedEnd(pos~, expected=_) => pos
    @parser.ParseError::InvalidNumber(pos~, value=_) => pos
    @parser.ParseError::InvalidModifier(pos~, name=_) => pos
    @parser.ParseError::InvalidSelector(pos~, value=_) => pos
  }
}

///|
pub fn MhxError::category(self : MhxError) -> String {
  match self {
    ParseError(_) => "ParseError"
    NetworkError(url=_, message=_, source_element=_) => "NetworkError"
    TimeoutError(url=_, timeout_ms=_, source_element=_) => "TimeoutError"
    AbortError(url=_, source_element=_) => "AbortError"
    DomError(element=_, operation=_, message=_) => "DomError"
    ConfigError(code=_, attribute=_, message=_, position=_, source_element=_) =>
      "ConfigError"
    SelectorError(code=_, selector=_, message=_, source_element=_) =>
      "SelectorError"
    SwapError(target=_, strategy=_, message=_, source_element=_) => "SwapError"
    FfiError(operation=_, message=_) => "FfiError"
    InternalError(code=_, message=_) => "InternalError"
  }
}

///|
pub fn MhxError::code(self : MhxError) -> String {
  match self {
    ParseError(error) => parse_error_code(error)
    NetworkError(url=_, message=_, source_element=_) => "MHX_NETWORK_ERROR"
    TimeoutError(url=_, timeout_ms=_, source_element=_) => "MHX_TIMEOUT_ERROR"
    AbortError(url=_, source_element=_) => "MHX_ABORT_ERROR"
    DomError(element=_, operation=_, message=_) => "MHX_DOM_ERROR"
    ConfigError(code~, attribute=_, message=_, position=_, source_element=_) =>
      code
    SelectorError(code~, selector=_, message=_, source_element=_) => code
    SwapError(target=_, strategy=_, message=_, source_element=_) =>
      "MHX_SWAP_ERROR"
    FfiError(operation=_, message=_) => "MHX_FFI_ERROR"
    InternalError(code~, message=_) => code
  }
}

///|
pub fn MhxError::message(self : MhxError) -> String {
  match self {
    ParseError(error) => parse_error_message(error)
    NetworkError(url=_, message~, source_element=_) => message
    TimeoutError(url~, timeout_ms~, source_element=_) =>
      "Request to `\{url}` exceeded \{timeout_ms}ms"
    AbortError(url~, source_element=_) => "Request to `\{url}` was aborted"
    DomError(element=_, operation~, message~) =>
      "DOM operation `\{operation}` failed: \{message}"
    ConfigError(code=_, attribute=_, message~, position=_, source_element=_) =>
      message
    SelectorError(code=_, selector=_, message~, source_element=_) => message
    SwapError(target=_, strategy~, message~, source_element=_) =>
      "Swap `\{strategy}` failed: \{message}"
    FfiError(operation~, message~) =>
      "FFI operation `\{operation}` failed: \{message}"
    InternalError(code=_, message~) => message
  }
}

///|
pub fn MhxError::attribute(self : MhxError) -> String? {
  match self {
    ParseError(_) => Some("mx-trigger")
    ConfigError(code=_, attribute~, message=_, position=_, source_element=_) =>
      Some(attribute)
    _ => None
  }
}

///|
pub fn MhxError::position(self : MhxError) -> @parser.Position? {
  match self {
    ParseError(error) => Some(parse_error_position(error))
    ConfigError(code=_, attribute=_, message=_, position~, source_element=_) =>
      position
    _ => None
  }
}

///|
pub fn MhxError::source_element(self : MhxError) -> String? {
  match self {
    NetworkError(url=_, message=_, source_element~) => source_element
    TimeoutError(url=_, timeout_ms=_, source_element~) => source_element
    AbortError(url=_, source_element~) => source_element
    ConfigError(code=_, attribute=_, message=_, position=_, source_element~) =>
      source_element
    SelectorError(code=_, selector=_, message=_, source_element~) =>
      source_element
    SwapError(target=_, strategy=_, message=_, source_element~) =>
      source_element
    _ => None
  }
}

///|
pub impl ToJson for MhxError with to_json(self) {
  {
    "category": self.category().to_json(),
    "code": self.code().to_json(),
    "message": self.message().to_json(),
    "attribute": self.attribute().to_json(),
    "sourceElement": self.source_element().to_json(),
    "position": self.position().to_json(),
    "recoverable": self.is_recoverable().to_json(),
  }
}

///|
pub impl Show for MhxError with output(self, logger) {
  logger.write_string(self.to_json().stringify())
}

///|
/// Error callback type for user-defined error handlers
pub(all) struct ErrorHandler {
  on_error : (MhxError) -> Unit
}

///|
/// Default error handler that logs a structured JSON payload.
pub fn default_error_handler(error : MhxError) -> Unit {
  @ffi.console_error("mhx error: " + error.to_json().stringify())
}

///|
/// Global error handler state
priv struct ErrorHandlerState {
  mut handler : (MhxError) -> Unit
}

///|
let global_error_state : ErrorHandlerState = { handler: default_error_handler }

///|
/// Set the global error handler
pub fn set_error_handler(handler : (MhxError) -> Unit) -> Unit {
  global_error_state.handler = handler
}

///|
/// Report an error through the global handler
pub fn report_error(error : MhxError) -> Unit {
  (global_error_state.handler)(error)
}

///|
/// Helper to create network errors from fetch failures
pub fn network_error(url : String, message : String) -> MhxError {
  MhxError::NetworkError(url~, message~, source_element=None)
}

///|
pub fn network_error_for_element(
  url : String,
  message : String,
  source_element : String,
) -> MhxError {
  MhxError::NetworkError(url~, message~, source_element=Some(source_element))
}

///|
/// Helper to create timeout errors
pub fn timeout_error(url : String, timeout_ms : Int) -> MhxError {
  MhxError::TimeoutError(url~, timeout_ms~, source_element=None)
}

///|
/// Helper to create abort errors
pub fn abort_error(url : String) -> MhxError {
  MhxError::AbortError(url~, source_element=None)
}

///|
/// Helper to create DOM errors
pub fn dom_error(
  element : String,
  operation : String,
  message : String,
) -> MhxError {
  MhxError::DomError(element~, operation~, message~)
}

///|
/// Helper to create configuration errors
pub fn config_error(attribute : String, message : String) -> MhxError {
  MhxError::ConfigError(
    code="MHX_CONFIG_ERROR",
    attribute~,
    message~,
    position=None,
    source_element=None,
  )
}

///|
pub fn config_issue_error(
  code : String,
  attribute : String,
  message : String,
  position : @parser.Position?,
  source_element : String?,
) -> MhxError {
  MhxError::ConfigError(code~, attribute~, message~, position~, source_element~)
}

///|
pub fn config_issue_from_parse_error(
  error : @parser.ParseError,
  attribute : String,
  source_element : String?,
) -> MhxError {
  config_issue_error(
    parse_error_code(error),
    attribute,
    parse_error_message(error),
    Some(parse_error_position(error)),
    source_element,
  )
}

///|
pub fn selector_error(
  selector : String,
  message : String,
  source_element : String?,
  code? : String = "MHX_SELECTOR_TARGET_NOT_FOUND",
) -> MhxError {
  MhxError::SelectorError(code~, selector~, message~, source_element~)
}

///|
/// Helper to create swap errors
pub fn swap_error(
  target : String,
  strategy : String,
  message : String,
) -> MhxError {
  MhxError::SwapError(target~, strategy~, message~, source_element=None)
}

///|
pub fn ffi_error(operation : String, message : String) -> MhxError {
  MhxError::FfiError(operation~, message~)
}

///|
pub fn internal_error(code : String, message : String) -> MhxError {
  MhxError::InternalError(code~, message~)
}

///|
/// Wrap a parse error
pub fn from_parse_error(error : @parser.ParseError) -> MhxError {
  MhxError::ParseError(error)
}

///|
/// Error recovery strategy
pub(all) enum RecoveryStrategy {
  /// Continue processing other elements.
  Continue
  /// Stop processing completely.
  Abort
  /// Retry the operation (for network errors).
  Retry(max_attempts~ : Int, delay_ms~ : Int)
}

///|
/// Get the recommended recovery strategy for an error
pub fn MhxError::recovery_strategy(self : MhxError) -> RecoveryStrategy {
  match self {
    ParseError(_) => RecoveryStrategy::Continue
    NetworkError(url=_, message=_, source_element=_) =>
      RecoveryStrategy::Retry(max_attempts=3, delay_ms=1000)
    TimeoutError(url=_, timeout_ms=_, source_element=_) =>
      RecoveryStrategy::Retry(max_attempts=2, delay_ms=2000)
    AbortError(url=_, source_element=_) => RecoveryStrategy::Continue
    DomError(element=_, operation=_, message=_) => RecoveryStrategy::Continue
    ConfigError(code=_, attribute=_, message=_, position=_, source_element=_) =>
      RecoveryStrategy::Continue
    SelectorError(code=_, selector=_, message=_, source_element=_) =>
      RecoveryStrategy::Continue
    SwapError(target=_, strategy=_, message=_, source_element=_) =>
      RecoveryStrategy::Continue
    FfiError(operation=_, message=_) => RecoveryStrategy::Continue
    InternalError(code=_, message=_) => RecoveryStrategy::Abort
  }
}

///|
/// Check if the error is recoverable
pub fn MhxError::is_recoverable(self : MhxError) -> Bool {
  !(self.recovery_strategy() is Abort)
}

///|
/// Check if the error should trigger a retry
pub fn MhxError::should_retry(self : MhxError) -> Bool {
  self.recovery_strategy() is Retry(max_attempts=_, delay_ms=_)
}
