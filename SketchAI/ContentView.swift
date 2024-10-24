//
//  ContentView.swift
//  SketchAI
//
//  Created by Kevin Fred  on 20/10/24.
//
import SwiftUI
import PencilKit


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
        canvasView.drawingPolicy = .anyInput
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
}

struct CanvasView: UIViewRepresentable {
    @ObservedObject var canvasManager: CanvasManager
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = canvasManager.canvasView
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .white
        canvas.maximumZoomScale = 5.0
        canvas.minimumZoomScale = 1.0
        canvas.drawing = canvasManager.drawing
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            canvas.allowsFingerDrawing = true
        }
        
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

struct ContentView: View {
    @StateObject private var canvasManager = CanvasManager()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro"))
                .previewDisplayName("iPhone 14 Pro")
            
            ContentView()
                .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (6th generation)"))
                .previewDisplayName("iPad Pro 12.9\"")
        }
    }
}
