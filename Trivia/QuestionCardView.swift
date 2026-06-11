//
//  QuestionCardView.swift
//  Trivia
//
//  Created by Aditi Patil on 6/9/26.
//

import SwiftUI

// MARK: - Interactive Question & Answer Popover
struct QuestionPopupView: View {
    let question: TriviaQuestion
    @ObservedObject var game: TriviaGameEngine
    
    // UI Interaction States
    @State private var isAnswerRevealed = false
    @State private var revealedHintsCount = 0
    
    let popupBackground = Color(nsColor: NSColor(red: 0.110, green: 0.365, blue: 0.388, alpha: 1.0))
    let team1Mint = Color(nsColor: NSColor(red: 0.580, green: 0.824, blue: 0.741, alpha: 1.0))
    let team2Teal = Color(nsColor: NSColor(red: 0.039, green: 0.576, blue: 0.588, alpha: 1.0))
    
    var body: some View {
        ZStack {
            popupBackground.ignoresSafeArea()
            VStack(spacing: 30) {
                
                // HEADER
                HStack {
                    Text(question.category.uppercased())
                        .font(.title3).bold()
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.15)))
                    Spacer()
                    Text("\(question.points) Pts")
                        .font(.system(.title, design: .rounded)).bold()
                        .foregroundColor(.white)
                }
                Divider().background(Color.white.opacity(0.3))
                
                // MAIN CONTENT AREA
                Group {
                    if isAnswerRevealed {
                        // 1. REVEALED ANSWER VIEW
                        VStack(spacing: 20) {
                            Text("ANSWER")
                                .font(.headline)
                                .foregroundColor(.yellow)
                                .tracking(4)
                            
                            mediaRenderer(type: question.answerType, text: question.answerText, resourceName: question.answerMediaResourceName)
                        }
                    } else {
                        // 2. QUESTION VIEW (Switches based on QuestionType enum)
                        mediaRenderer(type: question.questionType, text: question.questionText, resourceName: question.mediaResourceName)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Divider().background(Color.white.opacity(0.3))
                
                // BOTTOM ACTION BAR
                HStack(spacing: 20) {
                    Button("Missed / Nobody") {
                        game.markAsAnswered(question, awardedToTeam: nil)
                    }
                    .foregroundColor(.white.opacity(0.7))
                    .buttonStyle(.borderless)
                    .controlSize(.large)
                    .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                    
                    // Progressive Reveal Logic
                    if !isAnswerRevealed {
                        if question.questionType == .hints, let hints = question.hints, revealedHintsCount < hints.count {
                            Button("Reveal Next Hint") {
                                withAnimation { revealedHintsCount += 1 }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        } else {
                            Button("Reveal Answer") {
                                withAnimation { isAnswerRevealed = true }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.yellow)
                            .foregroundColor(.black)
                            .controlSize(.large)
                        }
                    }
                    
                    Spacer()
                    
                    // Points Awarding
                    Button(game.team1Name) {
                        game.markAsAnswered(question, awardedToTeam: 1)
                    }
                    .buttonStyle(.borderedProminent).tint(team1Mint).foregroundColor(.black).controlSize(.large)
                    
                    Button(game.team2Name) {
                        game.markAsAnswered(question, awardedToTeam: 2)
                    }
                    .buttonStyle(.borderedProminent).tint(team2Teal).controlSize(.large)
                }
            }
            .padding(40)
        }
        .frame(width: 750, height: 550)
    }
    
    // ViewBuilder dynamically rendering content based on the unified QuestionType enum
    @ViewBuilder
    private func mediaRenderer(type: QuestionType, text: String, resourceName: String) -> some View {
        switch type {
        case .text:
            Text(text)
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, 20)
            
        case .image:
            VStack(spacing: 20) {
                Image(systemName: "photo.artframe")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 220)
                    .foregroundColor(team1Mint)
                Text(text).font(.title2).foregroundColor(.white)
            }
            
        case .audio:
            VStack(spacing: 20) {
                HStack(spacing: 15) {
                    Image(systemName: "speaker.wave.3.fill").font(.system(size: 40))
                    Text("Audio Clue Playing...").font(.largeTitle).bold()
                }.foregroundColor(team1Mint)
                Text(text).font(.title2).foregroundColor(.white)
            }
            
        case .video:
            VStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.4))
                    .frame(height: 250)
                    .overlay(Image(systemName: "play.circle.fill").font(.system(size: 60)).foregroundColor(.white))
                Text(text).font(.title2).foregroundColor(.white)
            }
            
        case .hints:
            // Custom Layout just for hints
            VStack(alignment: .leading, spacing: 20) {
                Text(text)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .padding(.bottom, 10)
                
                if let hints = question.hints {
                    ForEach(0..<hints.count, id: \.self) { index in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1).")
                                .font(.title3).bold()
                                .foregroundColor(index < revealedHintsCount ? team1Mint : .white.opacity(0.2))
                                .frame(width: 30, alignment: .leading)
                            
                            Text(index < revealedHintsCount ? hints[index] : "???")
                                .font(.title3)
                                .foregroundColor(index < revealedHintsCount ? .white : .white.opacity(0.2))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 30)
        }
    }
}
