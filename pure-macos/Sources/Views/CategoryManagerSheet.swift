import SwiftUI

public class CategoryManagerViewModel: ObservableObject {
    @Published public var newCategoryName: String = ""
    @Published public var editingCategoryName: String? = nil
    @Published public var editInputName: String = ""
    @Published public var categoryToDelete: CategoryInfo? = nil
    @Published public var fallbackCategory: String = "Chung"
    @Published public var alertMessage: String? = nil
    
    public init() {}
}

public struct CategoryManagerSheet: View {
    @ObservedObject private var storage = StorageService.shared
    @StateObject private var vm = CategoryManagerViewModel()
    public var onClose: () -> Void
    
    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack(alignment: .center, spacing: 14) {
                LiquidGlassIconBadge(
                    icon: "folder.fill",
                    tintColor: Color.accentColor,
                    size: 38,
                    iconSize: 18,
                    cornerRadius: 10
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quản Lý Danh Mục")
                        .font(.lexioTitle)
                        .foregroundColor(.primary)
                    
                    Text("\(storage.allCategoryNames.count) danh mục • Phân loại và sắp xếp bộ thẻ thông minh")
                        .font(.lexioCaption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
                .help("Đóng (Esc)")
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider().opacity(0.6)
            
            // MARK: - Add New Category Bar
            HStack(spacing: 10) {
                Image(systemName: "plus.folder.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.accentColor)
                
                TextField("Nhập tên danh mục mới (VD: Tiếng Nhật, IELTS 7.0+, Công Sở...)", text: $vm.newCategoryName)
                    .textFieldStyle(.plain)
                    .font(.lexioBody)
                    .onSubmit {
                        addNewCategory()
                    }
                
                Button(action: addNewCategory) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Thêm")
                            .font(.lexioHeadline)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(7)
                }
                .buttonStyle(.plain)
                .disabled(vm.newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.7))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            
            // MARK: - Category List
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 8) {
                    let categories = storage.allCategoryInfos
                    if categories.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "folder.badge.questionmark")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary.opacity(0.35))
                            Text("Chưa có danh mục nào")
                                .font(.lexioCaption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 40)
                    } else {
                        ForEach(categories) { info in
                            categoryRow(info: info)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 16)
            }
            
            Divider().opacity(0.6)
            
            // MARK: - Footer
            HStack {
                Text("💡 Mẹo: Khi đổi tên danh mục, toàn bộ các bộ thẻ thuộc danh mục đó sẽ được cập nhật tự động.")
                    .font(.lexioCaption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Xong") {
                    onClose()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(VisualEffectView(material: .headerView, blendingMode: .withinWindow))
        }
        .frame(width: 600, height: 500)
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
        .alert("Xác nhận xóa danh mục", isPresented: Binding(
            get: { vm.categoryToDelete != nil },
            set: { if !$0 { vm.categoryToDelete = nil } }
        )) {
            Button("Xóa và Chuyển Bộ Thẻ", role: .destructive) {
                if let cat = vm.categoryToDelete {
                    storage.deleteCategory(named: cat.name, reassignTo: vm.fallbackCategory)
                    vm.categoryToDelete = nil
                }
            }
            Button("Hủy", role: .cancel) {
                vm.categoryToDelete = nil
            }
        } message: {
            if let cat = vm.categoryToDelete {
                if cat.deckCount > 0 {
                    Text("Danh mục \"\(cat.name)\" hiện có \(cat.deckCount) bộ thẻ. Các bộ thẻ này sẽ được tự động chuyển sang danh mục \"\(vm.fallbackCategory)\".")
                } else {
                    Text("Bạn có chắc chắn muốn xóa danh mục \"\(cat.name)\"?")
                }
            }
        }
    }
    
    // MARK: - Row View
    @ViewBuilder
    private func categoryRow(info: CategoryInfo) -> some View {
        let isEditing = vm.editingCategoryName == info.name
        
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.system(size: 16))
                .foregroundColor(info.deckCount > 0 ? .accentColor : .secondary.opacity(0.5))
                .frame(width: 24)
            
            if isEditing {
                TextField("Tên mới...", text: $vm.editInputName)
                    .textFieldStyle(.roundedBorder)
                    .font(.lexioHeadline)
                    .onSubmit {
                        commitRename(for: info.name)
                    }
                
                Button("Lưu") {
                    commitRename(for: info.name)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("Hủy") {
                    vm.editingCategoryName = nil
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Text(info.name)
                    .font(.lexioHeadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Badges
                HStack(spacing: 6) {
                    Text("\(info.deckCount) bộ thẻ")
                        .font(.lexioCaptionMedium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Capsule())
                    
                    Text("\(info.totalCards) từ")
                        .font(.lexioCaptionMedium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Capsule())
                    
                    if info.dueCards > 0 {
                        Text("\(info.dueCards) cần ôn")
                            .font(.lexioCaptionSemibold)
                            .foregroundColor(.red)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.red.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                
                // Action Buttons
                HStack(spacing: 4) {
                    Button {
                        vm.editingCategoryName = info.name
                        vm.editInputName = info.name
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)
                            .background(Color.primary.opacity(0.04))
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                    .help("Đổi tên danh mục này")
                    
                    Button {
                        let remaining = storage.allCategoryNames.filter { $0 != info.name }
                        vm.fallbackCategory = remaining.first ?? "Chung"
                        vm.categoryToDelete = info
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.red.opacity(0.8))
                            .frame(width: 24, height: 24)
                            .background(Color.red.opacity(0.06))
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                    .help("Xóa danh mục")
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 0.8)
                )
        )
    }
    
    // MARK: - Actions
    private func addNewCategory() {
        let trimmed = vm.newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        storage.createCategory(named: trimmed)
        vm.newCategoryName = ""
    }
    
    private func commitRename(for oldName: String) {
        let trimmed = vm.editInputName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            vm.editingCategoryName = nil
            return
        }
        storage.renameCategory(from: oldName, to: trimmed)
        vm.editingCategoryName = nil
    }
}
