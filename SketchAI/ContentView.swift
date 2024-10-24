//
//  ContentView.swift
//  SketchAI
//
//  Created by Kevin Fred  on 20/10/24.
//
import SwiftUI
import PencilKit



// MARK: - Canvas Manager
class CanvasManager: ObservableObject {
    @Published var canvasView: PKCanvasView
    @Published var drawing: PKDrawing
    private var toolPicker: PKToolPicker?
    
    init() {
        self.canvasView = PKCanvasView()
        self.drawing = PKDrawing()
        setupCanvas()
    }
    
    private func setupCanvas() {
        canvasView.drawingPolicy = .pencilOnly
        canvasView.backgroundColor = .white
        canvasView.maximumZoomScale = 5.0
        canvasView.minimumZoomScale = 1.0
        canvasView.drawing = drawing
    }
    
    func setupToolPicker() {
        toolPicker = PKToolPicker()
        toolPicker?.setVisible(true, forFirstResponder: canvasView)
        toolPicker?.addObserver(canvasView)
        
        DispatchQueue.main.async {
            self.canvasView.becomeFirstResponder()
        }
    }
    
    func toggleToolPicker(isVisible: Bool) {
        toolPicker?.setVisible(isVisible, forFirstResponder: canvasView)
    }
}

// MARK: - Canvas View
struct CanvasView: UIViewRepresentable {
    @ObservedObject var canvasManager: CanvasManager
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = canvasManager.canvasView
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .pencilOnly
        canvas.backgroundColor = .white
        canvas.maximumZoomScale = 5.0
        canvas.minimumZoomScale = 1.0
        canvas.drawing = canvasManager.drawing
        return canvas
    }
    
    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        if canvasView.drawing != canvasManager.drawing {
            DispatchQueue.main.async {
                canvasView.drawing = canvasManager.drawing
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasView
        
        init(_ parent: CanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            DispatchQueue.main.async {
                self.parent.canvasManager.drawing = canvasView.drawing
            }
        }
    }
}

// MARK: - Layer Management
struct Layer: Identifiable {
    let id = UUID()
    var name: String
    var isVisible: Bool = true
    var opacity: Double = 1.0
    var drawing: PKDrawing = PKDrawing()
}

class LayerManager: ObservableObject {
    @Published var layers: [Layer] = []
    @Published var selectedLayerIndex: Int = 0
    
    init() {
        addLayer(name: "Background")
    }
    
    func addLayer(name: String) {
        layers.append(Layer(name: name))
        selectedLayerIndex = layers.count - 1
    }
    
    func removeLayer(at index: Int) {
        guard layers.count > 1 else { return }
        layers.remove(at: index)
        selectedLayerIndex = max(0, selectedLayerIndex - 1)
    }
    
    func moveLayers(from source: IndexSet, to destination: Int) {
        layers.move(fromOffsets: source, toOffset: destination)
    }
    
    func toggleVisibility(at index: Int) {
        layers[index].isVisible.toggle()
    }
    
    func updateOpacity(at index: Int, opacity: Double) {
        layers[index].opacity = opacity
    }
}

// MARK: - Art Tools
enum ArtTool: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    case brush = "Brush"
    case pencil = "Pencil"
    case eraser = "Eraser"
    case smudge = "Smudge"
    case eyedropper = "Color Picker"
    case selection = "Selection"
    case move = "Move"
    case crop = "Crop"
    case shapes = "Shapes"
    case text = "Text"
    case gradient = "Gradient"
    case bucket = "Fill"
    case blend = "Blend"
    case ruler = "Ruler"
    case symmetry = "Symmetry"
    
    var icon: String {
        switch self {
        case .brush: return "paintbrush"
        case .pencil: return "pencil.tip"
        case .eraser: return "eraser"
        case .smudge: return "hand.draw"
        case .eyedropper: return "eyedropper.halffull"
        case .selection: return "lasso"
        case .move: return "arrow.up.and.down.and.arrow.left.and.right"
        case .crop: return "crop"
        case .shapes: return "square.on.circle"
        case .text: return "textformat"
        case .gradient: return "gradient"
        case .bucket: return "paintbrush.fill"
        case .blend: return "drop.fill"
        case .ruler: return "ruler"
        case .symmetry: return "arrow.left.and.right.circle"
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    @Binding var symmetryEnabled: Bool
    @Binding var symmetryValue: Double
    let canUndo: Bool
    let canRedo: Bool
    let onUndo: () -> Void
    let onRedo: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
            
            // Content
            HStack(spacing: 16) {
                // Back button
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                        .font(.system(size: 18, weight: .medium))
                }
                
                Divider()
                    .frame(height: 24)
                
                // Symmetry Controls
                Menu {
                    Button("Vertical Symmetry", action: { symmetryEnabled.toggle() })
                    Button("Horizontal Symmetry", action: { symmetryEnabled.toggle() })
                    Button("Radial Symmetry", action: { symmetryEnabled.toggle() })
                } label: {
                    HStack(spacing: 4) {
                        Text("Symmetry")
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.primary)
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                
                Slider(value: $symmetryValue, in: 0...100)
                    .frame(width: 120)
                
                Text("\(Int(symmetryValue))%")
                    .monospacedDigit()
                    .foregroundColor(.primary)
                    .frame(width: 44, alignment: .leading)
                
                Spacer()
                
                // Right side controls
                HStack(spacing: 20) {
                    Button(action: onUndo) {
                        Image(systemName: "arrow.uturn.backward")
                            .foregroundColor(canUndo ? .primary : .primary.opacity(0.3))
                    }
                    .disabled(!canUndo)
                    
                    Button(action: onRedo) {
                        Image(systemName: "arrow.uturn.forward")
                            .foregroundColor(canRedo ? .primary : .primary.opacity(0.3))
                    }
                    .disabled(!canRedo)
                    
                    Button(action: {}) {
                        Image(systemName: "questionmark.circle")
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "person.circle")
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "gearshape")
                    }
                }
                .foregroundColor(.primary)
                .font(.system(size: 18))
            }
            .padding(.horizontal)
            .frame(height: 44)
        }
        .frame(height: 44)
    }
}

