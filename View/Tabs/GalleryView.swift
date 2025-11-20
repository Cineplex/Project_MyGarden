import SwiftUI
import PhotosUI
import AVKit

enum GalleryFilter: String, CaseIterable {
    case all = "ทั้งหมด"
    case photos = "รูปภาพ"
    case videos = "วิดีโอ"
}

struct GalleryView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var galleryViewModel = GalleryViewModel()
    @State private var selectedPhotoPickerItems: [PhotosPickerItem] = []
    @State private var selectedVideoPickerItems: [PhotosPickerItem] = []
    @State private var showPhotoPicker = false
    @State private var showVideoPicker = false
    @State private var showActionSheet = false
    @State private var isSelectionMode = false
    @State private var selectedItems: Set<UUID> = []
    @State private var showDeleteAlert = false
    @State private var itemsToDelete: [GalleryItem] = []
    @State private var selectedFilter: GalleryFilter = .all
    
    var userGalleryItems: [GalleryItem] {
        guard let userId = authViewModel.currentUser?.id else { return [] }
        return galleryViewModel.getGalleryItems(for: userId)
    }
    
    var photos: [GalleryItem] {
        userGalleryItems.filter { $0.mediaType == .photo }
    }
    
    var videos: [GalleryItem] {
        userGalleryItems.filter { $0.mediaType == .video }
    }
    
    var filteredItems: [GalleryItem] {
        switch selectedFilter {
        case .all:
            return userGalleryItems
        case .photos:
            return photos
        case .videos:
            return videos
        }
    }
    
    var emptyStateMessage: String {
        switch selectedFilter {
        case .all:
            return "ยังไม่มีรูปภาพหรือวิดีโอ"
        case .photos:
            return "ยังไม่มีรูปภาพ"
        case .videos:
            return "ยังไม่มีวิดีโอ"
        }
    }
    
    var emptyStateIcon: String {
        switch selectedFilter {
        case .photos:
            return "photo"
        case .videos:
            return "video"
        case .all:
            return "photo.on.rectangle"
        }
    }
    
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: emptyStateIcon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text(emptyStateMessage)
                .font(.title2)
                .foregroundColor(.secondary)
            Text("กดปุ่ม + เพื่อเพิ่มรูปภาพหรือวิดีโอ")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    var navigationTitle: String {
        isSelectionMode ? "เลือก \(selectedItems.count) รายการ" : "Gallery"
    }
    
    @ViewBuilder
    var leadingToolbarItem: some View {
        if isSelectionMode {
            Button("ยกเลิก") {
                isSelectionMode = false
                selectedItems.removeAll()
            }
        }
    }
    
    @ViewBuilder
    var trailingToolbarItem: some View {
        HStack {
            if !filteredItems.isEmpty && !isSelectionMode {
                Button(action: {
                    isSelectionMode.toggle()
                }) {
                    Image(systemName: "checkmark.circle")
                }
            }
            
            if isSelectionMode {
                if areAllFilteredItemsSelected {
                    Button(action: {
                        deselectAllFilteredItems()
                    }) {
                        Text("ยกเลิกทั้งหมด")
                            .font(.subheadline)
                    }
                } else {
                    Button(action: {
                        selectAllFilteredItems()
                    }) {
                        Text("เลือกทั้งหมด")
                            .font(.subheadline)
                    }
                }
                
                if !selectedItems.isEmpty {
                    Button(role: .destructive, action: {
                        itemsToDelete = filteredItems.filter { selectedItems.contains($0.id) }
                        showDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                    }
                }
            } else {
                Button(action: {
                    showActionSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    var areAllFilteredItemsSelected: Bool {
        !filteredItems.isEmpty && filteredItems.allSatisfy { selectedItems.contains($0.id) }
    }
    
    private func selectAllFilteredItems() {
        for item in filteredItems {
            selectedItems.insert(item.id)
        }
    }
    
    private func deselectAllFilteredItems() {
        for item in filteredItems {
            selectedItems.remove(item.id)
        }
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control
                if !userGalleryItems.isEmpty {
                    Picker("ประเภท", selection: $selectedFilter) {
                        ForEach(GalleryFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                if userGalleryItems.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("ยังไม่มีรูปภาพหรือวิดีโอ")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("กดปุ่ม + เพื่อเพิ่มรูปภาพหรือวิดีโอ")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    GeometryReader { geometry in
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(filteredItems) { item in
                                    galleryItemView(
                                        item: item,
                                        geometry: geometry,
                                        isSelectionMode: isSelectionMode
                                    )
                                }
                            }
                            .padding(.horizontal, 2)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    leadingToolbarItem
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    trailingToolbarItem
                }
            }
            .alert("ยืนยันการลบ", isPresented: $showDeleteAlert) {
                deleteAlertButtons
            } message: {
                deleteAlertMessage
            }
            .confirmationDialog("เลือกประเภท", isPresented: $showActionSheet, titleVisibility: .visible) {
                mediaTypeSelectionButtons
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedPhotoPickerItems,
                maxSelectionCount: nil,
                matching: .images
            )
            .photosPicker(
                isPresented: $showVideoPicker,
                selection: $selectedVideoPickerItems,
                maxSelectionCount: nil,
                matching: .videos
            )
            .onChange(of: selectedPhotoPickerItems) { newItems in
                handlePhotoSelection(newItems)
            }
            .onChange(of: selectedVideoPickerItems) { newItems in
                handleVideoSelection(newItems)
            }
        }
    }
    
    @ViewBuilder
    private var deleteAlertButtons: some View {
        Button("ยกเลิก", role: .cancel) {
            itemsToDelete = []
        }
        Button("ลบ", role: .destructive) {
            galleryViewModel.deleteGalleryItems(itemsToDelete)
            selectedItems.removeAll()
            isSelectionMode = false
            itemsToDelete = []
        }
    }
    
    private var deleteAlertMessage: Text {
        Text("คุณต้องการลบ \(itemsToDelete.count) รายการนี้หรือไม่? การกระทำนี้ไม่สามารถยกเลิกได้")
    }
    
    @ViewBuilder
    private var mediaTypeSelectionButtons: some View {
        Button("รูปภาพ") {
            showPhotoPicker = true
        }
        Button("วิดีโอ") {
            showVideoPicker = true
        }
        Button("ยกเลิก", role: .cancel) { }
    }
    
    private func handlePhotoSelection(_ newItems: [PhotosPickerItem]) {
        Task {
            guard let userId = authViewModel.currentUser?.id else { return }
            
            for item in newItems {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        galleryViewModel.addPhoto(userId: userId, image: image)
                    }
                }
            }
            
            await MainActor.run {
                selectedPhotoPickerItems = []
            }
        }
    }
    
    private func handleVideoSelection(_ newItems: [PhotosPickerItem]) {
        Task {
            guard let userId = authViewModel.currentUser?.id else { return }
            
            for item in newItems {
                if let videoFile = try? await item.loadTransferable(type: VideoFile.self) {
                    await MainActor.run {
                        galleryViewModel.addVideo(userId: userId, videoURL: videoFile.url)
                    }
                }
            }
            
            await MainActor.run {
                selectedVideoPickerItems = []
            }
        }
    }
    
    @ViewBuilder
    private func galleryItemView(item: GalleryItem, geometry: GeometryProxy, isSelectionMode: Bool) -> some View {
        if isSelectionMode {
            Button(action: {
                if selectedItems.contains(item.id) {
                    selectedItems.remove(item.id)
                } else {
                    selectedItems.insert(item.id)
                }
            }) {
                GalleryThumbnailView(
                    galleryViewModel: galleryViewModel,
                    item: item,
                    size: (geometry.size.width - 4) / 3,
                    isSelected: selectedItems.contains(item.id),
                    showSelectionIndicator: true
                )
            }
        } else {
            NavigationLink(destination: GalleryDetailView(
                galleryViewModel: galleryViewModel,
                item: item
            )) {
                GalleryThumbnailView(
                    galleryViewModel: galleryViewModel,
                    item: item,
                    size: (geometry.size.width - 4) / 3,
                    isSelected: false,
                    showSelectionIndicator: false
                )
            }
            .contextMenu {
                Button(role: .destructive, action: {
                    itemsToDelete = [item]
                    showDeleteAlert = true
                }) {
                    Label("ลบ", systemImage: "trash")
                }
            }
        }
    }
}

struct GalleryThumbnailView: View {
    @ObservedObject var galleryViewModel: GalleryViewModel
    let item: GalleryItem
    let size: CGFloat
    let isSelected: Bool
    let showSelectionIndicator: Bool
    
    var body: some View {
        ZStack {
            if item.mediaType == .photo {
                if let image = galleryViewModel.loadImage(from: item) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: size, height: size)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
            } else {
                if let videoURL = galleryViewModel.loadVideoURL(from: item) {
                    VideoThumbnailView(videoURL: videoURL)
                        .frame(width: size, height: size)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: size, height: size)
                        .overlay(
                            Image(systemName: "video")
                                .foregroundColor(.gray)
                        )
                }
            }
            
            // Overlay เมื่อถูกเลือก
            if showSelectionIndicator {
                Rectangle()
                    .fill(Color.black.opacity(isSelected ? 0.3 : 0))
                    .frame(width: size, height: size)
                
                // ไอคอนเลือก
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? .blue : .white)
                            .font(.system(size: 24))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.8))
                            )
                    }
                    Spacer()
                }
            }
            
            // ไอคอนวิดีโอ
            if item.mediaType == .video && !showSelectionIndicator {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                            .padding(4)
                    }
                }
            }
        }
    }
}

struct VideoThumbnailView: UIViewRepresentable {
    let videoURL: URL
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        // สร้าง thumbnail จากวิดีโอ
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 0, preferredTimescale: 600)
        if let cgImage = try? imageGenerator.copyCGImage(at: time, actualTime: nil) {
            imageView.image = UIImage(cgImage: cgImage)
        }
        
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {}
}

struct VideoFile: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let copy = documentsPath.appendingPathComponent("\(UUID().uuidString).mov")
            if FileManager.default.fileExists(atPath: copy.path) {
                try? FileManager.default.removeItem(at: copy)
            }
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self.init(url: copy)
        }
    }
}
