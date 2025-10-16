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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .provisional, .criticalAlert]) { granted, error in
            print("Notification permission granted: \(granted)")
            if let error = error {
                print("Notification permission error: \(error)")
            }
            
            // Request critical alert permission for better lock screen visibility
            if granted {
                UNUserNotificationCenter.current().requestAuthorization(options: [.criticalAlert]) { criticalGranted, criticalError in
                    print("Critical alert permission: \(criticalGranted)")
                    if let criticalError = criticalError {
                        print("Critical alert permission error: \(criticalError)")
                    }
                }
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
        print("📱 User info: \(notification.request.content.userInfo)")
        
        // Always show notifications even when app is in foreground with maximum visibility
        let options: UNNotificationPresentationOptions = [.banner, .list, .sound, .badge]
        print("📱 Presenting with options: \(options)")
        completionHandler(options)
    }
}
