import UIKit

protocol EditAddressSearchBarControllerDelegate {
    func editAddressSearchBarControllerDidCancel(controller: EditAddressSearchBarController)
}

class EditAddressSearchBarController: UIViewController {
    private let nearbyEventsUseCase: NearbyEventsUseCase
    private let eventsNearAddressUseCase: EventsNearAddressUseCase!
    private let zipCodeValidator: ZipCodeValidator
    private let searchBarStylist: SearchBarStylist
    private let resultQueue: NSOperationQueue
    private let workerQueue: NSOperationQueue
    private let theme: Theme

    let searchBar = UISearchBar.newAutoLayoutView()
    let searchButton = UIButton.newAutoLayoutView()
    let cancelButton = UIButton.newAutoLayoutView()

    var delegate: EditAddressSearchBarControllerDelegate?

    private var currentSearchText = ""

    init(
        nearbyEventsUseCase: NearbyEventsUseCase,
        eventsNearAddressUseCase: EventsNearAddressUseCase,
        zipCodeValidator: ZipCodeValidator,
        searchBarStylist: SearchBarStylist,
        resultQueue: NSOperationQueue,
        workerQueue: NSOperationQueue,
        theme: Theme
        ) {
            self.nearbyEventsUseCase = nearbyEventsUseCase
            self.eventsNearAddressUseCase = eventsNearAddressUseCase
            self.zipCodeValidator = zipCodeValidator
            self.searchBarStylist = searchBarStylist
            self.resultQueue = resultQueue
            self.workerQueue = workerQueue
            self.theme = theme

            super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        view.clipsToBounds = true
        view.addSubview(searchBar)
        view.addSubview(searchButton)
        view.addSubview(cancelButton)

        cancelButton.setTitle(NSLocalizedString("EventsSearchBar_cancelButtonTitle", comment: ""), forState: .Normal)
        cancelButton.addTarget(self, action: "didTapCancelButton", forControlEvents: .TouchUpInside)

        searchButton.setTitle(NSLocalizedString("EventsSearchBar_searchButtonTitle", comment: ""), forState: .Normal)
        searchButton.addTarget("self", action: "didTapSearchButton", forControlEvents: .TouchUpInside)
        searchButton.enabled = false

        searchBarStylist.applyThemeToBackground(view)
        searchBarStylist.applyThemeToSearchBar(searchBar)

        searchBar.delegate = self
        searchBar.placeholder = NSLocalizedString("EventsSearchBar_searchBarPlaceholder",  comment: "")
        searchBar.accessibilityLabel = NSLocalizedString("EventsSearchBar_searchBarAccessibilityLabel",  comment: "")
        searchBar.keyboardType = .NumberPad

        nearbyEventsUseCase.addObserver(self)
        eventsNearAddressUseCase.addObserver(self)

        setupConstraints()
        applyTheme()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        searchBar.becomeFirstResponder()
    }

    private func setupConstraints() {
        let buttonWidth: CGFloat = 60
        let verticalShift: CGFloat = 8
        let horizontalPadding: CGFloat = 15
        let searchBarHeight: CGFloat = 34

        cancelButton.autoPinEdgeToSuperviewEdge(.Left, withInset: horizontalPadding)
        cancelButton.autoAlignAxis(.Horizontal, toSameAxisOfView: searchBar, withOffset: verticalShift)
        cancelButton.autoSetDimension(.Width, toSize: buttonWidth)

        searchButton.autoPinEdgeToSuperviewEdge(.Right, withInset: horizontalPadding)
        searchButton.autoAlignAxis(.Horizontal, toSameAxisOfView: searchBar, withOffset: verticalShift)
        searchButton.autoSetDimension(.Width, toSize: buttonWidth)

        searchBar.autoAlignAxis(.Horizontal, toSameAxisOfView: view)
        self.searchButton.autoPinEdge(.Left, toEdge: .Right, ofView: self.searchBar, withOffset: -horizontalPadding)
        self.cancelButton.autoPinEdge(.Right, toEdge: .Left, ofView: self.searchBar, withOffset: -horizontalPadding)

        if let searchBarContainer = searchBar.subviews.first {
            searchBarContainer.autoAlignAxis(.Horizontal, toSameAxisOfView: self.searchBar, withOffset: verticalShift)
            searchBarContainer.autoPinEdgeToSuperviewEdge(.Left, withInset: horizontalPadding)
            searchBarContainer.autoPinEdgeToSuperviewEdge(.Right, withInset: horizontalPadding)
            searchBarContainer.autoSetDimension(.Height, toSize: searchBarHeight)
        }
        if let textField = searchBar.valueForKey("searchField") as? UITextField {
            textField.autoAlignAxis(.Horizontal, toSameAxisOfView: self.searchBar, withOffset: verticalShift)
            textField.autoPinEdgeToSuperviewEdge(.Left, withInset: horizontalPadding)
            textField.autoPinEdgeToSuperviewEdge(.Right, withInset: horizontalPadding)

            textField.autoSetDimension(.Height, toSize: searchBarHeight)
        }

        if let background = searchBar.valueForKey("background") as? UIView {
            background.autoAlignAxis(.Horizontal, toSameAxisOfView: self.searchBar, withOffset: verticalShift)
            background.autoPinEdgeToSuperviewEdge(.Left)
            background.autoPinEdgeToSuperviewEdge(.Right)
            background.autoSetDimension(.Height, toSize: searchBarHeight)
        }
    }

