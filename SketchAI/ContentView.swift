//
//  ContentView.swift
//  SketchAI
//
//  Created by Kevin Fred  on 20/10/24.
//
import SwiftUI
import PencilKit

struct LogoView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SketchAI")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("empowering digital artists")
                    .font(.system(size: 12, weight: .light, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(height: 60)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
class CanvasManager: ObservableObject {
    @Published var canvasView: PKCanvasView
    @Published var drawing: PKDrawing // Removed private(set)
    private var toolPicker: PKToolPicker?
    
    init() {
        self.canvasView = PKCanvasView()
        self.drawing = PKDrawing()
        setupCanvas()
    }
    
    private func setupCanvas() {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .white
        canvasView.maximumZoomScale = 1.0
        canvasView.minimumZoomScale = 1.0
        canvasView.drawing = drawing
    }
    
    var canUndo: Bool {
        canvasView.undoManager?.canUndo ?? false
    }
    
    var canRedo: Bool {
        canvasView.undoManager?.canRedo ?? false
    }
    
    func setupToolPicker() {
        toolPicker = PKToolPicker()
        toolPicker?.setVisible(true, forFirstResponder: canvasView)
        toolPicker?.addObserver(canvasView)
        
        DispatchQueue.main.async {
            self.canvasView.becomeFirstResponder()
        }
    }
    
    func updateColor(_ color: Color) {
        DispatchQueue.main.async {
            self.canvasView.tool = PKInkingTool(.pen, color: UIColor(color), width: 1.0)
        }
    }
    
    func undo() {
        DispatchQueue.main.async {
            self.canvasView.undoManager?.undo()
            self.drawing = self.canvasView.drawing
        }
    }
    
    func redo() {
        DispatchQueue.main.async {
            self.canvasView.undoManager?.redo()
            self.drawing = self.canvasView.drawing
        }
    }
    
    func clearCanvas() {
        DispatchQueue.main.async {
            self.drawing = PKDrawing()
            self.canvasView.drawing = self.drawing
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
        canvas.maximumZoomScale = 1.0
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

struct ContentView: View {
    @StateObject private var canvasManager = CanvasManager()
    @State private var selectedColor: Color = .black
    @State private var showingColorPicker = false
    
    var body: some View {
        ZStack {
            CanvasView(canvasManager: canvasManager)
                .ignoresSafeArea()
                .onAppear {
                    canvasManager.setupToolPicker()
                }
            
            VStack {
                LogoView()
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: { showingColorPicker.toggle() }) {
                        Circle()
                            .fill(selectedColor)
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(radius: 2)
                    }
                    
                    Divider()
                        .frame(height: 30)
                        .background(Color.white)
                    
                    Button(action: canvasManager.undo) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .disabled(!canvasManager.canUndo)
                    
                    Button(action: canvasManager.redo) {
                        Image(systemName: "arrow.uturn.forward.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .disabled(!canvasManager.canRedo)
                    
                    Divider()
                        .frame(height: 30)
                        .background(Color.white)
                    
                    Button(action: canvasManager.clearCanvas) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .shadow(radius: 10)
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerView(selectedColor: $selectedColor)
        }
        .onChange(of: selectedColor) { newColor in
            canvasManager.updateColor(newColor)
        }
    }
}

struct ColorPickerView: View {
    @Binding var selectedColor: Color
    @Environment(\.dismiss) var dismiss
    
    let colors: [[Color]] = [
        [.black, .gray, .white],
        [.red, .orange, .yellow],
        [.green, .blue, .purple],
        [.pink, .brown, .mint]
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ForEach(colors, id: \.self) { row in
                    HStack(spacing: 20) {
                        ForEach(row, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .stroke(color == selectedColor ? Color.blue : Color.clear, lineWidth: 3)
                                )
                                .shadow(radius: 2)
                                .onTapGesture {
                                    selectedColor = color
                                    dismiss()
                                }
                        }
                    }
                }
                
                ColorPicker("Custom Color", selection: $selectedColor)
                    .padding()
            }
            .padding()
            .navigationTitle("Select Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
