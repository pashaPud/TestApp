//
//  ViewController.swift
//  TinkoffTestApp
//
//  Created by Admin on 30.01.2021.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var logoImage: UIImageView!
    
    private let token = "pk_d44620472c624e4a8527e23293fbdc37"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        companyNameLabel.text = "Tinkoff"
        
        companyPickerView.dataSource = self
        companyPickerView.delegate = self
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        requestQuote(for: "AAPL")
        requestQuoteUpdate()
    }
private lazy var companies = [
    "Apple" : "AAPL",
    "Microsoft" : "MSFT",
    "Google" : "GOOG",
    "Amazon" : "AMZN",
    "Facebook" : "FB"
]
    
    private func requestQuote(for symbol: String) {
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=\(token)") else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) {
            [weak self](data, response, error) in
            if let data = data,
               (response as? HTTPURLResponse)?.statusCode == 200,
               error == nil {
                self?.parseQuote(from: data)
            }else{
                print("Network error!")
            }
        }
        dataTask.resume()
    }
    
    private func requestLogo(for symbol: String) {
            guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/logo?token=\(token)") else {
                return
            }
            
            let dataTask = URLSession.shared.dataTask(with: url) {
                (data, response, error) in
                if let data = data,
                   (response as? HTTPURLResponse)?.statusCode == 200,
                   error == nil {
                    self.parseLogoImageResponse(from: data)
                } else {
                    print("Image load error")
                }
            }
            
            dataTask.resume()
        }
        
        private func parseLogoImageResponse(from data: Data) {
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data)
                
                guard let json = jsonObject as? [String: Any],
                      let urlString = json["url"] as? String,
                      let url = URL(string: urlString) else { return print("Invalid JSON") }
                logoImage.load(url: url)
                
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
            }
        }
    
    private func parseQuote(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double else {
                return print("Invalid JSON")}
            
            DispatchQueue.main.async{
                [weak self] in
                self?.displayStockInfo(companyName: companyName,
                                       companySymbol: companySymbol,
                                       price: price,
                                       priceChange: priceChange)
            }
        } catch {
            print("JSON parsing error: " + error.localizedDescription)
        }
    }
    private func displayStockInfo(companyName: String,
                                  companySymbol: String,
                                  price: Double,
                                  priceChange: Double) {
        activityIndicator.stopAnimating()
        companyNameLabel.text = companyName
        companySymbolLabel.text = companySymbol
        priceLabel.text = "\(price)"
        priceChangeLabel.text = "\(priceChange)"
        priceChangeLabel.textColor = setPriceChangeLabelColor(priceChange: priceChange)
    }
    
    
    private func setPriceChangeLabelColor(priceChange: Double) -> UIColor{
        switch priceChange {
        case 1...:
            return UIColor.green
        case ..<0:
            return UIColor.red
        default:
            return UIColor.black
        }
    }
    
    private func requestQuoteUpdate(){
        activityIndicator.startAnimating()
        companyNameLabel.text = "-"
        companySymbolLabel.text = "-"
        priceLabel.text = "-"
        priceChangeLabel.text = "-"
        priceChangeLabel.textColor = UIColor.black
        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(companies.values)[selectedRow]
        requestQuote(for: selectedSymbol)
        requestLogo(for: selectedSymbol)
    }
    }
extension ViewController: UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return companies.keys.count
    }
}
extension ViewController: UIPickerViewDelegate{
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Array(companies.keys)[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        requestQuoteUpdate()
    }
    
}

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}
