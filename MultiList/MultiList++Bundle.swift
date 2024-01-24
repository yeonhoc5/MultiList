//
//  MultiList++Bundle.swift
//  MultiList
//
//  Created by yeonhoc5 on 1/24/24.
//

import Foundation

extension Bundle {
    var kakao: String {
        guard let file = self.path(forResource: "ApiKeyInfo", ofType: "plist") else { return "" }
        guard let resource = NSDictionary(contentsOfFile: file) else { return "" }
        guard let key = resource["kakao"] as? String else {
            fatalError("kakako api를 가져오지 못했습니다.")
        }
        return key
    }
}
