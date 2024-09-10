//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Algorithms
import Foundation
import SwiftUI

// TODO: Remove this and strongly type instances if it makes sense.
extension String: Displayable {

    var displayTitle: String {
        self
    }
}

extension String {

    static let alphanumeric = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

    static func + (lhs: String, rhs: Character) -> String {
        lhs.appending(rhs)
    }

    func appending(_ element: String) -> String {
        self + element
    }

    func appending(_ element: String.Element) -> String {
        self + String(element)
    }

    func prepending(_ element: String) -> String {
        element + self
    }

    func removingFirst(if condition: Bool) -> String {
        if condition {
            var copy = self
            copy.removeFirst()
            return copy
        } else {
            return self
        }
    }

    func prepending(_ element: String, if condition: Bool) -> String {
        if condition {
            return element + self
        } else {
            return self
        }
    }

    func removeRegexMatches(pattern: String, replaceWith: String = "") -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: count)
            return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceWith)
        } catch { return self }
    }

    func leftPad(maxWidth width: Int, with character: Character) -> String {
        guard count < width else { return self }

        let padding = String(repeating: character, count: width - count)
        return padding + self
    }

    var text: Text {
        Text(self)
    }

    var initials: String {
        split(separator: " ")
            .compactMap(\.first)
            .reduce("", +)
    }

    static let emptyDash = "--"

    static let emptyTime = "--:--"

    var shortFileName: String {
        (split(separator: "/").last?.description ?? self)
            .replacingOccurrences(of: ".swift", with: "")
    }

    static func random(count: Int) -> String {
        (0 ..< count)
            .compactMap { _ in Self.alphanumeric.randomElement() }
            .map(String.init)
            .joined()
    }

    static func random(count range: Range<Int>) -> String {
        random(count: Int.random(in: range))
    }

    func trimmingSuffix(_ suffix: String) -> String {

        guard suffix.count <= count else { return self }

        var s = self
        var suffix = suffix

        while s.last == suffix.last {
            s.removeLast()
            suffix.removeLast()
        }

        return s
    }

    // TODO: remove after iOS 15 support removed

    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )

        return ceil(boundingBox.height)
    }
}

extension CharacterSet {

    // Character that appears on tvOS with voice input
    static var objectReplacement: CharacterSet = .init(charactersIn: "\u{fffc}")
}
