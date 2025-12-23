import SwiftUI
import ProximityReader

struct ReaderDemoView: View {
    
    @StateObject private var viewModel = ReaderDemoViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    logoSection
                    inputSection
                    readCardSection
                    configurationSection
                    resultSection
                    Spacer(minLength: 50)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .onTapGesture { isInputFocused = false }
            .navigationTitle("Reader Demo")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.startAutoSetup()
            }
            .overlay {
                if viewModel.showTransactionPopup {
                    ZStack {
                        // Dimmed background with blur
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    viewModel.showTransactionPopup = false
                                }
                            }
                        
                        // Dialog Card
                        VStack(spacing: 0) {
                            // Success icon with animated background
                            ZStack {
                                // Outer rotating ring
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.green.opacity(0.6), Color.green.opacity(0.2), Color.clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                                    .frame(width: 110, height: 110)
                                    .rotationEffect(.degrees(viewModel.showTransactionPopup ? 360 : 0))
                                    .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: viewModel.showTransactionPopup)
                                
                                // Animated circle background with pulse
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.green.opacity(0.2), Color.green.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .scaleEffect(viewModel.showTransactionPopup ? 1 : 0.3)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1), value: viewModel.showTransactionPopup)
                                
                                // Success icon with bounce
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 65, height: 65)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.green, Color.green.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                                    .scaleEffect(viewModel.showTransactionPopup ? 1 : 0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.2), value: viewModel.showTransactionPopup)
                                
                                // Sparkle particles
                                ForEach(0..<8) { index in
                                    Image(systemName: "sparkle")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green.opacity(0.7))
                                        .offset(
                                            x: viewModel.showTransactionPopup ? cos(Double(index) * .pi / 4) * 60 : 0,
                                            y: viewModel.showTransactionPopup ? sin(Double(index) * .pi / 4) * 60 : 0
                                        )
                                        .opacity(viewModel.showTransactionPopup ? 0 : 1)
                                        .scaleEffect(viewModel.showTransactionPopup ? 0.3 : 1)
                                        .animation(.easeOut(duration: 0.8).delay(0.3), value: viewModel.showTransactionPopup)
                                }
                            }
                            .padding(.top, 32)
                            .padding(.bottom, 20)
                            
                            // Title with slide in
                            Text("Transaction Successful")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.bottom, 8)
                                .offset(y: viewModel.showTransactionPopup ? 0 : 20)
                                .opacity(viewModel.showTransactionPopup ? 1 : 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: viewModel.showTransactionPopup)
                            
                            // Decorative line with expand animation
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.3), Color.green.opacity(0.6), Color.green.opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: viewModel.showTransactionPopup ? 60 : 0, height: 4)
                                .padding(.bottom, 20)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: viewModel.showTransactionPopup)
                            
                            // Summary details with fade in
                            Text(viewModel.lastTransactionSummary)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 28)
                                .offset(y: viewModel.showTransactionPopup ? 0 : 15)
                                .opacity(viewModel.showTransactionPopup ? 1 : 0)
                                .animation(.easeOut(duration: 0.4).delay(0.5), value: viewModel.showTransactionPopup)
                            
                            // Close button with slide up
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    viewModel.showTransactionPopup = false
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Text("Continue")
                                        .font(.system(size: 17, weight: .semibold))
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 16))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.85)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(14)
                                .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 28)
                            .offset(y: viewModel.showTransactionPopup ? 0 : 20)
                            .opacity(viewModel.showTransactionPopup ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: viewModel.showTransactionPopup)
                        }
                        .frame(width: 320)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                                .shadow(color: .black.opacity(0.1), radius: 40, x: 0, y: 20)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .scaleEffect(viewModel.showTransactionPopup ? 1 : 0.5)
                        .opacity(viewModel.showTransactionPopup ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: viewModel.showTransactionPopup)
                    }
                    .transition(.opacity)
                }
            }
            
        }
    }
}

// MARK: - Subviews
private extension ReaderDemoView {
    
    var logoSection: some View {
        Image("sbs_logo")
            .resizable()
            .scaledToFill()
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.gray.opacity(0.3), lineWidth: 1))
            .shadow(radius: 6)
            .padding(.top, 40)
    }
    
    var inputSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Group {
                TextField("Amount", value: $viewModel.amount, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .focused($isInputFocused)
                if let error = viewModel.amountError {
                    Text(error).foregroundColor(.red).font(.caption)
                }
            }
            
            Group {
                TextField("Currency (e.g. USD)", text: $viewModel.currency)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)
                if let error = viewModel.currencyError {
                    Text(error).foregroundColor(.red).font(.caption)
                }
            }
            
            VStack(alignment: .leading) {
                Text("Transaction Type")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: $viewModel.transactionType) {
                    Text("Purchase").tag(PaymentCardTransactionRequest.TransactionType.purchase)
                    //Text("Refund").tag(PaymentCardTransactionRequest.TransactionType.refund)
                }
                .pickerStyle(.segmented)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    var readCardSection: some View {
        VStack(spacing: 16) {
            Button(action: { Task { await viewModel.readCard() } }) {
                Label("Pay", systemImage: "creditcard.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(!viewModel.isSetupCompleted)
        }
        .padding(.horizontal)
    }
    
    var configurationSection: some View {
        Group {
            if viewModel.isConfiguring {
                VStack(spacing: 8) {
                    ProgressView(value: Double(viewModel.progress), total: 100)
                        .progressViewStyle(.linear)
                    Text("Configuration: \(viewModel.progress)%")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
        }
    }
    
    var resultSection: some View {
        Group {
            if !viewModel.resultMessages.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    headerResults
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(viewModel.resultMessages.indices, id: \.self) { index in
                                Text(viewModel.resultMessages[index])
                                    .font(.footnote)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
        }
    }
    
    var headerResults: some View {
        HStack {
            Text("Results")
                .font(.headline)
            Spacer()
            HStack(spacing: 12) {
                Button(action: { viewModel.clearResults() }) {
                    Label("Clear", systemImage: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                Button(action: { viewModel.shareLogs() }) {
                    Label("Share Logs", systemImage: "square.and.arrow.up")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
    }
}
