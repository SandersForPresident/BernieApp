import Foundation
import BrightFutures

class ConcreteNewsArticleRepository: NewsArticleRepository {
    private let urlProvider: URLProvider
    private let jsonClient: JSONClient
    private let newsArticleDeserializer: NewsArticleDeserializer
    private let operationQueue: NSOperationQueue

    init(
        urlProvider: URLProvider,
        jsonClient: JSONClient,
        newsArticleDeserializer: NewsArticleDeserializer,
        operationQueue: NSOperationQueue) {
            self.urlProvider = urlProvider
            self.jsonClient = jsonClient
            self.newsArticleDeserializer = newsArticleDeserializer
            self.operationQueue = operationQueue
    }

    func fetchNewsArticles() -> Future<Array<NewsArticle>, NSError> {
        let promise = Promise<Array<NewsArticle>, NSError>()

        let newsFeedJSONPromise = self.jsonClient.JSONPromiseWithURL(self.urlProvider.newsFeedURL(), method: "POST", bodyDictionary: self.HTTPBodyDictionary())

        newsFeedJSONPromise.then({ (deserializedObject) -> AnyObject! in
            let jsonDictionary = deserializedObject as? NSDictionary
            if jsonDictionary == nil {
                let incorrectObjectTypeError = NSError(domain: "ConcreteNewsArticleRepository", code: -1, userInfo: nil)
                self.operationQueue.addOperationWithBlock({ () -> Void in
                    promise.failure(incorrectObjectTypeError)
                })
                return incorrectObjectTypeError
            }


            let parsedNewsArticles = self.newsArticleDeserializer.deserializeNewsArticles(jsonDictionary!)

            self.operationQueue.addOperationWithBlock({ () -> Void in
                promise.success(parsedNewsArticles as [NewsArticle])
            })

            return parsedNewsArticles
            }, error: { (receivedError) -> AnyObject! in
                self.operationQueue.addOperationWithBlock({ () -> Void in
                    promise.failure(receivedError!)
                })
                return receivedError
        })

        return promise.future
    }

    // MARK: Private

    func HTTPBodyDictionary() -> NSDictionary {
        return [
            "from": 0, "size": 30,
            "_source": ["title", "body", "excerpt", "created_at", "url", "image_url"],
            "query": [
                "query_string": [
                    "default_field": "article_type",
                    "query": "NOT ExternalLink OR NOT Issues"
                ]
            ],
            "sort": [
                "created_at": ["order": "desc"]
            ]
        ]
    }
}
