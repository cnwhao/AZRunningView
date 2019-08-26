//
//  ViewController.swift
//  AZRunningView
//
//  Created by wanghaohao on 2019/8/21.
//  Copyright © 2019 whao. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    private var datas:Array<String> = {
        return ["1111111", "22", "3", "7897832642783647823"]
    }()
    
    private lazy var runningView:AZRunningView = {
        let run = AZRunningView(frame: CGRect(x: 0, y: 100, width: UIScreen.main.bounds.size.width, height: 80))
        run.dataSource = self
        run.delegate = self
        run.registerItemClasse(classType: UILabel.self, reuseIdentifier: "xxxxxx")
        return run
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.addSubview(self.runningView)
        
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.runningView.stop()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.runningView.run()
    }
}

extension ViewController:AZRunningViewDataSource {
    func runningView(_ runningView: AZRunningView, itemAt index: Int) -> UIView {
        
        let reuseLabel:UILabel? = runningView.dequeueItemViewResueIdentity(resueIdentity: "xxxxxx") as? UILabel
        if reuseLabel != nil {
            reuseLabel!.text = self.datas[index]
            return reuseLabel!
        }
        let label = UILabel()
        label.text = self.datas[index]
        label.font = UIFont.systemFont(ofSize: 20)
        label.backgroundColor = index % 2 == 0 ? .red : .yellow
        //        print("index = \(index)   text = \(label.text)")
        return label
    }
    
    func numberOfItemsAtRunningView(_ runningView: AZRunningView) -> Int {
        return datas.count
    }
    
    func runningView(_ runningView: AZRunningView, widthOfItem index: Int) -> CGFloat {
        let str = self.datas[index]
        let font = UIFont.systemFont(ofSize: 20)
        let rect = str.boundingRect(with:CGSize.init(width: CGFloat(MAXFLOAT), height: 50),options: NSStringDrawingOptions.usesLineFragmentOrigin,attributes: [NSAttributedString.Key.font:font],context:nil)
        if index % 2 == 0 {
            return rect.size.width
        }else{
            return rect.size.width
        }
    }
}

extension ViewController:AZRunningViewDelegate {
    func runningView(_ runningView: AZRunningView, didClickItemAt index: Int) {
        print("didClickItemAt ==== \(index)")
    }
}
