import UIKit
import WebImage

#if RELEASE
import Fabric
import Crashlytics
#endif

public class AppDelegate: UIResponder, UIApplicationDelegate {
    public var window: UIWindow?
    
    public func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions:
        [NSObject: AnyObject]?) -> Bool {

            #if RELEASE
                Fabric.with([Crashlytics.self()])
            #endif
            
            let defaultTheme = DefaultTheme()

            UITabBar.appearance().tintColor = defaultTheme.tabBarActiveTextColor()
            UINavigationBar.appearance().tintColor = defaultTheme.navigationBarTextColor()
            UIBarButtonItem.appearance().setTitleTextAttributes([
                NSFontAttributeName: defaultTheme.navigationBarFont(), NSForegroundColorAttributeName: defaultTheme.navigationBarTextColor()], forState: UIControlState.Normal)
            
            
            let mainQueue = NSOperationQueue.mainQueue()
            let sharedURLSession = NSURLSession.sharedSession()
            let analyticsService = ConcreteAnalyticsService()
            let stringContentSanitizer = ConcreteStringContentSanitizer()
            
            let urlProvider = ConcreteURLProvider()
            let urlOpener = URLOpener()
            let urlAttributionPresenter = ConcreteURLAttributionPresenter()
            
            let jsonSerializerProvider = NSJSONSerializationProvider()
            let jsonClient = ConcreteJSONClient(
                urlSession: sharedURLSession,
                jsonSerializationProvider: jsonSerializerProvider
            )
            
            let webImageManager = SDWebImageManager()
            let imageRepository = ConcreteImageRepository(webImageManager: webImageManager)
            
            let aboutController = AboutController(analyticsService: analyticsService, urlOpener: urlOpener, urlProvider: urlProvider, theme: defaultTheme)
            let feedbackController = FeedbackController(urlProvider: urlProvider, analyticsService: analyticsService)
            let privacyPolicyController = PrivacyPolicyController(urlProvider: urlProvider, analyticsService: analyticsService)
            let flossController = FLOSSController(analyticsService: analyticsService)
            let termsAndConditionsController = TermsAndConditionsController(analyticsService: analyticsService)
            let settingsController = SettingsController(
                tappableControllers: [aboutController, feedbackController, termsAndConditionsController, privacyPolicyController, flossController],
                analyticsService: analyticsService,
                theme: defaultTheme)
            
            let newsItemDeserializer = ConcreteNewsItemDeserializer(stringContentSanitizer: stringContentSanitizer)
            let newsItemRepository = ConcreteNewsItemRepository(
                urlProvider: urlProvider,
                jsonClient: jsonClient,
                newsItemDeserializer: newsItemDeserializer,
                operationQueue: mainQueue
            )
            let longDateFormatter = NSDateFormatter()
            longDateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
            let fullDateWithTimeFormatter = NSDateFormatter()
            fullDateWithTimeFormatter.dateFormat = "EEEE MMMM d, y h:mm a z"
            
            let newsItemControllerProvider = ConcreteNewsItemControllerProvider(
                dateFormatter: longDateFormatter, imageRepository: imageRepository, analyticsService: analyticsService, urlOpener: urlOpener, urlAttributionPresenter: urlAttributionPresenter, theme: defaultTheme
            )
            
            let newsFeedController = NewsFeedController(
                newsItemRepository: newsItemRepository,
                imageRepository: imageRepository,
                dateFormatter: longDateFormatter,
                newsItemControllerProvider: newsItemControllerProvider,
                settingsController: settingsController,
                analyticsService: analyticsService,
                theme: defaultTheme
            )
            
            let newsNavigationController = NavigationController(theme: defaultTheme)
            newsNavigationController.pushViewController(newsFeedController, animated: false)
            let issueDeserializer = ConcreteIssueDeserializer(stringContentSanitizer: stringContentSanitizer)
            
            let issueRepository = ConcreteIssueRepository(
                urlProvider: urlProvider,
                jsonClient: jsonClient,
                issueDeserializer: issueDeserializer,
                operationQueue: mainQueue
            )
            
            let issueControllerProvider = ConcreteIssueControllerProvider(imageRepository: imageRepository,
                analyticsService: analyticsService,
                urlOpener: urlOpener,
                urlAttributionPresenter: urlAttributionPresenter,
                theme: defaultTheme)
            
            let issuesTableController = IssuesController(
                issueRepository: issueRepository,
                issueControllerProvider: issueControllerProvider,
                settingsController: settingsController,
                analyticsService: analyticsService,
                theme: defaultTheme
            )
            let issuesNavigationController = NavigationController(theme: defaultTheme)
            issuesNavigationController.pushViewController(issuesTableController, animated: false)
            
            let organizeController = OrganizeController(urlProvider: urlProvider,
                theme: defaultTheme)
            
            let eventDeserializer = ConcreteEventDeserializer()
            let eventRepository = ConcreteEventRepository(
                geocoder: CLGeocoder(),
                urlProvider: urlProvider,
                jsonClient: jsonClient,
                eventDeserializer: eventDeserializer,
                operationQueue: mainQueue)
            let eventPresenter = EventPresenter(dateFormatter: fullDateWithTimeFormatter)
            let eventRSVPControllerProvider = ConcreteEventRSVPControllerProvider(analyticsService: analyticsService, theme: defaultTheme)
            let eventControllerProvider = ConcreteEventControllerProvider(
                eventPresenter: eventPresenter,
                eventRSVPControllerProvider: eventRSVPControllerProvider,
                urlProvider: urlProvider,
                urlOpener: urlOpener,
                analyticsService: analyticsService,
                theme: defaultTheme)
            let eventsController = EventsController(
                eventRepository: eventRepository,
                eventPresenter: eventPresenter,
                settingsController: settingsController,
                eventControllerProvider: eventControllerProvider,
                analyticsService: analyticsService,
                theme: defaultTheme
            )
            let eventsNavigationController = NavigationController(theme: defaultTheme)
            eventsNavigationController.pushViewController(eventsController, animated: false)
            
            let tabBarViewControllers = [
                newsNavigationController,
                issuesNavigationController,
                eventsNavigationController,
                organizeController
            ]
            let tabBarController = TabBarController(viewControllers: tabBarViewControllers, analyticsService: analyticsService, theme: defaultTheme)
            
            let termsAndConditionsAgreementRepository = ConcreteTermsAndConditionsAgreementRepository(
                userDefaults: NSUserDefaults.standardUserDefaults())
            let welcomeController = WelcomeController(
                termsAndConditionsAgreementRepository: termsAndConditionsAgreementRepository,
                termsAndConditionsController: termsAndConditionsController,
                privacyPolicyController: privacyPolicyController,
                analyticsService: analyticsService,
                theme: defaultTheme)
            let welcomeNavigationController = NavigationController(theme: defaultTheme)
            welcomeNavigationController.pushViewController(welcomeController, animated: false)
            
            let onboardingRouter = OnboardingRouter(
                termsAndConditionsAgreementRepository: termsAndConditionsAgreementRepository,
                onboardingController: welcomeNavigationController,
                postOnboardingController: tabBarController)
            
            welcomeController.onboardingRouter = onboardingRouter
            
            onboardingRouter.initialViewController { (controller) -> Void in
                self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
                self.window!.rootViewController = controller
                self.window!.backgroundColor = defaultTheme.defaultBackgroundColor()
                self.window!.makeKeyAndVisible()
            }
            
            
            return true
    }
}

