import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $appState.selectedTab)
                .frame(minWidth: 200)
        } detail: {
            switch appState.selectedTab {
            case .home:
                HomeView()
            case .scenes:
                SceneSelectionView()
            case .mistakeBook:
                MistakeBookView()
            case .stats:
                StatisticsView()
            }
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
        List(selection: $selectedTab) {
            NavigationLink(value: Tab.home) {
                Label("首页", systemImage: "house.fill")
            }
            
            NavigationLink(value: Tab.scenes) {
                Label("场景", systemImage: "book.fill")
            }
            
            NavigationLink(value: Tab.mistakeBook) {
                Label("错题本", systemImage: "bookmark.fill")
            }
            
            NavigationLink(value: Tab.stats) {
                Label("学习统计", systemImage: "chart.bar.fill")
            }
            
            Divider()
            
            Button {
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            } label: {
                Label("设置", systemImage: "gear")
            }
            .buttonStyle(.plain)
        }
        .listStyle(.sidebar)
        .navigationTitle("Xca Tutor")
    }
}
