import SwiftUI

@main
struct WarningSample: App {

  
  init() {
    // var foo = "bar"  
    let result = (20..<30)
      .map { Optional(Double($0)) }
      .compactMap { $0 }
      .filter { $0 > 10 }
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

struct ContentView: View {
  var body: some View {
    Text("Hello, World!")
  }
}
