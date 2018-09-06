//
//  InputContainerView.swift
//  Avalon-print
//
//  Created by Roman Mizin on 3/25/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//


import UIKit
import AVFoundation

class InputContainerView: UIControl {
  
  var audioPlayer: AVAudioPlayer!
  
  weak var mediaPickerController: MediaPickerControllerNew?
  weak var trayDelegate: ImagePickerTrayControllerDelegate?
  
  var attachedMedia = [MediaObject]()
  
  static let commentOrSendPlaceholder =  "Comment or Send"
  static let messagePlaceholder = "Message"
 
  weak var chatLogController: ChatLogViewController? {
    didSet {
      sendButton.addTarget(chatLogController, action: #selector(ChatLogViewController.handleSend), for: .touchUpInside)
      attachButton.addTarget(chatLogController, action: #selector(ChatLogViewController.togglePhoto), for: .touchDown)
      recordVoiceButton.addTarget(chatLogController, action: #selector(ChatLogViewController.toggleVoiceRecording), for: .touchDown)
    }
  }
  
  lazy var inputTextView: InputTextView = {
    let textView = InputTextView()
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.delegate = self
    
    return textView
  }()
  
  lazy var attachCollectionView: AttachCollectionView = {
    let attachCollectionView = AttachCollectionView()

    return attachCollectionView
  }()
  
  let placeholderLabel: UILabel = {
    let placeholderLabel = UILabel()
    placeholderLabel.text = messagePlaceholder
    placeholderLabel.sizeToFit()
    placeholderLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
    placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
    
    return placeholderLabel
  }()
  
  let attachButton: UIButton = {
    let attachButton = UIButton()
    attachButton.tintColor = FalconPalette.defaultBlue
    attachButton.translatesAutoresizingMaskIntoConstraints = false
    attachButton.setImage(UIImage(named: "ConversationAttach"), for: .normal)
    attachButton.setImage(UIImage(named: "SelectedModernConversationAttach"), for: .selected)
    
    return attachButton
  }()
  
  let recordVoiceButton: UIButton = {
    let recordVoiceButton = UIButton()
    recordVoiceButton.tintColor = FalconPalette.defaultBlue
    recordVoiceButton.translatesAutoresizingMaskIntoConstraints = false
    recordVoiceButton.setImage(UIImage(named: "microphone"), for: .normal)
    recordVoiceButton.setImage(UIImage(named: "microphoneSelected"), for: .selected)
    
    return recordVoiceButton
  }()
  
  let sendButton: UIButton = {
    let sendButton = UIButton(type: .custom)
    sendButton.setImage(UIImage(named: "send"), for: .normal)
    sendButton.translatesAutoresizingMaskIntoConstraints = false
    sendButton.isEnabled = false
    
    return sendButton
  }()
  
  private var heightConstraint: NSLayoutConstraint!
  
  private func addHeightConstraints() {
    heightConstraint = heightAnchor.constraint(equalToConstant: InputTextViewLayout.minHeight)
    heightConstraint.isActive = true
  }
  
  func confirugeHeightConstraint() {
    let size = inputTextView.sizeThatFits(CGSize(width: inputTextView.bounds.size.width, height: .infinity))
    let height = size.height + 12
    heightConstraint.constant = height < InputTextViewLayout.maxHeight() ? height : InputTextViewLayout.maxHeight()
    let maxHeight: CGFloat = InputTextViewLayout.maxHeight()
    guard height >= maxHeight else { inputTextView.isScrollEnabled = false; return }
    inputTextView.isScrollEnabled = true
  }
  
  func handleRotation() {
    attachCollectionView.collectionViewLayout.invalidateLayout()
    DispatchQueue.main.async { [unowned self] in
      self.attachCollectionView.frame.size.width = self.inputTextView.frame.width
      self.attachCollectionView.reloadData()
      self.confirugeHeightConstraint()
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
    addHeightConstraints()
    backgroundColor = ThemeManager.currentTheme().barBackgroundColor
    addSubview(attachButton)
    addSubview(recordVoiceButton)
    addSubview(inputTextView)
    addSubview(sendButton)
    addSubview(placeholderLabel)
    inputTextView.addSubview(attachCollectionView)

    if #available(iOS 11.0, *) {
      attachButton.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 5).isActive = true
      inputTextView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -15).isActive = true
    } else {
      attachButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 5).isActive = true
      inputTextView.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
    }
    
    attachButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    attachButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    attachButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
    
    recordVoiceButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    recordVoiceButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    recordVoiceButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
    recordVoiceButton.leftAnchor.constraint(equalTo: attachButton.rightAnchor, constant: 0).isActive = true
    
    inputTextView.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
    inputTextView.leftAnchor.constraint(equalTo: recordVoiceButton.rightAnchor, constant: 3).isActive = true
    inputTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6).isActive = true
    
