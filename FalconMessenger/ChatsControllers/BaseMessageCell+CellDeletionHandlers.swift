//
//  BaseMessageCell+CellDeletionHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 12/12/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import FTPopOverMenu_Swift
import Firebase

struct ContextMenuItems {
  static let copyItem = "Copy"
  static let copyPreviewItem = "Copy image preview"
  static let deleteItem = "Delete for myself"
}

extension BaseMessageCell {
  
  func bubbleImage(currentColor: UIColor) -> UIColor {
    
    switch currentColor {
    case ThemeManager.currentTheme().outgoingBubbleTintColor:
      return ThemeManager.currentTheme().selectedOutgoingBubbleTintColor
    case ThemeManager.currentTheme().incomingBubbleTintColor:
      return ThemeManager.currentTheme().selectedIncomingBubbleTintColor
    default:
     return currentColor
  }
}
  
  @objc func handleLongTap(_ longPressGesture: UILongPressGestureRecognizer) {
    
    var contextMenuItems = [ContextMenuItems.copyItem, ContextMenuItems.deleteItem]
    let config = FTConfiguration.shared
    let expandedMenuWidth: CGFloat = 150
    let defaultMenuWidth: CGFloat = 100
    config.menuWidth = expandedMenuWidth

    guard let indexPath = self.chatLogController?.collectionView.indexPath(for: self) else { return }
    
    if let cell = self.chatLogController?.collectionView.cellForItem(at: indexPath) as? OutgoingVoiceMessageCell {
      if self.message?.status == messageStatusSending { return }
      cell.bubbleView.tintColor = bubbleImage(currentColor: cell.bubbleView.tintColor)
      contextMenuItems = [ContextMenuItems.deleteItem]
    }
    
    if let cell = self.chatLogController?.collectionView.cellForItem(at: indexPath) as? IncomingVoiceMessageCell {
      if self.message?.status == messageStatusSending { return }
      contextMenuItems = [ContextMenuItems.deleteItem]
      cell.bubbleView.tintColor = bubbleImage(currentColor: cell.bubbleView.tintColor)
    }
    
    if let cell = self.chatLogController?.collectionView.cellForItem(at: indexPath) as? PhotoMessageCell {
       cell.bubbleView.tintColor = bubbleImage(currentColor: cell.bubbleView.tintColor)
      if !cell.playButton.isHidden {
        contextMenuItems = [ContextMenuItems.copyPreviewItem, ContextMenuItems.deleteItem]
        config.menuWidth = expandedMenuWidth
      }
    }
    
    if let cell = self.chatLogController?.collectionView.cellForItem(at: indexPath) as? IncomingPhotoMessageCell {
       cell.bubbleView.tintColor = bubbleImage(currentColor: cell.bubbleView.tintColor)
      if !cell.playButton.isHidden {
        contextMenuItems = [ContextMenuItems.copyPreviewItem, ContextMenuItems.deleteItem]
        config.menuWidth = expandedMenuWidth
      }
    }
    
    if let cell = self.chatLogController?.collectionView.cellForItem(at: indexPath) as? OutgoingTextMessageCell {
     cell.bubbleView.tintColor = bubbleImage(currentColor: cell.bubbleView.tintColor)
    }
    
    if let cell = self.chatLogController?.collectionView.cellForItem(at: indexPath) as? IncomingTextMessageCell {
      cell.bubbleView.tintColor = bubbleImage(currentColor: cell.bubbleView.tintColor)
    }
    
    if self.message?.messageUID == nil || self.message?.status == messageStatusSending {
      config.menuWidth = defaultMenuWidth
      contextMenuItems = [ContextMenuItems.copyItem]
    }
    
    FTPopOverMenu.showForSender(sender: bubbleView, with: contextMenuItems, done: { (selectedIndex) in
      guard contextMenuItems[selectedIndex] == ContextMenuItems.deleteItem else {
        self.handleCopy(indexPath: indexPath)
        return
      }
      self.handleDeletion(indexPath: indexPath)
    }) { //completeion
     self.chatLogController?.collectionView.reloadItems(at: [indexPath])
    }
  }
  
  fileprivate func handleCopy(indexPath: IndexPath) {
    self.chatLogController?.collectionView.reloadItems(at: [indexPath])
    if let cell = self.chatLogController?.collectionView.cellForItem(at: indexPath) as? PhotoMessageCell {
      if cell.messageImageView.image == nil {
        guard let controllerToDisplayOn = self.chatLogController else { return }
        basicErrorAlertWith(title: basicErrorTitleForAlert, message: copyingImageError, controller: controllerToDisplayOn)
        return
      }
      UIPasteboard.general.image = cell.messageImageView.image
    } else if let cell = self.chatLogController?.collectionView.cellForItem(at: indexPath) as? IncomingPhotoMessageCell {
      if cell.messageImageView.image == nil {
        guard let controllerToDisplayOn = self.chatLogController else { return }
        basicErrorAlertWith(title: basicErrorTitleForAlert, message: copyingImageError, controller: controllerToDisplayOn)
        return
      }
      UIPasteboard.general.image = cell.messageImageView.image
    } else if let cell = self.chatLogController?.collectionView.cellForItem(at: indexPath) as? OutgoingTextMessageCell {
      UIPasteboard.general.string = cell.textView.text
    } else if let cell = self.chatLogController?.collectionView.cellForItem(at: indexPath) as? IncomingTextMessageCell {
      UIPasteboard.general.string = cell.textView.text
    } else {
      return
    }
  }
  
  fileprivate func handleDeletion(indexPath: IndexPath) {
    guard let uid = Auth.auth().currentUser?.uid, let partnerID = self.message?.chatPartnerId(), let messageID = self.message?.messageUID, self.currentReachabilityStatus != .notReachable else {
      self.chatLogController?.collectionView.reloadItems(at: [indexPath])
      guard let controllerToDisplayOn = self.chatLogController else { return }
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: controllerToDisplayOn)
      return
    }
    
    var deletionReference: DatabaseReference!
    
    if let isGroupChat = self.chatLogController?.conversation?.isGroupChat , isGroupChat {
      guard let conversationID = self.chatLogController?.conversation?.chatID else { return }
      deletionReference = Database.database().reference().child("user-messages").child(uid).child(conversationID).child(userMessagesFirebaseFolder).child(messageID)
    } else {
      deletionReference = Database.database().reference().child("user-messages").child(uid).child(partnerID).child(userMessagesFirebaseFolder).child(messageID)
    }
    
    deletionReference.removeValue(completionBlock: { (error, reference) in
      if error != nil { return }
      
      if let isGroupChat = self.chatLogController?.conversation?.isGroupChat , isGroupChat {
        
        guard let conversationID = self.chatLogController?.conversation?.chatID else { return }
        
        var lastMessageReference = Database.database().reference().child("user-messages").child(uid).child(conversationID).child(messageMetaDataFirebaseFolder)
        if let lastMessageID = self.chatLogController?.messages.last?.messageUID {
          lastMessageReference.updateChildValues(["lastMessageID": lastMessageID])
        } else {
          lastMessageReference = lastMessageReference.child("lastMessageID")
          lastMessageReference.removeValue()
        }
        
      } else {
        var lastMessageReference = Database.database().reference().child("user-messages").child(uid).child(partnerID).child(messageMetaDataFirebaseFolder)
        if let lastMessageID = self.chatLogController?.messages.last?.messageUID {
          lastMessageReference.updateChildValues(["lastMessageID": lastMessageID])
        } else {
          lastMessageReference = lastMessageReference.child("lastMessageID")
          lastMessageReference.removeValue()
        }
      }
    })
  }
}