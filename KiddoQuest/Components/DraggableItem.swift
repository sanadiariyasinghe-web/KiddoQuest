import SwiftUI

// MARK: - Reusable DraggableItem Component
// Drag-and-drop component with finger following, scale lift, magnetic snapping,
// and smooth spring return for incorrect drops.

struct DraggableItem<Content: View>: View {
    let id: String
    var isEnabled: Bool = true
    var onDropAttempt: ((CGPoint, CGSize) -> Bool)? = nil
    var onSuccess: (() -> Void)? = nil
    var onFail: (() -> Void)? = nil
    @ViewBuilder let content: () -> Content
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var isSnapped: Bool = false
    
    var body: some View {
        content()
            .scaleEffect(isDragging ? 1.08 : (isSnapped ? 1.0 : 1.0))
            .shadow(
                color: isDragging ? Color.black.opacity(0.2) : Color.clear,
                radius: isDragging ? 12 : 0,
                y: isDragging ? 8 : 0
            )
            .offset(dragOffset)
            .opacity(isSnapped ? 0.6 : 1.0)
            .gesture(
                dragGesture
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: dragOffset)
    }
    
    private var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                guard isEnabled && !isSnapped else { return }
                isDragging = true
                dragOffset = value.translation
            }
            .onEnded { value in
                guard isEnabled && !isSnapped else { return }
                isDragging = false
                
                let success = onDropAttempt?(value.location, value.translation) ?? false
                if success {
                    isSnapped = true
                    onSuccess?()
                } else {
                    // Smooth return with gentle spring bounce
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        dragOffset = .zero
                    }
                    onFail?()
                }
            }
    }
}
