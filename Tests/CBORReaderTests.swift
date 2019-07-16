//
//  CBORReaderTests.swift
//  PotentCodables
//
//  Copyright © 2019 Outfox, inc.
//
//
//  Distributed under the MIT License, See LICENSE for details.
//

import XCTest
@testable import PotentCodables
@testable import PotentCBOR


class CBORReaderTests: XCTestCase {
  static var allTests = [
    ("testDecodeNumbers", testDecodeNumbers),
    ("testDecodeByteStrings", testDecodeByteStrings),
    ("testDecodeUtf8Strings", testDecodeUtf8Strings),
    ("testDecodeArrays", testDecodeArrays),
    ("testDecodeMaps", testDecodeMaps),
    ("testDecodeTagged", testDecodeTagged),
    ("testDecodeSimple", testDecodeSimple),
    ("testDecodeFloats", testDecodeFloats),
    ("testDecodePerformance", testDecodePerformance),
    ("testDecodeMapFromIssue29", testDecodeMapFromIssue29),
  ]

  func decode(_ bytes: UInt8...) throws -> CBOR {
    return try decode(Data(bytes))
  }

  func decode(_ data: Data) throws -> CBOR {
    return try CBORReader(stream: CBORDataStream(data: data)).decodeRequiredItem()
  }

  func testDecodeNumbers() {
    for i in 0 ..< 24 {
      XCTAssertEqual(try decode(UInt8(i)), .unsignedInt(UInt64(i)))
    }
    XCTAssertEqual(try decode(0x18, 0xFF), 255)
    XCTAssertEqual(try decode(0x19, 0x03, 0xE8), 1000) // Network byte order!
    XCTAssertEqual(try decode(0x19, 0xFF, 0xFF), 65535)
    XCTAssertThrowsError(try decode(0x19, 0xFF))
    XCTAssertEqual(try decode(0x1A, 0x00, 0x0F, 0x42, 0x40), 1000000)
    XCTAssertEqual(try decode(0x1A, 0xFF, 0xFF, 0xFF, 0xFF), .unsignedInt(4294967295))
    XCTAssertThrowsError(try decode(0x1A))
    XCTAssertEqual(try decode(0x1B, 0x00, 0x00, 0x00, 0xE8, 0xD4, 0xA5, 0x10, 0x00), .unsignedInt(1000000000000))
    XCTAssertEqual(try decode(0x1B, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF), .unsignedInt(18446744073709551615))
    XCTAssertThrowsError(try decode(0x1B, 0x00, 0x00))

    XCTAssertEqual(try decode(0x20), -1)
    XCTAssertEqual(try decode(0x21), .negativeInt(1))
    XCTAssertEqual(try decode(0x37), -24)
    XCTAssertEqual(try decode(0x38, 0xFF), -256)
    XCTAssertEqual(try decode(0x39, 0x03, 0xE7), -1000)
    XCTAssertEqual(try decode(0x3A, 0x00, 0x0F, 0x42, 0x3F), .negativeInt(999999))
    XCTAssertEqual(try decode(0x3B, 0x00, 0x00, 0x00, 0xE8, 0xD4, 0xA5, 0x0F, 0xFF), .negativeInt(999999999999))
  }

  func testDecodeByteStrings() {
    XCTAssertEqual(try decode(0x40), .byteString(Data()))
    XCTAssertEqual(try decode(0x41, 0xF0), .byteString(Data([0xF0])))
    XCTAssertEqual(try decode(0x57, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xAA),
                   .byteString(Data([0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xAA])))
    XCTAssertEqual(try decode(0x58, 0), .byteString(Data()))
    XCTAssertEqual(try decode(0x58, 1, 0xF0), .byteString(Data([0xF0])))
    XCTAssertEqual(try decode(0x59, 0x00, 3, 0xC0, 0xFF, 0xEE), .byteString(Data([0xC0, 0xFF, 0xEE])))
    XCTAssertEqual(try decode(0x5A, 0x00, 0x00, 0x00, 3, 0xC0, 0xFF, 0xEE), .byteString(Data([0xC0, 0xFF, 0xEE])))
    XCTAssertEqual(try decode(0x5B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 3, 0xC0, 0xFF, 0xEE), .byteString(Data([0xC0, 0xFF, 0xEE])))
    XCTAssertEqual(try decode(0x5F, 0x58, 3, 0xC0, 0xFF, 0xEE, 0x43, 0xC0, 0xFF, 0xEE, 0xFF), .byteString(Data([0xC0, 0xFF, 0xEE, 0xC0, 0xFF, 0xEE])))
  }

