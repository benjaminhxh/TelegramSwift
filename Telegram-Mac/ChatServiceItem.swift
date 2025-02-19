//
//  ChatServiceItem.swift
//  Telegram-Mac
//
//  Created by keepcoder on 06/11/2016.
//  Copyright © 2016 Telegram. All rights reserved.
//

import Cocoa
import TGUIKit
import TelegramCore
import TGCurrencyFormatter
import Postbox
import SwiftSignalKit
import InAppSettings
import CurrencyFormat
import ThemeSettings


class ChatServiceItem: ChatRowItem {
    
    static var photoSize = NSMakeSize(200, 200)

    let text:TextViewLayout
    private(set) var imageArguments:TransformImageArguments?
    private(set) var image:TelegramMediaImage?
    
    struct GiftData {
        let from: PeerId
        let to: PeerId
        let text: TextViewLayout
        let months: Int32
        
        init(from: PeerId, to: PeerId, text: TextViewLayout, months: Int32) {
            self.from = from
            self.to = to
            self.text = text
            self.months = months
            self.text.measure(width: 180)
        }
        
        var height: CGFloat {
            return 150 + text.layoutSize.height + 10 + 10
        }
        var alt: String {
            let alt: String
            switch months {
            case 1:
                alt = "1️⃣"
            case 3:
                alt = "2️⃣"
            case 6:
                alt = "3️⃣"
            case 12:
                alt = "4️⃣"
            case 24:
                alt = "5️⃣"
            default:
                alt = "5️⃣"
            }
            return alt
        }
    }
    
    struct SuggestPhotoData {
        let from: PeerId
        let to: PeerId
        let text: TextViewLayout
        let image: TelegramMediaImage
        let isIncoming: Bool
        init(from: PeerId, to: PeerId, text: TextViewLayout, isIncoming: Bool, image: TelegramMediaImage) {
            self.from = from
            self.to = to
            self.text = text
            self.isIncoming = isIncoming
            self.image = image
            self.text.measure(width: 160)
        }
        
        var height: CGFloat {
            return 10 + 100 + 10 + text.layoutSize.height + 10 + 30 + 10
        }
    }
    
    struct WallpaperData {
        let wallpaper: Wallpaper
        let aesthetic: TelegramWallpaper
        let peerId: PeerId
        let isIncoming: Bool
        init(wallpaper: Wallpaper, aesthetic: TelegramWallpaper, peerId: PeerId, isIncoming: Bool) {
            self.wallpaper = wallpaper
            self.aesthetic = aesthetic
            self.peerId = peerId
            self.isIncoming = isIncoming
        }
        
        var height: CGFloat {
            return 160
        }
    }

    
    private(set) var giftData: GiftData? = nil
    private(set) var suggestPhotoData: SuggestPhotoData? = nil
    private(set) var wallpaperData: WallpaperData? = nil

