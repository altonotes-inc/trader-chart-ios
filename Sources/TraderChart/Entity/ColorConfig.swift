//
//  ColorConfig.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/06/07.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// チャートの色設定。JSONの設定ファイルから作成できる
open class ColorConfig {
    
    var dictionary: [String: UIColor?] = [:]

    /// 初期化
    public init() {}

    /// JSONの設定ファイルのパスを指定して初期化
    public init(filePath: String) {
        guard let path = Bundle.main.url(forResource: filePath, withExtension: "json") else { return }
        guard let data = try? Data(contentsOf: path) else { return }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else { return }
        parseJson(json)
    }
    
    private func parseJson(_ json: [String: Any], parentKey: String = "") {
        json.forEach { key, value in
            if let argbHex = value as? String, argbHex.isNotEmpty {
                dictionary[parentKey + key] = UIColor(argbHex: argbHex)
            } else if let subDict = value as? [String: Any] {
                parseJson(subDict, parentKey: parentKey + key + ".")
            }
        }
    }

    /// 引数のキーに紐づく色を取得する
    open subscript(key: String) -> UIColor? {
        return dictionary[key] ?? nil
    }
}

/// ColorConfigを反映可能なことを示すプロトコル
public protocol ColorConfigurable {
    ///　色設定情報を反映する
    func reflectColorConfig(_ colorConfig: ColorConfig)
}
