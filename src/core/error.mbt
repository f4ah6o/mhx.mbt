///|
/// Error handling for mhx
/// Provides a unified error type for all mhx operations

///|
/// Unified error type for mhx operations
pub(all) suberror MhxError {
  /// Error during trigger parsing
  ParseError(@parser.ParseError)
  /// Network request error
  NetworkError(url~ : String, message~ : String)
  /// Network timeout error
  TimeoutError(url~ : String, timeout_ms~ : Int)
  /// Network abort error (request was cancelled)
  AbortError(url~ : String)
  /// DOM operation error
  DomError(element~ : String, operation~ : String, message~ : String)
  /// Configuration error
  ConfigError(attribute~ : String, message~ : String)
  /// Swap operation error
  SwapError(target~ : String, strategy~ : String, message~ : String)
} derive(Show)

///|
/// Error callback type for user-defined error handlers
pub(all) struct ErrorHandler {
  on_error : (MhxError) -> Unit
}

///|
/// Default error handler that logs to console
pub fn default_error_handler(error : MhxError) -> Unit {
  @ffi.console_error("mhx error: " + error.to_string())
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
  MhxError::NetworkError(url~, message~)
}

///|
/// Helper to create timeout errors
pub fn timeout_error(url : String, timeout_ms : Int) -> MhxError {
  MhxError::TimeoutError(url~, timeout_ms~)
}

///|
/// Helper to create abort errors
pub fn abort_error(url : String) -> MhxError {
  MhxError::AbortError(url~)
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
  MhxError::ConfigError(attribute~, message~)
}

///|
/// Helper to create swap errors
pub fn swap_error(
  target : String,
  strategy : String,
  message : String,
) -> MhxError {
  MhxError::SwapError(target~, strategy~, message~)
}

///|
/// Wrap a parse error
pub fn from_parse_error(error : @parser.ParseError) -> MhxError {
  MhxError::ParseError(error)
}

///|
/// Error recovery strategy
pub(all) enum RecoveryStrategy {
  /// Continue processing other elements
  Continue
  /// Stop processing completely
  Abort
  /// Retry the operation (for network errors)
  Retry(max_attempts~ : Int, delay_ms~ : Int)
}

///|
/// Get the recommended recovery strategy for an error
pub fn MhxError::recovery_strategy(self : MhxError) -> RecoveryStrategy {
  match self {
    ParseError(_) => RecoveryStrategy::Continue
    NetworkError(url=_, message=_) =>
      RecoveryStrategy::Retry(max_attempts=3, delay_ms=1000)
    TimeoutError(url=_, timeout_ms=_) =>
      RecoveryStrategy::Retry(max_attempts=2, delay_ms=2000)
    AbortError(url=_) => RecoveryStrategy::Continue
    DomError(element=_, operation=_, message=_) => RecoveryStrategy::Continue
    ConfigError(attribute=_, message=_) => RecoveryStrategy::Continue
    SwapError(target=_, strategy=_, message=_) => RecoveryStrategy::Continue
  }
}

///|
/// Check if the error is recoverable
pub fn MhxError::is_recoverable(self : MhxError) -> Bool {
  not(self.recovery_strategy() is Abort)
}

///|
/// Check if the error should trigger a retry
pub fn MhxError::should_retry(self : MhxError) -> Bool {
  self.recovery_strategy() is Retry(max_attempts=_, delay_ms=_)
}
