//
//  Theme.swift
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

class CoolTheme: Theme {
    let foregroundColor = UIColor.white
    let backgroundColor = UIColor(red: 0x01/0xff, green: 0x57/0xff, blue: 0x9b/0xff, alpha: 1.0)
    let backgroundDark2 = UIColor(red: 0x00/0xff, green: 0x2f/0xff, blue: 0x6c/0xff, alpha: 1.0)
    let backgroundDark5 = UIColor(red: 0x1e/0xff, green: 0x52/0xff, blue: 0x41/0xff, alpha: 1.0)

    let tableHeaderForeground = UIColor.darkGray
    let tableHeaderBackground = UIColor.groupTableViewBackground
}
