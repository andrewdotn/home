import SwiftUI

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context _: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = NSVisualEffectView.State.active
        return visualEffectView
    }

    func updateNSView(_ visualEffectView: NSVisualEffectView, context _: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

struct ContentView: View {
    @EnvironmentObject var appData: AppData

    var body: some View {
        Text($appData.text.wrappedValue)
            .fontWeight(.thin)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(VisualEffectView(material: .fullScreenUI, blendingMode: .behindWindow))
            .contextMenu {
                Button("Quit") {
                    exit(0)
                }
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let appData = AppData()
        appData.text = "hello"

        return ContentView().environmentObject(appData)
    }
}
