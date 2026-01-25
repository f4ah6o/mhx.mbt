///|
/// FFI bindings for MutationObserver
/// Used to detect DOM changes for automatic element processing

///|
/// Opaque type representing a MutationObserver
#external
pub type MutationObserver

///|
/// Opaque type representing a MutationRecord
#external
pub type MutationRecord

///|
/// Opaque type representing a Node (more general than Element)
#external
pub type Node

///|
/// Create a new MutationObserver with a callback ID
/// The callback will be invoked via a dispatch mechanism
pub fn MutationObserver::new_ffi(callback_id : Int) -> MutationObserver = "mhx_ffi" "mutation_observer_new"

///|
/// Start observing a target element
/// Options: subtree, childList, attributes, characterData
pub fn MutationObserver::observe(
  self : MutationObserver,
  target : Element,
  subtree : Bool,
  child_list : Bool,
  attributes : Bool,
) -> Unit = "mhx_ffi" "mutation_observer_observe"

///|
/// Stop observing
pub fn MutationObserver::disconnect(self : MutationObserver) -> Unit = "mhx_ffi" "mutation_observer_disconnect"

///|
/// Get the number of pending mutation records
pub fn MutationObserver::records_count(self : MutationObserver) -> Int = "mhx_ffi" "mutation_observer_records_count"

///|
/// Get mutation record at index
pub fn MutationObserver::record_at(
  self : MutationObserver,
  index : Int,
) -> MutationRecord = "mhx_ffi" "mutation_observer_record_at"

///|
/// Clear the records queue
pub fn MutationObserver::clear_records(self : MutationObserver) -> Unit = "mhx_ffi" "mutation_observer_clear_records"

///|
/// Get the mutation type ("attributes", "characterData", "childList")
pub fn MutationRecord::type_(self : MutationRecord) -> String = "mhx_ffi" "mutation_record_type"

///|
/// Get the target node of the mutation
pub fn MutationRecord::target(self : MutationRecord) -> Node = "mhx_ffi" "mutation_record_target"

///|
/// Get number of added nodes (for childList mutations)
pub fn MutationRecord::added_nodes_count(self : MutationRecord) -> Int = "mhx_ffi" "mutation_record_added_nodes_count"

///|
/// Get added node at index
pub fn MutationRecord::added_node_at(
  self : MutationRecord,
  index : Int,
) -> Node = "mhx_ffi" "mutation_record_added_node_at"

///|
/// Get number of removed nodes (for childList mutations)
pub fn MutationRecord::removed_nodes_count(self : MutationRecord) -> Int = "mhx_ffi" "mutation_record_removed_nodes_count"

///|
/// Get removed node at index
pub fn MutationRecord::removed_node_at(
  self : MutationRecord,
  index : Int,
) -> Node = "mhx_ffi" "mutation_record_removed_node_at"

///|
/// Get the attribute name (for attribute mutations, empty if not applicable)
pub fn MutationRecord::attribute_name(self : MutationRecord) -> String = "mhx_ffi" "mutation_record_attribute_name"

///|
/// Check if attribute name is set
pub fn MutationRecord::has_attribute_name(self : MutationRecord) -> Bool = "mhx_ffi" "mutation_record_has_attribute_name"

///|
/// Get the old value (for attribute/characterData mutations)
pub fn MutationRecord::old_value(self : MutationRecord) -> String = "mhx_ffi" "mutation_record_old_value"

///|
/// Check if old value is set
pub fn MutationRecord::has_old_value(self : MutationRecord) -> Bool = "mhx_ffi" "mutation_record_has_old_value"

///|
/// Check if a node is an Element
pub fn Node::is_element(self : Node) -> Bool = "mhx_ffi" "node_is_element"

///|
/// Cast Node to Element (unsafe, caller must check is_element first)
pub fn Node::as_element(self : Node) -> Element = "mhx_ffi" "node_as_element"

///|
/// Get the node type (1=Element, 3=Text, etc.)
pub fn Node::node_type(self : Node) -> Int = "mhx_ffi" "node_node_type"

///|
/// Get the node name
pub fn Node::node_name(self : Node) -> String = "mhx_ffi" "node_node_name"
