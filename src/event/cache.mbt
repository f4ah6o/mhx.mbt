///|
/// Cache for parsed trigger configurations
/// Stores parsed trigger definitions keyed by element reference

///|
/// Cached configuration for an element
pub(all) struct ElementConfig {
  /// Parsed trigger definitions
  triggers : Array[@trigger.TriggerDef]
  /// The HTTP method to use (GET, POST, etc.)
  http_method : HttpMethod
  /// The URL to request
  url : String
  /// The swap strategy to use
  swap : SwapStrategy
  /// Target selector (if specified)
  target : String?
  /// Whether this config has been processed
  processed : Bool
} derive(Show)

///|
/// HTTP methods supported
pub(all) enum HttpMethod {
  Get
  Post
  Put
  Patch
  Delete
} derive(Show, Eq)

///|
/// Swap strategies for DOM updates
pub(all) enum SwapStrategy {
  InnerHTML
  OuterHTML
  BeforeBegin
  AfterBegin
  BeforeEnd
  AfterEnd
  Delete
  None_
} derive(Show, Eq)

///|
pub impl ToJson for HttpMethod with to_json(self) {
  match self {
    Get => "GET".to_json()
    Post => "POST".to_json()
    Put => "PUT".to_json()
    Patch => "PATCH".to_json()
    Delete => "DELETE".to_json()
  }
}

///|
pub impl ToJson for SwapStrategy with to_json(self) {
  match self {
    InnerHTML => "innerHTML".to_json()
    OuterHTML => "outerHTML".to_json()
    BeforeBegin => "beforebegin".to_json()
    AfterBegin => "afterbegin".to_json()
    BeforeEnd => "beforeend".to_json()
    AfterEnd => "afterend".to_json()
    Delete => "delete".to_json()
    None_ => "none".to_json()
  }
}

///|
pub impl ToJson for ElementConfig with to_json(self) {
  {
    "triggers": self.triggers.to_json(),
    "method": self.http_method.to_json(),
    "url": self.url.to_json(),
    "swap": self.swap.to_json(),
    "target": match self.target {
      Some(t) => t.to_json()
      Option::None => Json::null()
    },
    "processed": self.processed.to_json(),
  }
}

///|
/// Create a default ElementConfig
pub fn ElementConfig::default() -> ElementConfig {
  {
    triggers: [],
    http_method: HttpMethod::Get,
    url: "",
    swap: SwapStrategy::InnerHTML,
    target: Option::None,
    processed: false,
  }
}

///|
/// The global configuration cache
/// Maps element IDs to their parsed configurations
struct ConfigCache {
  configs : Map[Int, ElementConfig]
  mut next_id : Int
  /// Maps element -> id (stored as element index in a side channel)
  element_ids : Map[Int, Int]
}

///|
/// Create a new config cache
pub fn ConfigCache::new() -> ConfigCache {
  { configs: {}, next_id: 1, element_ids: {} }
}

///|
/// Get or create an ID for an element (using JS-side element tracking)
pub fn ConfigCache::get_element_id(
  self : ConfigCache,
  element_hash : Int,
) -> Int {
  match self.element_ids.get(element_hash) {
    Some(id) => id
    Option::None => {
      let id = self.next_id
      self.next_id += 1
      self.element_ids[element_hash] = id
      id
    }
  }
}

///|
/// Store a configuration for an element
pub fn ConfigCache::set(
  self : ConfigCache,
  element_id : Int,
  config : ElementConfig,
) -> Unit {
  self.configs[element_id] = config
}

///|
/// Get a configuration for an element
pub fn ConfigCache::get(self : ConfigCache, element_id : Int) -> ElementConfig? {
  self.configs.get(element_id)
}

///|
/// Remove a configuration for an element
pub fn ConfigCache::remove(self : ConfigCache, element_id : Int) -> Unit {
  self.configs.remove(element_id)
}

///|
/// Check if we have a configuration for an element
pub fn ConfigCache::has(self : ConfigCache, element_id : Int) -> Bool {
  self.configs.contains(element_id)
}

///|
/// Get the number of cached configurations
pub fn ConfigCache::length(self : ConfigCache) -> Int {
  self.configs.length()
}

///|
/// Clear all cached configurations
pub fn ConfigCache::clear(self : ConfigCache) -> Unit {
  self.configs.clear()
  self.element_ids.clear()
  self.next_id = 1
}

///|
/// Parse HTTP method from string
pub fn parse_http_method(s : String) -> HttpMethod {
  match s.to_upper() {
    "GET" => HttpMethod::Get
    "POST" => HttpMethod::Post
    "PUT" => HttpMethod::Put
    "PATCH" => HttpMethod::Patch
    "DELETE" => HttpMethod::Delete
    _ => HttpMethod::Get
  }
}

///|
/// Parse swap strategy from string
pub fn parse_swap_strategy(s : String) -> SwapStrategy {
  match s.to_lower() {
    "innerhtml" => SwapStrategy::InnerHTML
    "outerhtml" => SwapStrategy::OuterHTML
    "beforebegin" => SwapStrategy::BeforeBegin
    "afterbegin" => SwapStrategy::AfterBegin
    "beforeend" => SwapStrategy::BeforeEnd
    "afterend" => SwapStrategy::AfterEnd
    "delete" => SwapStrategy::Delete
    "none" => SwapStrategy::None_
    _ => SwapStrategy::InnerHTML
  }
}
