//
//  GatewayResponse.swift
//
//  Copyright (C) 2018 Kenneth H. Cox
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

import Foundation
import os.log

public enum GatewayError: Error {
    case malformedPayload(String)
    case failure(String)
}

enum GatewayResponseType {
    case string
    case object
    case array
    case error
}

struct GatewayResponse {
    //MARK: - Properties

    var type: GatewayResponseType
    var error: GatewayError?

    // a field for each GatewayResultType; I'm sure there's a better way
    var stringResult: String?
    var objectResult: OSRFObject?
    var arrayResult: [Any]?
    var str: String? { return stringResult }
    var obj: OSRFObject? { return objectResult }
    var array: [Any]? { return arrayResult }

    var failed: Bool {
        return type == .error
    }
    var errorMessage: String {
        guard let error = self.error else {
            return "no error"
        }
        switch error {
        case .malformedPayload(let reason): return reason
        case .failure(let reason):          return reason
        }
        //NOTREACHED: switch statements must be exhaustive
    }
    
    //MARK: - Lifecycle
    
    init() {
        type = .error
        error = .failure("unintialized")
    }
    
    init(_ jsonString: String) {
        self.init()
        guard let data = jsonString.data(using: .utf8) else {
            error = .failure("Unable to encode as utf8: \(jsonString)")
            return
        }
        self.init(data)
    }

    init(_ data: Data) {
        self.init()

        guard var json = decodeJSON(data) else {
            os_log("resp.json: decode_error", log: Gateway.log, type: .info)
            error = .failure("Response not JSON")
            return
        }
        os_log("resp.json: %@", log: Gateway.log, type: .info, json)

        guard let status = json["status"] as? Int else {
            error = .failure("Response missing status")
            return
        }
        if status != 200 {
            error = .failure("Response status \(status)")
            return
        }

        // payload is always an array,
        // usually an array of one json object,
        // but in the cases of authInit it is an array of one string
        guard let payload = json["payload"] as? [Any] else {
            error = .failure("Response missing payload")
            return
        }
        if let val = payload.first as? [String: Any?] {
            do {
                try objectResult = decodeObject(val)
            }
            catch {
                self.error = .failure("Error decoding OSRF object")
                return
            }
            type = .object
        } else if let val = payload.first as? [Any] {
            type = .array
            arrayResult = val
        } else if let val = payload.first as? String {
            type = .string
            stringResult = val
        } else {
            error = .failure("Response has unexpected payload: \(String(describing: payload))")
            return
        }
        error = nil
    }
    
    // MARK: - Functions
    
    func decodeJSON(_ data: Data) -> [String: Any]? {
        if
            let json = try? JSONSerialization.jsonObject(with: data),
            let jsonObject = json as? [String: Any]
        {
            return jsonObject
        } else {
            return nil
        }
    }
    
    func decodeObject(_ jsonObject: [String: Any?]) throws -> OSRFObject? {
        return try OSRFCoder.decode(fromWireProtocol: jsonObject)
    }

    static func makeError(_ reason: String) -> GatewayResponse {
        var resp = GatewayResponse()
        resp.error = .failure(reason)
        return resp
    }
}
