//
//  Review.swift
//  Cinephile
//
//  Created by Thomas Ricouard on 16/06/2019.
//  Copyright © 2019 Thomas Ricouard. All rights reserved.
//

import Foundation
import SwiftUI

struct Review: Codable, Identifiable {
    let id: String
    let author: String
    let content: String
}
