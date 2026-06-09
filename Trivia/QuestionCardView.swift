//
//  QuestionCardView.swift
//  Trivia
//
//  Created by Aditi Patil on 6/9/26.
//

import SwiftUI
import AVKit

// MARK: - Large "Pamphlet" Media Question View
struct QuestionPopupView: View {
    let question: TriviaQuestion
    @ObservedObject var game: TriviaGameEngine
    
    // Midnight Mint Popup Specifics
    let popupBackground = Color(nsColor: NSColor(red: 0.110, green: 0.365, blue: 0.388, alpha: 1.0)) // #1C5D63
    let team1Mint = Color(nsColor: NSColor(red: 0.580, green: 0.824, blue: 0.741, alpha: 1.0))      // #94D2BD
    let team2Teal = Color(nsColor: NSColor(red: 0.039, green: 0.576, blue: 0.588, alpha: 1.0))      // #0A9396
    
    var body: some View {
        ZStack {
            popupBackground
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header (Pamphlet Style)
                HStack {
                    Text(question.category.uppercased())
                        .font(.title3).bold()
                        .tracking(2) // Adds nice letter spacing for a document feel
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
                
                // Main Content Area (Expanded)
                Group {
                    switch question.mediaType {
                    case .text:
                        Text(question.questionText)
                            .font(.system(size: 36, weight: .bold, design: .serif)) // Serif font feels more like a printed pamphlet
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(8)
                            .padding(.horizontal, 20)
                            
                    case .image:
                        VStack(spacing: 20) {
                            Image(systemName: "photo.artframe")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 220) // Much larger media display
                                .foregroundColor(team1Mint)
                                .shadow(radius: 10)
                            
                            Text(question.questionText)
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                    case .audio:
                        VStack(spacing: 20) {
                            HStack(spacing: 15) {
                                Image(systemName: "speaker.wave.3.fill")
                                    .font(.system(size: 40))
                                Text("Audio Clue Playing...")
                                    .font(.largeTitle).bold()
                            }
                            .foregroundColor(team1Mint)
                            
                            Text(question.questionText)
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                    case .video:
                        VStack(spacing: 20) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.4))
                                .frame(height: 250)
                                .overlay(
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.white)
                                )
                                .shadow(radius: 10)
                                
                            Text(question.questionText)
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Divider().background(Color.white.opacity(0.3))
                
                // Bottom Action Bar (Large Controls)
                HStack(spacing: 20) {
                    Button("Missed / Nobody") {
                        game.markAsAnswered(question, awardedToTeam: nil)
                    }
                    .foregroundColor(.white.opacity(0.7))
                    .buttonStyle(.borderless)
                    .controlSize(.large) // Native macOS large button
                    .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                    
                    Button(game.team1Name) {
                        game.markAsAnswered(question, awardedToTeam: 1)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(team1Mint)
                    .foregroundColor(.black)
                    .controlSize(.large)
                    
                    Button(game.team2Name) {
                        game.markAsAnswered(question, awardedToTeam: 2)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(team2Teal)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(40) // Massive padding for the pamphlet look
        }
        // Drastically increased size: 700x500
        .frame(width: 700, height: 500)
    }
}
