import Cocoa

let str = "5 7 17 22 20 18 15 9 5 1"
let scores = str.split(separator: " ").map { (score) -> Int in
    Int(score) ?? 0
}
var totalScore = 0
for (index, score) in scores.enumerated() {
    totalScore += score * (index + 1)
}
let sum = scores.reduce(0, +)
let mean = Double(totalScore) / Double(sum)
print(mean)
