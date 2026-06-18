import SwiftUI

struct CalculatorView: View {
    @StateObject private var vm = CalculatorViewModel()

    private let rows: [[String]] = [
        ["7", "8", "9", "/"],
        ["4", "5", "6", "*"],
        ["1", "2", "3", "-"],
        ["0", ".", "=", "+"]
    ]

    private var hasResult: Bool {
        !vm.resultText.isEmpty
    }

    private var displayExpression: String {
        vm.displayExpression
    }

    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    Text(displayExpression)
                        .font(.system(size: hasResult ? 24 : 56, weight: hasResult ? .semibold : .bold, design: .rounded))
                        .foregroundStyle(hasResult ? .secondary : (vm.expression.isEmpty ? .secondary : .primary))
                        .opacity(vm.expression.isEmpty && !hasResult ? 0.35 : 1)
                        .lineLimit(1)
                        .minimumScaleFactor(hasResult ? 0.5 : 0.45)
                        .offset(y: hasResult ? -68 : 0)

                    if hasResult {
                        Text(vm.displayResultText)
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.45)
                            .transition(.opacity)
                    }

                    if let fadingExpression = vm.fadingExpression {
                        Text(fadingExpression)
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .offset(y: -68)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 132, alignment: .bottomTrailing)
                .padding(.top)
                .animation(
                    vm.shouldAnimateDisplayTransition ? .spring(response: 0.45, dampingFraction: 0.82) : nil,
                    value: hasResult
                )
                .animation(.easeOut(duration: 0.25), value: vm.fadingExpression)

                if vm.isLoading {
                    ProgressView("Calculating on AWS...")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                if let error = vm.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .font(.footnote)
                }
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    CalculatorButton(title: "C") { vm.clear() }
                    CalculatorButton(title: "⌫") { vm.backspace() }
                }

                ForEach(rows, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(row, id: \.self) { key in
                            CalculatorButton(title: key) {
                                if key == "=" {
                                    Task { await vm.calculate() }
                                } else {
                                    vm.append(key)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

#Preview {
    NavigationStack { CalculatorView() }
}
