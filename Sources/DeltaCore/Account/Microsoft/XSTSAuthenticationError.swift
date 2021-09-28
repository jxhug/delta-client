//
//  XSTSAuthenticationErrorResponse.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 24/4/21.
//

import Foundation

public struct XSTSAuthenticationError: Codable {
  public var identity: String
  public var code: Int
  public var message: String
  public var redirect: String
  
  private enum CodingKeys: String, CodingKey {
    case identity = "Identity"
    case code = "XErr"
    case message = "Message"
    case redirect = "Redirect"
  }
}