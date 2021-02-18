//
//  ChatSessionDisconnect.swift
//  BPContactCenter
//
//  Created by Alexander Lobastov on 2/17/21.
//

import Foundation

struct ChatSessionDisconnectDto: Codable {
    let event: ContactCenterEventTypeDto
}

extension ChatSessionDisconnectDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionDisconnect
    }
}
