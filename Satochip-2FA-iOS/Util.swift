//
//  Util.swift
//
//  Created by Satochip on 21/01/2023.
//  Copyright © 2023 Satochip S.R.L.
//
import Foundation

// bytesToHex
extension Array where Element == UInt8 {
    var bytesToHex: String {
        var hexString: String = ""
        var count = self.count
        for byte in self
        {
            hexString.append(String(format:"%02X", byte))
            count = count - 1
        }
        return hexString // letters in uppercase
    }
}

// hexToBytes
extension Collection where Element == Character {
    var hexToBytes: [UInt8] {
        var last = first
        return dropFirst().compactMap {
            guard
                let lastHexDigitValue = last?.hexDigitValue,
                let hexDigitValue = $0.hexDigitValue else {
                    last = $0
                    return nil
                }
            defer {
                last = nil
            }
            return UInt8(lastHexDigitValue * 16 + hexDigitValue)
        }
    }
}

// Base64 decoding
extension Data {
    /// Same as ``Data(base64Encoded:)``, but adds padding automatically
    /// (if missing, instead of returning `nil`).
    public static func fromBase64(_ encoded: String) -> Data? {
        // Prefixes padding-character(s) (if needed).
        var encoded = encoded;
        let remainder = encoded.count % 4
        if remainder > 0 {
            encoded = encoded.padding(
                toLength: encoded.count + 4 - remainder,
                withPad: "=", startingAt: 0);
        }

        // Finally, decode.
        return Data(base64Encoded: encoded);
    }
}

extension String {
    public static func fromBase64(_ encoded: String) -> String? {
        if let data = Data.fromBase64(encoded) {
            return String(data: data, encoding: .utf8)
        }
        return nil;
    }
}

// https://github.com/muratogat/wallet-connect-swift/blob/master/WalletConnect/Extensions/Data%2BHex.swift
extension Data {
    /// Initializes `Data` with a hex string representation.
    public init?(hexString: String) {
        let string: String
        if hexString.hasPrefix("0x") {
            string = String(hexString.dropFirst(2))
        } else {
            string = hexString
        }

        // Convert the string to bytes for better performance
        guard let stringData = string.data(using: .ascii, allowLossyConversion: true) else {
            return nil
        }

        self.init(capacity: string.count / 2)
        let stringBytes = Array(stringData)
        for i in stride(from: 0, to: stringBytes.count, by: 2) {
            guard let high = Data.value(of: stringBytes[i]) else {
                return nil
            }
            if i < stringBytes.count - 1, let low = Data.value(of: stringBytes[i + 1]) {
                append((high << 4) | low)
            } else {
                append(high)
            }
        }
    }

    /// Converts an ASCII byte to a hex value.
    private static func value(of nibble: UInt8) -> UInt8? {
        guard let letter = String(bytes: [nibble], encoding: .ascii) else { return nil }
        return UInt8(letter, radix: 16)
    }

    /// Returns the hex string representation of the data.
    public var hexString: String {
        return map({ String(format: "%02x", $0) }).joined()
    }
}

// String substring 
//extension String {
//  subscript(_ i: Int) -> String {
//    let idx1 = index(startIndex, offsetBy: i)
//    let idx2 = index(idx1, offsetBy: 1)
//    return String(self[idx1..<idx2])
//  }
//
//  subscript (r: Range<Int>) -> String {
//    let start = index(startIndex, offsetBy: r.lowerBound)
//    let end = index(startIndex, offsetBy: r.upperBound)
//    return String(self[start ..< end])
//  }
//
//  subscript (r: CountableClosedRange<Int>) -> String {
//    let startIndex =  self.index(self.startIndex, offsetBy: r.lowerBound)
//    let endIndex = self.index(startIndex, offsetBy: r.upperBound - r.lowerBound)
//    return String(self[startIndex...endIndex])
//  }
//}

//extension String {
//    subscript(_ range: CountableRange<Int>) -> String {
//        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
//        let end = index(start, offsetBy: min(self.count - range.lowerBound,
//                                             range.upperBound - range.lowerBound))
//        return String(self[start..<end])
//    }
//
//    subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
//        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
//         return String(self[start...])
//    }
//
//
//}
