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
test "drop ignores repeated triggers while busy" {
  let manager = RequestManager::new()
  let options = RequestOptions::get()
  let first = match
    manager.schedule(4, "/items/1", options, @sync.SyncStrategy::Drop) {
    Execute(task) => task
    _ => fail("expected the first request to execute immediately")
  }
  guard manager.schedule(4, "/items/2", options, @sync.SyncStrategy::Drop)
    is Dropped else {
    fail("expected drop to ignore a repeated trigger while busy")
  }
  inspect(manager.pending_count(4), content="1")
  guard manager.complete(4, first.id) is None else {
    fail("expected no queued request after drop")
  }
  inspect(manager.pending_count(4), content="0")
}

///|
test "queue all preserves fifo order" {
  let manager = RequestManager::new()
  let options = RequestOptions::get()
  let first = match
    manager.schedule(5, "/items/1", options, @sync.SyncStrategy::Drop) {
    Execute(task) => task
    _ => fail("expected the first request to execute immediately")
  }
  guard manager.schedule(
      5,
      "/items/2",
      options,
      @sync.SyncStrategy::Queue(@sync.QueueMode::All),
    )
    is Queued else {
    fail("expected the second request to queue")
  }
  guard manager.schedule(
      5,
      "/items/3",
      options,
      @sync.SyncStrategy::Queue(@sync.QueueMode::All),
    )
    is Queued else {
    fail("expected the third request to queue")
  }
  inspect(manager.pending_count(5), content="3")
  let second = match manager.complete(5, first.id) {
    Some(task) => task
    None => fail("expected the second request")
  }
  inspect(second.url, content="/items/2")
  let third = match manager.complete(5, second.id) {
    Some(task) => task
    None => fail("expected the third request")
  }
  inspect(third.url, content="/items/3")
  guard manager.complete(5, third.id) is None else {
    fail("expected no queued request after fifo queue drains")
  }
  inspect(manager.pending_count(5), content="0")
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

///|
test "stale completion after replace does not clear the active request" {
  let manager = RequestManager::new()
  let options = RequestOptions::get()
  let first = match
    manager.schedule(6, "/items/1", options, @sync.SyncStrategy::Drop) {
    Execute(task) => task
    _ => fail("expected the first request to execute immediately")
  }
  let second = match
    manager.schedule(6, "/items/2", options, @sync.SyncStrategy::Replace) {
    Execute(task) => task
    _ => fail("expected replace to execute immediately")
  }
  guard manager.complete(6, first.id) is None else {
    fail("expected stale completion to be ignored")
  }
  inspect(manager.pending_count(6), content="1")
  guard manager.complete(6, second.id) is None else {
    fail("expected no queued request after replacement completes")
  }
  inspect(manager.pending_count(6), content="0")
}
