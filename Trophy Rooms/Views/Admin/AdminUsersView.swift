import SwiftUI

struct AdminUsersView: View {
    @StateObject private var viewModel = AdminUsersViewModel()
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search users by email or name", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit {
                        Task {
                            await viewModel.searchUsers(query: searchText)
                        }
                    }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        viewModel.users = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if viewModel.users.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        "Search Users",
                        systemImage: "person.2",
                        description: Text("Enter a search term to find users")
                    )
                } else {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "person.slash",
                        description: Text("No users found matching '\(searchText)'")
                    )
                }
            } else {
                List {
                    ForEach(viewModel.filteredUsers) { user in
                        UserRow(user: user, viewModel: viewModel)
                    }
                }
            }
        }
        .navigationTitle("Users & Roles")
        .onChange(of: searchText) { _, newValue in
            // Debounce search
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                if searchText == newValue && !newValue.isEmpty {
                    await viewModel.searchUsers(query: newValue)
                }
            }
        }
    }
}

struct UserRow: View {
    let user: AdminUser
    @ObservedObject var viewModel: AdminUsersViewModel
    @State private var selectedRole: UserRole
    @State private var isUpdating = false

    init(user: AdminUser, viewModel: AdminUsersViewModel) {
        self.user = user
        self.viewModel = viewModel
        _selectedRole = State(initialValue: user.role)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name ?? user.email)
                    .font(.headline)
                if user.name != nil {
                    Text(user.email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isUpdating {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Picker("Role", selection: $selectedRole) {
                    ForEach(UserRole.allCases, id: \.self) { role in
                        Text(role.displayName).tag(role)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedRole) { _, newRole in
                    guard newRole != user.role else { return }
                    isUpdating = true
                    Task {
                        let success = await viewModel.setUserRole(userId: user.id, role: newRole)
                        DispatchQueue.main.async {
                            isUpdating = false
                            if !success {
                                selectedRole = user.role
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        AdminUsersView()
    }
}
