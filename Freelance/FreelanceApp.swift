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
        print("🔔 Received notification response: \(response.actionIdentifier)")
        print("🔔 Notification content: \(response.notification.request.content.title)")
        print("🔔 User info: \(response.notification.request.content.userInfo)")
        
        // Ensure all notification handling happens on main thread
        DispatchQueue.main.async {
            // Handle notification responses
            print("🔔 Handling notification response")
            TimeTracker.shared.handleNotificationResponse(response)
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📱 Will present notification: \(notification.request.content.title)")
        print("📱 App state: \(UIApplication.shared.applicationState.rawValue) (0=active, 1=inactive, 2=background)")
        print("📱 Notification category: \(notification.request.content.categoryIdentifier)")
        print("📱 Thread ID: \(notification.request.content.threadIdentifier)")
        
        // If this is a dead man switch notification and app is active, show in-app alert as backup
        if notification.request.content.categoryIdentifier == "DEAD_MAN_SWITCH" && 
           UIApplication.shared.applicationState == .active {
            print("📱 Triggering in-app alert for dead man switch")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .deadManSwitchTriggered, object: nil)
            }
        }
        
        // Always show notifications even when app is in foreground with maximum visibility
        let options: UNNotificationPresentationOptions = [.banner, .list, .sound, .badge]
        print("📱 Presenting with options: \(options)")
        completionHandler(options)
    }
}
