import SwiftUI
import Combine
import UniformTypeIdentifiers

// MARK: - Models
enum MediaType: String, Codable {
    case text, image, audio, video
}

struct TriviaQuestion: Identifiable, Codable {
    var id = UUID()
    let points: Int
    let category: String
    let questionText: String
    let mediaType: MediaType
    let mediaResourceName: String
    var isAnswered: Bool = false
}

struct Category: Identifiable, Codable {
    var id = UUID()
    let name: String
    var questions: [TriviaQuestion]
}

struct GameState: Codable {
    let categories: [Category]
    let team1Name: String
    let team1Score: Int
    let team2Name: String
    let team2Score: Int
}

// MARK: - View Model
class TriviaGameEngine: ObservableObject {
    @Published var categories: [Category] = []
    @Published var selectedQuestion: TriviaQuestion? = nil
    
    @Published var team1Name: String = "Team 1"
    @Published var team1Score: Int = 0
    
    @Published var team2Name: String = "Team 2"
    @Published var team2Score: Int = 0
    
    @Published var confettiTrigger: Int = 0
    @Published var balloonTrigger: Int = 0
    @Published var heartsTrigger: Int = 0

    
    private var saveFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TriviaGameState.json")
    }
    
    init() {
        setupMockData()
    }
    
    private func setupMockData() {
        let values = [100, 200, 300, 400, 500]
        let names = ["Apple History", "Soundbites", "Space & Sci-Fi", "Geography", "Pop Culture"]
        
        self.categories = names.map { catName in
            let questions = values.map { points in
                let media: MediaType = points == 300 ? .image : (points == 400 ? .audio : (points == 500 ? .video : .text))
                return TriviaQuestion(
                    points: points,
                    category: catName,
                    questionText: "This is a \(points) point question about \(catName).",
                    mediaType: media,
                    mediaResourceName: ""
                )
            }
            return Category(name: catName, questions: questions)
        }
    }
    
    func markAsAnswered(_ question: TriviaQuestion, awardedToTeam: Int?) {
        if let catIndex = categories.firstIndex(where: { $0.name == question.category }),
           let qIndex = categories[catIndex].questions.firstIndex(where: { $0.id == question.id }) {
            
            categories[catIndex].questions[qIndex].isAnswered = true
            
            if awardedToTeam == 1 {
                team1Score += question.points
            } else if awardedToTeam == 2 {
                team2Score += question.points
            }
            
            if awardedToTeam != nil && question.points == 100  {
                confettiTrigger += 1
            }
            
            if question.points == 300 && awardedToTeam != nil {
                balloonTrigger += 1
            }
            
            if question.points == 400 && awardedToTeam != nil {
                heartsTrigger += 1
            }
            
            saveGame()
        }
        selectedQuestion = nil
    }
    
    func saveGame() {
        let currentState = GameState(categories: categories, team1Name: team1Name, team1Score: team1Score, team2Name: team2Name, team2Score: team2Score)
        do {
            let data = try JSONEncoder().encode(currentState)
            try data.write(to: saveFileURL)
        } catch {
            print("Failed to save game state: \(error.localizedDescription)")
        }
    }
    
    func importGame() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.json]
        panel.message = "Select your custom Trivia JSON file"
        
        if panel.runModal() == .OK, let selectedURL = panel.url {
            do {
                let data = try Data(contentsOf: selectedURL)
                let savedState = try JSONDecoder().decode(GameState.self, from: data)
                self.categories = savedState.categories
                self.team1Name = savedState.team1Name
                self.team1Score = savedState.team1Score
                self.team2Name = savedState.team2Name
                self.team2Score = savedState.team2Score
                saveGame()
            } catch {
                print("Failed to load JSON file: \(error.localizedDescription)")
            }
        }
    }
    
    func resetGame() {
        setupMockData()
        team1Name = "Team 1"
        team1Score = 0
        team2Name = "Team 2"
        team2Score = 0
        saveGame()
    }
}

// MARK: - Main Game Board
struct ContentView: View {
    @StateObject private var game = TriviaGameEngine()
    @State private var isShowingSettings = false
    
    let appBackground = Color(nsColor: NSColor(red: 0.024, green: 0.102, blue: 0.137, alpha: 1.0))
    let cardTeal = Color(nsColor: NSColor(red: 0.039, green: 0.576, blue: 0.588, alpha: 1.0))
    let team1Mint = Color(nsColor: NSColor(red: 0.580, green: 0.824, blue: 0.741, alpha: 1.0))
    let headerOverlay = Color.white.opacity(0.1)
    
