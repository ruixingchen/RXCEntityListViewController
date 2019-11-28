//
//  ViewController2.swift
//  Example
//
//  Created by ruixingchen on 11/28/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit

class ViewController2: UIViewController {

    let queue = DispatchQueue(label: "", qos: .default, attributes: .concurrent)
    let group = DispatchGroup()

    var list:[Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        for i in 0..<100 {
            self.queue.async(group: nil, qos: .default, flags: .barrier) {
                self.list.append(i)
            }
            print(self.list)
        }

        print("完成")
    }

}
