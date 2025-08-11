// ReceiptScannerView.swift
import SwiftUI
import ComposableArchitecture
import VisionKit
import Vision
import UIKit

struct ReceiptScannerView: View {
    let store: StoreOf<ReceiptScannerReducer>
    @Environment(.dismiss) var dismiss
    @State private var showingImagePicker = false
    @State private var showingDocumentScanner = false
    @State private var showingManualInput = false
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                ZStack {
                    CCDesign.backgroundPrimary.ignoresSafeArea()
                    
                    if viewStore.isProcessing {
                        ProcessingView()
                    } else if !viewStore.parsedItems.isEmpty {
                        ReceiptReviewView(store: store)
                    } else {
                        ScannerOptionsView(
                            showingImagePicker: $showingImagePicker,
                            showingDocumentScanner: $showingDocumentScanner,
                            showingManualInput: $showingManualInput
                        )
                    }
                }
                .navigationTitle("Scan Receipt")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(CCDesign.primaryGreen)
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { image in
                WithViewStore(self.store, observe: { $0 }) { viewStore in
                    viewStore.send(.imageCaptured(image))
                }
            }
        }
        .sheet(isPresented: $showingDocumentScanner) {
            DocumentScannerView { image in
                WithViewStore(self.store, observe: { $0 }) { viewStore in
                    viewStore.send(.imageCaptured(image))
                }
            }
        }
        .sheet(isPresented: $showingManualInput) {
            ManualInputView { items in
                WithViewStore(self.store, observe: { $0 }) { viewStore in
                    viewStore.send(.manualItemsAdded(items))
                }
            }
        }
    }
}

// MARK: - Scanner Options View
struct ScannerOptionsView: View {
    @Binding var showingImagePicker: Bool
    @Binding var showingDocumentScanner: Bool
    @Binding var showingManualInput: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(CCDesign.primaryGradient)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 8) {
                    Text("Scan Your Receipt")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(CCDesign.textPrimary)
                    
                    Text("Choose how you'd like to add your receipt")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(CCDesign.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Options
            VStack(spacing: 16) {
                ScannerOptionButton(
                    icon: "doc.text.viewfinder",
                    title: "Document Scanner",
                    subtitle: "Best for clear receipts",
                    action: { showingDocumentScanner = true }
                )
                
                ScannerOptionButton(
                    icon: "photo",
                    title: "Photo Library",
                    subtitle: "Choose existing photo",
                    action: { showingImagePicker = true }
                )
                
                ScannerOptionButton(
                    icon: "pencil",
                    title: "Manual Entry",
                    subtitle: "Type items yourself",
                    action: { showingManualInput = true }
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Scanner Option Button
struct ScannerOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(CCDesign.primaryGreen.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(CCDesign.primaryGreen)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(CCDesign.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(CCDesign.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(CCDesign.textTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: CCDesign.cardShadow, radius: 8, x: 0, y: 2)
            )
        }
    }
}

// MARK: - Processing View
struct ProcessingView: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(CCDesign.primaryGradient)
                    .frame(width: 80, height: 80)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
            
            VStack(spacing: 8) {
                Text("Processing Receipt...")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(CCDesign.textPrimary)
                
                Text("Extracting items and prices")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(CCDesign.textSecondary)
            }
        }
    }
}

// MARK: - Receipt Review View
struct ReceiptReviewView: View {
    let store: StoreOf<ReceiptScannerReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(spacing: 24) {
                    // Event Details
                    EventDetailsSection(
                        eventName: viewStore.binding(
                            get: \.eventName,
                            send: ReceiptScannerReducer.Action.setEventName
                        ),
                        restaurantName: viewStore.binding(
                            get: \.restaurantName,
                            send: ReceiptScannerReducer.Action.setRestaurantName
                        )
                    )
                    
                    // Items List
                    ItemsListSection(
                        items: viewStore.parsedItems,
                        onToggleItem: { index in
                            viewStore.send(.toggleItemSelection(index))
                        }
                    )
                    
                    // Summary
                    SummarySection(
                        selectedItemsTotal: viewStore.selectedItemsTotal,
                        totalItems: viewStore.parsedItems.count,
                        selectedItems: viewStore.parsedItems.filter { $0.isSelected }.count
                    )
                    
                    // Create Event Button
                    PrimaryActionButton(
                        title: "Create Event",
                        icon: "checkmark.circle.fill",
                        isLoading: false,
                        isEnabled: !viewStore.eventName.isEmpty && viewStore.selectedItemsTotal > 0
                    ) {
                        viewStore.send(.createEvent)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
            }
        }
    }
}

