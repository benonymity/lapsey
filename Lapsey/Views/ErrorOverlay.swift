import SwiftUI

// Adapted from https://github.com/elai950/AlertToast/blob/master/Sources/AlertToast/AlertToast.swift

private struct AnimatedXmark: View {
    /// X-mark color
    var color: Color = .red

    /// X-mark size
    var size: Int = 50

    var height: CGFloat {
        CGFloat(size)
    }

    var width: CGFloat {
        CGFloat(size)
    }

    @State private var percentage: CGFloat = .zero

    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: width, y: height))
            }
            .trim(from: 0, to: percentage)
            .stroke(color, style: StrokeStyle(lineWidth: CGFloat(size / 8), lineCap: .round, lineJoin: .round))

            Path { path in
                path.move(to: CGPoint(x: 0, y: height))
                path.addLine(to: CGPoint(x: width, y: 0))
            }
            .trim(from: 0, to: percentage)
            .stroke(color, style: StrokeStyle(lineWidth: CGFloat(size / 8), lineCap: .round, lineJoin: .round))
        }
        .animation(Animation.spring().speed(0.75).delay(0.25), value: percentage)
        .onAppear {
            percentage = 1.0
        }
        .frame(width: width, height: height, alignment: .center)
    }
}

private struct ErrorOverlayModifier: ViewModifier {
    @Binding var isPresented: Bool
    let duration: Double
    let text: (() -> Text)?

    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                VStack {
                    AnimatedXmark(color: .red)
                    if let text {
                        text()
                            .padding(.top, 5)
                            .padding(.bottom, 0)
                    }
                }
                .padding(30)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.thickMaterial)
                }
                .transition(.scale(scale: 0.7).combined(with: .opacity))
                .task {
                    try? await Task.sleep(for: .seconds(duration))
                    isPresented = false
                }
            }
        }
        .animation(.spring(duration: 0.3), value: isPresented)
    }
}

extension View {
    func errorOverlay(isPresented: Binding<Bool>, duration: Double = 2, text: (() -> Text)? = nil) -> some View {
        modifier(ErrorOverlayModifier(isPresented: isPresented,
                                      duration: duration, text: text))
    }
}
