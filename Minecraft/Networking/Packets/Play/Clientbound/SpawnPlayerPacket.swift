//
//  SpawnPlayerPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct SpawnPlayerPacket: ClientboundPacket {
  static let id: Int = 0x04
  
  var entityId: Int32
  var playerUUID: UUID
  var position: EntityPosition
  var rotation: EntityRotation
  
  init(fromReader packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    playerUUID = packetReader.readUUID()
    position = packetReader.readEntityPosition()
    rotation = packetReader.readEntityRotation()
  }
}