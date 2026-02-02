import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("L2RR2L")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Learn to Read, Read to Learn")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
