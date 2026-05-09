import SwiftUI

struct ContentView: View {
    @Bindable var session: TranslationSessionStore

    var body: some View {
        NavigationSplitView {
            SidebarView(session: session)
                .navigationSplitViewColumnWidth(min: 240, ideal: 260, max: 300)
        } detail: {
            CaptionBoardView(session: session)
        }
    }
}
