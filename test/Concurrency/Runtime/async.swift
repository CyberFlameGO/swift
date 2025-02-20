// REQUIRES: rdar79670222
// RUN: %target-run-simple-swift( -Xfrontend -disable-availability-checking %import-libdispatch)

// REQUIRES: executable_test
// REQUIRES: concurrency
// REQUIRES: libdispatch

// rdar://76038845
// UNSUPPORTED: use_os_stdlib

import Dispatch
import StdlibUnittest

// for sleep
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

var asyncTests = TestSuite("Async")

@available(SwiftStdlib 5.5, *)
actor MyActor {
  func synchronous() { }

  func doSomething(expectedPriority: TaskPriority) {
    async {
      synchronous() // okay to be synchronous
      assert(Task.currentPriority == expectedPriority)
    }
  }
}

if #available(SwiftStdlib 5.5, *) {
  let actor = MyActor()

  asyncTests.test("Detach") {
    detach(priority: .background) {
      async {
        assert(Task.currentPriority == .background)
        await actor.doSomething(expectedPriority: .background)
      }
    }
    sleep(1)
  }

  asyncTests.test("MainQueue") {
    DispatchQueue.main.async {
      async {
        assert(Task.currentPriority == .userInitiated)
      }
    }
    sleep(1)
  }

  asyncTests.test("GlobalDispatchQueue") {
    DispatchQueue.global(qos: .utility).async {
      async {
#if (os(macOS) || os(iOS) || os(tvOS) || os(watchOS))
        // Non-Darwin platforms currently lack qos_class_self().
        assert(Task.currentPriority == .utility)
#endif
      }
    }
    sleep(1)
  }
}

runAllTests()
