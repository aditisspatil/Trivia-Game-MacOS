import SwiftUI
import AVKit
import Combine
import Foundation

// MARK: - Models (Codable for File Storage)
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

// Struct to represent the entire save file payload
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
    
    // Track Scores and Dynamic Team Names
    @Published var team1Name: String = "Team 1"
    @Published var team1Score: Int = 0
    
    @Published var team2Name: String = "Team 2"
    @Published var team2Score: Int = 0
    
    // Define the save file location (Documents directory)
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
            
            saveGame()
        }
        selectedQuestion = nil
    }
    
    // MARK: - File Persistence Methods
    func saveGame() {
        let currentState = GameState(
            categories: categories,
            team1Name: team1Name,
            team1Score: team1Score,
            team2Name: team2Name,
            team2Score: team2Score
        )
        
        do {
            let data = try JSONEncoder().encode(currentState)
            try data.write(to: saveFileURL)
            print("Game saved successfully to: \(saveFileURL.path)")
        } catch {
            print("Failed to save game state: \(error.localizedDescription)")
        }
    }
    
    func importGame() {
        do {
            let data = try Data(contentsOf: saveFileURL)
            let savedState = try JSONDecoder().decode(GameState.self, from: data)
            
            self.categories = savedState.categories
            self.team1Name = savedState.team1Name
            self.team1Score = savedState.team1Score
            self.team2Name = savedState.team2Name
            self.team2Score = savedState.team2Score
            print("Game imported successfully!")
        } catch {
            print("Failed to load game state or file does not exist: \(error.localizedDescription)")
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

// MARK: - Main Game Board (Midnight Mint Theme)
struct ContentView: View {
    @StateObject private var game = TriviaGameEngine()
    @State private var isShowingSettings = false
    
    // Midnight Mint Hex Values
    let appBackground = Color(nsColor: NSColor(red: 0.024, green: 0.102, blue: 0.137, alpha: 1.0)) // #061A23
    let cardTeal = Color(nsColor: NSColor(red: 0.039, green: 0.576, blue: 0.588, alpha: 1.0))      // #0A9396
    let team1Mint = Color(nsColor: NSColor(red: 0.580, green: 0.824, blue: 0.741, alpha: 1.0))     // #94D2BD
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
                    
                    // Score Trackers & Settings Button
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
                        
                        // Settings Toggle Button
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
        }
        .frame(minWidth: 950, minHeight: 550)
        .popover(item: $game.selectedQuestion) { question in
            QuestionPopupView(question: question, game: game)
        }
    }
}

// MARK: - Game Settings Popover Component
struct GameSettingsView: View {
    @ObservedObject var game: TriviaGameEngine
    @Environment(\.dismiss) var dismiss // Allows us to close the popover after clicking reset/import
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Game Settings")
                .font(.headline)
            
            // Score Editor Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Left Team")
                    .font(.caption).bold()
                    .foregroundColor(.secondary)
                
                TextField("Team Name", text: $game.team1Name)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: game.team1Name) { _ in game.saveGame() }
                
                HStack {
                    Text("Score:")
                    TextField("Score", value: $game.team1Score, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .onChange(of: game.team1Score) { _ in game.saveGame() }
                    Stepper("", value: $game.team1Score, step: 100)
                        .labelsHidden()
                        .onChange(of: game.team1Score) { _ in game.saveGame() }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Right Team")
                    .font(.caption).bold()
                    .foregroundColor(.secondary)
                
                TextField("Team Name", text: $game.team2Name)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: game.team2Name) { _ in game.saveGame() }
                
                HStack {
                    Text("Score:")
                    TextField("Score", value: $game.team2Score, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .onChange(of: game.team2Score) { _ in game.saveGame() }
                    Stepper("", value: $game.team2Score, step: 100)
                        .labelsHidden()
                        .onChange(of: game.team2Score) { _ in game.saveGame() }
                }
            }
            
            Divider()
            
            // Admin File Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Admin Settings")
                    .font(.caption).bold()
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Button(action: {
                        game.resetGame()
                        dismiss() // Closes the popover
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset Board")
                        }
                        .font(.caption).bold()
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        game.importGame()
                        dismiss() // Closes the popover
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import Save")
                        }
                        .font(.caption).bold()
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.15))
                        .foregroundColor(.primary)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .frame(width: 280)
    }
}

// MARK: - Media Question Popover Component
struct QuestionPopupView: View {
    let question: TriviaQuestion
    @ObservedObject var game: TriviaGameEngine
    
    let popupBackground = Color(nsColor: NSColor(red: 0.110, green: 0.365, blue: 0.388, alpha: 1.0)) // #1C5D63
    let team1Mint = Color(nsColor: NSColor(red: 0.580, green: 0.824, blue: 0.741, alpha: 1.0))      // #94D2BD
    let team2Teal = Color(nsColor: NSColor(red: 0.039, green: 0.576, blue: 0.588, alpha: 1.0))      // #0A9396
    
    var body: some View {
        ZStack {
            popupBackground
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Text(question.category)
                        .font(.caption).bold()
                        .foregroundColor(.white.opacity(0.9))
                        .padding(6)
                        .background(Capsule().fill(Color.white.opacity(0.15)))
                    Spacer()
                    Text("\(question.points) Pts")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Divider().background(Color.white.opacity(0.2))
                
                Group {
                    switch question.mediaType {
                    case .text:
                        Text(question.questionText)
                            .font(.title2).bold()
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            
                    case .image:
                        VStack(spacing: 12) {
                            Image(systemName: "photo.artframe")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 120)
                                .foregroundColor(team1Mint)
                            Text(question.questionText).font(.body).foregroundColor(.white)
                        }
                        
                    case .audio:
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "speaker.wave.3.fill")
                                Text("Audio Clue Playing...")
                            }
                            .font(.headline).foregroundColor(team1Mint)
                            Text(question.questionText).font(.body).foregroundColor(.white)
                        }
                        
                    case .video:
                        VStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.4))
                                .frame(height: 140)
                                .overlay(Image(systemName: "play.circle.fill").scaleEffect(2).foregroundColor(.white))
                            Text(question.questionText).font(.body).foregroundColor(.white)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Divider().background(Color.white.opacity(0.2))
                
                HStack(spacing: 12) {
                    Button("Missed / Nobody") {
                        game.markAsAnswered(question, awardedToTeam: nil)
                    }
                    .foregroundColor(.white.opacity(0.7))
                    .buttonStyle(.borderless)
                    .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                    
                    Button(game.team1Name) {
                        game.markAsAnswered(question, awardedToTeam: 1)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(team1Mint)
                    .foregroundColor(.black)
                    
                    Button(game.team2Name) {
                        game.markAsAnswered(question, awardedToTeam: 2)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(team2Teal)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(24)
        }
        .frame(width: 480, height: 340)
    }
}
