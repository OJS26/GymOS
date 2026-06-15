import SwiftUI
import WebKit

// MARK: - Body Map View
struct BodyMapView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingAddToWorkout = false
    @State private var selectedExerciseName = ""
    
    var body: some View {
        NavigationView {
            VStack {
                MuscleWikiWebView(onExerciseSelected: { exerciseName in
                    selectedExerciseName = exerciseName
                    showingAddToWorkout = true
                })
                
                // Quick add button (if in active workout)
                if workoutManager.currentWorkout != nil {
                    Text("Tap any exercise on MuscleWiki to add it to your current workout")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .navigationTitle("Exercise Guide")
            .alert("Add to Workout", isPresented: $showingAddToWorkout) {
                if workoutManager.currentWorkout != nil {
                    Button("Add to Current Workout") {
                        // Add logic to create exercise from name
                        addExerciseFromName(selectedExerciseName)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Add \(selectedExerciseName) to your workout?")
            }
        }
    }
    
    private func addExerciseFromName(_ name: String) {
        // Find existing exercise or create new one
        if let existingExercise = workoutManager.availableExercises.first(where: { $0.name.lowercased().contains(name.lowercased()) }) {
            workoutManager.addExercise(existingExercise)
        } else {
            // Create new custom exercise
            let newExercise = Exercise(name: name, category: .chest, muscleGroups: ["Unknown"], isCustom: true)
            workoutManager.availableExercises.append(newExercise)
            workoutManager.addExercise(newExercise)
        }
    }
}

// MARK: - WebView for MuscleWiki
struct MuscleWikiWebView: UIViewRepresentable {
    let onExerciseSelected: (String) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        if let url = URL(string: "https://musclewiki.com") {
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: MuscleWikiWebView
        
        init(_ parent: MuscleWikiWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            if let url = navigationAction.request.url?.absoluteString {
                // Detect when user clicks on an exercise
                if url.contains("exercises") {
                    // Extract exercise name from URL or page title
                    webView.evaluateJavaScript("document.title") { result, error in
                        if let title = result as? String {
                            self.parent.onExerciseSelected(title)
                        }
                    }
                }
            }
            
            decisionHandler(.allow)
        }
    }
}

#Preview {
    BodyMapView()
        .environmentObject(WorkoutManager())
}
