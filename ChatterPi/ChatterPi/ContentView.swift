//
//  ContentView.swift
//  ChatterPi
//
//  Created by Frank Lim on 4/2/23.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State var chatMessages: [ChatMessage] = []
    @State var messageText: String = ""
    
    let openAIService = OpenAIService()
    @State var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack {
                    ForEach(chatMessages, id: \.id) { message in
                        messageView(message: message)
                    }
                }
            }
            HStack {
                TextField("Enter a message", text: $messageText){
                    sendMessage()
                }
                .padding()
                .backgroundStyle(.gray.opacity(0.1))
                .cornerRadius(12)
                Button {
                    sendMessage()
                } label: {
                    Text("Send")
                        .foregroundColor(.white)
                        .padding()
                        .background(.black)
                        .cornerRadius(12)
                    
                }
            }
        }
        .padding()
    }
    
    func messageView(message: ChatMessage) -> some View {
        let senderIsMe = message.sender == .me
        return HStack {
            if senderIsMe { Spacer() }
            Text(message.content)
                .foregroundColor(senderIsMe ? .white : .black)
                .padding()
                .background(senderIsMe ? .blue : .gray.opacity(0.1))
                .cornerRadius(16)
            if !senderIsMe { Spacer() }
        }
    }
    
    func sendMessage() {
        let myMessage = ChatMessage(
            id: UUID().uuidString,
            content: messageText,
            dateCreated: Date(),
            sender: .me
        )
        chatMessages.append(myMessage)
        
        openAIService.sendMessage(message: messageText).sink { completion in
            // Handle error
        } receiveValue: { response in
            guard
                let textResponse = response.choices.first?.text
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                            .union(.init(charactersIn: "\""))
                    )
            else { return }
            let gptMessage = ChatMessage(
                id: response.id,
                content: textResponse,
                dateCreated: Date(),
                sender: .gpt
            )
            chatMessages.append(gptMessage)
        }
        .store(in: &cancellables)
    }
    
    
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
    
    struct ChatMessage{
        let id: String
        let content: String
        let dateCreated: Date
        let sender: MessageSender
    }
    
    enum MessageSender {
        case me
        case gpt
    }
}
