//
//  ContentView.swift
//  SketchAI
//
//  Created by Kevin Fred  on 20/10/24.
//

import SwiftUI
import PencilKit
import UniformTypeIdentifiers

// MARK: - Logo View (Existing)
struct LogoView: View {
    @State private var isAnimating = false
    let idiom: UIUserInterfaceIdiom
    
    private let gradientColors = [
        Color(red: 0.94, green: 0.42, blue: 0.84),  // Vibrant Pink (#F06BD6)
        Color(red: 0.47, green: 0.29, blue: 0.98),  // Electric Purple (#784BFA)
        Color(red: 0.24, green: 0.71, blue: 0.96)   // Bright Blue (#3DB6F5)
    ]
    
    init(idiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) {
        self.idiom = idiom
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Logo Symbol
            ZStack {
                // Animated background circles
                ForEach(0..<3) { index in
                    Circle()
                        .fill(
                            AngularGradient(
                                gradient: Gradient(colors: gradientColors),
                                center: .center
                            )
                        )
                        .frame(width: idiom == .pad ? 50 : 40, height: idiom == .pad ? 50 : 40)
                        .offset(x: isAnimating ? 2 : -2, y: isAnimating ? -2 : 2)
                        .animation(
                            Animation.easeInOut(duration: 2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.3),
                            value: isAnimating
                        )
                }
                
                // Pencil icon
                Image(systemName: "pencil.tip")
                    .font(.system(size: idiom == .pad ? 30 : 24, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 8)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
            .frame(width: idiom == .pad ? 60 : 50, height: idiom == .pad ? 60 : 50)
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                // App name with modern gradient
                Text("SketchAI")
                    .font(.system(size: idiom == .pad ? 34 : 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                // Tagline with glass effect
                Text("Empowering Digital Artists")
                    .font(.system(size: idiom == .pad ? 14 : 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.2))
                            .blur(radius: 0.5)
                    )
            }
            
            Spacer()
            
            // iPad-specific additional controls
            if idiom == .pad {
                HStack(spacing: 20) {
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "gear")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal, idiom == .pad ? 30 : 20)
        .padding(.vertical, idiom == .pad ? 15 : 10)
        .background(
            ZStack {
                // Dynamic background with more vibrant dark gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.13, green: 0.13, blue: 0.28),  // Rich Dark Blue (#212147)
                        Color(red: 0.08, green: 0.08, blue: 0.20)   // Deep Dark Blue (#14143C)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Enhanced pattern overlay
                GeometryReader { geometry in
                    Path { path in
                        for i in stride(from: 0, to: geometry.size.width, by: 20) {
                            path.move(to: CGPoint(x: i, y: 0))
                            path.addLine(to: CGPoint(x: i + 10, y: geometry.size.height))
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.94, green: 0.42, blue: 0.84).opacity(0.1),  // Pink glow
                                Color(red: 0.24, green: 0.71, blue: 0.96).opacity(0.05)  // Blue glow
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.94, green: 0.42, blue: 0.84).opacity(0.3),  // Pink highlight
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Canvas Manager (Enhanced)
class CanvasManager: ObservableObject {
    @Published var canvasView: PKCanvasView
    @Published var drawing: PKDrawing
    @Published var selectedTool: Tool = .brush
    private var toolPicker: PKToolPicker?
    
    init() {
        self.canvasView = PKCanvasView()
        self.drawing = PKDrawing()
        setupCanvas()
    }
    
    private func setupCanvas() {
        canvasView.drawingPolicy = .pencilOnly // Changed to pencilOnly
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
    
    func updateTool(_ tool: Tool) {
        selectedTool = tool
        // Implement tool-specific settings
    }
}

// MARK: - Canvas View (Enhanced)
struct CanvasView: UIViewRepresentable {
    @ObservedObject var canvasManager: CanvasManager
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = canvasManager.canvasView
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .pencilOnly // Changed to pencilOnly
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


// MARK: - Tool Management
enum Tool: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    // Drawing Tools
    case brush = "Brush"
    case pencil = "Pencil"
    case pen = "Pen"
    case eraser = "Eraser"
    case fill = "Fill"
    
    // Selection Tools
    case rectangleSelect = "Rectangle Select"
    case ellipseSelect = "Ellipse Select"
    case lassoSelect = "Lasso Select"
    case magicWand = "Magic Wand"
    
    // Shape Tools
    case rectangle = "Rectangle"
    case circle = "Circle"
    case line = "Line"
    case polygon = "Polygon"
    case star = "Star"
    
    // Effect Tools
    case blur = "Blur"
    case sharpen = "Sharpen"
    case smudge = "Smudge"
    case clone = "Clone"
    
    // Utility Tools
    case move = "Move"
    case text = "Text"
    case eyedropper = "Eyedropper"
    case hand = "Hand"
    case zoom = "Zoom"
    
    var icon: String {
        switch self {
        case .brush: return "paintbrush.pointed.fill"
        case .pencil: return "pencil"
        case .pen: return "pencil.tip"
        case .eraser: return "eraser.fill"
        case .fill: return "paintbrush.fill"
        case .rectangleSelect: return "selection"
        case .ellipseSelect: return "circle.dotted"
        case .lassoSelect: return "lasso"
        case .magicWand: return "wand.and.stars"
        case .rectangle: return "rectangle"
        case .circle: return "circle"
        case .line: return "line.diagonal"
        case .polygon: return "hexagon"
        case .star: return "star"
        case .blur: return "blur"
        case .sharpen: return "diamond.fill"
        case .smudge: return "hand.draw.fill"
        case .clone: return "stamp"
        case .move: return "arrow.up.and.down.and.arrow.left.and.right"
        case .text: return "text.cursor"
        case .eyedropper: return "eyedropper.halffull"
        case .hand: return "hand.raised"
        case .zoom: return "magnifyingglass"
        }
    }
    
    var group: ToolGroup {
        switch self {
        case .brush, .pencil, .pen, .eraser, .fill:
            return .drawing
        case .rectangleSelect, .ellipseSelect, .lassoSelect, .magicWand:
            return .selection
        case .rectangle, .circle, .line, .polygon, .star:
            return .shape
        case .blur, .sharpen, .smudge, .clone:
            return .effect
        case .move, .text, .eyedropper, .hand, .zoom:
            return .utility
        }
    }
}

enum ToolGroup: String, CaseIterable {
    case drawing = "Drawing"
    case selection = "Selection"
    case shape = "Shape"
    case effect = "Effect"
    case utility = "Utility"
}

// MARK: - Layer Management
struct Layer: Identifiable {
    let id = UUID()
    var name: String
    var isVisible: Bool = true
    var opacity: Double = 1.0
    var drawing: PKDrawing = PKDrawing()
    var blendMode: LayerBlendMode = .normal
    var isLocked: Bool = false
    var type: LayerType
}

enum LayerType {
    case drawing
    case image(UIImage?)
    case shape(ShapeType)
    case text(String)
    case adjustment(AdjustmentType)
}

enum LayerBlendMode {
    case normal, multiply, screen, overlay, softLight, hardLight
}

enum AdjustmentType {
    case brightness, contrast, saturation, exposure
}

enum ShapeType {
    case rectangle, circle, triangle, line, polygon, star
}

class LayerManager: ObservableObject {
    @Published var layers: [Layer] = []
    @Published var selectedLayerIndex: Int = 0
    
    init() {
        // Add initial background layer
        addLayer(name: "Background", type: .drawing)
    }
    
    func addLayer(name: String, type: LayerType) {
        layers.append(Layer(name: name, type: type))
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
    
    func toggleLock(at index: Int) {
        layers[index].isLocked.toggle()
    }
    
    func updateOpacity(at index: Int, opacity: Double) {
        layers[index].opacity = opacity
    }
    
    func updateBlendMode(at index: Int, blendMode: LayerBlendMode) {
        layers[index].blendMode = blendMode
    }
}

// MARK: - Tool Settings View
struct ToolSettingsView: View {
    @ObservedObject var toolManager: ToolManager
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Size")
                Slider(value: $toolManager.brushSize, in: 1...100)
            }
            
            HStack {
                Text("Opacity")
                Slider(value: $toolManager.opacity, in: 0...1)
            }
            
            HStack {
                Text("Color")
                ColorPicker("", selection: $toolManager.color)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Enhanced Toolbar View
struct EnhancedToolbarView: View {
    @ObservedObject var toolManager: ToolManager
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(ToolGroup.allCases, id: \.self) { group in
                        GroupBox(
                            label: Text(group.rawValue)
                                .font(.caption)
                                .foregroundColor(.gray)
                        ) {
                            LazyVGrid(columns: [GridItem(.flexible())], spacing: 4) {
                                ForEach(Tool.allCases.filter { $0.group == group }) { tool in
                                    ToolButton(
                                        tool: tool,
                                        isSelected: toolManager.selectedTool == tool,
                                        action: {
                                            toolManager.selectedTool = tool
                                            if tool.group == .drawing {
                                                showingSettings = true
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            if showingSettings {
                ToolSettingsView(toolManager: toolManager)
            }
        }
        .frame(width: 80)
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Layer Panel View
struct LayerPanelView: View {
    @ObservedObject var layerManager: LayerManager
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Layers")
                    .font(.headline)
                Spacer()
                Button(action: { addNewLayer() }) {
                    Image(systemName: "plus")
                }
            }
            .padding()
            
            List {
                ForEach(Array(layerManager.layers.enumerated()), id: \.1.id) { index, layer in
                    LayerRowView(
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
    }
    
    private func addNewLayer() {
        layerManager.addLayer(name: "Layer \(layerManager.layers.count + 1)", type: .drawing)
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var canvasManager = CanvasManager()
    @StateObject private var layerManager = LayerManager()
    @StateObject private var toolManager = ToolManager()
    @State private var showingLayers = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        NavigationView {
            HStack(spacing: 0) {
                // Left Toolbar
                EnhancedToolbarView(toolManager: toolManager)
                    .onChange(of: toolManager.selectedTool) { tool in
                        canvasManager.updateTool(tool)
                    }
                
                // Main Canvas
                ZStack {
                    CanvasView(canvasManager: canvasManager)
                        .ignoresSafeArea()
                        .onAppear {
                            canvasManager.setupToolPicker()
                        }
                    
                    VStack {
                        LogoView(idiom: UIDevice.current.userInterfaceIdiom)
                        Spacer()
                    }
                }
                
                // Right Layer Panel (iPad only)
                if horizontalSizeClass == .regular {
                    LayerPanelView(layerManager: layerManager)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if horizontalSizeClass != .regular {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingLayers.toggle() }) {
                            Image(systemName: "square.on.square")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingLayers) {
            NavigationView {
                LayerPanelView(layerManager: layerManager)
                    .navigationTitle("Layers")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showingLayers = false }
                        }
                    }
            }
        }
    }
}

// MARK: - Supporting Views and Classes
class ToolManager: ObservableObject {
    @Published var selectedTool: Tool = .brush
    @Published var brushSize: Double = 1.0
    @Published var opacity: Double = 1.0
    @Published var color: Color = .black
}

struct ToolButton: View {
    let tool: Tool
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
            .frame(width: 60, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            )
        }
    }
}

struct LayerRowView: View {
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
                set: { onUpdateOpacity($0) }
            ), in: 0...1)
            .frame(width: 80)
        }
        .padding(.vertical, 4)
        .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
        .cornerRadius(6)
        .onTapGesture(perform: onSelect)
    }
}
