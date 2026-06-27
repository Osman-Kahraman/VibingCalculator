import Foundation
import SwiftUI
import Combine

@MainActor
final class CalculatorViewModel: ObservableObject {
    @Published var expression: String = ""
    @Published var resultText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showResultPopup: Bool = false
    @Published var shouldAnimateDisplayTransition = true
    @Published var fadingExpression: String?

    private var isContinuingFromResult = false
    @Published var expressionHistory: [String] = []

    private var lastExpressionBeforeContinuing: String? {
        expressionHistory.last
    }

    var displayExpression: String {
        if !resultText.isEmpty && isContinuingFromResult {
            if let last = lastExpressionBeforeContinuing, !last.isEmpty {
                return last
            } else {
                return "0"
            }
        }

        return expression.isEmpty ? "0" : expression
    }

    var displayResultText: String {
        isContinuingFromResult ? expression : resultText
    }

    func append(_ text: String) {
        errorMessage = nil

        if !resultText.isEmpty {
            if isOperator(text) {
                if !isContinuingFromResult {
                    expression = resultText + text
                } else if let lastCharacter = expression.last, isOperator(String(lastCharacter)) {
                    expression.removeLast()
                    expression.append(text)
                } else {
                    expression.append(text)
                }

                isContinuingFromResult = true
                showResultPopup = false
                return
            }

            if isContinuingFromResult {
                expression.append(text == "." ? "0." : text)
                showResultPopup = false
                return
            }

            expression = text == "." ? "0." : text
            resultText = ""
            // Preserve history when starting a new number
            showResultPopup = false
            return
        }

        expression.append(text)
    }

    private func isOperator(_ text: String) -> Bool {
        ["/", "*", "-", "+"].contains(text)
    }

    func clear() {
        expression = ""
        resultText = ""
        errorMessage = nil
        isContinuingFromResult = false
        expressionHistory.removeAll()
        fadingExpression = nil
    }

    func backspace() {
        if !resultText.isEmpty {
            resultText = ""
            showResultPopup = false
        }

        guard !expression.isEmpty else { return }
        expression.removeLast()
        isContinuingFromResult = false
        // Keep history on backspace
        fadingExpression = nil
    }

    func calculate() async {
        guard !expression.isEmpty else { return }

        if isContinuingFromResult {
            shouldAnimateDisplayTransition = false
            if let last = lastExpressionBeforeContinuing, !last.isEmpty {
                fadingExpression = last
            } else {
                fadingExpression = nil
            }
            resultText = ""
            isContinuingFromResult = false
            // Preserve history when continuing from result
            showResultPopup = false
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(280))
                self.fadingExpression = nil
            }
        }

        if !expression.isEmpty {
            if expressionHistory.last != expression {
                expressionHistory.append(expression)
            }
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        await withCheckedContinuation { continuation in
            LambdaService.calculate(expression: self.expression) { result in
                DispatchQueue.main.async {
                    Task { @MainActor in
                        switch result {
                        case .success(let value):
                            self.shouldAnimateDisplayTransition = true
                            self.resultText = "\(value)"
                            self.isContinuingFromResult = false
                            // Preserve history on success
                            self.showResultPopup = true
                            Task { @MainActor in
                                try? await Task.sleep(for: .seconds(0.5))
                                self.showResultPopup = false
                            }
                        case .failure(let error):
                            self.errorMessage = "Something went wrong: \(error.localizedDescription)"
                            self.showResultPopup = false
                        }
                        continuation.resume()
                    }
                }
            }
        }
    }
}

