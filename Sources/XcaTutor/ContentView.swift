import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            SidebarView(selectedTab: $appState.selectedTab)
                .frame(minWidth: 200)
            
            // Default view
            HomeView()
        }
        .sheet(isPresented: $appState.showSceneSelection) {
            SceneSelectionView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .sheet(item: $appState.currentConversation) { conversation in
            PracticeView(conversation: conversation)
                .frame(minWidth: 900, minHeight: 700)
        }
    }
}

// MARK: - Sidebar
struct SidebarView: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Xca Tutor")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            Divider()
            
            SidebarButton(icon: "house.fill", title: "首页", tab: .home, selectedTab: $selectedTab)
            SidebarButton(icon: "book.fill", title: "场景", tab: .scenes, selectedTab: $selectedTab)
            SidebarButton(icon: "bookmark.fill", title: "错题本", tab: .mistakeBook, selectedTab: $selectedTab)
            SidebarButton(icon: "chart.bar.fill", title: "学习统计", tab: .stats, selectedTab: $selectedTab)
            
            Spacer()
            
            Divider()
            
            Button {
                // Show settings
            } label: {
                Label("设置", systemImage: "gear")
                    .padding()
            }
            .buttonStyle(.plain)
        }
    }
}

struct SidebarButton: View {
    let icon: String
    let title: String
    let tab: Tab
    @Binding var selectedTab: Tab
    
    var isSelected: Bool {
        selectedTab == tab
    }
    
    var body: some View {
        Button {
            selectedTab = tab
        } label: {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(title)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }
}
