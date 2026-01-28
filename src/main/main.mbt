///|
let _keep_fetch_success : (Int, String) -> Unit = @network.on_fetch_success

///|
let _keep_fetch_error : (Int, String) -> Unit = @network.on_fetch_error

///|
let _keep_mutation : (Int) -> Unit = @core.on_mutation_observed

///|
async fn main {
  @core.init_mhx()
}