    override init(_ initialSize:NSSize, _ chatInteraction:ChatInteraction, _ context: AccountContext, _ entry: ChatHistoryEntry, _ downloadSettings: AutomaticMediaDownloadSettings, theme: TelegramPresentationTheme) {
        let message:Message = entry.message!
                
        
        let linkColor: NSColor = theme.controllerBackgroundMode.hasWallpaper ? theme.chatServiceItemTextColor : entry.renderType == .bubble ? theme.chat.linkColor(true, entry.renderType == .bubble) : theme.colors.link
        let grayTextColor: NSColor = theme.chatServiceItemTextColor

        let authorId:PeerId? = message.author?.id
        var authorName:String = ""
        if let displayTitle = message.author?.displayTitle {
            authorName = displayTitle
        }
        
        let isIncoming: Bool = message.isIncoming(context.account, entry.renderType == .bubble)

        
        let nameColor:(PeerId) -> NSColor = { peerId in
            return theme.chatServiceItemTextColor

//            if theme.controllerBackgroundMode.hasWallpaper {
//                return theme.chatServiceItemTextColor
//            }
//            let mainPeer = coreMessageMainPeer(message)
//
//            if mainPeer is TelegramChannel || mainPeer is TelegramGroup {
//                if let peer = mainPeer as? TelegramChannel, case .broadcast(_) = peer.info {
//                    return theme.chat.linkColor(isIncoming, entry.renderType == .bubble)
//                } else if context.peerId != peerId {
//                    let value = abs(Int(peerId.id._internalGetInt64Value()) % 7)
//                    return theme.chat.peerName(value)
//                }
//            }
//            return theme.chat.linkColor(isIncoming, false)
        }
        
        
        let attributedString:NSMutableAttributedString = NSMutableAttributedString()
        if let media = message.media[0] as? TelegramMediaAction {
           
            if let peer = coreMessageMainPeer(message) {
               
                switch media.action {
                case let .groupCreated(title: title):
                    if !peer.isChannel {
                        let _ =  attributedString.append(string: strings().chatServiceGroupCreated1(authorName, title), color: grayTextColor, font: .normal(theme.fontSize))
                        
                        if let authorId = authorId {
                            let range = attributedString.string.nsstring.range(of: authorName)
                            attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                            attributedString.addAttribute(.font, value: NSFont.medium(theme.fontSize), range: range)
                        }
                    } else {
                        let _ =  attributedString.append(string: strings().chatServiceChannelCreated, color: grayTextColor, font: .normal(theme.fontSize))
                    }
                    
                    
                case let .addedMembers(peerIds):
                    if peerIds.first == authorId {
                        let _ =  attributedString.append(string: strings().chatServiceGroupAddedSelf(authorName), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                    } else {
                        let _ =  attributedString.append(string: strings().chatServiceGroupAddedMembers1(authorName, ""), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                        for peerId in peerIds {
                            
                            if let peer = message.peers[peerId] {
                                let range = attributedString.append(string: peer.displayTitle, color: nameColor(peer.id), font: .medium(theme.fontSize))
                                attributedString.add(link:inAppLink.peerInfo(link: "", peerId:peerId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(peerId))
                                if peerId != peerIds.last {
                                    _ = attributedString.append(string: ", ", color: grayTextColor, font: .normal(theme.fontSize))
                                }
                                
                            }
                        }
                    }
                    if let authorId = authorId {
                        let range = attributedString.string.nsstring.range(of: authorName)
                        attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                        attributedString.addAttribute(.font, value: NSFont.medium(theme.fontSize), range: range)
                    }
                    
                case let .removedMembers(peerIds):
                    if peerIds.first == message.author?.id {
                        let _ =  attributedString.append(string: strings().chatServiceGroupRemovedSelf(authorName), color: grayTextColor, font: .normal(theme.fontSize))
                    } else {
                        let _ =  attributedString.append(string: strings().chatServiceGroupRemovedMembers1(authorName, ""), color: grayTextColor, font: .normal(theme.fontSize))
                        for peerId in peerIds {
                            
                            if let peer = message.peers[peerId] {
                                let range = attributedString.append(string: peer.displayTitle, color: nameColor(peerId), font: .medium(theme.fontSize))
                                attributedString.add(link:inAppLink.peerInfo(link: "", peerId:peerId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(peer.id))
                                if peerId != peerIds.last {
                                    _ = attributedString.append(string: ", ", color: grayTextColor, font: .normal(theme.fontSize))
                                }
                                
                            }
                        }
                    }
                    if let authorId = authorId {
                        let range = attributedString.string.nsstring.range(of: authorName)
                        attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                        attributedString.addAttribute(NSAttributedString.Key.font, value: NSFont.medium(theme.fontSize), range: range)
                    }
                    
                case let .photoUpdated(image):
                    if let image = image {
                        
                        let text: String
                        if image.videoRepresentations.isEmpty {
                            text = peer.isChannel ? strings().chatServiceChannelUpdatedPhoto : strings().chatServiceGroupUpdatedPhoto(authorName)
                        } else {
                            text = peer.isChannel ? strings().chatServiceChannelUpdatedVideo : strings().chatServiceGroupUpdatedVideo(authorName)
                        }
                        
                        let _ =  attributedString.append(string: text, color: grayTextColor, font: .normal(theme.fontSize))
                        let size = ChatServiceItem.photoSize
                        imageArguments = TransformImageArguments(corners: ImageCorners(radius: 10), imageSize: size, boundingSize: size, intrinsicInsets: NSEdgeInsets())
                    } else {
                        let _ =  attributedString.append(string: peer.isChannel ? strings().chatServiceChannelRemovedPhoto : strings().chatServiceGroupRemovedPhoto(authorName), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                        
                    }
                    if let authorId = authorId {
                        let range = attributedString.string.nsstring.range(of: authorName)
                        attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                        attributedString.addAttribute(NSAttributedString.Key.font, value: NSFont.medium(theme.fontSize), range: range)
                    }
                    self.image = image
                    
                    
                case let .titleUpdated(title):
                    let _ =  attributedString.append(string: peer.isChannel ? strings().chatServiceChannelUpdatedTitle(title) : strings().chatServiceGroupUpdatedTitle1(authorName, title), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                    
                    if let authorId = authorId {
                        
                        let range = attributedString.string.nsstring.range(of: authorName)
                        attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                        attributedString.addAttribute(.font, value: NSFont.medium(theme.fontSize), range: range)
                    }
                case .customText(let text, _):
                    let _ = attributedString.append(string: text, color: grayTextColor, font: NSFont.normal(theme.fontSize))
                case .pinnedMessageUpdated:
                    var replyMessageText = ""
                    var pinnedId: MessageId?
                    for attribute in message.attributes {
                        if let attribute = attribute as? ReplyMessageAttribute, let message = message.associatedMessages[attribute.messageId] {
                            let text = (pullText(from: message).string as String).replacingOccurrences(of: "\n", with: " ")
                            replyMessageText = message.restrictedText(context.contentSettings) ?? text
                            pinnedId = attribute.messageId
                        }
                    }
                    let cutted = replyMessageText.prefixWithDots(30)
                    _ = attributedString.append(string: strings().chatServiceGroupUpdatedPinnedMessage1(authorName, cutted), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                    let pinnedRange = attributedString.string.nsstring.range(of: cutted)
                    if pinnedRange.location != NSNotFound {
                        attributedString.add(link: inAppLink.callback("", { [weak chatInteraction] _ in
                            if let pinnedId = pinnedId {
                                chatInteraction?.focusMessageId(nil, pinnedId, .CenterEmpty)
                            }
                        }), for: pinnedRange, color: grayTextColor)
                        attributedString.addAttribute(NSAttributedString.Key.font, value: NSFont.medium(theme.fontSize), range: pinnedRange)
                    }
                   
                    
                    
                    if let authorId = authorId {
                        let range = attributedString.string.nsstring.range(of: authorName)
                        attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                        attributedString.addAttribute(NSAttributedString.Key.font, value: NSFont.medium(theme.fontSize), range: range)

                    }
                    
                case .joinedByLink:
                    let _ =  attributedString.append(string: strings().chatServiceGroupJoinedByLink(authorName), color: grayTextColor, font: .normal(theme.fontSize))
                    if let authorId = authorId {
                        let range = attributedString.string.nsstring.range(of: authorName)
                        attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                        attributedString.addAttribute(.font, value: NSFont.medium(theme.fontSize), range: range)
                    }
                    
                case .channelMigratedFromGroup, .groupMigratedToChannel:
                    let _ =  attributedString.append(string: strings().chatServiceGroupMigratedToSupergroup, color: grayTextColor, font: NSFont.normal(theme.fontSize))
                case let .messageAutoremoveTimeoutUpdated(seconds, autoSourcePeerId):
                    
                    if let authorId = authorId {
                        if authorId == context.peerId {
                            if seconds > 0 {
                                if autoSourcePeerId == context.peerId {
                                    let _ =  attributedString.append(string: strings().chatAutoremoveTimerSetUserGlobalYou(autoremoveLocalized(Int(seconds))), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                                    
                                } else {
                                    let _ =  attributedString.append(string: strings().chatServiceSecretChatSetTimerSelf1(autoremoveLocalized(Int(seconds))), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                                }
                                
                            } else {
                                let _ =  attributedString.append(string: strings().chatServiceSecretChatDisabledTimerSelf1, color: grayTextColor, font: NSFont.normal(theme.fontSize))
                            }
                        } else {
                            if let peer = coreMessageMainPeer(message) {
                                if peer.isGroup || peer.isSupergroup {
                                    if seconds > 0 {
                                        let _ =  attributedString.append(string: strings().chatServiceGroupSetTimer(autoremoveLocalized(Int(seconds))), color: grayTextColor, font: .normal(theme.fontSize))
                                    } else {
                                        let _ =  attributedString.append(string: strings().chatServiceGroupDisabledTimer, color: grayTextColor, font: .normal(theme.fontSize))
                                    }
                                } else if peer.isChannel {
                                    if seconds > 0 {
                                        let _ =  attributedString.append(string: strings().chatServiceChannelSetTimer(autoremoveLocalized(Int(seconds))), color: grayTextColor, font: .normal(theme.fontSize))
                                    } else {
                                        let _ =  attributedString.append(string: strings().chatServiceChannelDisabledTimer, color: grayTextColor, font: .normal(theme.fontSize))
                                    }
                                } else {
                                    if seconds > 0 {
                                        if autoSourcePeerId == authorId {
                                            let _ =  attributedString.append(string: strings().chatAutoremoveTimerSetUserGlobal(authorName, autoremoveLocalized(Int(seconds))), color: grayTextColor, font: .normal(theme.fontSize))
                                        } else {
                                            let _ =  attributedString.append(string: strings().chatServiceSecretChatSetTimer1(authorName, autoremoveLocalized(Int(seconds))), color: grayTextColor, font: .normal(theme.fontSize))
                                        }
                                    } else {
                                        let _ =  attributedString.append(string: strings().chatServiceSecretChatDisabledTimer1(authorName), color: grayTextColor, font: .normal(theme.fontSize))
                                    }
                                }
                                let range = attributedString.string.nsstring.range(of: authorName)
                                attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                                attributedString.addAttribute(NSAttributedString.Key.font, value: NSFont.medium(theme.fontSize), range: range)
                            }

                        }
                    }
                case .historyScreenshot:
                    let _ =  attributedString.append(string: strings().chatServiceGroupTookScreenshot(authorName), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                    if let authorId = authorId {
                        let range = attributedString.string.nsstring.range(of: authorName)
                        attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                        attributedString.addAttribute(.font, value: NSFont.medium(theme.fontSize), range: range)
                    }
                case let .phoneCall(callId: _, discardReason: reason, duration: duration, _):
                    if let reason = reason {
                        switch reason {
                        case .busy:
                            _ = attributedString.append(string: strings().chatListServiceCallCancelled, color: grayTextColor, font: NSFont.normal(theme.fontSize))
                        case .disconnect:
                            _ = attributedString.append(string: strings().chatListServiceCallMissed, color: grayTextColor, font: NSFont.normal(theme.fontSize))
                        case .hangup:
                            if let duration = duration {
                                if message.author?.id == context.peerId {
                                    _ = attributedString.append(string: strings().chatListServiceCallOutgoing(.durationTransformed(elapsed: Int(duration))), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                                } else {
                                    _ = attributedString.append(string: strings().chatListServiceCallIncoming(.durationTransformed(elapsed: Int(duration))), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                                }
                            }
                        case .missed:
                            _ = attributedString.append(string: strings().chatListServiceCallMissed, color: grayTextColor, font: NSFont.normal(theme.fontSize))
                        }
                    } else if let duration = duration {
                        if authorId == context.peerId {
                            _ = attributedString.append(string: strings().chatListServiceCallOutgoing(.durationTransformed(elapsed: Int(duration))), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                        } else {
                            _ = attributedString.append(string: strings().chatListServiceCallIncoming(.durationTransformed(elapsed: Int(duration))), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                        }
                    }
                case let .gameScore(gameId: _, score: score):
                    
                    var gameName:String = ""
                    for attr in message.attributes {
                        if let attr = attr as? ReplyMessageAttribute {
                            if let message = message.associatedMessages[attr.messageId], let gameMedia = message.anyMedia as? TelegramMediaGame {
                                gameName = gameMedia.name
                            }
                        }
                    }
                    
                    if let authorId = authorId {
                        let range = attributedString.append(string: authorName, color: linkColor, font: NSFont.medium(theme.fontSize))
                        attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                        _ = attributedString.append(string: " ")
                    }
                    _ = attributedString.append(string: strings().chatListServiceGameScored1Countable(Int(score), gameName), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                case let .paymentSent(currency, totalAmount, _, isRecurringInit, isRecurringUsed):
                    var paymentMessage:Message?
                    for attr in message.attributes {
                        if let attr = attr as? ReplyMessageAttribute {
                            if let message = message.associatedMessages[attr.messageId] {
                                paymentMessage = message
                            }
                        }
                    }
                    let media = paymentMessage?.anyMedia as? TelegramMediaInvoice
                    
                    if let paymentMessage = paymentMessage, let media = media, let peer = paymentMessage.peers[paymentMessage.id.peerId] {
                        if isRecurringInit {
                            _ = attributedString.append(string: strings().chatServicePaymentSentRecurringInit(TGCurrencyFormatter.shared().formatAmount(totalAmount, currency: currency), peer.displayTitle, media.title), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                        } else if isRecurringUsed {
                            _ = attributedString.append(string: strings().chatServicePaymentSentRecurringUsed(TGCurrencyFormatter.shared().formatAmount(totalAmount, currency: currency), peer.displayTitle, media.title), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                        } else {
                            _ = attributedString.append(string: strings().chatServicePaymentSent1(TGCurrencyFormatter.shared().formatAmount(totalAmount, currency: currency), peer.displayTitle, media.title), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                        }
                        attributedString.detectBoldColorInString(with: .medium(theme.fontSize))
                        
                        attributedString.add(link:inAppLink.callback("", { _ in
                            showModal(with: PaymentsReceiptController(context: context, messageId: message.id, invoice: media), for: context.window)
                        }), for: attributedString.range, color: grayTextColor)
                    } else if let peer = coreMessageMainPeer(message) {
                        if isRecurringInit {
                            _ = attributedString.append(string: strings().chatServicePaymentSentRecurringInitNoTitle(TGCurrencyFormatter.shared().formatAmount(totalAmount, currency: currency), peer.displayTitle), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                        } else if isRecurringUsed {
                            _ = attributedString.append(string: strings().chatServicePaymentSentRecurringUsedNoTitle(TGCurrencyFormatter.shared().formatAmount(totalAmount, currency: currency), peer.displayTitle), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                        } else {
                            _ = attributedString.append(string: strings().chatServicePaymentSent1NoTitle(TGCurrencyFormatter.shared().formatAmount(totalAmount, currency: currency), peer.displayTitle), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                        }
                        attributedString.detectBoldColorInString(with: .medium(theme.fontSize))
                    }
                case let .botDomainAccessGranted(domain):
                    _ = attributedString.append(string: strings().chatServiceBotPermissionAllowed(domain), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                case let .botSentSecureValues(types):
                    let permissions = types.map({$0.rawValue}).joined(separator: ", ")
                     _ = attributedString.append(string: strings().chatServiceSecureIdAccessGranted(peer.displayTitle, permissions), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                case .peerJoined:
                    let _ =  attributedString.append(string: strings().chatServicePeerJoinedTelegram(authorName), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                    
                    if let authorId = authorId {
                        let range = attributedString.string.nsstring.range(of: authorName)
                        attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                        attributedString.addAttribute(.font, value: NSFont.medium(theme.fontSize), range: range)
                    }
                case let .geoProximityReached(fromId, toId, distance):
                    let distanceString = stringForDistance(distance: Double(distance))
                    let text: String
                    if fromId == context.peerId {
                        text = strings().notificationProximityYouReached1(distanceString, message.peers[toId]?.displayTitle ?? "")
                    } else if toId == context.peerId {
                        text = strings().notificationProximityReachedYou1(message.peers[fromId]?.displayTitle ?? "", distanceString)
                    } else {
                        text = strings().notificationProximityReached1(message.peers[fromId]?.displayTitle ?? "", distanceString, message.peers[toId]?.displayTitle ?? "")
                    }
                    let _ = attributedString.append(string: text, color: grayTextColor, font: NSFont.normal(theme.fontSize))

                    if let authorId = authorId {
                        let range = attributedString.string.nsstring.range(of: authorName)
                        if range.location != NSNotFound {
                            attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                            attributedString.addAttribute(.font, value: NSFont.medium(theme.fontSize), range: range)
                        }
                    }
                    if let peer = message.peers[toId], !peer.displayTitle.isEmpty {
                        let range = attributedString.string.nsstring.range(of: peer.displayTitle)
                        if range.location != NSNotFound {
                            attributedString.add(link:inAppLink.peerInfo(link: "", peerId: peer.id, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(peer.id))
                            attributedString.addAttribute(.font, value: NSFont.medium(theme.fontSize), range: range)
                        }
                    }
                    if let peer = message.peers[fromId], !peer.displayTitle.isEmpty {
                        let range = attributedString.string.nsstring.range(of: peer.displayTitle)
                        if range.location != NSNotFound {
                            attributedString.add(link:inAppLink.peerInfo(link: "", peerId: peer.id, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(peer.id))
                            attributedString.addAttribute(.font, value: NSFont.medium(theme.fontSize), range: range)
                        }
                    }
                case let .groupPhoneCall(callId, accessHash, scheduleDate, duration):
                    let text: String
                    if let duration = duration {
                        if peer.isChannel {
                            text = strings().chatServiceVoiceChatFinishedChannel1(autoremoveLocalized(Int(duration)))
                        } else if authorId == context.peerId {
                            text = strings().chatServiceVoiceChatFinishedYou(autoremoveLocalized(Int(duration)))
                        } else {
                            text = strings().chatServiceVoiceChatFinished(authorName, autoremoveLocalized(Int(duration)))
                        }
                        let _ = attributedString.append(string: text, color: grayTextColor, font: NSFont.normal(theme.fontSize))
                    } else {
                        if peer.isChannel {
                            if let scheduled = scheduleDate {
                                text = strings().chatServiceVoiceChatScheduledChannel1(stringForMediumDate(timestamp: scheduled))
                            } else {
                                text = strings().chatServiceVoiceChatStartedChannel1
                            }
                        } else if authorId == context.peerId {
                            if let scheduled = scheduleDate {
                                text = strings().chatServiceVoiceChatScheduledYou(stringForMediumDate(timestamp: scheduled))
                            } else {
                                text = strings().chatServiceVoiceChatStartedYou
                            }
                        } else {
                            if let scheduled = scheduleDate {
                                text = strings().chatServiceVoiceChatScheduled(authorName, stringForMediumDate(timestamp: scheduled))
                            } else {
                                text = strings().chatServiceVoiceChatStarted(authorName)
                            }
                        }
                        let parsed = parseMarkdownIntoAttributedString(text, attributes: MarkdownAttributes.init(body: MarkdownAttributeSet(font: .normal(theme.fontSize), textColor: grayTextColor), bold: MarkdownAttributeSet(font: .medium(theme.fontSize), textColor: grayTextColor), link: MarkdownAttributeSet(font: .medium(theme.fontSize), textColor: linkColor), linkAttribute: { [weak chatInteraction] link in
                            return (NSAttributedString.Key.link.rawValue, inAppLink.callback("", { _ in
                                
                                let call = chatInteraction?.presentation.groupCall?.activeCall ?? CachedChannelData.ActiveCall(id: callId, accessHash: accessHash, title: nil, scheduleTimestamp: scheduleDate, subscribedToScheduled: false, isStream: false)
                                
                                chatInteraction?.joinGroupCall(call, nil)
                            }))
                        }))
                        attributedString.append(parsed)
                    }
                    
                    if let authorId = authorId {
                        let range = attributedString.string.nsstring.range(of: authorName)
                        if range.location != NSNotFound {
                            attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                            attributedString.addAttribute(.font, value: NSFont.medium(theme.fontSize), range: range)
                        }
                    }
                case let .setChatTheme(emoji):
                    let text: String
                    
                    if message.author?.id == context.peerId {
                        if emoji.isEmpty {
                            text = strings().chatServiceDisabledThemeYou
                        } else {
                            text = strings().chatServiceUpdateThemeYou(emoji)
                        }
                    } else {
                        if emoji.isEmpty {
                            text = strings().chatServiceDisabledTheme(authorName)
                        } else {
                            text = strings().chatServiceUpdateTheme(authorName, emoji)
                        }
                    }
                    
                    let parsed = parseMarkdownIntoAttributedString(text, attributes: MarkdownAttributes.init(body: MarkdownAttributeSet(font: .normal(theme.fontSize), textColor: grayTextColor), bold: MarkdownAttributeSet(font: .medium(theme.fontSize), textColor: grayTextColor), link: MarkdownAttributeSet(font: .medium(theme.fontSize), textColor: linkColor), linkAttribute: { link in
                        return (NSAttributedString.Key.link.rawValue, inAppLink.callback("", { _ in
                            
                        }))
                    }))
                    attributedString.append(parsed)

                    if let authorId = authorId {
                        let range = attributedString.string.nsstring.range(of: authorName)
                        if range.location != NSNotFound {
                            attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                            attributedString.addAttribute(.font, value: NSFont.medium(theme.fontSize), range: range)
                        }
                    }
                    
                    if !emoji.isEmpty {
                        let range = attributedString.string.nsstring.range(of: emoji)
                        if range.location != NSNotFound {
                            attributedString.add(link:inAppLink.callback("", { [weak chatInteraction] _ in
                                chatInteraction?.setupChatThemes()
                            }), for: range, color: linkColor)
                        }
                    }

                    
                case let .inviteToGroupPhoneCall(callId, accessHash, peerIds):
                    let text: String
                    
                    let list = NSMutableAttributedString()
                    for peerId in peerIds {
                        
                        if let peer = message.peers[peerId] {
                            let range = list.append(string: peer.displayTitle, color: nameColor(peerId), font: .medium(theme.fontSize))
                            list.add(link:inAppLink.peerInfo(link: "", peerId:peerId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(peer.id))
                            if peerId != peerIds.last {
                                _ = list.append(string: ", ", color: grayTextColor, font: .normal(theme.fontSize))
                            }
                        }
                    }
                    
                    if message.author?.id == context.peerId {
                        text = strings().chatServiceVoiceChatInvitationByYou("%mark%")
                    } else if peerIds.first == context.peerId {
                        text = strings().chatServiceVoiceChatInvitationForYou(authorName)
                    } else {
                        text = strings().chatServiceVoiceChatInvitation(authorName, "%mark%")
                    }
                    
                    let parsed = parseMarkdownIntoAttributedString(text, attributes: MarkdownAttributes.init(body: MarkdownAttributeSet(font: .normal(theme.fontSize), textColor: grayTextColor), bold: MarkdownAttributeSet(font: .medium(theme.fontSize), textColor: grayTextColor), link: MarkdownAttributeSet(font: .medium(theme.fontSize), textColor: linkColor), linkAttribute: { [weak chatInteraction] link in
                        return (NSAttributedString.Key.link.rawValue, inAppLink.callback("", { _ in
                            chatInteraction?.joinGroupCall(CachedChannelData.ActiveCall(id: callId, accessHash: accessHash, title: nil, scheduleTimestamp: nil, subscribedToScheduled: false, isStream: false), nil)
                        }))
                    }))
                    attributedString.append(parsed)
                    
                    let markRange = attributedString.string.nsstring.range(of: "%mark%")
                    if markRange.location != NSNotFound {
                        attributedString.replaceCharacters(in: markRange, with: list)
                    }

                    if let authorId = authorId {
                        let range = attributedString.string.nsstring.range(of: authorName)
                        if range.location != NSNotFound {
                            attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                            attributedString.addAttribute(.font, value: NSFont.medium(theme.fontSize), range: range)
                        }
                    }
                case .joinedByRequest:
                    let text: String
                    if authorId == context.peerId {
                        if message.peers[message.id.peerId]?.isChannel == true {
                            text = strings().chatServiceJoinedChannelByRequest
                        } else {
                            text = strings().chatServiceJoinedGroupByRequest
                        }
                    } else {
                        if message.peers[message.id.peerId]?.isChannel == true {
                            text = strings().chatServiceUserJoinedChannelByRequest(authorName)
                        } else {
                            text = strings().chatServiceUserJoinedGroupByRequest(authorName)
                        }
                    }
                    let _ =  attributedString.append(string: text, color: grayTextColor, font: NSFont.normal(theme.fontSize))
                    
                    if let authorId = authorId {
                        let range = attributedString.string.nsstring.range(of: authorName)
                        attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                        attributedString.addAttribute(.font, value: NSFont.medium(theme.fontSize), range: range)
                    }
                case let .webViewData(text):
                    let _ =  attributedString.append(string: strings().chatServiceWebData(text), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                case let .giftPremium(currency, amount, months, cryptoCurrency, cryptoCurrencyAmount):
                    
                    let info = NSMutableAttributedString()
                    _ = info.append(string: strings().chatServicePremiumGiftInfoCountable(Int(months)), color: grayTextColor, font: .normal(theme.fontSize))
                    info.detectBoldColorInString(with: .medium(theme.fontSize))
                    
                    self.giftData = .init(from: authorId ?? message.id.peerId, to: message.id.peerId, text: TextViewLayout(info, alignment: .center), months: months)
                    
                    let text: String
                    if authorId == context.peerId {
                        text = strings().chatServicePremiumGiftSentYou(formatCurrencyAmount(amount, currency: currency))
                    } else {
                        text = strings().chatServicePremiumGiftSent(authorName, formatCurrencyAmount(amount, currency: currency))
                    }
                    let _ =  attributedString.append(string: text, color: grayTextColor, font: NSFont.normal(theme.fontSize))
                    
                    if let authorId = authorId {
                        let range = attributedString.string.nsstring.range(of: authorName)
                        attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                        attributedString.addAttribute(.font, value: NSFont.medium(theme.fontSize), range: range)
                    }
                case let .suggestedProfilePhoto(image):
                    
                    
                    if let image = image {
                                                
                        let info = NSMutableAttributedString()
                        if authorId == context.peerId {
                            _ = info.append(string: strings().chatServiceSuggestPhotoInfoYou(message.peers[message.id.peerId]?.compactDisplayTitle ?? ""), color: grayTextColor, font: .normal(.text))
                        } else {
                            _ = info.append(string: strings().chatServiceSuggestPhotoInfo(authorName), color: grayTextColor, font: .normal(.text))
                        }
                        self.suggestPhotoData = .init(from: authorId ?? message.id.peerId, to: message.id.peerId, text: TextViewLayout(info, alignment: .center), isIncoming: authorId != context.peerId, image: image)
                    } else {
                        let text: String
                        if authorId == context.peerId {
                            text = strings().chatServiceYouSuggestedPhoto
                        } else {
                            text = strings().chatServiceSuggestedPhoto(authorName)
                        }
                        let _ = attributedString.append(string: text, color: grayTextColor, font: NSFont.normal(theme.fontSize))
                        
                        if let authorId = authorId {
                            let range = attributedString.string.nsstring.range(of: authorName)
                            attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                            attributedString.addAttribute(.font, value: NSFont.medium(theme.fontSize), range: range)
                        }
                    }
                case let .topicCreated(title, _, iconFileId):
                    let text: String
                    if let iconFileId = iconFileId {
                        text = strings().chatServiceGroupTopicCreatedIcon("~~\(iconFileId)~~", title.prefixWithDots(30))
                    } else {
                        text = strings().chatServiceGroupTopicCreated(title)
                    }
                    let _ =  attributedString.append(string: text, color: grayTextColor, font: NSFont.normal(theme.fontSize))
                    
                    
                    if let authorId = authorId {
                        let range = attributedString.string.nsstring.range(of: authorName)
                        attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                        attributedString.addAttribute(.font, value: NSFont.medium(theme.fontSize), range: range)
                    }
                    if let fileId = iconFileId {
                        let range = text.nsstring.range(of: "~~\(fileId)~~")
                        if range.location != NSNotFound {
                            InlineStickerItem.apply(to: attributedString, associatedMedia: [:], entities: [.init(range: range.lowerBound ..< range.upperBound, type: .CustomEmoji(stickerPack: nil, fileId: fileId))], isPremium: context.isPremium)
                        }
                    }
                case let .topicEdited(components):
                    let text: String
                    var fileId: Int64? = nil
                    if let component = components.first {
                        switch component {
                        case let .title(title):
                            if authorId == context.peerId {
                                text = strings().chatServiceGroupTopicEditedYouTitle(title.prefixWithDots(30))
                            } else {
                                text = strings().chatServiceGroupTopicEditedTitle(authorName, title.prefixWithDots(30))
                            }
                        case let .iconFileId(iconFileId):
                            fileId = iconFileId
                            if let iconFileId = iconFileId {
                                if authorId == context.peerId {
                                    text = strings().chatServiceGroupTopicEditedYouIcon("~~\(iconFileId)~~")
                                } else {
                                    text = strings().chatServiceGroupTopicEditedIcon(authorName, "~~\(iconFileId)~~")
                                }
                            } else {
                                if authorId == context.peerId {
                                    text = strings().chatServiceGroupTopicEditedYouIconRemoved
                                } else {
                                    text = strings().chatServiceGroupTopicEditedIconRemoved(authorName)
                                }
                            }
                        case let .isClosed(closed):
                            if authorId == context.peerId {
                                if closed {
                                    text = strings().chatServiceGroupTopicEditedYouPaused
                                } else {
                                    text = strings().chatServiceGroupTopicEditedYouResumed
                                }
                            } else {
                                if closed {
                                    text = strings().chatServiceGroupTopicEditedPaused(authorName)
                                } else {
                                    text = strings().chatServiceGroupTopicEditedResumed(authorName)
                                }
                            }
                        case let .isHidden(hidden):
                            if authorId == context.peerId {
                                if hidden {
                                    text = strings().chatServiceGroupTopicEditedYouHided
                                } else {
                                    text = strings().chatServiceGroupTopicEditedYouUnhided
                                }
                            } else {
                                if hidden {
                                    text = strings().chatServiceGroupTopicEditedHided(authorName)
                                } else {
                                    text = strings().chatServiceGroupTopicEditedUnhided(authorName)
                                }
                            }
                        }
                    } else {
                        var title: String = ""
                        var iconFileId: Int64?
                        for component in components {
                            switch component {
                            case let .title(value):
                                title = value.prefixWithDots(30)
                            case let .iconFileId(value):
                                iconFileId = value
                            case .isClosed:
                                break
                            case .isHidden:
                                break
                            }
                        }
                        fileId = iconFileId
                        if let iconFileId = iconFileId {
                            if authorId == context.peerId {
                                text = strings().chatServiceGroupTopicEditedYouMixed("~~\(iconFileId)~~", title)
                            } else {
                                text = strings().chatServiceGroupTopicEditedMixed(authorName, "~~\(iconFileId)~~", title)
                            }
                        } else {
                            if authorId == context.peerId {
                                text = strings().chatServiceGroupTopicEditedYouTitle(title)
                            } else {
                                text = strings().chatServiceGroupTopicEditedTitle(authorName, title)
                            }
                        }
                    }
                    let _ =  attributedString.append(string: text, color: grayTextColor, font: NSFont.normal(theme.fontSize))
                    
                    if let authorId = authorId {
                        let range = attributedString.string.nsstring.range(of: authorName)
                        attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                        attributedString.addAttribute(.font, value: NSFont.medium(theme.fontSize), range: range)
                    }
                    if let fileId = fileId {
                        let range = text.nsstring.range(of: "~~\(fileId)~~")
                        if range.location != NSNotFound {
                            InlineStickerItem.apply(to: attributedString, associatedMedia: [:], entities: [.init(range: range.lowerBound ..< range.upperBound, type: .CustomEmoji(stickerPack: nil, fileId: fileId))], isPremium: context.isPremium)
                        }
                    }
                case .attachMenuBotAllowed:
                    _ = attributedString.append(string: strings().chatServiceBotWriteAllowed, color: grayTextColor, font: NSFont.normal(theme.fontSize))
                case let .requestedPeer(_, peerId):
                    if let peer = message.peers[peerId], let botPeer = message.peers[message.id.peerId] {
                        let name = peer.displayTitle
                        _ = attributedString.append(string: strings().chatServicePeerRequested(name, botPeer.displayTitle), color: grayTextColor, font: NSFont.normal(theme.fontSize))
                        let range = attributedString.string.nsstring.range(of: name)
                        attributedString.add(link:inAppLink.peerInfo(link: "", peerId: peerId, action:nil, openChat: true, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(peerId))
                        attributedString.addAttribute(.font, value: NSFont.medium(theme.fontSize), range: range)
                    }
                case let .setChatWallpaper(wallpaper):
                    
                    let text: String
                    if authorId == context.peerId {
                        text = strings().chatServiceYouChangedWallpaper
                    } else {
                        text = strings().chatServiceChangedWallpaper(authorName)
                    }
                    let _ = attributedString.append(string: text, color: grayTextColor, font: NSFont.normal(theme.fontSize))
                    
                    if let authorId = authorId {
                        let range = attributedString.string.nsstring.range(of: authorName)
                        attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                        attributedString.addAttribute(.font, value: NSFont.medium(theme.fontSize), range: range)
                    }
                    self.wallpaperData = .init(wallpaper: wallpaper.uiWallpaper, aesthetic: wallpaper, peerId: message.id.peerId, isIncoming: authorId != context.peerId)
                case .setSameChatWallpaper:
                    let text: String
                    if authorId == context.peerId {
                        text = strings().chatServiceYouChangedToSameWallpaper
                    } else {
                        text = strings().chatServiceChangedToSameWallpaper(authorName)
                    }
                    let _ = attributedString.append(string: text, color: grayTextColor, font: NSFont.normal(theme.fontSize))
                    
                    if let authorId = authorId {
                        let range = attributedString.string.nsstring.range(of: authorName)
                        attributedString.add(link:inAppLink.peerInfo(link: "", peerId:authorId, action:nil, openChat: false, postId: nil, callback: chatInteraction.openInfo), for: range, color: nameColor(authorId))
                        attributedString.addAttribute(.font, value: NSFont.medium(theme.fontSize), range: range)
                    }
                default:
                    break
                }
            }
        } else if let media = message.media[0] as? TelegramMediaExpiredContent {
            let text:String
            switch media.data {
            case .image:
                text = strings().serviceMessageExpiredPhoto
            case .file:
                if message.id.peerId.namespace == Namespaces.Peer.SecretChat {
                    text = strings().serviceMessageExpiredVideo
                } else {
                    text = strings().serviceMessageExpiredVideo
                }
            }
            _ = attributedString.append(string: text, color: grayTextColor, font: .normal(theme.fontSize))
        } else if message.id.peerId.namespace == Namespaces.Peer.CloudUser, message.autoremoveAttribute != nil || message.autoclearTimeout != nil {
            let isPhoto: Bool = message.anyMedia is TelegramMediaImage
            if authorId == context.peerId {
                _ = attributedString.append(string: isPhoto ? strings().serviceMessageDesturctingPhotoYou(authorName) : strings().serviceMessageDesturctingVideoYou(authorName), color: grayTextColor, font: .normal(theme.fontSize))
            } else if let _ = authorId {
                _ = attributedString.append(string:  isPhoto ? strings().serviceMessageDesturctingPhoto(authorName) : strings().serviceMessageDesturctingVideo(authorName), color: grayTextColor, font: .normal(theme.fontSize))
            }
        }
        
        
        text = TextViewLayout(attributedString, truncationType: .end, cutout: nil, alignment: .center)
        text.mayItems = false
        text.interactions = globalLinkExecutor
        super.init(initialSize, chatInteraction, entry, downloadSettings, theme: theme)
    }
    
    override func makeContentSize(_ width: CGFloat) -> NSSize {
        return NSZeroSize
    }
    
    override var isBubbled: Bool {
        return presentation.wallpaper.wallpaper != .none && super.isBubbled
    }
    
    override var height: CGFloat {
        var height:CGFloat = text.layoutSize.height + (isBubbled ? 0 : 12)
        if let imageArguments = imageArguments {
            height += imageArguments.imageSize.height + (isBubbled ? 9 : 6)
        }
        if let data = self.giftData {
            height += data.height + (isBubbled ? 9 : 6)
        }
        if let data = self.suggestPhotoData {
            height += data.height + (isBubbled ? 9 : 6)
        }
        if let data = self.wallpaperData {
            height += data.height + (isBubbled ? 9 : 6)
        }
        return height
    }
    
    override func makeSize(_ width: CGFloat, oldWidth:CGFloat) -> Bool {
        text.measure(width: width - 40)
        if isBubbled {
            if shouldBlurService {
                text.generateAutoBlock(backgroundColor: presentation.chatServiceItemColor.withAlphaComponent(1))
            } else {
                text.generateAutoBlock(backgroundColor: presentation.chatServiceItemColor)
            }
        }
        return true
    }
    
    override var shouldBlurService: Bool {
        if context.isLite(.blur) {
            return false
        }
        return presentation.shouldBlurService
    }
    
    override func viewClass() -> AnyClass {
        return ChatServiceRowView.self
    }
    
    func openPhotoEditor(_ image: TelegramMediaImage) -> Void {
        let resource: Signal<MediaResourceData, NoError>
        let context = self.context
        let isVideo: Bool
        let peerId = context.peerId
        if let video = image.videoRepresentations.last {
            resource = context.account.postbox.mediaBox.resourceData(video.resource)
            isVideo = true
        } else if let rep = image.representationForDisplayAtSize(.init(640, 640)) {
            resource = context.account.postbox.mediaBox.resourceData(rep.resource)
            isVideo = false
        } else {
            resource = .complete()
            isVideo = false
        }
        
        let photoDisposable = MetaDisposable()
        
        let updatePhoto:(Signal<NSImage, NoError>)->Void = { image in
            let signal = image |> mapToSignal {
                putToTemp(image: $0, compress: true)
            } |> deliverOnMainQueue
            _ = signal.start(next: { path in
                let controller = EditImageModalController(URL(fileURLWithPath: path), context: context, settings: .disableSizes(dimensions: .square), doneString: strings().modalSet)
                showModal(with: controller, for: context.window, animationType: .scaleCenter)
                
                let updateSignal = controller.result |> map { path, _ -> TelegramMediaResource in
                    return LocalFileReferenceMediaResource(localFilePath: path.path, randomId: arc4random64())
                    } |> castError(UploadPeerPhotoError.self) |> mapToSignal { resource -> Signal<UpdatePeerPhotoStatus, UploadPeerPhotoError> in
                        return context.engine.accountData.updateAccountPhoto(resource: resource, videoResource: nil, videoStartTimestamp: nil, markup: nil, mapResourceToAvatarSizes: { resource, representations in
                            return mapResourceToAvatarSizes(postbox: context.account.postbox, resource: resource, representations: representations)
                        })
                    } |> deliverOnMainQueue
                
                photoDisposable.set(updateSignal.start(next: { result in
                    switch result {
                    case .complete:
                        showModalText(for: context.window, text: strings().chatServiceSuggestSuccess)
                    default:
                        break
                    }
                }, error: { error in
                    showModalText(for: context.window, text: strings().unknownError)
                }))
            })
        }
        
        
            
        let updateVideo:(Signal<VideoAvatarGeneratorState, NoError>) -> Void = { signal in
                            
            let updateSignal: Signal<UpdatePeerPhotoStatus, UploadPeerPhotoError> = signal
            |> castError(UploadPeerPhotoError.self)
            |> mapToSignal { state in
                switch state {
                case .error:
                    return .fail(.generic)
                case .start:
                    return .next(.progress(0))
                case let .progress(value):
                    return .next(.progress(value * 0.2))
                case let .complete(thumb, video, keyFrame):
                    let (thumbResource, videoResource) = (LocalFileReferenceMediaResource(localFilePath: thumb, randomId: arc4random64(), isUniquelyReferencedTemporaryFile: true),
                                                          LocalFileReferenceMediaResource(localFilePath: video, randomId: arc4random64(), isUniquelyReferencedTemporaryFile: true))
                    return context.engine.peers.updatePeerPhoto(peerId: peerId, photo: context.engine.peers.uploadedPeerPhoto(resource: thumbResource), video: context.engine.peers.uploadedPeerVideo(resource: videoResource) |> map(Optional.init), videoStartTimestamp: keyFrame, mapResourceToAvatarSizes: { resource, representations in
                        return mapResourceToAvatarSizes(postbox: context.account.postbox, resource: resource, representations: representations)
                    }) |> map { result in
                        switch result {
                        case let .progress(current):
                            return .progress(0.2 + (current * 0.8))
                        default:
                            return result
                        }
                    }
                }
            } |> deliverOnMainQueue
            photoDisposable.set(updateSignal.start(next: { result in
                switch result {
                case .complete:
                    showModalText(for: context.window, text: strings().chatServiceSuggestSuccess)
                default:
                    break
                }
            }, error: { error in
                showModalText(for: context.window, text: strings().unknownError)
            }))
        }
        
        let data = resource |> filter { $0.complete } |> take(1)
        
        _ = showModalProgress(signal: data, for: context.window).start(next: { data in
            let ext: String
            if isVideo {
                ext = ".mp4"
            } else {
                ext = ".jpeg"
            }
            let path = NSTemporaryDirectory() + data.path.nsstring.lastPathComponent + ext
            
            try? FileManager.default.copyItem(atPath: data.path, toPath: path)
            
            if isVideo {
                selectVideoAvatar(context: context, path: path, localize: "", signal: { signal in
                    updateVideo(signal)
                })
            } else {
                if let image = NSImage(contentsOf: .init(fileURLWithPath: path)) {
                    updatePhoto(.single(image))
                }
            }
        })
    }
}

class ChatServiceRowView: TableRowView {
    
    private class GiftView : Control {
        
        private let disposable = MetaDisposable()
        private let stickerView: MediaAnimatedStickerView = MediaAnimatedStickerView(frame: NSMakeSize(150, 150).bounds)
        
        private var visualEffect: VisualEffect?
        
        private let textView = TextView()
        
        required init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            addSubview(stickerView)
            addSubview(textView)
            textView.userInteractionEnabled = false
            textView.isSelectable = false
            
            stickerView.userInteractionEnabled = false 
            self.scaleOnClick = true
            layer?.cornerRadius = 10
        }
        
        func update(item: ChatServiceItem, data: ChatServiceItem.GiftData, animated: Bool) {
            
            let context = item.context
            
            let alt:String = data.alt
            
            
            textView.update(data.text)
            
            let stickerFile: Signal<TelegramMediaFile, NoError> = item.context.giftStickers
            |> map { items in
                return items.first(where: {
                    $0.stickerText?.fixed == alt
                }) ?? items.first
            }
            |> filter { $0 != nil }
            |> map { $0! }
            |> take(1)
            |> deliverOnMainQueue
            
            disposable.set(stickerFile.start(next: { [weak self] file in
                self?.setFile(file, context: context)
            }))
            
            if item.shouldBlurService {
                let current: VisualEffect
                if let view = self.visualEffect {
                    current = view
                } else {
                    current = VisualEffect(frame: bounds)
                    self.visualEffect = current
                    addSubview(current, positioned: .below, relativeTo: self.subviews.first)
                }
                current.bgColor = item.presentation.blurServiceColor
                
                self.backgroundColor = .clear
                
            } else if let view = visualEffect {
                performSubviewRemoval(view, animated: animated)
                self.visualEffect = nil
                self.backgroundColor = item.presentation.chatServiceItemColor
            }
        }
        
        private func setFile(_ file: TelegramMediaFile, context: AccountContext) {
            let parameters = ChatAnimatedStickerMediaLayoutParameters(playPolicy: .onceEnd, media: file)
            stickerView.update(with: file, size: NSMakeSize(150, 150), context: context, table: nil, parameters: parameters, animated: false)
            needsLayout = true
        }
        
        override func layout() {
            super.layout()
            stickerView.centerX(y: 0)
            textView.centerX(y: stickerView.frame.height + 10)
        }
        
        deinit {
            disposable.dispose()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    private class SuggestView : Control {
        

        var interactive: NSView? {
            return self.photo ?? self.photoVideoView
        }
        
        private let disposable = MetaDisposable()
        private var photo: TransformImageView?
        
        private var photoVideoView: MediaPlayerView?
        private var photoVideoPlayer: MediaPlayer?

        private var visualEffect: VisualEffect?
        
        private let textView = TextView()
                
        fileprivate let viewButton = TitleButton()
        
        required init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            addSubview(textView)
            addSubview(viewButton)
            textView.userInteractionEnabled = false
            textView.isSelectable = false
            
            viewButton.scaleOnClick = true
            viewButton.autohighlight = false
            self.scaleOnClick = true
            layer?.cornerRadius = 10
        }
        
        private var videoRepresentation: TelegramMediaImage.VideoRepresentation?

        
        func update(item: ChatServiceItem, data: ChatServiceItem.SuggestPhotoData, animated: Bool) {
            
            let size = NSMakeSize(100, 100)
            
            if item.shouldBlurService {
                let current: VisualEffect
                if let view = self.visualEffect {
                    current = view
                } else {
                    current = VisualEffect(frame: bounds)
                    self.visualEffect = current
                    addSubview(current, positioned: .below, relativeTo: self.subviews.first)
                }
                current.bgColor = item.presentation.blurServiceColor
                
                self.backgroundColor = .clear
                
            } else if let view = visualEffect {
                performSubviewRemoval(view, animated: animated)
                self.visualEffect = nil
                self.backgroundColor = item.presentation.chatServiceItemColor
            }
            
            if let represenstation = data.image.representationForDisplayAtSize(.init(640, 640)) {
                
                let arguments = TransformImageArguments(corners: .init(radius: size.height / 2), imageSize: represenstation.dimensions.size, boundingSize: size, intrinsicInsets: .init())
                
                let photo: TransformImageView
                if let view = self.photo {
                    photo = view
                } else {
                    photo = TransformImageView(frame: size.bounds)
                    self.photo = photo
                    addSubview(photo)
                }
                
                photo.setSignal(signal: cachedMedia(media: data.image, arguments: arguments, scale: System.backingScale))
                
                if !photo.isFullyLoaded, let message = item.message {
                    photo.setSignal(chatMessagePhoto(account: item.context.account, imageReference: .message(message: .init(message), media: data.image), scale: System.backingScale, autoFetchFullSize: true), cacheImage: { result in
                        cacheMedia(result, media: data.image, arguments: arguments, scale: System.backingScale)
                    })
                }
                
                photo.set(arguments: arguments)
            } else if let photo = self.photo {
                performSubviewRemoval(photo, animated: animated)
                self.photo = nil
            }
            
            if let video = data.image.videoRepresentations.last {
                let equal = videoRepresentation?.resource.id == video.resource.id
                
                if !equal {
                    self.photoVideoView?.removeFromSuperview()
                    self.photoVideoView = nil
                    
                    self.photoVideoView = MediaPlayerView(backgroundThread: true)
                    photoVideoView?.layer?.cornerRadius = size.height / 2
                    if #available(macOS 10.15, *) {
                        self.photoVideoView?.layer?.cornerCurve = .circular
                    }
                    self.addSubview(self.photoVideoView!)
                    self.photoVideoView!.isEventLess = true
                    
                    self.photoVideoView!.frame = size.bounds

                    let file = TelegramMediaFile(fileId: MediaId(namespace: 0, id: 0), partialReference: nil, resource: video.resource, previewRepresentations: data.image.representations, videoThumbnails: [], immediateThumbnailData: nil, mimeType: "video/mp4", size: video.resource.size, attributes: [])
                    
                    
                    let reference: MediaResourceReference
                    
                    if let peer = item.peer, let peerReference = PeerReference(peer) {
                        reference = MediaResourceReference.avatar(peer: peerReference, resource: file.resource)
                    } else {
                        reference = MediaResourceReference.standalone(resource: file.resource)
                    }
                    
                    let userLocation: MediaResourceUserLocation
                    if let id = item.message?.id.peerId {
                        userLocation = .peer(id)
                    } else {
                        userLocation = .other
                    }
                    
                    let mediaPlayer = MediaPlayer(postbox: item.context.account.postbox, userLocation: userLocation, userContentType: .avatar, reference: reference, streamable: true, video: true, preferSoftwareDecoding: false, enableSound: false, fetchAutomatically: true)
                    
                    mediaPlayer.actionAtEnd = .loop(nil)
                    
                    self.photoVideoPlayer = mediaPlayer
                    
                    if let seekTo = video.startTimestamp {
                        mediaPlayer.seek(timestamp: seekTo)
                    }
                    mediaPlayer.attachPlayerView(self.photoVideoView!)
                    self.videoRepresentation = video
                }
            } else {
                self.photoVideoPlayer = nil
                self.photoVideoView?.removeFromSuperview()
                self.photoVideoView = nil
                self.videoRepresentation = nil
            }
                        
            textView.update(data.text)
            
            viewButton.set(font: .normal(.text), for: .Normal)
            viewButton.set(color: item.shouldBlurService ? .white : theme.colors.underSelectedColor, for: .Normal)
            viewButton.set(background: item.shouldBlurService ? item.presentation.chatServiceItemColor.withAlphaComponent(0.5) : item.presentation.colors.accent, for: .Normal)
            viewButton.set(text: strings().chatServiceSuggestView, for: .Normal)
            viewButton.sizeToFit(NSMakeSize(20, 12))
            
            viewButton.layer?.cornerRadius = viewButton.frame.height / 2
            needsLayout = true
        }
        
        func updateAnimatableContent() -> Void {
            let accept = window != nil && window!.isKeyWindow && !NSIsEmptyRect(visibleRect) && !self.isDynamicContentLocked
            
            if let photoVideoPlayer = photoVideoPlayer {
                if accept {
                    photoVideoPlayer.play()
                } else {
                    photoVideoPlayer.pause()
                }
            }
        }
        
        override func layout() {
            super.layout()
            visualEffect?.frame = bounds
            photo?.centerX(y: 10)
            photoVideoView?.centerX(y: 10)
            textView.centerX(y: 110 + 10)
            viewButton.centerX(y: textView.frame.maxY + 10)
        }
        
        deinit {
            disposable.dispose()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    private class WallpaperView : Control {
        
        private let disposable = MetaDisposable()
        private let wallpaper: TransformImageView = TransformImageView(frame: NSMakeRect(0, 0, 100, 100))
        

        private var visualEffect: VisualEffect?
                        
        fileprivate let viewButton = TitleButton()
        private var progressView: RadialProgressView?
        private let statusDisposable = MetaDisposable()
        private var progressText: TextView?
        
        
        required init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            addSubview(wallpaper)
            addSubview(viewButton)
            viewButton.scaleOnClick = true
            viewButton.autohighlight = false
            self.scaleOnClick = true
            self.wallpaper.layer?.cornerRadius = 50
            layer?.cornerRadius = 10
        }
        
        private var message: Message?
        
        func update(item: ChatServiceItem, data: ChatServiceItem.WallpaperData, animated: Bool) {
            
            let previous = self.message
            
            guard let messageId = item.message?.id else {
                return
            }
            
            viewButton.isHidden = messageId.namespace == Namespaces.Message.Local
            
            self.message = item.message
            
            let mediaUpdated = previous?.stableId != item.message?.stableId
            
            let context = item.context
            
            let size = NSMakeSize(100, 100)
            if messageId.namespace == Namespaces.Message.Local {
                self.statusDisposable.set((item.context.account.pendingPeerMediaUploadManager.uploadProgress(messageId: messageId)
                |> deliverOnMainQueue).start(next: { [weak self, weak item] progress in
                    if let item = item {
                        self?.updateProgress(progress, messageId: messageId, item: item, context: context)
                    }
                }))
            } else {
                self.statusDisposable.set(nil)
                self.updateProgress(nil, messageId: messageId, item: item, context: context)
            }
            
            if item.shouldBlurService {
                let current: VisualEffect
                if let view = self.visualEffect {
                    current = view
                } else {
                    current = VisualEffect(frame: bounds)
                    self.visualEffect = current
                    addSubview(current, positioned: .below, relativeTo: self.subviews.first)
                }
                current.bgColor = item.presentation.blurServiceColor
                
                self.backgroundColor = .clear
                
            } else if let view = visualEffect {
                performSubviewRemoval(view, animated: animated)
                self.visualEffect = nil
                self.backgroundColor = item.presentation.chatServiceItemColor
            }
            let updateImageSignal = wallpaperPreview(account: item.context.account, palette: item.presentation.colors, wallpaper: data.wallpaper, mode: .thumbnail)
            
            let arguments = TransformImageArguments(corners: .init(), imageSize: size, boundingSize: size, intrinsicInsets: .init())
            
            let settings = TelegramThemeSettings.init(baseTheme: .classic, accentColor: 0, outgoingAccentColor: nil, messageColors: [], animateMessageColors: false, wallpaper: data.aesthetic)
            
            wallpaper.setSignal(signal: cachedMedia(media: settings, arguments: arguments, scale: System.backingScale), clearInstantly: mediaUpdated)
            
            if !wallpaper.isFullyLoaded {
                wallpaper.setSignal(updateImageSignal, clearInstantly: mediaUpdated, cacheImage: { result in
                    cacheMedia(result, media: settings, arguments: arguments, scale: System.backingScale)
                })
            }
            
            wallpaper.set(arguments: arguments)
                        
            viewButton.set(font: .normal(.text), for: .Normal)
            viewButton.set(color: item.shouldBlurService ? .white : theme.colors.underSelectedColor, for: .Normal)
            viewButton.set(background: item.shouldBlurService ? item.presentation.chatServiceItemColor.withAlphaComponent(0.5) : item.presentation.colors.accent, for: .Normal)
            viewButton.set(text: data.isIncoming ? strings().chatServiceViewBackground : strings().chatServiceUpdateBackground, for: .Normal)
            viewButton.sizeToFit(NSMakeSize(20, 12))
            
            viewButton.layer?.cornerRadius = viewButton.frame.height / 2
            needsLayout = true
        }
        
        
        private func updateProgress(_ progress: Float?, messageId: MessageId, item: ChatServiceItem, context: AccountContext) {
            if let progress = progress {
                let current: RadialProgressView
                if let view = self.progressView {
                    current = view
                } else {
                    current = RadialProgressView(theme:RadialProgressTheme(backgroundColor: .blackTransparent, foregroundColor: .white, icon: playerPlayThumb))
                    current.frame = wallpaper.focus(NSMakeSize(40, 40))
                    self.progressView = current
                    wallpaper.addSubview(current)
                    
                }
                current.fetchControls = .init(fetch: {
                    context.account.pendingPeerMediaUploadManager.cancel(peerId: messageId.peerId)
                })
                current.state = .Fetching(progress: progress, force: false)
                
                
                let progressTextView: TextView
                if let view = self.progressText {
                    progressTextView = view
                } else {
                    progressTextView = TextView()
                    progressTextView.userInteractionEnabled = false
                    progressTextView.isSelectable = false
                    self.progressText = progressTextView
                    self.addSubview(progressTextView)
                }
                let text = strings().chatServiceUploadingWallpaper("\(Int(progress * 100))")
                let attr = NSMutableAttributedString()
                attr.append(string: text, color: item.presentation.chatServiceItemTextColor, font: .normal(.short))
                attr.detectBoldColorInString(with: .medium(.short))
                let layout = TextViewLayout(attr, alignment: .center)
                layout.measure(width: frame.width - 40)
                progressTextView.update(layout)
            } else {
                if let view = self.progressView {
                    performSubviewRemoval(view, animated: true)
                    self.progressView = nil
                }
                if let view = self.progressText {
                    performSubviewRemoval(view, animated: true)
                    self.progressText = nil
                }
            }
            needsLayout = true
        }

        
        override func layout() {
            super.layout()
            visualEffect?.frame = bounds
            wallpaper.centerX(y: 10)
            viewButton.centerX(y: wallpaper.frame.maxY + 10)
            progressText?.centerX(y: wallpaper.frame.maxY + 10)
            progressView?.center()
        }
        
        deinit {
            statusDisposable.dispose()
            disposable.dispose()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    
    
    private var textView:TextView
    private var imageView:TransformImageView?
    
    private var photoVideoView: MediaPlayerView?
    private var photoVideoPlayer: MediaPlayer?
    
    private var giftView: GiftView?
    private var suggestView: SuggestView?
    private var wallpaperView: WallpaperView?

    private var inlineStickerItemViews: [InlineStickerItemLayer.Key: InlineStickerItemLayer] = [:]
    
    required init(frame frameRect: NSRect) {
        textView = TextView()
        textView.isSelectable = false
        //textView.userInteractionEnabled = false
        //do not enable
       // textView.isEventLess = true
        super.init(frame: frameRect)
        //layerContentsRedrawPolicy = .onSetNeedsDisplay
        addSubview(textView)


        textView.set(handler: { [weak self] control in
            if let item = self?.item as? ChatServiceItem {
                if let message = item.message, let action = message.extendedMedia as? TelegramMediaAction {
                    switch action.action {
                    case let .messageAutoremoveTimeoutUpdated(timeout, _):
                        if let peer = item.chatInteraction.peer {
                            if peer.canManageDestructTimer, timeout > 0 {
                                item.chatInteraction.showDeleterSetup(control)
                            }
                        }
                    default:
                        break
                    }
                }
            }
        }, for: .Click)
    }
    
    override var backdorColor: NSColor {
        if let item = item as? ChatServiceItem {
            return item.isBubbled ? .clear : item.presentation.chatBackground
        } else {
            return .clear
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layout() {
        super.layout()
        
        if let item = item as? ChatServiceItem {
            textView.update(item.text)
            textView.centerX(y:6)
            if let imageArguments = item.imageArguments {
                imageView?.setFrameSize(imageArguments.imageSize)
                imageView?.centerX(y:textView.frame.maxY + (item.isBubbled ? 0 : 6))
                self.imageView?.set(arguments: imageArguments)
                self.photoVideoView?.centerX(y:textView.frame.maxY + (item.isBubbled ? 0 : 6))
            }
            if let view = giftView {
                view.centerX(y: textView.frame.maxY + (item.isBubbled ? 0 : 6))
            }
            if let view = suggestView {
                view.centerX(y: textView.frame.maxY + (item.isBubbled ? 0 : 6))
            }
            if let view = wallpaperView {
                view.centerX(y: textView.frame.maxY + (item.isBubbled ? 0 : 6))
            }
        }
    }
    
    
    override func doubleClick(in location: NSPoint) {
        if let item = self.item as? ChatRowItem, item.chatInteraction.presentation.state == .normal {
            if self.hitTest(location) == nil || self.hitTest(location) == self {
                item.chatInteraction.setupReplyMessage(item.message?.id)
            }
        }
    }
    
    
    func updatePlayerIfNeeded() {
        let accept = window != nil && window!.isKeyWindow && !NSIsEmptyRect(visibleRect) && !self.isDynamicContentLocked
        if let photoVideoPlayer = photoVideoPlayer {
            if accept {
                photoVideoPlayer.play()
            } else {
                photoVideoPlayer.pause()
            }
        }
    }
    
    override func addAccesoryOnCopiedView(innerId: AnyHashable, view: NSView) {
        photoVideoPlayer?.seek(timestamp: 0)
    }

    
    
    override func mouseUp(with event: NSEvent) {
        if let imageView = imageView, imageView._mouseInside() {
            if let item = self.item as? ChatServiceItem {
                showPhotosGallery(context: item.context, peerId: item.chatInteraction.peerId, firstStableId: item.stableId, item.table, nil)
            }
        } else {
            super.mouseUp(with: event)
        }
    }
    
    override func interactionContentView(for innerId: AnyHashable, animateIn: Bool) -> NSView {
        return self.suggestView?.interactive ?? imageView ?? self
    }
    
    
    override func set(item: TableRowItem, animated: Bool) {
        super.set(item: item, animated:animated)
        textView.disableBackgroundDrawing = true

        guard let item = item as? ChatServiceItem else {
            return
        }
        
        
        
        if item.shouldBlurService {
            textView.blurBackground = item.presentation.blurServiceColor
            textView.backgroundColor = .clear
        } else {
            textView.blurBackground = nil
            textView.backgroundColor = .clear
        }

        var interactiveTextView: Bool = false

        if let message = item.message, let action = message.extendedMedia as? TelegramMediaAction {
            switch action.action {
            case let .messageAutoremoveTimeoutUpdated(timeout, _):
                if let peer = item.chatInteraction.peer {
                    interactiveTextView = peer.canManageDestructTimer && timeout > 0
                }
            default:
                break
            }
        }
        textView.scaleOnClick = interactiveTextView


        if let arguments = item.imageArguments {


            if let image = item.image {
                if imageView == nil {
                    self.imageView = TransformImageView()
                    self.addSubview(imageView!)
                }
                imageView?.setSignal(signal: cachedMedia(media: image, arguments: arguments, scale: backingScaleFactor))
                imageView?.setSignal( chatMessagePhoto(account: item.context.account, imageReference: ImageMediaReference.message(message: MessageReference(item.message!), media: image), toRepresentationSize:NSMakeSize(300, 300), scale: backingScaleFactor, autoFetchFullSize: true), cacheImage: { [weak image] result in
                    if let media = image {
                        cacheMedia(result, media: media, arguments: arguments, scale: System.backingScale, positionFlags: nil)
                    }
                })
                
                
                imageView?.set(arguments: arguments)
                
                
                if let video = image.videoRepresentations.last {
                    if self.photoVideoView == nil {
                        self.photoVideoView = MediaPlayerView()
                        self.photoVideoView!.layer?.cornerRadius = 10
                        self.addSubview(self.photoVideoView!)
                        self.photoVideoView!.isEventLess = true
                    }
                    self.photoVideoView!.frame = NSMakeRect(0, 0, ChatServiceItem.photoSize.width, ChatServiceItem.photoSize.height)
                    
                    let file = TelegramMediaFile(fileId: MediaId(namespace: 0, id: 0), partialReference: nil, resource: video.resource, previewRepresentations: image.representations, videoThumbnails: [], immediateThumbnailData: nil, mimeType: "video/mp4", size: video.resource.size, attributes: [])
                    
                    let userLocation: MediaResourceUserLocation
                    if let id = item.message?.id.peerId {
                        userLocation = .peer(id)
                    } else {
                        userLocation = .other
                    }
                    
                    let mediaPlayer = MediaPlayer(postbox: item.context.account.postbox, userLocation: userLocation, userContentType: .avatar, reference: MediaResourceReference.standalone(resource: file.resource), streamable: true, video: true, preferSoftwareDecoding: false, enableSound: false, fetchAutomatically: true)
                    
                    mediaPlayer.actionAtEnd = .loop(nil)
                    self.photoVideoPlayer = mediaPlayer
                    mediaPlayer.play()
                    
                    if let seekTo = video.startTimestamp {
                        mediaPlayer.seek(timestamp: seekTo)
                    }
                    mediaPlayer.attachPlayerView(self.photoVideoView!)
                    
                } else {
                    self.photoVideoView?.removeFromSuperview()
                    self.photoVideoView = nil
                }
                
            } else {
                imageView?.removeFromSuperview()
                imageView = nil
            }
        } else {
            imageView?.removeFromSuperview()
            imageView = nil
        }
        
        
        if let giftData = item.giftData {
            let context = item.context
            let current: GiftView
            if let view = self.giftView {
                current = view
            } else {
                current = GiftView(frame: NSMakeRect(0, 0, 200, giftData.height))
                self.giftView = current
                addSubview(current)
                
                current.set(handler: { _ in 
                    showModal(with: PremiumBoardingController(context: item.context, source: .gift(from: giftData.from, to: giftData.to, months: giftData.months)), for: context.window)
                }, for: .Click)
            }
            
            current.update(item: item, data: giftData, animated: animated)
        } else if let view = self.giftView {
            performSubviewRemoval(view, animated: animated)
            self.giftView = nil
        }
        
        if let data = item.suggestPhotoData {
            let current: SuggestView
            if let view = self.suggestView {
                current = view
            } else {
                current = SuggestView(frame: NSMakeRect(0, 0, 200, data.height))
                self.suggestView = current
                addSubview(current)
                
                let open: (Control)->Void = { [weak self] _ in
                    if let item = self?.item as? ChatServiceItem, let message = item.message {
                        if !data.isIncoming {
                            showChatGallery(context: item.context, message: message, item.table, type: .alone)
                        } else {
                            item.openPhotoEditor(data.image)
                        }
                    }
                }
                current.set(handler: open, for: .Click)
                current.viewButton.set(handler: open, for: .Click)
            }
            
            current.update(item: item, data: data, animated: animated)
        } else if let view = self.suggestView {
            performSubviewRemoval(view, animated: animated)
            self.suggestView = nil
        }
        
        if let data = item.wallpaperData {
            let current: WallpaperView
            if let view = self.wallpaperView {
                current = view
            } else {
                current = WallpaperView(frame: NSMakeRect(0, 0, 200, data.height))
                self.wallpaperView = current
                addSubview(current)
                
                let open: (Control)->Void = { [weak self] _ in
                    if let item = self?.item as? ChatServiceItem, let messageId = item.message?.id, let data = item.wallpaperData {
                        if data.isIncoming {
                            let chatInteraction = item.chatInteraction
                            showModal(with: WallpaperPreviewController(item.context, wallpaper: data.wallpaper, source: .message(messageId, nil), onComplete: { [weak chatInteraction] in
                                chatInteraction?.closeChatThemes()
                            }), for: item.context.window)
                        } else {
                            item.chatInteraction.setupChatThemes()
                        }
                    }
                }
                current.set(handler: open, for: .Click)
                current.viewButton.set(handler: open, for: .Click)
            }
            
            current.update(item: item, data: data, animated: animated)
        } else if let view = self.wallpaperView {
            performSubviewRemoval(view, animated: animated)
            self.wallpaperView = nil
        }

        
        updateInlineStickers(context: item.context, view: self.textView, textLayout: item.text)
        
        
        self.needsLayout = true
    }
    
        
    
    override func updateAnimatableContent() -> Void {
        for (_, value) in inlineStickerItemViews {
            if let superview = value.superview {
                var isKeyWindow: Bool = false
                if let window = self.window {
                    if !window.canBecomeKey {
                        isKeyWindow = true
                    } else {
                        isKeyWindow = window.isKeyWindow
                    }
                }
                value.isPlayable = NSIntersectsRect(value.frame, superview.visibleRect) && isKeyWindow && !isEmojiLite
            }
        }
        self.updatePlayerIfNeeded()
        self.suggestView?.updateAnimatableContent()
    }
    
    override var isEmojiLite: Bool {
        if let item = item as? ChatServiceItem {
            return item.context.isLite(.emoji)
        }
        return super.isEmojiLite
    }
    
    func updateInlineStickers(context: AccountContext, view textView: TextView, textLayout: TextViewLayout) {
        var validIds: [InlineStickerItemLayer.Key] = []
        var index: Int = textView.hashValue

        let textColor: NSColor
        if textLayout.attributedString.length > 0 {
            var range:NSRange = NSMakeRange(NSNotFound, 0)
            let attrs = textLayout.attributedString.attributes(at: 0, effectiveRange: &range)
            textColor = attrs[.foregroundColor] as? NSColor ?? theme.colors.text
        } else {
            textColor = theme.colors.text
        }
        
        for item in textLayout.embeddedItems {
            if let stickerItem = item.value as? InlineStickerItem, case let .attribute(emoji) = stickerItem.source {
                
                let id = InlineStickerItemLayer.Key(id: emoji.fileId, index: index)
                validIds.append(id)
                
                
                var rect: NSRect
                if textLayout.isBigEmoji {
                    rect = item.rect
                } else {
                    rect = item.rect.insetBy(dx: -2, dy: -2)
                }
                if let item = self.item as? ChatServiceItem, item.isBubbled {
                    rect = rect.offsetBy(dx: 9, dy: 2)
                }
                
                let view: InlineStickerItemLayer
                if let current = self.inlineStickerItemViews[id], current.frame.size == rect.size {
                    view = current
                } else {
                    self.inlineStickerItemViews[id]?.removeFromSuperlayer()
                    view = InlineStickerItemLayer(account: context.account, inlinePacksContext: context.inlinePacksContext, emoji: emoji, size: rect.size, textColor: textColor)
                    self.inlineStickerItemViews[id] = view
                    view.superview = textView
                    textView.addEmbeddedLayer(view)
                }
                index += 1
                var isKeyWindow: Bool = false
                if let window = window {
                    if !window.canBecomeKey {
                        isKeyWindow = true
                    } else {
                        isKeyWindow = window.isKeyWindow
                    }
                }
                view.isPlayable = NSIntersectsRect(rect, textView.visibleRect) && isKeyWindow
                view.frame = rect
            }
        }
        
        var removeKeys: [InlineStickerItemLayer.Key] = []
        for (key, itemLayer) in self.inlineStickerItemViews {
            if !validIds.contains(key) {
                removeKeys.append(key)
                itemLayer.removeFromSuperlayer()
            }
        }
        for key in removeKeys {
            self.inlineStickerItemViews.removeValue(forKey: key)
        }
    }
    
    override func onInsert(_ animation: NSTableView.AnimationOptions, appearAnimated: Bool) {
        if let item = item as? ChatRowItem, !isLite(.animations) {
            if item.isBubbled, appearAnimated {
                self.layer?.animateScaleSpring(from: 0.5, to: 1, duration: 0.4, bounce: false)
                self.layer?.animateAlpha(from: 0, to: 1, duration: 0.35)
            }
        }
    }
    
}
