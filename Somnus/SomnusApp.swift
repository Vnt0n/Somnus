//
//  SomnusApp.swift
//  Somnus
//
//  Created by Antoine on 08/10/2024.
//

import SwiftUI
import IOKit.pwr_mgt

@main
struct SomnusApp: App {
    @StateObject private var viewModel = SomnusViewModel()

    var body: some Scene {
        WindowGroup {
            SettingsView(viewModel: viewModel)
        }
        MenuBarExtra {
            // Contenu du menu déroulant
            VStack {
                Button(action: {
                    viewModel.toggleDisplaySleepMode() // Gérer la mise en veille de l'écran
                }) {
                    HStack {
                        if viewModel.isDisplaySleepDisabled {
                            Image(systemName: "checkmark")
                        }
                        Text("Prevent Display sleep")
                    }
                }

                Button(action: {
                    viewModel.toggleSystemSleepMode() // Gérer la mise en veille du système
                }) {
                    HStack {
                        if viewModel.isSystemSleepDisabled {
                            Image(systemName: "checkmark")
                        }
                        Text("Prevent System sleep")
                    }
                }
                
                Divider() // Séparation pour les options du menu

                Button(action: {
                    viewModel.showAboutMe() // Ouvre la fenêtre AboutMe
                }) {
                    HStack {
                        Text("About Somnus")
                    }
                }
                
                Divider() // Séparation pour les options du menu

                Button(action: {
                    viewModel.showSettings()
                }) {
                    HStack {
                        Text("Settings")
                    }
                }
                
                Divider() // Séparation pour les options du menu

                Button(action: {
                    NSApp.terminate(nil) // Quitte l'application
                }) {
                    HStack {
                        Text("Quit Somnus")
                    }
                }
            }
            
        } label: {
            // Label pour la barre de menu (icône dynamique)
            Image(systemName: viewModel.menuIcon)
        }
//        Settings {
//            SettingsView(viewModel: viewModel) // Ajout de la vue Settings
//        }
    }
}

// Vue pour l'onglet "About me"
struct AboutMeView: View {
    var body: some View {
        VStack {
            Text("About Somnus")
                .font(.title)
                .padding()
            Text("This app prevents your Mac from sleeping.")
                .padding()
        }
        .frame(width: 300, height: 200)
    }
}

// Vue pour les Settings
struct SettingsView: View {
    @ObservedObject var viewModel: SomnusViewModel
    
    var body: some View {
        Form {
            Section(header: Text("Sleep Settings")) {
                Toggle("Prevent Display Sleep", isOn: $viewModel.isDisplaySleepDisabled)
                    .onChange(of: viewModel.isDisplaySleepDisabled) {
                        viewModel.toggleDisplaySleepMode()
                    }
                
                Toggle("Prevent System Sleep", isOn: $viewModel.isSystemSleepDisabled)
                    .onChange(of: viewModel.isSystemSleepDisabled) {
                        viewModel.toggleSystemSleepMode()
                    }
            }
        }
        .frame(minWidth: 400, minHeight: 200)
        .padding()
    }
}

class SomnusViewModel: ObservableObject {
    // Propriétés pour la mise en veille de l'écran
    @Published var menuIcon: String = "bolt" // Icône dans la barre de menu
    private var sleepAssertionID: IOPMAssertionID = 0
    @Published var isDisplaySleepDisabled: Bool = false

    // Propriétés pour la mise en veille du système
    private var systemSleepAssertionID: IOPMAssertionID = 0
    @Published var isSystemSleepDisabled: Bool = false

    // Fenêtre pour la vue AboutMe
    private var aboutWindow: NSWindow?
    private var settingsWindow: NSWindow?

    // Fonction pour gérer la mise en veille de l'écran
    func toggleDisplaySleepMode() {
        if isDisplaySleepDisabled {
            enableDisplaySleep()
        } else {
            disableDisplaySleep()
            // Désactive la mise en veille du système si l'écran reste éveillé
            if isSystemSleepDisabled {
                enableSystemSleep()
            }
        }
        menuIcon = isDisplaySleepDisabled ? "bolt.fill" : "bolt"
    }

    private func disableDisplaySleep() {
        let result = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep as CFString,
                                                 IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                                 "Prevent Display Sleep" as CFString,
                                                 &sleepAssertionID)
        if result == kIOReturnSuccess {
            isDisplaySleepDisabled = true
            // Désactive la mise en veille du système si l'écran reste éveillé
            if isSystemSleepDisabled {
                enableSystemSleep()
            }
        }
    }

    private func enableDisplaySleep() {
        let result = IOPMAssertionRelease(sleepAssertionID)
        if result == kIOReturnSuccess {
            isDisplaySleepDisabled = false
        }
    }

    // Fonction pour gérer la mise en veille du système
    func toggleSystemSleepMode() {
        if isSystemSleepDisabled {
            enableSystemSleep()
        } else {
            disableSystemSleep()
            // Désactive la mise en veille de l'écran si le système reste éveillé
            if isDisplaySleepDisabled {
                enableDisplaySleep()
            }
        }
        menuIcon = isSystemSleepDisabled ? "bolt.fill" : "bolt"
    }

    private func disableSystemSleep() {
        let result = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoIdleSleep as CFString,
                                                 IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                                 "Prevent System Sleep" as CFString,
                                                 &systemSleepAssertionID)
        if result == kIOReturnSuccess {
            isSystemSleepDisabled = true
            // Désactive la mise en veille de l'écran si le système reste éveillé
            if isDisplaySleepDisabled {
                enableDisplaySleep()
            }
        }
    }

    private func enableSystemSleep() {
        let result = IOPMAssertionRelease(systemSleepAssertionID)
        if result == kIOReturnSuccess {
            isSystemSleepDisabled = false
        }
    }

    // Fonction pour afficher la vue AboutSomnus
    func showAboutMe() {
        if aboutWindow == nil {
            let aboutView = NSHostingController(rootView: AboutMeView())
            aboutWindow = NSWindow(
                contentViewController: aboutView
            )
            aboutWindow?.setContentSize(NSSize(width: 300, height: 200))
            aboutWindow?.styleMask = [.titled, .closable, .miniaturizable]
            aboutWindow?.title = "About Somnus"
        }
        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true) // Active l'application pour s'assurer que la fenêtre apparaît
    }
    
    // Fonction pour afficher la vue Settings
    func showSettings() {
        if settingsWindow == nil {
            let settingsView = NSHostingController(rootView: SettingsView(viewModel: self))
            settingsWindow = NSWindow(
                contentViewController: settingsView
            )
            settingsWindow?.setContentSize(NSSize(width: 400, height: 200))
            settingsWindow?.styleMask = [.titled, .closable, .miniaturizable]
            settingsWindow?.title = "Settings"
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true) // Active l'application pour s'assurer que la fenêtre apparaît
    }
}
