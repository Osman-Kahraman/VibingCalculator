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
    private var expressionBeforeContinuingFromResult = ""
    private let endpoint = URL(string: "...")!

    var displayExpression: String {
        if !resultText.isEmpty && isContinuingFromResult {
            return expressionBeforeContinuingFromResult.isEmpty ? "0" : expressionBeforeContinuingFromResult
        }

        return expression.isEmpty ? "0" : expression
    }

    var displayResultText: String {
        guard isContinuingFromResult else {
            return resultText
        }

        return formattedExpression(expression)
    }

    func append(_ text: String) {
        errorMessage = nil

        if !resultText.isEmpty {
            if isOperator(text) {
                if !isContinuingFromResult {
                    expressionBeforeContinuingFromResult = expression
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
            expressionBeforeContinuingFromResult = ""
            showResultPopup = false
            return
        }

        expression.append(text)
    }

    private func isOperator(_ text: String) -> Bool {
        ["/", "*", "-", "+"].contains(text)
    }

    private func formattedExpression(_ expression: String) -> String {
        expression.reduce(into: "") { formatted, character in
            let text = String(character)

            if isOperator(text) {
                formatted += " \(text) "
            } else {
                formatted += text
            }
        }
        .trimmingCharacters(in: .whitespaces)
    }

    func clear() {
        expression = ""
        resultText = ""
        errorMessage = nil
        isContinuingFromResult = false
        expressionBeforeContinuingFromResult = ""
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
        expressionBeforeContinuingFromResult = ""
        fadingExpression = nil
    }

    func calculate() async {
        guard !expression.isEmpty else { return }

        if isContinuingFromResult {
            shouldAnimateDisplayTransition = false
            fadingExpression = expressionBeforeContinuingFromResult.isEmpty ? nil : expressionBeforeContinuingFromResult
            resultText = ""
            isContinuingFromResult = false
            expressionBeforeContinuingFromResult = ""
            showResultPopup = false
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(280))
                self.fadingExpression = nil
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
                            try? await Task.sleep(for: .seconds(1))
                            self.shouldAnimateDisplayTransition = true
                            self.resultText = "\(value)"
                            self.isContinuingFromResult = false
                            self.expressionBeforeContinuingFromResult = ""
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
