//
//  ISSSendAlert.swift
//  iss-passes
//
//  Created by Bradston S Henry on 1/16/18.
//  Copyright © 2018 Brad. All rights reserved.
//

import UIKit

class ISSTableViewController: UITableViewController {
    
    var userLatitude : Double = 0.0
    var userLongitude : Double = 0.0
    
    var selectedRiseTime : String = "";
    var selectedDuration : Double = 0.0;
    
    var dataDictionay = [[String:Int]]()
    
    let numOfPassesRetrieved = 100
    
    let activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "ISSTableViewCell", bundle: nil), forCellReuseIdentifier: "ISSTableViewCell")
        
        // set up activity indicator view
        activityIndicator.center = view.center
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray;
        activityIndicator.hidesWhenStopped = true;
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        // get ISS data and reload tables on completion
        GetISSPassData(latitude: userLatitude, longitude: userLongitude)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataDictionay.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ISSTableViewCell") as! ISSTableViewCell
        
            // format duration in minutes and seconds
            if let duration = dataDictionay[indexPath.row]["duration"] {
                let timeFormatter = DateComponentsFormatter()
                timeFormatter.allowedUnits = [.minute,.second]
                timeFormatter.unitsStyle = .short
                cell.durationLabel.text = timeFormatter.string(from: TimeInterval(duration))
            }
        
            // format date from ISS time interval
            if let risetime = dataDictionay[indexPath.row]["risetime"] {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .long
                dateFormatter.timeStyle = .long
                let date = Date(timeIntervalSince1970: Double(risetime))
                cell.risetimeLabel.text = dateFormatter.string(from: date)
            }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //Grab the duration value fromthe dictionary based on cell selected
        if let duration = dataDictionay[indexPath.row]["duration"] {
            selectedDuration = Double(duration);
        }
        
        if let risetime = dataDictionay[indexPath.row]["risetime"] {
            selectedRiseTime = String(risetime);
        }
        
        //When a row is selected, perform a seque to detail view of ISS Pass
        performSegue(withIdentifier: "InHistorySegue", sender: nil)
    }
    
    func GetISSPassData(latitude: Double, longitude: Double){
        
        guard let issURL = URL(string: "http://api.open-notify.org/iss-pass.json?lat=\(latitude)&lon=\(longitude)" + "&n=" + String(numOfPassesRetrieved)) else{return}
        
        let request = URLRequest(url: issURL)
        
        let dataTask = URLSession.shared.dataTask(with: request){ (data, response, error) -> Void in
            
            if (error != nil) {
               sendAlert(message: String.init(describing: error!.localizedDescription))
            }else {
                // Attempt to Serialize data into JSON
                if let data = data, let dataDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]{
                    //If data exists and contains responses, set ISS pass tada to data Dictionary and reload table
                    if let dict = dataDict, let passes = dict["response"] as? [[String:Int]]{
                        self.dataDictionay = passes
                        DispatchQueue.main.async {
                            self.activityIndicator.stopAnimating()
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
        dataTask.resume()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        //Pass ISS riseTime and duration to next view controller for setting view
        if let tableviewController = segue.destination as? ViewPassInfoViewController{
            tableviewController.riseTime = selectedRiseTime;
            tableviewController.duration = selectedDuration;
        }
        
    }

}
