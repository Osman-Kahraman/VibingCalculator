//
//  LambdaService.swift
//  VibingCalculator
//
//  Created by Osman Kahraman on 2026-06-17.
//

import Foundation

struct LambdaService {
    static let invokeURL = ""

    static func calculate(
        expression: String,
        aiMode: Bool,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        guard let url = URL(string: invokeURL) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        let body: [String: Any] = [
            "expression": expression,
            "aiMode": aiMode
        ]

        request.httpBody =
            try? JSONSerialization.data(
                withJSONObject: body
            )

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -2)))

                return
            }

            if let raw = String(data: data, encoding: .utf8) {
                print("Lambda response:")
                print(raw)

                let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

                if let intResult = Int(trimmed) {
                    completion(.success(intResult))
                    return
                }

                if let doubleResult = Double(trimmed) {
                    completion(.success(Int(doubleResult)))
                    return
                }
            }

            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let body = json["body"] as? String else {
                    throw NSError(domain: "Parse error", code: -3)
                }

                let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)

                if let intResult = Int(trimmed) {
                    completion(.success(intResult))
                    return
                }

                if let doubleResult = Double(trimmed) {
                    completion(.success(Int(doubleResult)))
                    return
                }

                completion(.failure(NSError(domain: "Parse error", code: -3)))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
