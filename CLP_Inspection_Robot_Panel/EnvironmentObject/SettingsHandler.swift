//
//  StorageHandler.swift
//  CLP_Inspection_Robot_Panel
//
//  Created by Kam Ho Leung on 24/5/2025.
//

import Foundation
import os
import SwiftUI


class SettingsHandler : ObservableObject {
    
    @AppStorage("rosIP") var ip : String = "localhost"
    @AppStorage("rosPort") var port : Int = 5000
    @AppStorage("cameraIP") var cam_ip : String = "localhost"
    @AppStorage("cameraPort") var cam_port : Int = 4000
    @AppStorage("updateRate") var updateRate : Double = 1.0
    @AppStorage("forceUserView") var forceUserView : Bool = false

    init() {

    }
}
