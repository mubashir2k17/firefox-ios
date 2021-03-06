/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let websiteUrl1 = "www.mozilla.org"
let websiteUrl2 = "developer.mozilla.org"
let invalidUrl = "1-2-3"
let exampleUrl = "test-example.html"

class HomePageSettingsUITests: BaseTestCase {
    private func enterWebPageAsHomepage(text: String) {
        app.textFields["HomePageSettingTextField"].tap()
        app.textFields["HomePageSettingTextField"].typeText(text)
        let value = app.textFields["HomePageSettingTextField"].value
        XCTAssertEqual(value as? String, text, "The webpage typed does not match with the one saved")
    }
    let testWithDB = ["testTopSitesCustomNumberOfRows"]
    let prefilledTopSites = "testBookmarksDatabase1000-browser.db"
    
    override func setUp() {
        // Test name looks like: "[Class testFunc]", parse out the function name
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let key = String(parts[1])
        if testWithDB.contains(key) {
            // for the current test name, add the db fixture used
            launchArguments = [LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, LaunchArguments.LoadDatabasePrefix + prefilledTopSites]
        }
        super.setUp()
    }
    func testCheckHomeSettingsByDefault() {
        navigator.goto(HomeSettings)
        XCTAssertTrue(app.tables.cells["Firefox Home"].exists)
        XCTAssertTrue(app.tables.cells["Bookmarks"].exists)
        XCTAssertTrue(app.tables.cells["History"].exists)
        XCTAssertTrue(app.tables.cells["HomePageSetting"].exists)
        waitForExistence(app.tables.cells["TopSitesRows"])
        XCTAssertEqual(app.tables.cells["TopSitesRows"].label as String, "Top Sites, Rows: 2")
        XCTAssertTrue(app.tables.switches["ASPocketStoriesVisible"].isEnabled)
    }

    func testTyping() {
        navigator.goto(HomeSettings)
        // Enter a webpage
        enterWebPageAsHomepage(text: websiteUrl1)

        // Check if it is saved going back and then again to home settings menu
        navigator.goto(SettingsScreen)
        navigator.goto(HomeSettings)
        let valueAfter = app.textFields["HomePageSettingTextField"].value
        XCTAssertEqual(valueAfter as? String, "http://\(websiteUrl1)")

        // Check that it is actually set by opening a different website and going to Home
        navigator.openURL(websiteUrl2)
        navigator.goto(BrowserTabMenu)

        //Now check open home page should load the previously saved home page
        let homePageMenuItem = app.cells["menu-Home"]
        waitForExistence(homePageMenuItem)
        homePageMenuItem.tap()
        waitForValueContains(app.textFields["url"], value: websiteUrl1)
    }

    /* Test disabled until bug 1510243 is fixed
    func testTypingBadURL() {
        waitForExistence(app.buttons["TabToolbar.menuButton"], timeout: 5)
        navigator.goto(HomeSettings)
        // Enter an invalid Url
        enterWebPageAsHomepage(text: invalidUrl)
        navigator.goto(SettingsScreen)
        // Check that it is not saved
        navigator.goto(HomeSettings)
        waitForExistence(app.textFields["HomePageSettingTextField"])
        let valueAfter = app.textFields["HomePageSettingTextField"].value
        XCTAssertEqual("Enter a webpage", valueAfter as! String)

        // There is no option to go to Home, instead the website open has the option to be set as HomePageSettings
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForExistence(app.buttons["TabToolbar.menuButton"], timeout: 5)
        navigator.goto(BrowserTabMenu)
        let homePageMenuItem = app.tables["Context Menu"].cells["Open Homepage"]
        XCTAssertFalse(homePageMenuItem.exists)
    }*/

    func testClipboard() {
        // Check that what's in clipboard is copied
        UIPasteboard.general.string = websiteUrl1
        navigator.goto(HomeSettings)
        app.textFields["HomePageSettingTextField"].tap()
        app.textFields["HomePageSettingTextField"].press(forDuration: 3)
        print(app.debugDescription)
        waitForExistence(app.menuItems["Paste"])
        app.menuItems["Paste"].tap()
        waitForValueContains(app.textFields["HomePageSettingTextField"], value: "mozilla")
        // Check that the webpage has been correclty copied into the correct field
        let value = app.textFields["HomePageSettingTextField"].value as! String
        XCTAssertEqual(value, websiteUrl1)
    }

