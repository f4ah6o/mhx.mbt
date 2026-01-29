///|
let _keep_fetch_success : (Int, String) -> Unit = @network.on_fetch_success

///|
let _keep_fetch_error : (Int, String) -> Unit = @network.on_fetch_error

///|
let _keep_mutation : (Int) -> Unit = @core.on_mutation_observed

///|
pub fn on_fetch_success(callback_id : Int, response_text : String) -> Unit {
  @network.on_fetch_success(callback_id, response_text)
}

///|
pub fn on_fetch_error(callback_id : Int, error_message : String) -> Unit {
  @network.on_fetch_error(callback_id, error_message)
}

///|
pub fn on_mutation_observed(callback_id : Int) -> Unit {
  @core.on_mutation_observed(callback_id)
}

///|
async fn main {
  @core.init_mhx()
}
