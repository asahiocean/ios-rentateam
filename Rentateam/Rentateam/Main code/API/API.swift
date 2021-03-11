import Foundation

protocol GETPOST {
    typealias ResultDataError = (Result<Data?,Error>) -> ()
    static func get(to urlStr: String, with completion: @escaping ResultDataError)
    static func post(to urlStr: String, with postbody: [String:Any], _ completion: ResultDataError?)
}

class API: GETPOST {
    
    private static var cache = URLCache(memoryCapacity: 100.mb, diskCapacity: 100.mb, diskPath: "unsplash")
    private static var cachePolicy: URLRequest.CachePolicy = .reloadIgnoringCacheData
    static weak var delegate: URLSessionDelegate?
    
    static func get(to urlStr: String, with completion: @escaping ResultDataError) {
        let url = URL(string: urlStr)!
        
        let urlSession: URLSession = {
            let config: URLSessionConfiguration = .ephemeral
            // config.multipathServiceType = .aggregate
            // config.networkServiceType = .default
            // config.waitsForConnectivity = false // Force don't wait for network recovery
            return .init(configuration: config)
        }()
        
        let request = NSMutableURLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: .zero)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Authorization":"Client-ID 2zEHm8DKHU65WYhql1K_Mcf_iIkLdRc41C21ybej3MU"]
        
        if let cached = cache.cachedResponse(for: request as URLRequest) {
            completion(.success(cached.data))
        } else {
            DispatchQueue(label: "api.get.queue", qos: .background, attributes: .concurrent).async {
                let task = urlSession.dataTask(with: request as URLRequest) { (data,response,error) in
                    if let error = error {
                        completion(.failure(error))
                    } else if let data = data {
                        if urlStr.contains("images.unsplash.com"), let response = response {
                            let cachedResponse = CachedURLResponse(response: response, data: data, storagePolicy: .allowed)
                            cache.storeCachedResponse(cachedResponse, for: request as URLRequest)
                        }
                        completion(.success(data))
                    }
                }
                task.priority = URLSessionTask.highPriority
                task.resume()
            }
        }
    }
    
    static func post(to urlStr: String, with postbody: [String: Any], _ completion: ResultDataError?) {
        
    }
}
