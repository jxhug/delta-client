import SwiftUI
import DeltaCore
import GameController

#if os(macOS)
import Carbon
#endif

final class ClientInputDelegate: InputDelegate {
  /// ``mouseSensitivity`` is multiplied by this factor before use.
  let sensitivityAdjustmentFactor: Float = 0.004

  var mouseSensitivity = ConfigManager.default.config.mouseSensitivity

  var client: Client

  var cursorCaptured: Bool
  var pressedKeys: Set<Key> = []

  var leftTriggerIsPressed = false
  var rightTriggerIsPressed = false

  init(for client: Client) {
    self.client = client

    // Use a dummy binding until `bind(_:)` is called.
    cursorCaptured = false

    // Function to run intially to lookout for any MFI or Remote Controllers in the area
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(connectControllers),
      name: NSNotification.Name.GCControllerDidConnect,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(disconnectControllers),
      name: NSNotification.Name.GCControllerDidDisconnect,
      object: nil
    )

    // Check for controllers that might already be connected.
    connectControllers()
  }

  @objc func disconnectControllers() {
    client.moveLeftThumbstick(0, 0)
    client.moveRightThumbstick(0, 0)
  }

  @objc func connectControllers() {
    for controller in GCController.controllers() {
      if let pad = controller.extendedGamepad {
        pad.valueChangedHandler = { [weak self] pad, element in
          guard let self = self else { return }

          if element == pad.buttonA {
            if pad.buttonA.isPressed {
              self.client.press(.jump)
            } else {
              self.client.release(.jump)
            }
          } else if element == pad.leftThumbstick {
            self.client.moveLeftThumbstick(
              pad.leftThumbstick.xAxis.value,
              pad.leftThumbstick.yAxis.value
            )
          } else if element == pad.rightThumbstick {
            self.client.moveRightThumbstick(
              pad.rightThumbstick.xAxis.value,
              pad.rightThumbstick.yAxis.value
            )
          } else if element == pad.leftTrigger {
            // Extra checks are required because triggers are analog which causes many more updates
            // than just one when pressed and one when released.
            if pad.leftTrigger.isPressed && !self.leftTriggerIsPressed {
              self.client.press(.place)
              self.leftTriggerIsPressed = true
            } else if !pad.leftTrigger.isPressed && self.leftTriggerIsPressed {
              self.client.release(.place)
              self.leftTriggerIsPressed = false
            }
          } else if element == pad.rightTrigger {
            // Extra checks are required because triggers are analog which causes many more updates
            // than just one when pressed and one when released.
            if pad.rightTrigger.isPressed && !self.rightTriggerIsPressed {
              self.client.press(.destroy)
              self.rightTriggerIsPressed = true
            } else if !pad.rightTrigger.isPressed && self.rightTriggerIsPressed {
              self.client.release(.destroy)
              self.rightTriggerIsPressed = false
            }
          } else if element == pad.leftShoulder && pad.leftShoulder.isPressed {
            if pad.leftShoulder.isPressed {
              self.client.press(.previousSlot)
            } else {
              self.client.release(.previousSlot)
            }
          } else if element == pad.rightShoulder {
            if pad.rightShoulder.isPressed {
              self.client.press(.nextSlot)
            } else {
              self.client.release(.nextSlot)
            }
          } else if element == pad.leftThumbstickButton {
            if pad.leftThumbstickButton?.isPressed == true {
              self.client.press(.sprint)
            } else {
              self.client.release(.sprint)
            }
          } else if element == pad.buttonB {
            if pad.buttonB.isPressed {
              self.client.press(.sneak)
            } else {
              self.client.release(.sneak)
            }
          } else if element == pad.dpad {
            // TODO: This approach doesn't work if a dpad button is pressed while another one is
            // already pressed because the one that's already pressed will get triggered a second
            // time. May need to debounce
            if pad.dpad.up.isPressed {
              self.client.press(.changePerspective)
            } else {
              self.client.release(.changePerspective)
            }

            if pad.dpad.right.isPressed {
              self.client.press(.openChat)
            } else {
              self.client.release(.openChat)
            }
          }
        }
      }
    }
  }

  func onKeyDown(_ key: Key, _ characters: [Character] = []) {
    pressedKeys.insert(key)
    client.press(key, characters)
  }

  func onKeyUp(_ key: Key) {
    pressedKeys.remove(key)
    client.release(key)
  }

  func onMouseMove(_ deltaX: Float, _ deltaY: Float) {
    let sensitivity = sensitivityAdjustmentFactor * mouseSensitivity
    client.moveMouse(sensitivity * deltaX, sensitivity * deltaY)
  }

  func releaseCursor() {
    for key in pressedKeys {
      client.release(key)
    }

    pressedKeys = []

    #if os(macOS)
    if cursorCaptured {
      CGAssociateMouseAndMouseCursorPosition(1)
      NSCursor.unhide()
    }
    #endif
    cursorCaptured = false
  }

  func captureCursor() {
    #if os(macOS)
    if !cursorCaptured {
      CGAssociateMouseAndMouseCursorPosition(0)
      NSCursor.hide()
    }
    #endif
    cursorCaptured = true
  }
}