    placeholderLabel.font = UIFont.systemFont(ofSize: (inputTextView.font!.pointSize))
    placeholderLabel.isHidden = !inputTextView.text.isEmpty
    placeholderLabel.leftAnchor.constraint(equalTo: inputTextView.leftAnchor, constant: 12).isActive = true
    placeholderLabel.rightAnchor.constraint(equalTo: inputTextView.rightAnchor).isActive = true
    placeholderLabel.topAnchor.constraint(equalTo: attachCollectionView.bottomAnchor, constant: inputTextView.font!.pointSize / 2.3).isActive = true
    placeholderLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
    
    sendButton.rightAnchor.constraint(equalTo: inputTextView.rightAnchor, constant: -4).isActive = true
    sendButton.bottomAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: -4).isActive = true
    sendButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
    sendButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
    configureAttachCollectionView()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc func changeTheme() {
    backgroundColor = ThemeManager.currentTheme().barBackgroundColor
    inputTextView.changeTheme()
  }
  
  required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
    fatalError("init(coder:) has not been implemented")
  }
}

extension InputContainerView {
  
  func resetChatInputConntainerViewSettings() {
    guard attachedMedia.isEmpty else { return }
    attachCollectionView.frame = CGRect(x: 0, y: 0, width: inputTextView.frame.width, height: 0)
    inputTextView.textContainerInset = InputTextViewLayout.defaultInsets
    placeholderLabel.text = InputContainerView.messagePlaceholder
    sendButton.isEnabled = !inputTextView.text.isEmpty
    confirugeHeightConstraint()
  }
  
  func expandCollection() {
    sendButton.isEnabled = (!inputTextView.text.isEmpty || !attachedMedia.isEmpty)
    placeholderLabel.text = InputContainerView.commentOrSendPlaceholder
    attachCollectionView.frame = CGRect(x: 0, y: 3, width: inputTextView.frame.width, height: AttachCollectionView.height)
    inputTextView.textContainerInset = InputTextViewLayout.extendedInsets
    confirugeHeightConstraint()
  }
}

extension InputContainerView: UIGestureRecognizerDelegate {
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    guard attachCollectionView.bounds.contains(touch.location(in: attachCollectionView)) else { return true }
      return false
  }
}

extension InputContainerView: UITextViewDelegate {
  
 private func handleSendButtonState() {
    let whiteSpaceIsEmpty = inputTextView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty
    if (attachedMedia.count > 0 && !whiteSpaceIsEmpty) || (inputTextView.text != "" && !whiteSpaceIsEmpty) {
      sendButton.isEnabled = true
    } else {
      sendButton.isEnabled = false
    }
  }
  
  func textViewDidChange(_ textView: UITextView) {
    confirugeHeightConstraint()
    placeholderLabel.isHidden = !textView.text.isEmpty
    chatLogController?.isTyping = !textView.text.isEmpty
    handleSendButtonState()
  }
  
  func textViewDidEndEditing(_ textView: UITextView) {
      attachButton.isSelected = false
      recordVoiceButton.isSelected = false
   
    if chatLogController?.chatLogAudioPlayer != nil  {
      chatLogController?.chatLogAudioPlayer.stop()
      chatLogController?.chatLogAudioPlayer = nil
    }
    guard chatLogController != nil, chatLogController?.voiceRecordingViewController != nil,
      chatLogController!.voiceRecordingViewController.recorder != nil else {
      return
    }
    guard chatLogController!.voiceRecordingViewController.recorder.isRecording  else { return }
    chatLogController?.voiceRecordingViewController.stop()
  }
  
  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    guard text == "\n", let chatLogController = self.chatLogController else { return true }
    if chatLogController.isScrollViewAtTheBottom() {
      chatLogController.collectionView.instantMoveToBottom()
    }
    return true
  }
}