import Foundation

@MainActor
final class ChildProfileService: ObservableObject {
    static let shared = ChildProfileService()

    @Published private(set) var children: [Child] = []
    @Published private(set) var activeChild: Child?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    private let apiClient: APIClient
    private let activeChildKey = "active_child_id"

    private init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
        restoreActiveChild()
    }

    // MARK: - Public Methods

    func fetchChildren() async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let response: ChildrenResponse = try await apiClient.get("/children", requiresAuth: true)
        children = response.children

        // Restore active child if it still exists
        if let activeId = UserDefaults.standard.string(forKey: activeChildKey),
           let child = children.first(where: { $0.id == activeId }) {
            activeChild = child
        } else if activeChild != nil {
            // Active child no longer exists
            activeChild = nil
            UserDefaults.standard.removeObject(forKey: activeChildKey)
        }
    }

    func createChild(_ request: CreateChildRequest) async throws -> Child {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let response: ChildResponse = try await apiClient.post("/children", body: request, requiresAuth: true)
        children.append(response.child)

        // Auto-select if first child
        if children.count == 1 {
            setActiveChild(response.child)
        }

        return response.child
    }

    func updateChild(id: String, _ updates: UpdateChildRequest) async throws -> Child {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let response: ChildResponse = try await apiClient.put("/children/\(id)", body: updates, requiresAuth: true)

        if let index = children.firstIndex(where: { $0.id == id }) {
            children[index] = response.child
        }

        // Update active child if it was the one modified
        if activeChild?.id == id {
            activeChild = response.child
        }

        return response.child
    }

    func deleteChild(id: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        try await apiClient.delete("/children/\(id)", requiresAuth: true)
        children.removeAll { $0.id == id }

        // Clear active child if it was deleted
        if activeChild?.id == id {
            activeChild = nil
            UserDefaults.standard.removeObject(forKey: activeChildKey)
        }
    }

    func setActiveChild(_ child: Child?) {
        activeChild = child
        if let child = child {
            UserDefaults.standard.set(child.id, forKey: activeChildKey)
        } else {
            UserDefaults.standard.removeObject(forKey: activeChildKey)
        }
    }

    // MARK: - Private Methods

    private func restoreActiveChild() {
        // Note: Active child is fully restored after fetchChildren() is called
        // This just prepares the stored ID for restoration
    }
}

// Response types are defined in APIModels.swift
