//
//  PhotoProvider.swift
//  Test
//
//  Created by Danil Otmakhov on 26.02.2025.
//

import UIKit

/// Класс для загрузки отзывов.
final class PhotoProvider {
    
    static let shared = PhotoProvider()
    
    private init() {}
    
}

// MARK: - Internal

extension PhotoProvider {
    
    typealias GetPhotoResult = Result<UIImage, GetPhotoError>
    
    enum GetPhotoError: Error {
        
        case invalidURL
        case missingData
        case httpStatusCode
        case urlSessionError
        case urlRequestError(Error)
        
    }
    
    func getPhoto(from urlString: String, completion: @escaping (GetPhotoResult) -> Void) {
        let completeOnTheMainThread: (GetPhotoResult) -> Void = { result in
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
        
        DispatchQueue.global(qos: .background).async { [completeOnTheMainThread] in
            if let cachedResponse = URLCache.shared.cachedResponse(for: request),
               let image = UIImage(data: cachedResponse.data) {
                completeOnTheMainThread(.success(image))
                return
            }
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data, let response, let statusCode = (response as? HTTPURLResponse)?.statusCode {
                if 200 ..< 300 ~= statusCode {
                    guard let image = UIImage(data: data) else {
                        completeOnTheMainThread(.failure(.missingData))
                        return
                    }
                    
                    let cachedResponse = CachedURLResponse(response: response, data: data)
                    URLCache.shared.storeCachedResponse(cachedResponse, for: request)
                    
                    completeOnTheMainThread(.success(image))
                } else {
                    completeOnTheMainThread(.failure(.httpStatusCode))
                }
            } else if let error = error {
                completeOnTheMainThread(.failure(.urlRequestError(error)))
            } else {
                completeOnTheMainThread(.failure(.urlSessionError))
            }
        }.resume()
    }
    
}