  func testDecodeData() {
    XCTAssertEqual(try decode(0x40), .byteString(Data()))
    XCTAssertEqual(try decode(0x41, 0xF0), .byteString(Data([0xF0])))
    XCTAssertEqual(try decode(0x57, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xAA),
                   .byteString(Data([0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xAA])))
    XCTAssertEqual(try decode(0x58, 0), .byteString(Data()))
    XCTAssertEqual(try decode(0x58, 1, 0xF0), .byteString(Data([0xF0])))
    XCTAssertEqual(try decode(0x59, 0x00, 3, 0xC0, 0xFF, 0xEE), .byteString(Data([0xC0, 0xFF, 0xEE])))
    XCTAssertEqual(try decode(0x5A, 0x00, 0x00, 0x00, 3, 0xC0, 0xFF, 0xEE), .byteString(Data([0xC0, 0xFF, 0xEE])))
    XCTAssertEqual(try decode(0x5B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 3, 0xC0, 0xFF, 0xEE), .byteString(Data([0xC0, 0xFF, 0xEE])))
    XCTAssertEqual(try decode(0x5F, 0x58, 3, 0xC0, 0xFF, 0xEE, 0x43, 0xC0, 0xFF, 0xEE, 0xFF), .byteString(Data([0xC0, 0xFF, 0xEE, 0xC0, 0xFF, 0xEE])))
  }

  func testDecodeUtf8Strings() {
    XCTAssertEqual(try decode(0x60), .utf8String(""))
    XCTAssertEqual(try decode(0x61, 0x42), "B")
    XCTAssertEqual(try decode(0x78, 0), "")
    XCTAssertEqual(try decode(0x78, 1, 0x42), "B")
    XCTAssertEqual(try decode(0x79, 0x00, 3, 0x41, 0x42, 0x43), .utf8String("ABC"))
    XCTAssertEqual(try decode(0x7A, 0x00, 0x00, 0x00, 3, 0x41, 0x42, 0x43), "ABC")
    XCTAssertEqual(try decode(0x7B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 3, 0x41, 0x42, 0x43), "ABC")
    XCTAssertEqual(try decode(0x7F, 0x78, 3, 0x41, 0x42, 0x43, 0x63, 0x41, 0x42, 0x43, 0xFF), "ABCABC")
  }

  func testDecodeArrays() {
    XCTAssertEqual(try decode(0x80), [])
    XCTAssertEqual(try decode(0x82, 0x18, 1, 0x79, 0x00, 3, 0x41, 0x42, 0x43), [1, "ABC"])
    XCTAssertEqual(try decode(0x98, 0), [])
    XCTAssertEqual(try decode(0x98, 3, 0x18, 2, 0x18, 2, 0x79, 0x00, 3, 0x41, 0x42, 0x43, 0xFF), [2, 2, "ABC"])
    XCTAssertEqual(try decode(0x9F, 0x18, 255, 0x9B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 2, 0x18, 1, 0x79, 0x00, 3, 0x41, 0x42, 0x43, 0x79, 0x00, 3, 0x41, 0x42, 0x43, 0xFF), [255, [1, "ABC"], "ABC"])
    XCTAssertEqual(try decode(0x9F, 0x81, 0x01, 0x82, 0x02, 0x03, 0x9F, 0x04, 0x05, 0xFF, 0xFF), [[1], [2, 3], [4, 5]])
  }

