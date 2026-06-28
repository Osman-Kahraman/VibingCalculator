import SwiftUI

struct CalculatorView: View {
    @StateObject private var vm = CalculatorViewModel()
    @Namespace private var animNS

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
                ZStack() {
                    VStack {
                        HStack {
                            Button {
                                withAnimation(.spring()) {
                                    vm.isAIMode.toggle()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "cloud.fill")
                                    if vm.isAIMode {
                                        Text("AI")
                                            .font(.caption.bold())
                                    }
                                }
                                .foregroundStyle(
                                    vm.isAIMode
                                    ? .blue
                                    : .gray.opacity(0.45)
                                )
                                .symbolEffect(
                                    .bounce,
                                    value: vm.isAIMode
                                )
                            }

                            Spacer()
                        }

                        Spacer()
                    }
                    .padding(16)
                    
                    VStack(alignment: .trailing, spacing: 6) {
                        ScrollViewReader { proxy in
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(alignment: .trailing, spacing: 6) {
                                    ForEach(vm.expressionHistory, id: \.self) { item in
                                        Text(item)
                                            .font(.system(size: 16, weight: .regular, design: .rounded))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.6)
                                            .matchedGeometryEffect(id: "expr-\(item)", in: animNS)
                                            .transition(.move(edge: .top).combined(with: .opacity))
                                            .id(item)
                                    }
                                    Color.clear
                                        .frame(height: 1)
                                        .id("BOTTOM")
                                }
                            }
                            .frame(maxHeight: 150)
                            .defaultScrollAnchor(.bottom)
                            .onAppear {
                                proxy.scrollTo("BOTTOM", anchor: .bottom)
                            }
                            .onChange(of: vm.expressionHistory.count) { _, _ in
                                withAnimation(.easeOut(duration: 0.25)) {
                                    proxy.scrollTo("BOTTOM", anchor: .bottom)
                                }
                            }
                        }
                        
                        Group {
                            if hasResult {
                                Text(vm.displayResultText)
                                    .font(.system(size: 56, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.45)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            } else {
                                Text(displayExpression)
                                    .font(.system(size: 56, weight: .bold, design: .rounded))
                                    .foregroundStyle(vm.expression.isEmpty ? .secondary : .primary)
                                    .opacity(vm.expression.isEmpty ? 0.35 : 1)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.45)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                    .matchedGeometryEffect(id: "expr-\(displayExpression)", in: animNS)
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
