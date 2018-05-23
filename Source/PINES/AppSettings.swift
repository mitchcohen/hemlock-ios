//
//  AppSettings.swift
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

import UIKit

//todo make this a protocol
struct AppSettings {
    static let appTitle = "PINES"
    static let url = "https://gapines.org"
    static let themeBackgroundColor = UIColor(red: 0x37/255.0, green: 0x96/255.0, blue: 0x76/255.0, alpha: 1.0)
    static let themeForegroundColor = UIColor.white

    static var idlParserStatus: Bool?
    static var account: Account?
}
