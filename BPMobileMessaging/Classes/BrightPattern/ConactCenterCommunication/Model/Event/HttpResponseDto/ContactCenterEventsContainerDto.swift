//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation

/// - Tag: ContactCenterEventsContainerDto
struct ContactCenterEventsContainerDto: Codable {
    let events: [ContactCenterEvent]

    enum CodingKeys: String, CodingKey {
        case events
    }

    init(events: [ContactCenterEvent]) {
        self.events = events
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var eventsContainer = try container.nestedUnkeyedContainer(forKey: .events)
        var events = [ContactCenterEvent]()
        var eventDtoTypes = [ContactCenterEventTypeDto]()
        guard let count = eventsContainer.count else {
            self.events = []
            return
        }
        events.reserveCapacity(count)
        eventDtoTypes.reserveCapacity(count)
        // Decoding Dto will be done in two passes
        // On the first pass Dto types are decoded
        // On the second pass Dto objects are decoded
        while !eventsContainer.isAtEnd {
            do {
                // The backend sends a collection of event of different types
                // To decode each item to a specific type use JSONEncoder to get data
                // 1. Try to infer a specific Dto type based on the "event" property
                let eventType = try eventsContainer.decode(ContactCenterEventTypeContainerDto.self).event
                eventDtoTypes.append(eventType)
            } catch {
                // Skip unknown messages and continue to parse
                _ = try eventsContainer.decode(UnknownEventDto.self)
                eventDtoTypes.append(.unknown)
                log.error("Failed to parse unknown message from server: \(error)")
            }
        }
        // Each decode() call changes container internal state
        // So, reset it to decode Dto objects
        eventsContainer = try container.nestedUnkeyedContainer(forKey: .events)
        self.events = eventDtoTypes.compactMap { dtoType in
            do {
                // 2. Based on dto type decode data to a specific Dto object
                // superDecoder() returns a Decoder that points to the part that represents the whole object
                guard let dtoConvertible = try dtoType.codableType.init(from: eventsContainer.superDecoder()) as? ContactCenterEventModelConvertible else {

                    throw ContactCenterError.failedToCast("to: \(ContactCenterEventModelConvertible.self)")
                }

                return dtoConvertible.toModel()
            } catch {
                // Skip unknown messages and continue to parse
                log.error("Failed to parse unknown message from server: \(error)")
                return nil
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var eventsNestedContainer = container.nestedUnkeyedContainer(forKey: .events)
        events.forEach { event in
            do {
                try event.toDto().encode(to: eventsNestedContainer.superEncoder())
            } catch {
                log.error("Failed to encode: \(error)")
            }
        }
    }
}

/// Special Dto type that correposnd to an unknown event from the server
/// The purpose of this is to skip unknown events when parsing
/// When parsing this type can be used to decode unknown events and increase currentIndex of decoding container
internal struct UnknownEventDto: Codable {
}

/// This Dto is used to decode event types by decoding their names from `event` property
private struct ContactCenterEventTypeContainerDto: Decodable {
    let event: ContactCenterEventTypeDto
}
