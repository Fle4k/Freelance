//
//  FreelanceApp.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI
import UserNotifications

@main
struct FreelanceApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        TimeTracker.shared.setupNotificationCategories()
        
        // Request notification permissions on app launch
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { granted, error in
            print("Notification permission granted: \(granted)")
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("App entered background")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("App will enter foreground")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Received notification response: \(response.actionIdentifier)")
        
        // Check if this is a timeout notification being dismissed/opened
        if let userInfo = response.notification.request.content.userInfo["type"] as? String,
           userInfo == "dead_man_timeout" && response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            // User opened the timeout notification - handle it as a timeout
            TimeTracker.shared.handleTimeoutNotification()
        } else {
            // Handle other notification responses normally
            TimeTracker.shared.handleNotificationResponse(response)
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Will present notification: \(notification.request.content.title)")
        print("App state: \(UIApplication.shared.applicationState.rawValue)")
        
        // Check if this is a timeout notification
        if let userInfo = notification.request.content.userInfo["type"] as? String,
           userInfo == "dead_man_timeout" {
            print("Timeout notification delivered - stopping timer")
            TimeTracker.shared.handleTimeoutNotification()
        }
        
        // Always show notifications even when app is in foreground
        // Use .banner and .list for persistent notification display (replaces deprecated .alert)
        completionHandler([.banner, .list, .sound, .badge])
    }
}
