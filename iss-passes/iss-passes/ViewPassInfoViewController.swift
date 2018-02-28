//
//  ViewPassInfoViewController.swift
//  iss-passes
//
//  Created by Bradston S Henry on 2/18/18.
//  Copyright © 2018 Brad. All rights reserved.
//

import UIKit
import UserNotifications

class ViewPassInfoViewController: UIViewController, UNUserNotificationCenterDelegate {


    @IBOutlet weak var passDateLabel: UILabel!
    @IBOutlet weak var passDurationLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var eventTextLabe: UILabel!
    
    @IBOutlet weak var activityIndicatorYear: UIActivityIndicatorView!
    @IBOutlet weak var activityIndicatorEvent: UIActivityIndicatorView!
    
    @IBOutlet weak var setReminderButton: UIButton!
    
    @IBAction func setReminderButtonAction(_ sender: Any) {
        
        if let rise = riseTime {
            
            //Create a Notification Reminding of passing ISS at specified date and time selected from tableview
            let issReminderContent = UNMutableNotificationContent();
            issReminderContent.title = "ISS Pass Reminder";
            issReminderContent.body = "The International Space Station is passing your previously set location now!";
            issReminderContent.categoryIdentifier = "issReminderNotificationCategory";
            
            //Set Date from rise time
            let date = Date(timeIntervalSince1970: Double(rise)!)
            //Create a calendar and specify the calendar components we would like to use
            let calendar = Calendar.current
            let unitFlags = Set<Calendar.Component>([.month, .hour, .year, .minute, .second ])
            //Create a DateComponents variable to be used on creating the Trigger for notification
            let components = calendar.dateComponents(unitFlags, from: date as Date)
            //Create Notiifcation from Date Components created
            let ISSPassTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false);
            
            //Set up Notification request for setting request on system
            let testRequestIdentifier = "issReminderRequest";
            let request = UNNotificationRequest(identifier: testRequestIdentifier, content: issReminderContent, trigger: ISSPassTrigger);
            
            //Add request to Notification center and check to see if there were any errors
            UNUserNotificationCenter.current().add(request){
                (error) in
                
                //If no error, set Button with appopriate text and state
                guard let err = error else {
                    DispatchQueue.main.async {
                        print(ISSPassTrigger);
                        self.setReminderButton.isUserInteractionEnabled = false;
                        self.setReminderButton.titleLabel?.text = "Reminder Set!";
                        
                    }
                    return
                };
                
                sendAlert(message: "Error occurred when setting Reminder");
                print(err as Any);
                
            }
            
        }
        
    }
    
    var riseTime : String?;
    var duration : Double?;
    var urlDateText : String?;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicatorYear.hidesWhenStopped = true;
        activityIndicatorYear.startAnimating();
        
        activityIndicatorEvent.hidesWhenStopped = true;
        activityIndicatorEvent.startAnimating();
        
        //Set Button label Alignment to center
        setReminderButton.titleLabel?.textAlignment = NSTextAlignment.center;
        
        //Set the correct data to ISS data labels
        FormatISSPassDataLabels();
        
        //Make this Viewcontroller a delegate of User Notification
        UNUserNotificationCenter.current().delegate = self;
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func FormatISSPassDataLabels(){
        
        // format duration in minutes and seconds
        if let dur = duration {
            let timeFormatter = DateComponentsFormatter()
            timeFormatter.allowedUnits = [.minute,.second]
            timeFormatter.unitsStyle = .short
            passDurationLabel.text = timeFormatter.string(from: TimeInterval(dur))
        }
        
        // format date from ISS time interval
        if let rise = riseTime {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .long
            let date = Date(timeIntervalSince1970: Double(rise)!)
            passDateLabel.text = dateFormatter.string(from: date)
            
            let urlDateFormat = DateFormatter();
            urlDateFormat.dateFormat = "MM/dd";
            print("The Date is \(urlDateFormat.string(from: date))");
            urlDateText = urlDateFormat.string(from: date);
        }
        
        //Function to call request to grab history data from history data API
        GetTodayInHistory();
        
    }
    
    //Grab a random fun history fact about the particular ISS pass day selected from table view
    func GetTodayInHistory(){
        
        //Do not proceed if no url Data text is avalaible (month and day used for parameters to call API)
        if let dateText = urlDateText {
            //IF not valid URL, do not proceed any further
            guard let todayInHistoryURL = URL(string: "http://history.muffinlabs.com/date/\(dateText)") else{return}
            
            let dataTask = URLSession.shared.dataTask(with: todayInHistoryURL){ (data, response, error) in
                
                if (error != nil) {
                    sendAlert(message: String.init(describing: error!.localizedDescription))
                }else {
                    // Attempt to Serialize data into JSON
                    if let data = data, let dataDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]{
                        //If data exists at endpoint, parse through data to retrieve event data
                        if let dict = dataDict, let dateData = dict["data"] as? [String:Any], let events = dateData["Events"] as? [Any]{
                            //Choose a random indice from event array which will be used for retrieving random event
                            let ranIndiceNum = arc4random_uniform(UInt32(events.count));
                            //If random indice holds an event, put event data in view
                            if let event = events[Int(ranIndiceNum)] as? [String:Any] {
                                //If event year data and event text data exists, update view with info
                                if let eventYear = event["year"] as? String, let eventText = event["text"] as? String{
                                    DispatchQueue.main.async {
                                        //Stop activity indicator once data is loaded and set appropriate labels
                                        self.activityIndicatorYear.stopAnimating();
                                        self.activityIndicatorEvent.stopAnimating();
                                        self.yearLabel.text = eventYear;
                                        self.eventTextLabe.text = eventText;
                                    }
                                    
                                }
                            }
                            
                        }
                    }
                }
                
            }
            dataTask.resume()
        }
        
    }
    
    //MARK - UNNotification Delgate Methods
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        //Set completion handler with Notification parameters desired
        completionHandler([.alert,.sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
    }

}