  func testDecodeMaps() {
    XCTAssertEqual(try decode(0xA0), [:])
    XCTAssertEqual(try decode(0xA1, 0x63, 0x6B, 0x65, 0x79, 0x37)["key"], -24)
    XCTAssertEqual(try decode(0xB8, 1, 0x63, 0x6B, 0x65, 0x79, 0x81, 0x37), ["key": [-24]])
    XCTAssertEqual(try decode(0xBF, 0x63, 0x6B, 0x65, 0x79, 0xA1, 0x63, 0x6B, 0x65, 0x79, 0x37, 0xFF), ["key": ["key": -24]])
  }

  func testDecodeTagged() {
    XCTAssertEqual(try decode(0xC0, 0x79, 0x00, 3, 0x41, 0x42, 0x43), .tagged(.iso8601DateTime, "ABC"))
    XCTAssertEqual(try decode(0xD8, 255, 0x79, 0x00, 3, 0x41, 0x42, 0x43), .tagged(.init(rawValue: 255), "ABC"))
    XCTAssertEqual(try decode(0xDB, 255, 255, 255, 255, 255, 255, 255, 255, 0x79, 0x00, 3, 0x41, 0x42, 0x43), .tagged(.init(rawValue: UInt64.max), "ABC"))
    XCTAssertEqual(try decode(0xDB, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 3, 0xBF, 0x63, 0x6B, 0x65, 0x79, 0xA1, 0x63, 0x6B, 0x65, 0x79, 0x37, 0xFF), .tagged(.negativeBignum, ["key": ["key": -24]]))
  }

  func testDecodeSimple() {
    XCTAssertEqual(try decode(0xE0), .simple(0))
    XCTAssertEqual(try decode(0xF3), .simple(19))
    XCTAssertEqual(try decode(0xF8, 19), .simple(19))
    XCTAssertEqual(try decode(0xF4), false)
    XCTAssertEqual(try decode(0xF5), true)
    XCTAssertEqual(try decode(0xF6), .null)
    XCTAssertEqual(try decode(0xF7), .undefined)
  }

  func testDecodeFloats() {
    XCTAssertEqual(try decode(0xF9, 0xC4, 0x00), .half(-4.0))
    XCTAssertEqual(try decode(0xF9, 0xFC, 0x00), .half(Half(-Float.infinity)))
    XCTAssertEqual(try decode(0xFA, 0x47, 0xC3, 0x50, 0x00), .float(100000.0))
    XCTAssertEqual(try decode(0xFA, 0x7F, 0x80, 0x00, 0x00), .float(Float.infinity))
    XCTAssertEqual(try decode(0xFB, 0xC0, 0x10, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66), .double(-4.1))
  }

  //
  //    func testDecodeDates() {
  //        let dateOne = Date(timeIntervalSince1970: 1363896240)
  //        XCTAssertEqual(try decode(0xc1, 0x1a, 0x51, 0x4b, 0x67, 0xb0), .date(dateOne))
  //        let dateTwo = Date(timeIntervalSince1970: 1363896240.5)
  //        XCTAssertEqual(try decode(0xc1, 0xfb, 0x41, 0xd4, 0x52, 0xd9, 0xec, 0x20, 0x00, 0x00), .date(dateTwo))
  //    }

  func testDecodePerformance() {
    var data = Data([0x9F])
    for i in 0 ..< 255 {
      data.append(contentsOf: [0xBF, 0x63, 0x6B, 0x65, 0x79, 0xA1, 0x63, 0x6B, 0x65, 0x79, 0x18, UInt8(i), 0xFF])
    }
    data.append(0xFF)
    measure {
      _ = try! decode(data)
    }
  }

