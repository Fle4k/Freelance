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
        TimeTracker.shared.handleNotificationResponse(response)
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Will present notification: \(notification.request.content.title)")
        print("App state: \(UIApplication.shared.applicationState.rawValue)")
        
        // Always show notifications even when app is in foreground
        // Use .alert instead of .banner for better lock screen visibility
        completionHandler([.alert, .sound, .badge])
    }
}
