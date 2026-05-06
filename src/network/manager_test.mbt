///|
test "queue first keeps the first pending request" {
  let manager = RequestManager::new()
  let options = RequestOptions::get()
  let first = match
    manager.schedule(1, "/items/1", options, @sync.SyncStrategy::Drop) {
    Execute(task) => task
    _ => fail("expected the first request to execute immediately")
  }
  guard manager.schedule(
      1,
      "/items/2",
      options,
      @sync.SyncStrategy::Queue(@sync.QueueMode::First),
    )
    is Queued else {
    fail("expected the first queued request to be accepted")
  }
  guard manager.schedule(
      1,
      "/items/3",
      options,
      @sync.SyncStrategy::Queue(@sync.QueueMode::First),
    )
    is Dropped else {
    fail("expected later queue:first requests to be dropped")
  }
  inspect(manager.pending_count(1), content="2")
  match manager.complete(1, first.id) {
    Some(next) => inspect(next.url, content="/items/2")
    None => fail("expected the preserved queued request")
  }
}

///|
test "queue last keeps only the latest pending request" {
  let manager = RequestManager::new()
  let options = RequestOptions::get()
  let first = match
    manager.schedule(2, "/items/1", options, @sync.SyncStrategy::Drop) {
    Execute(task) => task
    _ => fail("expected the first request to execute immediately")
  }
  guard manager.schedule(
      2,
      "/items/2",
      options,
      @sync.SyncStrategy::Queue(@sync.QueueMode::Last),
    )
    is Queued else {
    fail("expected the first queued request to be accepted")
  }
  guard manager.schedule(
      2,
      "/items/3",
      options,
      @sync.SyncStrategy::Queue(@sync.QueueMode::Last),
    )
    is Queued else {
    fail("expected queue:last to replace the queued request")
  }
  inspect(manager.pending_count(2), content="2")
  match manager.complete(2, first.id) {
    Some(next) => inspect(next.url, content="/items/3")
    None => fail("expected the latest queued request")
  }
}

///|
test "replace cancels the in-flight task" {
  let manager = RequestManager::new()
  let options = RequestOptions::get()
  let first = match
    manager.schedule(3, "/items/1", options, @sync.SyncStrategy::Drop) {
    Execute(task) => task
    _ => fail("expected the first request to execute immediately")
  }
  guard manager.schedule(3, "/items/2", options, @sync.SyncStrategy::Replace)
    is Execute(_) else {
    fail("expected replace to execute immediately")
  }
  inspect(first.is_cancelled(), content="true")
}
