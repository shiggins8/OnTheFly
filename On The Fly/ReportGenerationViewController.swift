//
//  ReportGenerationViewController.swift
//  On The Fly
//
//  Created by Scott Higgins on 1/26/17.
//  Copyright © 2017 ScottieH. All rights reserved.
//

import UIKit
import Charts
import MessageUI
import Firebase

class ReportGenerationViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var sendReportCheckbox: CheckboxButton!
    @IBOutlet weak var saveLocallyCheckbox: CheckboxButton!

    @IBOutlet weak var emailTextfield: PaddedTextField!

    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveLocallyButton: UIButton!

    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var lineChartView: LineChartView!

    var flight: Flight?
    var plane: Plane?
    var activeField: PaddedTextField?

    var flightGraphPath: String?

    var reportCreator = ReportComposer()
    var docController: UIDocumentInteractionController?

    @IBOutlet weak var webView: UIWebView!


    override func viewDidLoad() {
        super.viewDidLoad()

        emailTextfield.roundCorners()
        addKeyboardToolBar(textField: emailTextfield)

        sendButton.addBlackBorder()
        cancelButton.addBlackBorder()
        saveLocallyButton.addBlackBorder()

        lineChartView.noDataText = "No center of gravity envelope data found."
        lineChartView.noDataTextColor = .blue

        var coordArray: [(ChartDataEntry, Int)] = []

        if let thisPlane = self.plane {
            let envPoints = thisPlane.centerOfGravityEnvelope
            for (index, element) in envPoints.enumerated() {
                let newPoint = ChartDataEntry(x: element["x"]!, y: element["y"]!)
                coordArray.append((newPoint, index))
            }
        }

        let ySeries = coordArray.map { x, _ in
            return x
        }

        let bottomConnectorSeries = [ySeries.first!, ySeries.last!]

        var cogSeries: [ChartDataEntry] = []

        cogSeries.append(ChartDataEntry(x: flight!.calcLandingCenterOfGravity(plane: plane!), y: flight!.calcLandingWeight(plane: plane!)))

        cogSeries.append(ChartDataEntry(x: flight!.calcTakeoffCenterOfGravity(plane: plane!), y: flight!.calcTakeoffWeight(plane: plane!)))

        let data = LineChartData()

        let dataset = LineChartDataSet(values: ySeries, label: "CoG Envelope")
        dataset.colors = [NSUIColor.blue]
        dataset.circleRadius = 4.0
        dataset.lineWidth = 3.0
        data.addDataSet(dataset)

        let dataset2 = LineChartDataSet(values: bottomConnectorSeries, label: "Lower Limit")
        dataset2.colors = [NSUIColor.red]
        dataset2.circleRadius = 4.0
        dataset2.lineWidth = 3.0
        data.addDataSet(dataset2)

        let dataset3 = LineChartDataSet(values: cogSeries, label: "Flight Shift")
        dataset3.colors = [NSUIColor.darkGray]
        dataset3.circleRadius = 4.0
        dataset3.lineWidth = 2.0
        dataset3.valueFont = UIFont.systemFont(ofSize: 9)
        data.addDataSet(dataset3)

        self.lineChartView.data = data

        self.lineChartView.xAxis.axisMinimum = ySeries.first!.x - 2.0
        self.lineChartView.xAxis.axisMaximum = ySeries.last!.x + 2.0

        self.lineChartView.gridBackgroundColor = NSUIColor.white
        self.lineChartView.xAxis.drawGridLinesEnabled = true;
        self.lineChartView.xAxis.labelPosition = XAxis.LabelPosition.bottom
        self.lineChartView.chartDescription?.text = "W & B Graph"

        self.flightGraphPath = "\((UIApplication.shared.delegate as! AppDelegate).getDocDir())/flightGraph\(arc4random_uniform(767)).PNG"

        if self.lineChartView.save(to: flightGraphPath! , format: .png, compressionQuality: 0.5) {

            reportCreator.flight = self.flight!
            reportCreator.plane = self.plane!

            let myData = self.reportCreator.renderReport(imagePath: flightGraphPath!)

            self.webView.loadHTMLString(myData!, baseURL: nil)

        } else {
            print("flight graph couldn't be saved")
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        self.lineChartView.animate(xAxisDuration: 0.5, yAxisDuration: 0.5)

        registerForKeyboardNotifications()

        if let userid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference().child("users")
            ref.child(userid).observe(DataEventType.value, with: { (snapshot) in
                let userInfo = snapshot.value as! [String:Any]
                self.emailTextfield.text = (userInfo["email"] as! String)
            })
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        deregisterFromKeyboardNotifications()
        clearTempFiles()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func sendReportButtonPressed(_ sender: Any) {
        sendReportCheckbox.checkBox()
    }

    @IBAction func saveLocallyButtonPressed(_ sender: Any) {
        saveLocallyCheckbox.checkBox()
    }

    @IBAction func saveButtonPressed(_ sender: Any) {
        let path = self.reportCreator.pdfFilename!
        let targetURL = NSURL.fileURL(withPath: path)
        docController = UIDocumentInteractionController(url: targetURL)
        let url = NSURL(string:"itms-books:")
        if UIApplication.shared.canOpenURL(url! as URL) {
            docController!.presentOpenInMenu(from: CGRect.zero, in: self.view, animated: true)
        }else{
            self.alert(message: "Can't open the PDF in iBooks.", title: "Local Save Error")
        }
    }


    @IBAction func sendButtonPressed(_ sender: AnyObject) {
        if let regEmail = emailTextfield.text {
            if (regEmail.isValidEmail()) {

                if MFMailComposeViewController.canSendMail() {
                    let mailComposeViewController = MFMailComposeViewController()
                    mailComposeViewController.mailComposeDelegate = self
                    mailComposeViewController.setSubject("W & B Report")
                    mailComposeViewController.setToRecipients([regEmail])
                    mailComposeViewController.addAttachmentData(NSData(contentsOfFile: reportCreator.pdfFilename)! as Data, mimeType: "application/pdf", fileName: "W & B Report")
                    present(mailComposeViewController, animated: true, completion: nil)
                }

                let alert = UIAlertController(title: "Report Sent!", message: "Your weight and balance report has been send to the email address above.", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK. Return to Home", style: UIAlertActionStyle.default, handler: {action in

                    self.performSegue(withIdentifier: "homeAfterReportSegue", sender: nil)

                }))

                self.present(alert, animated: true, completion: nil)
            } else {
                alert(message: "The email you entered is not valid, please check the email and try again", title: "Invalid email address")
            }
        }
    }


    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - UITextField Navigation Keyboard Toolbar

    func registerForKeyboardNotifications(){
        // Adding notifies on keyboard appearing
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }

    func deregisterFromKeyboardNotifications(){
        // Removing notifies on keyboard appearing
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }

    @objc func keyboardWasShown(notification: NSNotification){

        self.scrollView.isScrollEnabled = true
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let point2 = CGPoint(x: 0, y: activeField!.frame.origin.y + activeField!.frame.height)


        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height
        if let activeField = self.activeField {
            if (!aRect.contains(activeField.frame.origin) || !aRect.contains(point2)){
                print("part of view at least covered")
                let yOffset = abs(aRect.origin.y + aRect.height - point2.y) + 80
                self.scrollView.setContentOffset(CGPoint(x: 0, y: yOffset), animated: true)
            } else {
                print("nothing covered")
                self.scrollView.setContentOffset(CGPoint.zero, animated: true)
            }
        } else {
            print("invalid active field")
        }

    }

    func addKeyboardToolBar(textField: UITextField) {
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        keyboardToolbar.barStyle = .default
        keyboardToolbar.isTranslucent = true



        let kbDoneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePressed))
        let blankSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        blankSpacer.width = kbDoneBtn.width
        let flexiSpacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let kbTitleBtn = UIBarButtonItem(title: "Title", style: .plain, target: nil, action: nil)
        kbTitleBtn.isEnabled = false
        keyboardToolbar.setItems([blankSpacer, flexiSpacer, kbTitleBtn, flexiSpacer, kbDoneBtn], animated: true)

        let textPlaceholderLabel = UILabel()
        textPlaceholderLabel.sizeToFit()
        textPlaceholderLabel.backgroundColor = UIColor.clear
        textPlaceholderLabel.textAlignment = .center
        kbTitleBtn.customView = textPlaceholderLabel

        textPlaceholderLabel.text = textField.placeholder!
        textPlaceholderLabel.sizeToFit()

        keyboardToolbar.isUserInteractionEnabled = true
        keyboardToolbar.sizeToFit()

        textField.inputAccessoryView = keyboardToolbar
    }

    @objc func donePressed() {
        self.view.endEditing(true)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeField = textField as? PaddedTextField
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeField = nil
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "reportPreviewSegue" {
            let previewVC = segue.destination as! ReportPreviewViewController
            previewVC.reportHtml = self.reportCreator.renderReport(imagePath: self.flightGraphPath!)
        }
    }

    @IBAction func backPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

}

extension ReportGenerationViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

extension ReportGenerationViewController: UIWebViewDelegate {

    func webViewDidFinishLoad(_ webView: UIWebView) {
        let frame = self.webView.frame
        self.webView.frame = CGRect.zero
        self.webView.frame = frame
        if (self.reportCreator.renderReport(imagePath: self.flightGraphPath!)) != nil {
            self.reportCreator.exportHTMLContentToPDF(webView: webView)
        }
    }

    func clearTempFiles() {
        let fileManager = FileManager.default
        let tempFolderPath = (UIApplication.shared.delegate as! AppDelegate).getDocDir()

        do {
            var deletePath = self.flightGraphPath!
            try fileManager.removeItem(atPath: deletePath)
            deletePath = tempFolderPath.appending("/Report1.pdf")
            try fileManager.removeItem(atPath: deletePath)
        } catch let error as NSError {
            print("Could not clear temp folder: \(error.debugDescription)")
        }
    }

}

