//
//  PinesAppConfiguration.swift
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

class PinesAppConfiguration: AppConfiguration {
    var title = "PINES"
    let url = "https://gapines.org"
    let bugReportEmailAddress = "kenstir.apps@gmail.com"
    var sort: String? = nil

    let enableHierarchicalOrgTree = true
    let enableHoldShowQueuePosition = false
    let enableHoldPhoneNotification = true
    let enablePartHolds = true
    let enableTitleHoldOnItemWithParts = true
    let enableMainSceneBottomToolbar = true
    let enablePayFines = true
    let enableHoursOfOperation = true
    let enableMessages = true
    let groupCopyInfoBySystem = true
    let enableCopyInfoWebLinks = true
    let needMARCRecord = true
    let showOnlineAccessHostname = true
    let alwaysPopupOnlineLinks = true
    let haveColorButtonImages = false

    let barcodeFormat: BarcodeFormat = .Codabar
    let searchLimit = 200
}
