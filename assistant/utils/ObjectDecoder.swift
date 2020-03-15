//
//  ObjectDecoder.swift
//  assistant
//
//  Created by Gabe Kangas on 2/13/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation

enum DateError: String, Error {
    case invalidDate
}

struct ObjectDecoder<T: Decodable> {
    enum DecoderError: Error {
        case UnableToConvertStringToData
    }
    
    /// Get an object from a JSON string.
    func getObjectFrom(jsonString: String, decodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) throws -> T {
        guard let data = jsonString.data(using: .utf16) else {
            throw DecoderError.UnableToConvertStringToData
        }
        
        return try getObjectFrom(jsonData: data, decodingStrategy: decodingStrategy)
    }
    
    /// Get an object from JSON data.
    func getObjectFrom(jsonData: Data, decodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) throws -> T {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = decodingStrategy
        
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        jsonDecoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            // Try different date formatting to pull a date object from.
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            throw DateError.invalidDate
        })
        return try jsonDecoder.decode(T.self, from: jsonData)
    }
}

extension Encodable {
    var jsonString: String? {
        let jsonEncoder = JSONEncoder()
        guard let data = try? jsonEncoder.encode(self) else { return nil }//.string(encoding: .utf8)) ?? nil
        return String(data: data, encoding: .utf8)
    }
    
    var data: Data? {
        let jsonEncoder = JSONEncoder()
        guard let data = try? jsonEncoder.encode(self) else { return nil }//.string(encoding: .utf8)) ?? nil
        return data
    }
}
