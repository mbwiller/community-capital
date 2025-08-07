//
//  ReceiptScannerView.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

// ReceiptScannerView.swift
import SwiftUI
import ComposableArchitecture
import VisionKit
import Vision

// MARK: - Receipt Scanner View with Real Camera
struct ReceiptScannerView: View {
    let store: StoreOf<ReceiptScannerReducer>
    @Environment(.dismiss) var dismiss
    @State private var showingImagePicker = false
    @State private var showingDocumentScanner = false
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                ZStack {
                    CCDesign.backgroundPrimary.ignoresSafeArea()
                    
                    if viewStore.isProcessing {
                        ProcessingReceiptView(
                            restaurantName: viewStore.restaurantName,
                            itemCount: viewStore.parsedItems.count
                        )
                    } else if !viewStore.parsedItems.isEmpty {
                        ParsedReceiptView(store: store)
                    } else {
                        CameraCaptureView(
                            showingImagePicker: $showingImagePicker,
                            showingDocumentScanner: $showingDocumentScanner,
                            onImageCaptured: { image in
                                viewStore.send(.imageCaptured(image))
                                viewStore.send(.processReceipt)
                            }
                        )
                    }
                    
                    if let error = viewStore.errorMessage {
                        VStack {
                            Spacer()
                            ErrorBanner(message: error)
                                .padding()
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(CCDesign.primaryGreen)
                    }
                    
                    ToolbarItem(placement: .principal) {
                        Text("Scan Receipt")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker { image in
                        viewStore.send(.imageCaptured(image))
                        viewStore.send(.processReceipt)
                    }
                }
                .sheet(isPresented: $showingDocumentScanner) {
                    DocumentScannerView { image in
                        viewStore.send(.imageCaptured(image))
                        viewStore.send(.processReceipt)
                    }
                }
            }
        }
    }
}

// MARK: - Camera Capture View
struct CameraCaptureView: View {
    @Binding var showingImagePicker: Bool
    @Binding var showingDocumentScanner: Bool
    let onImageCaptured: (UIImage) -> Void
    var body: some View {
        VStack(spacing: 24) {
            // Instructions
            VStack(spacing: 12) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 60))
                    .foregroundColor(CCDesign.primaryGreen)
                
                Text("Scan Your Receipt")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(CCDesign.textPrimary)
                
                Text("Choose your preferred scanning method")
                    .font(.system(size: 16))
                    .foregroundColor(CCDesign.textSecondary)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Scanning options
            VStack(spacing: 16) {
                // Document Scanner (Recommended)
                Button(action: {
                    showingDocumentScanner = true
                }) {
                    HStack {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 24))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Document Scanner")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Best for receipts • Auto-crop • Multi-page")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Text("Recommended")
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(4)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(CCDesign.primaryGradient)
                    .cornerRadius(16)
                }
                
                // Photo Library
                Button(action: {
                    showingImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 24))
                            .foregroundColor(CCDesign.primaryGreen)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Choose from Photos")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(CCDesign.textPrimary)
                            Text("Select existing receipt photo")
                                .font(.system(size: 12))
                                .foregroundColor(CCDesign.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(CCDesign.primaryGreen, lineWidth: 1.5)
                    )
                }
                
                // Mock scan for testing
                #if DEBUG
                SecondaryActionButton(
                    title: "Use Test Receipt",
                    icon: "ladybug"
                ) {
                    // Create a mock image for testing
                    let mockImage = UIImage(systemName: "doc.text.fill") ?? UIImage()
                    onImageCaptured(mockImage)
                }
                #endif
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Document Scanner View (VisionKit)
struct DocumentScannerView: UIViewControllerRepresentable {
    let completion: (UIImage) -> Void
    @Environment(.dismiss) var dismiss
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
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
            guard scan.pageCount > 0 else {
                parent.dismiss()
                return
            }
            
