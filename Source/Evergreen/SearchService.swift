//
//  SearchService.swift
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
import PromiseKit

class SearchService {
    static var copyStatusLoaded = false
    
    static func fetchCopyStatusAll() -> Promise<Void> {
        if copyStatusLoaded {
            return Promise<Void>()
        }
        let req = Gateway.makeRequest(service: API.search, method: API.copyStatusAll, args: [])
        let promise = req.gatewayArrayResponse().done { array in
            CopyStatus.loadCopyStatus(fromArray: array)
            copyStatusLoaded = true
        }
        return promise
    }
    
    static func fetchCopySummary(orgID: Int, recordID: Int) -> Promise<([OSRFObject])> {
        let req = Gateway.makeRequest(service: API.search, method: API.copyCount, args: [orgID, recordID])
        let promise = req.gatewayArrayResponse()
        return promise
    }
}