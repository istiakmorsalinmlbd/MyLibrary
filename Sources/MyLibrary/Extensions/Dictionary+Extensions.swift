//
//  Dictionary+Extensions.swift
//  image-uploader
//
//  Created by Bd Stock Air-M on 17/12/22.
//

import Foundation

extension Dictionary where Value: Equatable {
    func key(from value: Value) -> Key? {
        return self.first(where: { $0.value == value })?.key
    }
}
