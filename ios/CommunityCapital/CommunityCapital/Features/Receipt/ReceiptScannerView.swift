// ReceiptScannerView.swift
import SwiftUI
import ComposableArchitecture
import VisionKit

struct ReceiptScannerView: View {
    let store: StoreOf<ReceiptScannerReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                VStack {
                    if let image = viewStore.scannedImage {
                        ScrollView {
                            VStack(spacing: 20) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 300)
                                    .cornerRadius(12)
                                    .shadow(radius: 5)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    TextField("Event Name", text: viewStore.binding(
                                        get: \.eventName,
                                        send: ReceiptScannerReducer.Action.setEventName
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    TextField("Restaurant Name", text: viewStore.binding(
                                        get: \.restaurantName,
                                        send: ReceiptScannerReducer.Action.setRestaurantName
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                .padding(.horizontal)
                                
                                if viewStore.isProcessing {
                                    ProgressView("Processing receipt...")
                                        .padding()
                                } else if !viewStore.parsedItems.isEmpty {
                                    ParsedItemsView(items: viewStore.binding(
                                        get: \.parsedItems,
                                        send: { _ in .processReceipt }
                                    ))
                                }
                                
                                Button(action: {
                                    viewStore.send(.createEvent)
                                }) {
                                    Label("Create Event", systemImage: "arrow.right.circle.fill")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal)
                                .disabled(viewStore.parsedItems.isEmpty || viewStore.eventName.isEmpty)
                            }
                        }
                    } else {
                        DocumentScannerView { image in
                            viewStore.send(.imageCaptured(image))
                        }
                    }
                }
                .navigationTitle("Scan Receipt")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct DocumentScannerView: UIViewControllerRepresentable {
    var completion: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView
        
        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else { return }
            let image = scan.imageOfPage(at: 0)
            parent.completion(image)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true)
        }
    }
}

struct ParsedItemsView: View {
    @Binding var items: [BillItem]
    
    var subtotal: Double {
        items.reduce(0) { $0 + $1.price }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Parsed Items")
                    .font(.headline)
                
                Spacer()
                
                Text("\(items.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach($items) { $item in
                    HStack {
                        TextField("Item name", text: $item.name)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        Spacer()
                        
                        TextField("0.00", value: $item.price, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.horizontal)
            
            HStack {
                Text("Subtotal")
                    .font(.headline)
                
                Spacer()
                
                Text("$\(subtotal, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.green)
            }
            .padding(.horizontal)
        }
    }
}