// MARK: - Event Details Section
struct EventDetailsSection: View {
    @Binding var eventName: String
    @Binding var restaurantName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Event Details")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(CCDesign.textPrimary)
            
            VStack(spacing: 12) {
                InputField(
                    title: "Event Name",
                    placeholder: "e.g., Lunch with Friends",
                    text: $eventName
                )
                
                InputField(
                    title: "Restaurant",
                    placeholder: "e.g., Chipotle",
                    text: $restaurantName
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Items List Section
struct ItemsListSection: View {
    let items: [BillItem]
    let onToggleItem: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Receipt Items")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(CCDesign.textPrimary)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    ItemRow(
                        item: item,
                        isSelected: item.isSelected,
                        onToggle: { onToggleItem(index) }
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Item Row
struct ItemRow: View {
    let item: BillItem
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? CCDesign.primaryGreen : CCDesign.textTertiary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(CCDesign.textPrimary)
                        .lineLimit(2)
                    
                    if item.quantity > 1 {
                        Text("Qty: \(item.quantity)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(CCDesign.textSecondary)
                    }
                }
                
                Spacer()
                
                Text("$\(String(format: "%.2f", item.price))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(CCDesign.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? CCDesign.lightGreen : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? CCDesign.primaryGreen : Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Summary Section
struct SummarySection: View {
    let selectedItemsTotal: Double
    let totalItems: Int
    let selectedItems: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(CCDesign.textPrimary)
            
            VStack(spacing: 12) {
                SummaryRow(
                    label: "Items Selected",
                    value: "\(selectedItems) of \(totalItems)"
                )
                
                SummaryRow(
                    label: "Total Amount",
                    value: "$\(String(format: "%.2f", selectedItemsTotal))",
                    isHighlighted: true
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Summary Row
struct SummaryRow: View {
    let label: String
    let value: String
    var isHighlighted: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(CCDesign.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isHighlighted ? CCDesign.primaryGreen : CCDesign.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Input Field
struct InputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(CCDesign.textSecondary)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageSelected: (UIImage) -> Void
        
        init(onImageSelected: @escaping (UIImage) -> Void) {
            self.onImageSelected = onImageSelected
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImageSelected(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Document Scanner View
struct DocumentScannerView: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onImageSelected: (UIImage) -> Void
        
        init(onImageSelected: @escaping (UIImage) -> Void) {
            self.onImageSelected = onImageSelected
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            if scan.pageCount > 0 {
                let image = scan.imageOfPage(at: 0)
                onImageSelected(image)
            }
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - Manual Input View
struct ManualInputView: View {
    let onItemsAdded: ([BillItem]) -> Void
    @Environment(.dismiss) var dismiss
    @State private var items: [BillItem] = []
    @State private var itemName = ""
    @State private var itemPrice = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Add Item Form
                VStack(spacing: 16) {
                    TextField("Item name", text: $itemName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Price", text: $itemPrice)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                    
                    Button("Add Item") {
                        if let price = Double(itemPrice), !itemName.isEmpty {
                            let item = BillItem(
                                id: UUID().uuidString,
                                name: itemName,
                                price: price,
                                quantity: 1,
                                claimedBy: [],
                                isSharedByTable: false,
                                isSelected: true
                            )
                            items.append(item)
                            itemName = ""
                            itemPrice = ""
                        }
                    }
                    .disabled(itemName.isEmpty || itemPrice.isEmpty)
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                
                // Items List
                List {
                    ForEach(items) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text("$\(String(format: "%.2f", item.price))")
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                
                Spacer()
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onItemsAdded(items)
                        dismiss()
                    }
                    .disabled(items.isEmpty)
                }
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
}
