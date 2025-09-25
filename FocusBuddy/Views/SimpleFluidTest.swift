import SwiftUI

struct SimpleFluidTest: View {
    @State private var progress: Double = 0.3

    var body: some View {
        VStack {
            Text("Fluid Animation Test")
                .font(.title)
                .padding()

            ZStack {
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 300)
                    .overlay(
                        Rectangle()
                            .fill(Color.blue.opacity(0.7))
                            .frame(height: 300 * progress)
                            .animation(.easeInOut(duration: 1), value: progress),
                        alignment: .bottom
                    )

                Text("Progress: \(Int(progress * 100))%")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, maxHeight: 300)
            .clipped()

            HStack(spacing: 20) {
                Button("0%") { withAnimation { progress = 0 } }
                Button("25%") { withAnimation { progress = 0.25 } }
                Button("50%") { withAnimation { progress = 0.5 } }
                Button("75%") { withAnimation { progress = 0.75 } }
                Button("100%") { withAnimation { progress = 1.0 } }
            }
            .padding()

            Spacer()
        }
    }
}

#Preview {
    SimpleFluidTest()
}