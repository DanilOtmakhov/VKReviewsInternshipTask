//
//  PhotoProvider.swift
//  Test
//
//  Created by Danil Otmakhov on 26.02.2025.
//

import UIKit

/// Класс для загрузки отзывов.
final class ImageProvider {
    
    static let shared = ImageProvider()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    
    private init() {}
    
}

// MARK: - Internal

extension ImageProvider {
    
    typealias FetchImageResult = Result<UIImage, FetchImageError>
    
    enum FetchImageError: Error {
        
        case invalidURL
        case missingData
        case httpStatusCode
        case urlSessionError
        case urlRequestError(Error)
        
    }
    
    func fetchImage(from urlString: String, completion: @escaping (FetchImageResult) -> Void) {
        let completeOnTheMainThread: (FetchImageResult) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        
        guard
            let url = URL(string: urlString)
        else {
            completeOnTheMainThread(.failure(.invalidURL))
            return
        }
        
        let request = URLRequest(url: url)
        
        if let cachedImage = memoryCache.object(forKey: urlString as NSString) {
            completeOnTheMainThread(.success(cachedImage))
            return
        }
        
        if let cachedResponse = URLCache.shared.cachedResponse(for: request),
           let image = UIImage(data: cachedResponse.data) {
            memoryCache.setObject(image, forKey: urlString as NSString)
            completeOnTheMainThread(.success(image))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let data, let response, let statusCode = (response as? HTTPURLResponse)?.statusCode {
                if 200 ..< 300 ~= statusCode {
                    guard let image = UIImage(data: data) else {
                        completeOnTheMainThread(.failure(.missingData))
                        return
                    }
                    
                    let cachedResponse = CachedURLResponse(response: response, data: data)
                    URLCache.shared.storeCachedResponse(cachedResponse, for: request)
                    self?.memoryCache.setObject(image, forKey: urlString as NSString)
                    
                    completeOnTheMainThread(.success(image))
                } else {
                    completeOnTheMainThread(.failure(.httpStatusCode))
                }
            } else if let error = error {
                completeOnTheMainThread(.failure(.urlRequestError(error)))
            } else {
                completeOnTheMainThread(.failure(.urlSessionError))
            }
        }
        task.resume()
    }
    
}
