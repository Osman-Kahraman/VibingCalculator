import Foundation
import SwiftUI
import Combine

@MainActor
final class CalculatorViewModel: ObservableObject {
    @Published var isAIMode = false
    @Published var expression: String = ""
    @Published var resultText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showResultPopup: Bool = false
    @Published var shouldAnimateDisplayTransition = true
    @Published var fadingExpression: String?

    @Published private(set) var isContinuingFromResult = false
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
    
    private func performLambdaCalculation() async {
        await withCheckedContinuation { continuation in
            LambdaService.calculate(
                expression: self.expression,
                aiMode: false
            ) { result in
                DispatchQueue.main.async {
                    Task { @MainActor in
                        self.handleCalculationResult(result)
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    private func performAICalculation() async {
        await withCheckedContinuation { continuation in
            LambdaService.calculate(
                expression: self.expression,
                aiMode: true
            ) { result in
                DispatchQueue.main.async {
                    Task { @MainActor in
                        self.handleCalculationResult(result)
                        continuation.resume()
                    }
                }
            }
        }
    }

    private func handleCalculationResult(_ result: Result<Int, Error>) {
        switch result {
        case .success(let value):
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                if self.expressionHistory.last != self.expression {
                    self.expressionHistory.append(self.expression)
                }
            }

            self.shouldAnimateDisplayTransition = true
            self.resultText = "\(value)"
            self.isContinuingFromResult = false
            self.showResultPopup = true

            Task {
                try? await Task.sleep(for: .seconds(0.5))
                self.showResultPopup = false
            }

        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }
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

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if isAIMode {
            await performAICalculation()
        } else {
            await performLambdaCalculation()
        }
    }
}