    // Test disabled until bug 1510243 is fixed/clarified
    /*
    func testDisabledClipboard() {
        // Type an incorrect URL and copy it
        navigator.goto(URLBarOpen)
        app.textFields["address"].typeText(invalidUrl)
        app.textFields["address"].press(forDuration: 5)
        app.menuItems["Select All"].tap()
        app.menuItems["Copy"].tap()
        waitForExistence(app.buttons["goBack"])
        app.buttons["goBack"].tap()

        // Go to HomePage settings and check that it is not possible to copy it into the set webpage field
        navigator.nowAt(BrowserTab)
        navigator.goto(HomeSettings)
        waitForExistence(app.staticTexts["Use Copied Link"])

        // Check that nothing is copied in the Set webpage field
        app.cells["Use Copied Link"].tap()
        let value = app.textFields["HomePageSettingTextField"].value

        XCTAssertEqual("Enter a webpage", value as! String)
    }*/

    func testSetCustomURLAsHome() {
        navigator.goto(HomeSettings)
        // Enter a webpage
        enterWebPageAsHomepage(text: websiteUrl1)

        // Open a new tab and tap on Home option
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForTabsButton()
        navigator.performAction(Action.GoToHomePage)
        waitForExistence(app.textFields["url"], timeout: 5)
        waitForValueContains(app.textFields["url"], value: "mozilla")
    }

    func testSetBookmarksAsHome() {
        waitForTabsButton()
        navigator.performAction(Action.SelectHomeAsBookmarksPage)
        // Go to home to check that the changes are done, no bookmarks
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForTabsButton()
        navigator.performAction(Action.GoToHomePage)
        waitForExistence(app.tables["Bookmarks List"], timeout: 3)
        // There are no bookmarks in the list
        XCTAssertEqual(app.tables["Bookmarks List"].cells.count, 0)
        // Go to home to check that the changes are done, one bookmark
        navigator.openURL(path(forTestPage: exampleUrl))
        waitUntilPageLoad()
        navigator.performAction(Action.BookmarkThreeDots)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForTabsButton()
        navigator.performAction(Action.GoToHomePage)
        waitForExistence(app.tables["Bookmarks List"], timeout: 3)
        // There is one bookmark in the list
        XCTAssertEqual(app.tables["Bookmarks List"].cells.count, 1)
    }

    func testSetHistoryAsHome() {
        waitForTabsButton()
        navigator.performAction(Action.SelectHomeAsHistoryPage)
        // Open new tab to check the changes are done
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForTabsButton()
        navigator.performAction(Action.GoToHomePage)
        waitForExistence(app.tables["History List"], timeout: 3)
        // There are three cells for, clear recent history, recently closed and sync, no entries
        XCTAssertEqual(app.tables["History List"].cells.count, 3)
        // Go to home to check that the changes are done, one history
        // Using local server does not work here, the item is not displayed
        navigator.openURL("www.example.com")
        waitUntilPageLoad()
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForTabsButton()
        navigator.performAction(Action.GoToHomePage)
        waitForExistence(app.tables["History List"], timeout: 3)
        // There is one entry
        XCTAssertEqual(app.tables["History List"].cells.count, 4)
    }
    
    func testTopSitesCustomNumberOfRows() {
        var topSitesPerRow:Int
        //Ensure testing in portrait mode
        XCUIDevice.shared.orientation = .portrait
        //Run test for both iPhone and iPad devices as behavior differs between the two
        if iPad() {
            // On iPad, 6 top sites per row are displayed
            topSitesPerRow = 6
            //Test each of the custom row options from 1-4
            for n in 1...4 {
                userState.numTopSitesRows = n
                navigator.performAction(Action.SelectTopSitesRows)
                XCTAssertEqual(app.tables.cells["TopSitesRows"].label as String, "Top Sites, Rows: " + String(n))
                navigator.performAction(Action.GoToHomePage)
                checkNumberOfExpectedTopSites(numberOfExpectedTopSites: (n * topSitesPerRow))
            }
        } else {
            // On iPhone, 4 top sites per row are displayed
            topSitesPerRow = 4
            //Test each of the custom row options from 1-4
            for n in 1...4 {
                userState.numTopSitesRows = n
                navigator.performAction(Action.SelectTopSitesRows)
                XCTAssertEqual(app.tables.cells["TopSitesRows"].label as String, "Top Sites, Rows: " + String(n))
                navigator.performAction(Action.GoToHomePage)
                checkNumberOfExpectedTopSites(numberOfExpectedTopSites: (n * topSitesPerRow))
            }
        }
    }
    //Function to check the number of top sites shown given a selected number of rows
    private func checkNumberOfExpectedTopSites(numberOfExpectedTopSites: Int) {
        waitForExistence(app.cells["TopSitesCell"])
        XCTAssertTrue(app.cells["TopSitesCell"].exists)
        let numberOfTopSites = app.collectionViews.cells["TopSitesCell"].cells.matching(identifier: "TopSite").count
        XCTAssertEqual(numberOfTopSites, numberOfExpectedTopSites)
    }
}