// MARK: - Enhanced Tool Bar
struct CollapsibleToolBar: View {
    @Binding var selectedTool: ArtTool
    @Binding var isToolBarVisible: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            if isToolBarVisible {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(ArtTool.allCases) { tool in
                            ToolButton(tool: tool, isSelected: selectedTool == tool) {
                                selectedTool = tool
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(width: 72)
                .background(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 5)
            }
            
            Button(action: { withAnimation { isToolBarVisible.toggle() } }) {
                Image(systemName: isToolBarVisible ? "chevron.left" : "chevron.right")
                    .foregroundColor(.primary)
                    .frame(width: 20, height: 44)
                    .background(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .shadow(radius: 3)
            }
            .padding(.leading, 4)
        }
        .padding(.leading, 8)
    }
}

// MARK: - Tool Button
struct ToolButton: View {
    let tool: ArtTool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tool.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .blue : .primary)
                
                Text(tool.rawValue)
                    .font(.system(size: 9))
                    .foregroundColor(isSelected ? .blue : .primary)
            }
            .frame(width: 60, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            )
        }
    }
}


// MARK: - Layer Panel
struct LayerPanelView: View {
    @ObservedObject var layerManager: LayerManager
    @Binding var isVisible: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            if isVisible {
                VStack {
                    HStack {
                        Text("Layers")
                            .font(.headline)
                        Spacer()
                        Button(action: { layerManager.addLayer(name: "Layer \(layerManager.layers.count + 1)") }) {
                            Image(systemName: "plus")
                        }
                    }
                    .padding()
                    
                    List {
                        ForEach(Array(layerManager.layers.enumerated()), id: \.element.id) { index, layer in
                            LayerRow(
                                layer: layer,
                                isSelected: index == layerManager.selectedLayerIndex,
                                onSelect: { layerManager.selectedLayerIndex = index },
                                onToggleVisibility: { layerManager.toggleVisibility(at: index) },
                                onUpdateOpacity: { layerManager.updateOpacity(at: index, opacity: $0) }
                            )
                        }
                        .onMove { layerManager.moveLayers(from: $0, to: $1) }
                    }
                }
                .frame(width: 250)
                .background(Color(UIColor.systemBackground))
            }
            
            Button(action: { withAnimation { isVisible.toggle() } }) {
                Image(systemName: isVisible ? "chevron.right" : "chevron.left")
                    .foregroundColor(.primary)
                    .frame(width: 20, height: 44)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .shadow(radius: 3)
            }
        }
        .padding(.trailing, 8)
    }
}

struct LayerRow: View {
    let layer: Layer
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleVisibility: () -> Void
    let onUpdateOpacity: (Double) -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggleVisibility) {
                Image(systemName: layer.isVisible ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(layer.isVisible ? .primary : .gray)
            }
            
            Text(layer.name)
                .lineLimit(1)
            
            Slider(value: Binding(
                get: { layer.opacity },
                set: onUpdateOpacity
            ), in: 0...1)
            .frame(width: 80)
        }
        .padding(.vertical, 4)
        .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
        .onTapGesture(perform: onSelect)
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var canvasManager = CanvasManager()
    @StateObject private var layerManager = LayerManager()
    @State private var selectedTool: ArtTool = .brush
    @State private var isToolBarVisible = true
    @State private var isLayerPanelVisible = true
    @State private var isPencilKitToolPickerVisible = true
    
    // Header states
    @State private var symmetryEnabled = false
    @State private var symmetryValue: Double = 63
    
    var body: some View {
        VStack(spacing: 0) {
            // Status Bar spacer
            Color.clear
                .frame(height: UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)
            
            // Header
            HeaderView(
                symmetryEnabled: $symmetryEnabled,
                symmetryValue: $symmetryValue,
                canUndo: canvasManager.canvasView.undoManager?.canUndo ?? false,
                canRedo: canvasManager.canvasView.undoManager?.canRedo ?? false,
                onUndo: { canvasManager.canvasView.undoManager?.undo() },
                onRedo: { canvasManager.canvasView.undoManager?.redo() }
            )
            
            // Main Content
            HStack(spacing: 0) {
                // Left Toolbar
                CollapsibleToolBar(
                    selectedTool: $selectedTool,
                    isToolBarVisible: $isToolBarVisible
                )
                
                // Main Canvas
                ZStack {
                    CanvasView(canvasManager: canvasManager)
                        .ignoresSafeArea(edges: [.leading, .trailing, .bottom])
                        .onAppear {
                            canvasManager.setupToolPicker()
                        }
                    
                    // PencilKit Tool Picker Toggle
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    isPencilKitToolPickerVisible.toggle()
                                    canvasManager.toggleToolPicker(isVisible: isPencilKitToolPickerVisible)
                                }
                            }) {
                                Image(systemName: isPencilKitToolPickerVisible ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.primary)
                                    .padding(8)
                                    .background(Color(UIColor.systemBackground))
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                            .padding()
                        }
                        Spacer()
                    }
                }
                
                // Right Layer Panel
                LayerPanelView(
                    layerManager: layerManager,
                    isVisible: $isLayerPanelVisible
                )
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
