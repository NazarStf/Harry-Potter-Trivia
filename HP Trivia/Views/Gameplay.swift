//
//  Gameplay.swift
//  HP Trivia
//
//  Created by NazarStf on 23.07.2023.
//

import SwiftUI
import AVKit

// MARK: - Gameplay View

// Define the Gameplay struct that conforms to the View protocol.
struct Gameplay: View {
	// Create environment variables for the game and dismissal function.
	@Environment(\.dismiss) private var dismiss
	@EnvironmentObject private var game: Game
	
	// Declare namespace for the matchedGeometryEffect
	@Namespace private var namespace
	
	// Create state variables for the audio players and animations.
	@State private var musicPlayer: AVAudioPlayer!
	@State private var sfxPlayer: AVAudioPlayer!
	@State private var animateViewsIn = false
	@State private var tappedCorrectAnswer = false
	@State private var hintWiggle = false
	@State private var scaleNextButton = false
	@State private var movePointToScore = false
	@State private var revealHint = false
	@State private var revealBook = false
	@State private var wrongAnswersTapped: [Int] = []
	
	// Define the body of the Gameplay view.
	var body: some View {
		// Use a GeometryReader to get the size of the view.
		GeometryReader { geo in
			// Stack the elements on top of each other.
			ZStack {
				// Display the background image.
				Image("hogwarts")
					.resizable()
					.frame(width: geo.size.width * 3, height: geo.size.height * 1.05)
					.overlay(Rectangle().foregroundColor(.black.opacity(0.8)))
				
				VStack {
					// MARK: Controls
					HStack {
						Button("End Game") {
							game.endGame()
							dismiss()
						}
						.buttonStyle(.borderedProminent)
						.tint(.red.opacity(0.5))
						
						Spacer()
						
						Text("Score: \(game.gameScore)")
					}
					.padding()
					.padding(.vertical, 30)
					
					// MARK: Question
					VStack {
						if animateViewsIn {
							Text(game.currentQuestion.question)
								.font(.custom(Constants.hpFont, size: 50))
								.multilineTextAlignment(.center)
								.padding()
								.transition(.scale)
								.opacity(tappedCorrectAnswer ? 0.1 : 1)
						}
					}
					.animation(.easeOut(duration: animateViewsIn ? 2 : 0), value: animateViewsIn)
					
					Spacer()
					
					// MARK: Hints
					HStack {
						VStack {
							if animateViewsIn {
								Image(systemName: "questionmark.app.fill")
									.resizable()
									.scaledToFit()
									.frame(width: 100)
									.foregroundColor(.cyan)
									.rotationEffect(.degrees(hintWiggle ? -13 : -17))
									.padding()
									.padding(.leading, 20)
									.transition(.offset(x: -geo.size.width/2))
									.onAppear() {
										withAnimation(
											.easeInOut(duration: 0.1).repeatCount(9).delay(5).repeatForever()) {
												hintWiggle = true
											}
									}
									.onTapGesture {
										withAnimation(.easeOut(duration: 1)) {
											revealHint = true
										}
										
										playFlipSound()
										game.questionScore -= 1
									}
									.rotation3DEffect(.degrees(revealHint ? 1440 : 0), axis: (x: 0, y: 1, z: 0))
									.scaleEffect(revealHint ? 5 : 1)
									.opacity(revealHint ? 0 : 1)
									.offset(x: revealHint ? geo.size.width/2 : 0)
									.overlay(
										Text(game.currentQuestion.hint)
											.padding(.leading, 33)
											.minimumScaleFactor(0.5)
											.multilineTextAlignment(.center)
											.opacity(revealHint ? 1 : 0)
											.scaleEffect(revealHint ? 1.33 : 1)
									)
									.opacity(tappedCorrectAnswer ? 0.1 : 1)
									.disabled(tappedCorrectAnswer)
							}
						}
						.animation(.easeOut(duration: animateViewsIn ? 1.5 : 0).delay(animateViewsIn ? 2 : 0), value: animateViewsIn)
						
						Spacer()
						
						VStack {
							if animateViewsIn {
								Image(systemName: "book.closed")
									.resizable()
									.scaledToFit()
									.frame(width: 50)
									.foregroundColor(.black)
									.frame(width: 100, height: 100)
									.background(.cyan)
									.cornerRadius(20)
									.rotationEffect(.degrees(hintWiggle ?  13 : 17))
									.padding()
									.padding(.trailing, 20)
									.transition(.offset(x: geo.size.width/2))
									.onAppear() {
										withAnimation(
											.easeInOut(duration: 0.1).repeatCount(9).delay(5).repeatForever()) {
												hintWiggle = true
											}
									}
									.onTapGesture {
										withAnimation(.easeOut(duration: 1)) {
											revealBook = true
										}
										
										playFlipSound()
										game.questionScore -= 1
									}
									.rotation3DEffect(.degrees(revealBook ? 1440 : 0), axis: (x: 0, y: 1, z: 0))
									.scaleEffect(revealBook ? 5 : 1)
									.opacity(revealBook ? 0 : 1)
									.offset(x: revealBook ? -geo.size.width/2 : 0)
									.overlay(
										Image("hp\(game.currentQuestion.book)")
											.resizable()
											.scaledToFit()
											.padding(.trailing, 33)
											.opacity(revealBook ? 1 : 0)
											.scaleEffect(revealBook ? 1.33 : 1)
									)
									.opacity(tappedCorrectAnswer ? 0.1 : 1)
									.disabled(tappedCorrectAnswer)
							}
						}
						.animation(.easeOut(duration: animateViewsIn ? 1.5 : 0).delay(animateViewsIn ? 2 : 0), value: animateViewsIn)
					}
					.padding(.bottom)
					
					// MARK: Answers
					LazyVGrid(columns: [GridItem(), GridItem()]) {
						ForEach(Array(game.answers.enumerated()), id: \.offset) { i, answer in
							if game.currentQuestion.answers[answer] == true {
								VStack {
									if animateViewsIn {
										if tappedCorrectAnswer == false {
											Text(answer)
												.minimumScaleFactor(0.5)
												.multilineTextAlignment(.center)
												.padding(10)
												.frame(width: geo.size.width/2.15, height: 80)
												.background(.green.opacity(0.5))
												.cornerRadius(25)
												.transition(.asymmetric(insertion: .scale, removal: .scale(scale: 5).combined(with: .opacity.animation(.easeOut(duration: 0.5)))))
												.matchedGeometryEffect(id: "answer", in: namespace)
												.onTapGesture {
													withAnimation(
														.easeOut(duration: 1)) {
															tappedCorrectAnswer = true
														}
													
													playCorrectSound()
													
													DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
														game.correct()
													}
												}
										}
									}
								}
								.animation(.easeOut(duration: animateViewsIn ? 1 : 0).delay(animateViewsIn ? 1.5 : 0), value: animateViewsIn)
							} else {
								VStack {
									if animateViewsIn {
										Text(answer)
											.minimumScaleFactor(0.5)
											.multilineTextAlignment(.center)
											.padding(10)
											.frame(width: geo.size.width/2.15, height: 80)
											.background(wrongAnswersTapped.contains(i) ? .red.opacity(0.5) : .green.opacity(0.5))
											.cornerRadius(25)
											.transition(.scale)
											.onTapGesture {
												withAnimation(.easeOut(duration: 1)) {
													wrongAnswersTapped.append(i)
												}
												
												playWrongSound()
												giveWrongFeedback()
												game.questionScore -= 1
											}
											.scaleEffect(wrongAnswersTapped.contains(i) ? 0.8 : 1)
											.disabled(tappedCorrectAnswer || wrongAnswersTapped.contains(i))
											.opacity(tappedCorrectAnswer ? 0.1 : 1)
									}
								}
								.animation(.easeOut(duration: animateViewsIn ? 1 : 0).delay(animateViewsIn ? 1.5 : 0), value: animateViewsIn)
							}
						}
					}
					
					Spacer()
					
				}
				.frame(width: geo.size.width, height: geo.size.height)
				.foregroundColor(.white)
				
				// MARK: Celebration
				VStack {
					
					Spacer()
					
					VStack {
						if tappedCorrectAnswer {
							Text("\(game.questionScore)")
								.font(.largeTitle)
								.padding(.top, 50)
								.transition(.offset(y: -geo.size.height/4))
								.offset(x: movePointToScore ? geo.size.width/2.3 : 0, y: movePointToScore ? -geo.size.height/13 : 0)
								.opacity(movePointToScore ? 0 : 1)
								.onAppear {
									withAnimation(
										.easeInOut(duration: 1).delay(3)) {
											movePointToScore = true
										}
								}
						}
					}
					.animation(.easeInOut(duration: 1).delay(2), value: tappedCorrectAnswer)
					
					Spacer()
					
					VStack {
						if tappedCorrectAnswer {
							Text("Brilliant!")
								.font(.custom(Constants.hpFont, size: 100))
								.transition(.scale.combined(with: .offset(y: -geo.size.height/2)))
						}
					}
					.animation(.easeInOut(duration: tappedCorrectAnswer ? 1 : 0).delay(tappedCorrectAnswer ? 1 : 0), value: tappedCorrectAnswer)
					
					Spacer()
					
					if tappedCorrectAnswer {
						Text(game.correctAnswer)
							.minimumScaleFactor(0.5)
							.multilineTextAlignment(.center)
							.padding(10)
							.frame(width: geo.size.width/2.15, height: 80)
							.background(.green.opacity(0.5))
							.cornerRadius(25)
							.scaleEffect(2)
							.matchedGeometryEffect(id: "answer", in: namespace)
					}
						
					Spacer()
					Spacer()
					
					Group {
						VStack {
							if tappedCorrectAnswer {
								Button("Next Level >") {
									animateViewsIn = false
									tappedCorrectAnswer = false
									revealHint = false
									revealBook = false
									movePointToScore = false
									wrongAnswersTapped = []
									game.newQuestion()
									
									DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
										animateViewsIn = true
									}
								}
								.buttonStyle(.borderedProminent)
								.tint(.blue.opacity(0.5))
								.font(.largeTitle)
								.transition(.offset(y: geo.size.height/3))
								.scaleEffect(scaleNextButton ? 1.2 : 1)
								.onAppear {
									withAnimation(.easeInOut(duration: 1.3).repeatForever()) {
										scaleNextButton.toggle()
									}
								}
							}
						}
						.animation(.easeInOut(duration: tappedCorrectAnswer ? 2.7 : 0).delay(tappedCorrectAnswer ? 2.7 : 0), value: tappedCorrectAnswer)
						
						Spacer()
						Spacer()
					}
				}
				.foregroundColor(.white)
			}
			.frame(width: geo.size.width, height: geo.size.height)
		}
		.ignoresSafeArea()
		.onAppear {
			animateViewsIn = true
			
			DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
				playMusic()
			}
		}
	}
	
	// MARK: - Code for the helper functions
	
	private func playMusic() {
		let songs = ["Audio/deep-in-the-dell", "Audio/spellcraft", "Audio/let-the-mystery-unfold", "Audio/hiding-place-in-the-forest"]
		
		let i = Int.random(in: 0...3)
		
		if let sound = Bundle.main.path(forResource: songs[i], ofType: "mp3") {
			do {
				// Try to initialize the audio player
				musicPlayer = try AVAudioPlayer(contentsOf: URL(filePath: sound))
				// Set the number of loops and play the audio
				musicPlayer.volume = 0.1
				musicPlayer.numberOfLoops = -1
				musicPlayer.play()
			} catch {
				// This block will execute if any error occurs
				print("There was an issue playing the sound: \(error)")
			}
		} else {
			print("Couldn't find the sound file")
		}
	}
	
	private func playFlipSound() {
		let sound = Bundle.main.path(forResource: "Audio/page-flip", ofType: "mp3")
		sfxPlayer = try! AVAudioPlayer(contentsOf: URL(filePath: sound!))
		sfxPlayer.play()
	}
	
	private func playWrongSound() {
		let sound = Bundle.main.path(forResource: "Audio/negative-beeps", ofType: "mp3")
		sfxPlayer = try! AVAudioPlayer(contentsOf: URL(filePath: sound!))
		sfxPlayer.play()
	}
	
	private func playCorrectSound() {
		let sound = Bundle.main.path(forResource: "Audio/magic-wand", ofType: "mp3")
		sfxPlayer = try! AVAudioPlayer(contentsOf: URL(filePath: sound!))
		sfxPlayer.play()
	}
	
	private func giveWrongFeedback() {
		let generator = UINotificationFeedbackGenerator()
		generator.notificationOccurred(.error)
	}
}

// MARK: - Preview

// Define a PreviewProvider for the Gameplay view.
struct Gameplay_Previews: PreviewProvider {
	static var previews: some View {
		VStack {
			Gameplay()
				.environmentObject(Game())
		}
	}
}