    var body: some View {
        ZStack {
            appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header Panel
                HStack {
                    Text("Trivia Dashboard")
                        .font(.system(.title, design: .rounded)).bold()
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        // Team 1
                        VStack(spacing: 2) {
                            Text(game.team1Name.uppercased())
                                .font(.caption).bold()
                                .foregroundColor(.black.opacity(0.6))
                            Text("\(game.team1Score)")
                                .font(.title2).bold()
                                .foregroundColor(.black.opacity(0.9))
                        }
                        .frame(minWidth: 80)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(team1Mint))
                        
                        // Team 2
                        VStack(spacing: 2) {
                            Text(game.team2Name.uppercased())
                                .font(.caption).bold()
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(game.team2Score)")
                                .font(.title2).bold()
                                .foregroundColor(.white)
                        }
                        .frame(minWidth: 80)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(cardTeal))
                        
                        // Settings Button
                        Button(action: {
                            isShowingSettings.toggle()
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(8)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $isShowingSettings, arrowEdge: .bottom) {
                            GameSettingsView(game: game)
                        }
                    }
                }
                .padding([.top, .horizontal])
                
                // Grid Columns Layout
                HStack(alignment: .top, spacing: 15) {
                    ForEach(game.categories) { category in
                        VStack(spacing: 12) {
                            Text(category.name)
                                .font(.headline).bold()
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(RoundedRectangle(cornerRadius: 12).fill(headerOverlay))
                            
                            ForEach(category.questions) { question in
                                Button(action: {
                                    if !question.isAnswered { game.selectedQuestion = question }
                                }) {
                                    Text("\(question.points)")
                                        .font(.title2).bold()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 70)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(question.isAnswered ? Color.black.opacity(0.3) : cardTeal)
                                        )
                                        .foregroundColor(question.isAnswered ? .white.opacity(0.2) : .white)
                                        .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                                }
                                .buttonStyle(.plain)
                                .disabled(question.isAnswered)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            
            ConfettiView(trigger: $game.confettiTrigger)
                .allowsHitTesting(false)
            BalloonView(trigger: $game.balloonTrigger)
                .allowsHitTesting(false)
            HeartView(trigger: $game.heartsTrigger)
                .allowsHitTesting(false)
        }
        .frame(minWidth: 950, minHeight: 550)
        // CHANGED: Using .sheet instead of .popover for the pamphlet feel!
        .sheet(item: $game.selectedQuestion) { question in
            QuestionPopupView(question: question, game: game)
        }
    }
}

// MARK: - Game Settings Popover
struct GameSettingsView: View {
    @ObservedObject var game: TriviaGameEngine
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Game Settings")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Left Team")
                    .font(.caption).bold().foregroundColor(.secondary)
                TextField("Team Name", text: $game.team1Name)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: game.team1Name) { _ in game.saveGame() }
                HStack {
                    Text("Score:")
                    TextField("Score", value: $game.team1Score, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder).frame(width: 80)
                        .onChange(of: game.team1Score) { _ in game.saveGame() }
                    Stepper("", value: $game.team1Score, step: 100).labelsHidden()
                        .onChange(of: game.team1Score) { _ in game.saveGame() }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Right Team")
                    .font(.caption).bold().foregroundColor(.secondary)
                TextField("Team Name", text: $game.team2Name)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: game.team2Name) { _ in game.saveGame() }
                HStack {
                    Text("Score:")
                    TextField("Score", value: $game.team2Score, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder).frame(width: 80)
                        .onChange(of: game.team2Score) { _ in game.saveGame() }
                    Stepper("", value: $game.team2Score, step: 100).labelsHidden()
                        .onChange(of: game.team2Score) { _ in game.saveGame() }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Admin Settings")
                    .font(.caption).bold().foregroundColor(.secondary)
                HStack(spacing: 12) {
                    Button(action: { game.resetGame(); dismiss() }) {
                        HStack { Image(systemName: "arrow.counterclockwise"); Text("Reset Board") }
                        .font(.caption).bold().padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.red.opacity(0.15)).foregroundColor(.red).cornerRadius(6)
                    }.buttonStyle(.plain)
                    
                    Button(action: { game.importGame(); dismiss() }) {
                        HStack { Image(systemName: "square.and.arrow.down"); Text("Import Save") }
                        .font(.caption).bold().padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.15)).foregroundColor(.primary).cornerRadius(6)
                    }.buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .frame(width: 280)
    }
}

