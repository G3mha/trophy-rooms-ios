import Foundation

extension AdminGamesViewModel {
    var canGoNext: Bool {
        currentPage < totalPages && !isLoading
    }

    var canGoPrevious: Bool {
        currentPage > 1 && !isLoading
    }

    func fetchGames(page: Int = 1, search: String? = nil) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let response = try await api.fetchGames(page: page, pageSize: pageSize, search: search)
            DispatchQueue.main.async {
                self.games = response.adminGames.items
                self.currentPage = response.adminGames.page
                self.totalCount = response.adminGames.totalCount
                self.totalPages = response.adminGames.totalPages
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func goToPage(_ page: Int) async {
        guard page >= 1 && page <= totalPages && page != currentPage else { return }
        await fetchGames(page: page, search: searchText.isEmpty ? nil : searchText)
    }

    func goToNextPage() async {
        guard canGoNext else { return }
        await goToPage(currentPage + 1)
    }

    func goToPreviousPage() async {
        guard canGoPrevious else { return }
        await goToPage(currentPage - 1)
    }

    func goToFirstPage() async {
        await goToPage(1)
    }

    func goToLastPage() async {
        await goToPage(totalPages)
    }

    func search() async {
        await fetchGames(page: 1, search: searchText.isEmpty ? nil : searchText)
    }

    func setPageSize(_ newSize: Int) async {
        pageSize = newSize
        await fetchGames(page: 1, search: searchText.isEmpty ? nil : searchText)
    }

    func fetchPlatforms() async {
        do {
            let response = try await api.fetchPlatforms()
            DispatchQueue.main.async {
                self.platforms = response.platforms
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
