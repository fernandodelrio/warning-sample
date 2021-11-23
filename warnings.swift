#!/usr/bin/env swift

import Foundation

let arguments: [String] = CommandLine.arguments
let isVerbose = arguments.contains("verbose")
let newBranch = arguments[1]

struct Warning: Hashable {
  struct Message: Hashable {
    var value: String
    private var valueToCompare: String {
      let regex = try? NSRegularExpression(pattern: #" took \d+ms to "#)
      return regex?.stringByReplacingMatches(
        in: value,
        options: [],
        range: NSRange(value.startIndex..<value.endIndex, in: value),
        withTemplate: ""
      ) ?? ""
    }
    static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.valueToCompare == rhs.valueToCompare
    }
  }
  let path: String
  let position: String
  let message: Message

  var description: String {
    "\(path)\(position)\(message.value)"
  }
}

func makeShell(isVerbose: Bool) -> (_ arguments: String...) -> String {
  { (_ arguments: String...) -> String in
    let command = arguments.joined(separator: " ")
    if isVerbose { print(command) }
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", command]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String? ?? ""
  }
}
func getWarnings(_ log: String) -> Set<Warning> {
  let regex = try? NSRegularExpression(pattern: #"(.+)(:\d+?:\d+?:) warning: (.+)"#)
  let matches = regex?.matches(in: log, options: [], range: NSRange(log.startIndex..<log.endIndex, in: log)) ?? []
  var warnings = Set<Warning>()
  for match in matches {
    var results: [String] = []
    for rangeIndex in 0..<match.numberOfRanges {
      guard let substringRange = Range(match.range(at: rangeIndex), in: log) else { continue }
      results.append(String(log[substringRange]))
    }
    let groupCaptures = Array(results.dropFirst())
    guard groupCaptures.count == 3 else { continue }
    warnings.insert(
      Warning(path: groupCaptures[0], position: groupCaptures[1], message: .init(value: groupCaptures[2]))
    )
  }
  return warnings
}

let shell = makeShell(isVerbose: isVerbose)

_ = shell("git checkout \(newBranch)")
let cleanBuild = "xcodebuild -scheme App -target App -destination 'platform=iOS Simulator,name=iPhone 13,OS=15.0' clean build | grep warning:"
let newWarningsLog = shell(cleanBuild)
  .trimmingCharacters(in: .whitespacesAndNewlines)
_ = shell("git checkout main^")
let mainWarningsLog = shell(cleanBuild)
  .trimmingCharacters(in: .whitespacesAndNewlines)
_ = shell("git checkout \(newBranch)")

let newWarnings = getWarnings(newWarningsLog)
var mainWarnings = getWarnings(mainWarningsLog)

print("Before: \n")
mainWarnings.forEach { print("\($0.description)\n") }
print("After: \n")
newWarnings.forEach { print("\($0.description)\n") }


let introducedWarnings = newWarnings.filter { warning in
  let index = mainWarnings.firstIndex { $0.message == warning.message && $0.path == warning.path }
  if let index = index {
    mainWarnings.remove(at: index)
  }
  return index == nil
}


print("Introduced warnings: \n")
introducedWarnings.forEach { print("\($0.description)\n") }

if !introducedWarnings.isEmpty {
  let joined = introducedWarnings.map(\.description).joined(separator: "\n")
  exit(1)
}