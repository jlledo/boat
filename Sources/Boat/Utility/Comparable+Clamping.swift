// From https://github.com/apple/swift-evolution/pull/641/commits/78af6b180e8218ebee1ff97fd4ee77ecff126ffe
extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        if self > range.upperBound {
            return range.upperBound
        } else if self < range.lowerBound {
            return range.lowerBound
        } else {
            return self
        }
    }
}
