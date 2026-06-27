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
        VStack() {
            Spacer()
            
            VStack() {
                ZStack(alignment: .bottomTrailing) {
                    VStack(alignment: .trailing, spacing: 6) {
                        // 1) History: oldest at top, newest at bottom
                        ForEach(vm.expressionHistory.dropLast(), id: \.self) { item in
                            Text(item)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // 2) Current small expression (only when there is a result, so it appears above the big result)
                        if hasResult {
                            Text(displayExpression)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .transition(.opacity)
                        }

                        // 3) Big result or big expression (newest at the bottom)
                        Group {
                            if hasResult {
                                Text(vm.displayResultText)
                                    .font(.system(size: 56, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.45)
                                    .transition(.opacity)
                            } else {
                                Text(displayExpression)
                                    .font(.system(size: 56, weight: .bold, design: .rounded))
                                    .foregroundStyle(vm.expression.isEmpty ? .secondary : .primary)
                                    .opacity(vm.expression.isEmpty ? 0.35 : 1)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.45)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 20)
                    .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity, minHeight: 260, alignment: .bottomTrailing)
                .animation(
                    vm.shouldAnimateDisplayTransition ? .spring(response: 0.45, dampingFraction: 0.82) : nil,
                    value: hasResult
                )
                .animation(.easeOut(duration: 0.25), value: vm.fadingExpression)
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        Color(
                            red: 0.78,
                            green: 0.82,
                            blue: 0.70
                        )
                    )
            )
            .padding(.horizontal, 20)

            if let error = vm.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .font(.footnote)
            }

            Spacer()

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    CalculatorButton(title: "") { vm.append("") }
                    CalculatorButton(title: "") { vm.append("") }
                    CalculatorButton(title: "C") { vm.clear() }
                    CalculatorButton(title: "⌫") { vm.backspace() }
                }
                .padding(.horizontal)

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
        .background(
            Color(
                red: 0.12,
                green: 0.12,
                blue: 0.12
            )
            .ignoresSafeArea()
        )
    }
}

#Preview {
    NavigationStack { CalculatorView() }
}
