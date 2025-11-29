import SwiftUI
import AVKit

struct GalleryDetailView: View {
    @ObservedObject var galleryViewModel: GalleryViewModel
    let item: GalleryItem
    @State private var showFullScreen = false
    @State private var player: AVPlayer?
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) var dismiss
    
    private let backgroundColor = Color(red: 0.956, green: 0.949, blue: 0.922)
    private let themeGreen = Color(red: 42/255, green: 111/255, blue: 54/255)
    private let navBarColor = Color(red: 0x95 / 255.0, green: 0xB1 / 255.0, blue: 0x5D / 255.0)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                mediaSection
                creationDateSection
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(backgroundColor)
        .navigationTitle("รายละเอียด")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive, action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                }
            }
        }
        .toolbarBackground(navBarColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .confirmationDialog("ยืนยันการลบ", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("ลบ", role: .destructive) {
                galleryViewModel.deleteGalleryItem(item)
                dismiss()
            }
            Button("ยกเลิก", role: .cancel) {}
        } message: {
            Text("คุณต้องการลบรายการนี้หรือไม่? การกระทำนี้ไม่สามารถยกเลิกได้")
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            FullScreenMediaView(
                galleryViewModel: galleryViewModel,
                item: item,
                isPresented: $showFullScreen,
                existingPlayer: player
            )
        }
        .onDisappear {
            // หยุดวิดีโอเมื่อ view หายไป (เช่น เมื่อเปลี่ยน tabs)
            player?.pause()
            player = nil
        }
    }
    
    @ViewBuilder
    private var mediaSection: some View {
        if item.mediaType == .photo {
            if let image = galleryViewModel.loadImage(from: item) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, alignment: .top)
                    .onTapGesture {
                        showFullScreen = true
                    }
            } else {
                Text("ไม่สามารถโหลดรูปภาพได้")
                    .foregroundColor(.secondary)
            }
        } else {
            if let videoURL = galleryViewModel.loadVideoURL(from: item) {
                Group {
                    if let player = player {
                        VideoPlayer(player: player)
                            .frame(height: 300)
                            .onTapGesture {
                                showFullScreen = true
                            }
                    } else {
                        ProgressView()
                            .frame(height: 300)
                    }
                }
                .onAppear {
                    if player == nil {
                        player = AVPlayer(url: videoURL)
                    }
                }
            } else {
                Text("ไม่สามารถโหลดวิดีโอได้")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var creationDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("วันที่สร้าง")
                .font(.headline)
            
            Text(formatDateTime(item.createdAt))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.7))
        )
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "th_TH")
        return formatter.string(from: date)
    }
}

struct FullScreenMediaView: View {
    @ObservedObject var galleryViewModel: GalleryViewModel
    let item: GalleryItem
    @Binding var isPresented: Bool
    let existingPlayer: AVPlayer?
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // ปุ่มกากบาท
                HStack {
                    Spacer()
                    Button(action: {
                        player?.pause()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .padding()
                
                Spacer()
                
                // แสดงรูปภาพหรือวิดีโอ
                if item.mediaType == .photo {
                    if let image = galleryViewModel.loadImage(from: item) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Text("ไม่สามารถโหลดรูปภาพได้")
                            .foregroundColor(.white)
                    }
                } else {
                    // ใช้ player ที่มีอยู่แล้วหรือสร้างใหม่
                    Group {
                        if let player = player {
                            VideoPlayer(player: player)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .onAppear {
                        // ใช้ player ที่มีอยู่แล้วหรือสร้างใหม่
                        if let existingPlayer = existingPlayer {
                            player = existingPlayer
                            player?.play()
                        } else if let videoURL = galleryViewModel.loadVideoURL(from: item) {
                            player = AVPlayer(url: videoURL)
                            player?.play()
                        }
                    }
                }
                
                Spacer()
            }
        }
        .onDisappear {
            // หยุดวิดีโอเมื่อปิด full screen
            player?.pause()
            // ไม่ต้อง set player = nil เพราะอาจจะใช้ player เดิมต่อ
        }
    }
}

