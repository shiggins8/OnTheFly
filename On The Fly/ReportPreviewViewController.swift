//
//  ReportPreviewViewController.swift
//  On The Fly
//
//  Created by Scott Higgins on 5/4/17.
//  Copyright © 2017 ScottieH. All rights reserved.
//

import UIKit

class ReportPreviewViewController: UIViewController {

    @IBOutlet weak var reportWebView: UIWebView!
    var reportHtml: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let reportData = reportHtml {
            reportWebView.loadHTMLString(reportData, baseURL: nil)
        } else {
            print("no data")
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        reportWebView.scrollView.contentInset = UIEdgeInsets.zero
    }
    
    @IBAction func donePressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    

}