  func testDecodeMapFromIssue29() {
    let loremIpsumData = Data([0x4C, 0x6F, 0x72, 0x65, 0x6D, 0x20, 0x69, 0x70, 0x73, 0x75, 0x6D, 0x20, 0x64, 0x6F, 0x6C, 0x6F, 0x72, 0x20, 0x73, 0x69, 0x74, 0x20, 0x61, 0x6D, 0x65, 0x74, 0x2C, 0x20, 0x63, 0x6F, 0x6E, 0x73, 0x65, 0x63, 0x74, 0x65, 0x74, 0x75, 0x72, 0x20, 0x61, 0x64, 0x69, 0x70, 0x69, 0x73, 0x63, 0x69, 0x6E, 0x67, 0x20, 0x65, 0x6C, 0x69, 0x74, 0x2E, 0x20, 0x51, 0x75, 0x69, 0x73, 0x71, 0x75, 0x65, 0x20, 0x65, 0x78, 0x20, 0x61, 0x6E, 0x74, 0x65, 0x2C, 0x20, 0x73, 0x65, 0x6D, 0x70, 0x65, 0x72, 0x20, 0x75, 0x74, 0x20, 0x66, 0x61, 0x75, 0x63, 0x69, 0x62, 0x75, 0x73, 0x20, 0x70, 0x68, 0x61, 0x72, 0x65, 0x74, 0x72, 0x61, 0x2C, 0x20, 0x61, 0x63, 0x63, 0x75, 0x6D, 0x73, 0x61, 0x6E, 0x20, 0x65, 0x74, 0x20, 0x61, 0x75, 0x67, 0x75, 0x65, 0x2E, 0x20, 0x56, 0x65, 0x73, 0x74, 0x69, 0x62, 0x75, 0x6C, 0x75, 0x6D, 0x20, 0x76, 0x75, 0x6C, 0x70, 0x75, 0x74, 0x61, 0x74, 0x65, 0x20, 0x65, 0x6C, 0x69, 0x74, 0x20, 0x6C, 0x69, 0x67, 0x75, 0x6C, 0x61, 0x2C, 0x20, 0x65, 0x75, 0x20, 0x74, 0x69, 0x6E, 0x63, 0x69, 0x64, 0x75, 0x6E, 0x74, 0x20, 0x6F, 0x72, 0x63, 0x69, 0x20, 0x6C, 0x61, 0x63, 0x69, 0x6E, 0x69, 0x61, 0x20, 0x71, 0x75, 0x69, 0x73, 0x2E, 0x20, 0x50, 0x72, 0x6F, 0x69, 0x6E, 0x20, 0x73, 0x63, 0x65, 0x6C, 0x65, 0x72, 0x69, 0x73, 0x71, 0x75, 0x65, 0x20, 0x64, 0x75, 0x69, 0x20, 0x61, 0x74, 0x20, 0x6D, 0x61, 0x67, 0x6E, 0x61, 0x20, 0x70, 0x6C, 0x61, 0x63, 0x65, 0x72, 0x61, 0x74, 0x2C, 0x20, 0x69, 0x64, 0x20, 0x62, 0x6C, 0x61, 0x6E, 0x64, 0x69, 0x74, 0x20, 0x66, 0x65, 0x6C, 0x69, 0x73, 0x20, 0x76, 0x65, 0x68, 0x69, 0x63, 0x75, 0x6C, 0x61, 0x2E, 0x20, 0x4D, 0x61, 0x65, 0x63, 0x65, 0x6E, 0x61, 0x73, 0x20, 0x61, 0x63, 0x20, 0x6E, 0x69, 0x73, 0x6C, 0x20, 0x61, 0x20, 0x6F, 0x64, 0x69, 0x6F, 0x20, 0x76, 0x61, 0x72, 0x69, 0x75, 0x73, 0x20, 0x63, 0x6F, 0x6E, 0x64, 0x69, 0x6D, 0x65, 0x6E, 0x74, 0x75, 0x6D, 0x20, 0x6C])
    let data = Data([0xBF, 0x63, 0x6F, 0x66, 0x66, 0x00, 0x64, 0x64, 0x61, 0x74, 0x61, 0x59, 0x01, 0x2C] + loremIpsumData + [0x62, 0x72, 0x63, 0x00, 0x63, 0x6C, 0x65, 0x6E, 0x19, 0x01, 0x2C, 0xFF])

    let expectedMap = CBOR.map([
      .utf8String("off"): .unsignedInt(0),
      .utf8String("data"): .byteString(loremIpsumData),
      .utf8String("rc"): .unsignedInt(0),
      .utf8String("len"): .unsignedInt(300),
    ])

    XCTAssertEqual(try decode(data), expectedMap)
  }
}