    private func applyTheme() {
        searchButton.setTitleColor(theme.defaultButtonDisabledTextColor(), forState: .Disabled)
        searchButton.setTitleColor(theme.navigationBarButtonTextColor(), forState: .Normal)
        searchButton.titleLabel!.font = self.theme.eventsSearchBarFont()

        cancelButton.setTitleColor(theme.defaultButtonDisabledTextColor(), forState: .Disabled)
        cancelButton.setTitleColor(theme.navigationBarButtonTextColor(), forState: .Normal)
        cancelButton.titleLabel!.font = self.theme.eventsSearchBarFont()
    }
}

// MARK: Actions

extension EditAddressSearchBarController {
    func didTapCancelButton() {
        searchBar.text = currentSearchText
        delegate?.editAddressSearchBarControllerDidCancel(self)
    }

    func didTapSearchButton() {
        workerQueue.addOperationWithBlock {
            self.eventsNearAddressUseCase.fetchEventsNearAddress(self.searchBar.text!, radiusMiles: 10.0)
        }
    }
}

// MARK: NearbyEventsUseCaseObserver
extension EditAddressSearchBarController: NearbyEventsUseCaseObserver {
    func nearbyEventsUseCase(useCase: NearbyEventsUseCase, didFailFetchEvents: NearbyEventsUseCaseError) {

    }

    func nearbyEventsUseCase(useCase: NearbyEventsUseCase, didFetchEventSearchResult: EventSearchResult) {

    }

    func nearbyEventsUseCaseDidStartFetchingEvents(useCase: NearbyEventsUseCase) {
        resultQueue.addOperationWithBlock {
            self.currentSearchText = ""
            self.searchBar.text = ""
            self.searchButton.enabled = false
        }
    }

    func nearbyEventsUseCaseFoundNoNearbyEvents(useCase: NearbyEventsUseCase) {

    }
}

// MARK: EventsNearAddressUseCaseObserver
extension EditAddressSearchBarController: EventsNearAddressUseCaseObserver {
    func eventsNearAddressUseCase(useCase: EventsNearAddressUseCase, didFailFetchEvents error: EventsNearAddressUseCaseError, address: Address) {

    }

    func eventsNearAddressUseCase(useCase: EventsNearAddressUseCase, didFetchEventSearchResult eventSearchResult: EventSearchResult, address: Address) {

    }

    func eventsNearAddressUseCaseDidStartFetchingEvents(useCase: EventsNearAddressUseCase, address: Address) {
        resultQueue.addOperationWithBlock {
            self.currentSearchText = address
            self.searchBar.text = address
        }
    }

    func eventsNearAddressUseCaseFoundNoEvents(useCase: EventsNearAddressUseCase, address: Address) {

    }
}

// MARK: UISearchBarDelegate
extension EditAddressSearchBarController: UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        let updatedZipCode = (searchBar.text! as NSString).stringByReplacingCharactersInRange(range, withString: text)

        if updatedZipCode.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) < 6 {
            searchButton.enabled = zipCodeValidator.validate(updatedZipCode)
        }

        return updatedZipCode.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) <= 5
    }
}