            let image = scan.imageOfPage(at: 0)
            parent.completion(image)
            parent.dismiss()
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.dismiss()
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    let completion: (UIImage) -> Void
    @Environment(.dismiss) var dismiss
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.completion(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Processing View
struct ProcessingReceiptView: View {
    let restaurantName: String
    let itemCount: Int
    @State private var processingStep = 0
    @State private var animationAmount: Double = 1
    let steps = [
        ("scanner.fill", "Capturing receipt..."),
        ("text.viewfinder", "Extracting text..."),
        ("brain", "Analyzing items..."),
        ("checkmark.shield.fill", "Verifying amounts..."),
        ("sparkles", "Categorizing expenses...")
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            // Animated icon
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(CCDesign.primaryGreen.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                        .frame(width: 100 + CGFloat(index * 30), height: 100 + CGFloat(index * 30))
                        .scaleEffect(animationAmount)
                        .opacity(2 - animationAmount)
                        .animation(
                            Animation.easeOut(duration: 1.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.2),
                            value: animationAmount
                        )
                }
                
                if processingStep < steps.count {
                    Image(systemName: steps[processingStep].0)
                        .font(.system(size: 40))
                        .foregroundColor(CCDesign.primaryGreen)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .onAppear {
                animationAmount = 2
            }
            
            // Status text
            VStack(spacing: 12) {
                Text("Processing Receipt")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(CCDesign.textPrimary)
                
                if processingStep < steps.count {
                    Text(steps[processingStep].1)
                        .font(.system(size: 16))
                        .foregroundColor(CCDesign.textSecondary)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            
            // Progress indicators
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= processingStep ? CCDesign.primaryGreen : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: processingStep)
                }
            }
            
            // ML Insights
            if processingStep >= 2 {
                VStack(spacing: 8) {
                    if !restaurantName.isEmpty {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(CCDesign.info)
                            Text("Detected: \(restaurantName)")
                                .font(.system(size: 14))
                                .foregroundColor(CCDesign.textSecondary)
                        }
                    }
                    
                    if itemCount > 0 {
                        HStack {
                            Image(systemName: "cart.fill")
                                .foregroundColor(CCDesign.success)
                            Text("Found \(itemCount) items")
                                .font(.system(size: 14))
                                .foregroundColor(CCDesign.textSecondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(CCDesign.lightGreen)
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(40)
        .onAppear {
            startProcessing()
        }
    }
    
    func startProcessing() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            withAnimation {
                if processingStep < steps.count - 1 {
                    processingStep += 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}

// MARK: - Parsed Receipt View
struct ParsedReceiptView: View {
    let store: StoreOf<ReceiptScannerReducer>
    @State private var editingItem: BillItem?
    @State private var showingEditSheet = false
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                // Header with restaurant info
                VStack(spacing: 12) {
                    Text(viewStore.restaurantName.isEmpty ? "Receipt Items" : viewStore.restaurantName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(CCDesign.textPrimary)
                    
                    // Confidence and stats
                    HStack(spacing: 16) {
                        Label("\(viewStore.parsedItems.count) items", systemImage: "cart.fill")
                            .font(.system(size: 14))
                            .foregroundColor(CCDesign.textSecondary)
                        
                        Label(String(format: "%.0f%% confidence", viewStore.confidenceScore * 100), systemImage: "checkmark.shield.fill")
                            .font(.system(size: 14))
                            .foregroundColor(viewStore.confidenceScore > 0.8 ? CCDesign.success : CCDesign.warning)
                    }
                    
                    // Total
                    let total = viewStore.parsedItems.reduce(0) { $0 + $1.price * Double($1.quantity) }
                    Text(String(format: "Total: $%.2f", total))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(CCDesign.textPrimary)
                }
                .padding()
                .background(Color.white)
                
                // Items list
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewStore.parsedItems) { item in
                            ItemRow(
                                item: item,
                                onEdit: {
                                    editingItem = item
                                    showingEditSheet = true
                                },
                                onDelete: {
                                    viewStore.send(.removeItem(item.id))
                                }
                            )
                        }
                        
                        // Add item button
                        Button(action: {
                            let newItem = BillItem(
                                id: UUID().uuidString,
                                name: "New Item",
                                price: 0.0,
                                quantity: 1,
                                claimedBy: [],
                                isSharedByTable: false
                            )
                            viewStore.send(.addItem(newItem))
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Item")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(CCDesign.primaryGreen)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(CCDesign.primaryGreen.opacity(0.3), lineWidth: 1)
                                    .background(CCDesign.lightGreen.cornerRadius(12))
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .padding(.vertical)
                }
                
                // Actions
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        SecondaryActionButton(
                            title: "Rescan",
                            icon: "arrow.clockwise"
                        ) {
                            viewStore.send(.reset)
                        }
                        
                        PrimaryActionButton(
                            title: "Create Event",
                            icon: "arrow.right"
                        ) {
                            viewStore.send(.createEvent)
                        }
                    }
                    
                    Text("Tip: Tap items to edit, swipe to delete")
                        .font(.system(size: 12))
                        .foregroundColor(CCDesign.textSecondary)
                }
                .padding()
                .background(Color.white)
            }
            .sheet(isPresented: $showingEditSheet) {
                if let item = editingItem {
                    EditItemSheet(
                        item: item,
                        onSave: { updatedItem in
                            viewStore.send(.itemEdited(id: item.id, updatedItem))
                            showingEditSheet = false
                        },
                        onCancel: {
                            showingEditSheet = false
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Item Row
struct ItemRow: View {
    let item: BillItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    var category: String {
        MLCategorizer.categorize(item.name)
    }
    
    var categoryIcon: String {
        MLCategorizer.categoryIcon(for: item.name)
    }
    
    var categoryColor: Color {
        MLCategorizer.categoryColor(for: item.name)
    }
    
    var body: some View {
        HStack {
            // Category icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 18))
                    .foregroundColor(categoryColor)
            }
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(CCDesign.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(category)
                        .font(.system(size: 12))
                        .foregroundColor(CCDesign.textSecondary)
                    
                    if item.quantity > 1 {
                        Text("×\(item.quantity)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(CCDesign.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(CCDesign.lightGreen)
                            )
                    }
                }
            }
            
            Spacer()
            
            // Price
            Text(String(format: "$%.2f", item.price * Double(item.quantity)))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(CCDesign.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: CCDesign.cardShadow, radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Edit Item Sheet
struct EditItemSheet: View {
    @State var item: BillItem
    let onSave: (BillItem) -> Void
    let onCancel: () -> Void
    var body: some View {
        NavigationView {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $item.name)
                    
                    HStack {
                        Text("Price")
                        Spacer()
                        TextField("0.00", value: $item.price, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Stepper("Quantity: \(item.quantity)", value: $item.quantity, in: 1...99)
                }
                
                Section("Category") {
                    HStack {
                        Image(systemName: MLCategorizer.categoryIcon(for: item.name))
                            .foregroundColor(MLCategorizer.categoryColor(for: item.name))
                        Text(MLCategorizer.categorize(item.name))
                            .foregroundColor(CCDesign.textSecondary)
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(item)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - ML Categorizer
struct MLCategorizer {
    static func categorize(_ itemName: String) -> String {
        let lowercased = itemName.lowercased()
        // Enhanced categorization logic
        if lowercased.contains("beer") || lowercased.contains("wine") ||
            lowercased.contains("cocktail") || lowercased.contains("sake") ||
            lowercased.contains("soda") || lowercased.contains("juice") {
            return "Beverages"
        } else if lowercased.contains("tip") || lowercased.contains("gratuity") {
            return "Tip"
        } else if lowercased.contains("tax") || lowercased.contains("service") {
            return "Tax & Fees"
        } else if lowercased.contains("dessert") || lowercased.contains("cake") ||
                    lowercased.contains("ice cream") || lowercased.contains("tiramisu") {
            return "Dessert"
        } else if lowercased.contains("salad") || lowercased.contains("appetizer") ||
                    lowercased.contains("starter") || lowercased.contains("soup") {
            return "Appetizer"
        } else if lowercased.contains("chicken") || lowercased.contains("beef") ||
                    lowercased.contains("fish") || lowercased.contains("pasta") ||
                    lowercased.contains("burger") || lowercased.contains("steak") {
            return "Main Course"
        } else {
            return "Food"
        }
    }
    
    static func categoryIcon(for itemName: String) -> String {
        switch categorize(itemName) {
        case "Beverages": return "wineglass"
        case "Dessert": return "birthday.cake"
        case "Appetizer": return "leaf"
        case "Tax & Fees": return "dollarsign.circle"
        case "Tip": return "hand.thumbsup"
        case "Main Course": return "fork.knife"
        default: return "cart"
        }
    }
    
    static func categoryColor(for itemName: String) -> Color {
        switch categorize(itemName) {
        case "Beverages": return CCDesign.info
        case "Dessert": return CCDesign.accentOrange
        case "Appetizer": return CCDesign.success
        case "Tax & Fees": return CCDesign.textSecondary
        case "Tip": return CCDesign.warning
        case "Main Course": return CCDesign.primaryGreen
        default: return CCDesign.textPrimary
        }
    }
}
