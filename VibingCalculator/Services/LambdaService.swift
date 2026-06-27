//
//  LambdaService.swift
//  VibingCalculator
//
//  Created by Osman Kahraman on 2026-06-17.
//

import Foundation

struct LambdaService {
    static let invokeURL = "https://3gi6e1vzth.execute-api.us-east-2.amazonaws.com/dev/calculate"
    
    static func calculate(
        expression: String,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        guard let url = URL(string: invokeURL) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body: [String: Any] = ["expression": expression]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -2)))
                return
            }
            
            do {
                // JSON parse
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let body = json["body"] as? String,
                   let result = Int(body) {
                    completion(.success(result))
                    return
                } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let body = json["body"] as? Int {
                    completion(.success(body))
                    return
                } else if let resultString = String(data: data, encoding: .utf8),
                          let intResult = Int(resultString.trimmingCharacters(in: .whitespacesAndNewlines)) {

                    completion(.success(intResult))
                    return
                }
                completion(.failure(NSError(domain: "Parse error", code: -3)))
            }
        }.resume()
    }
}

