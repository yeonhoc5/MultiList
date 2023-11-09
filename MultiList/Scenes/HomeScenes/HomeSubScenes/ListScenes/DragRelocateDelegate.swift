//
//  DragRelocateDelegate.swift
//  MultiList
//
//  Created by yeonhoc5 on 10/9/23.
//

import SwiftUI

struct DragRelocateDelegate: DropDelegate {
    @ObservedObject var userData: UserData
    @ObservedObject var viewModel: ListViewModel
    let toSection: SectionList
    let toItem: MultiList!
    @Binding var fromSection: SectionList?
    @Binding var current: MultiList?
    
    let oriSectionType: SectionType!
    let oriSectionIndex: Int!
    let oriMultiIndex: Int!
    
    let finishAction: () -> Void
    
    init(userData: UserData, viewModel: ListViewModel,
         toSection: SectionList, toItem: MultiList! = nil,
         oriSectionType: SectionType! = nil, oriSectionIndex: Int! = nil, oriMultiIndex: Int! = nil,
         fromSection: Binding<SectionList?>, current: Binding<MultiList?>,
         action: @escaping () -> Void) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.toSection = toSection
        self.toItem = toItem
        _fromSection = fromSection
        _current = current
        
        self.oriSectionType = oriSectionType
        self.oriSectionIndex = oriSectionIndex
        self.oriMultiIndex = oriMultiIndex
        
        finishAction = action
    }

    
    func dropEntered(info: DropInfo) {
        guard let fromSection = fromSection,
              let current = current else { return }

        if fromSection.sectionID == userData.sectionShared?.sectionID {
            // 1. shared에서 shared로 (순서만 이동)
            guard let fromIndex = userData.sectionShared.multiList.firstIndex(of: current) else { return }
            if toSection.sectionID == fromSection.sectionID {
                guard let toIndex = userData.sectionShared.multiList.firstIndex(of: toItem) else { return }
                withAnimation {
                    moveItem(oriSection: .share, fromItemIndex: fromIndex, current: current,
                             toSection: .share, toItemInex: toIndex, toItem: toItem)
                }
            } else {
                // 2. shared에서 sectionList로 (섹션 이동)
                guard let toSectionIndex = userData.sectionList.firstIndex(of: toSection),
                      let toIndex = userData.sectionList[toSectionIndex].multiList.firstIndex(of: toItem) else { return }
                withAnimation {
                    moveItem(oriSection: .share, fromItemIndex: fromIndex, current: current,
                             toSection: .list, toSectionIndex: toSectionIndex, toItemInex: toIndex, toItem: toItem)
                    self.fromSection = userData.sectionList[toSectionIndex]
                }
            }
        } else {
            // 2. sectionList에서 sectionList로
            if toSection.sectionID == fromSection.sectionID {
                guard let fromSectionIndex = userData.sectionList.firstIndex(of: fromSection),
                      let fromIndex = userData.sectionList[fromSectionIndex].multiList.firstIndex(of: current) else { return }
                if let toIndex = userData.sectionList[fromSectionIndex].multiList.firstIndex(of: toItem) {
                    withAnimation {
                        moveItem(oriSection: .list, oriSectionIndex: fromSectionIndex, fromItemIndex: fromIndex, current: current,
                                 toSection: .list, toSectionIndex: fromSectionIndex, toItemInex: toIndex, toItem: toItem)
                    }
                } else {
                    let count = toSection.multiList.filter({$0.isTemp == false && $0.isHidden == false}).count
                    let toItem = toSection.multiList[count-1]
                    withAnimation {
                        moveItem(oriSection: .list, oriSectionIndex: fromSectionIndex, fromItemIndex: fromIndex, current: current,
                                 toSection: .list, toSectionIndex: fromSectionIndex, toItemInex: count, toItem: toItem)
                    }
                }
            } else {
                guard let fromSectionIndex = userData.sectionList.firstIndex(of: fromSection),
                      let toSectionIndex = userData.sectionList.firstIndex(of: toSection) else { return }
                guard let fromIndex = userData.sectionList[fromSectionIndex].multiList.firstIndex(of: current) else { return }
                      
                if let toIndex = userData.sectionList[toSectionIndex].multiList.firstIndex(of: toItem) {
                    withAnimation {
                        moveItem(oriSection: .list, oriSectionIndex: fromSectionIndex, fromItemIndex: fromIndex, current: current,
                                 toSection: .list, toSectionIndex: toSectionIndex, toItemInex: toIndex, toItem: toItem)
                        self.fromSection = userData.sectionList[toSectionIndex]
                    }
                } else {
                    let count = toSection.multiList.filter({$0.isTemp == false && $0.isHidden == false}).count
                    let toItem = toSection.multiList[count-1]
                    withAnimation {
                        moveItem(oriSection: .list, oriSectionIndex: fromSectionIndex, fromItemIndex: fromIndex, current: current,
                                 toSection: .list, toSectionIndex: toSectionIndex, toItemInex: count, toItem: toItem)
                        self.fromSection = userData.sectionList[toSectionIndex]
                    }
                }
            }
        }
    }
    
    func moveItem(oriSection: SectionType, oriSectionIndex: Int! = nil, fromItemIndex: Int, current: MultiList,
                  toSection: SectionType, toSectionIndex: Int! = nil, toItemInex: Int, toItem: MultiList) {
        let tempMulti = MultiList(multiID: current.multiID, order: current.order, listType: .checkList, isTemp: true)
        if oriSection == .share {
            if toSection == .share {
                withAnimation {
                    userData.sectionShared.multiList.move(fromOffsets: IndexSet(integer: fromItemIndex),
                                                          toOffset: toItemInex > fromItemIndex ? toItemInex + 1 : toItemInex)
                }
            } else if toSection == .list && toSectionIndex != nil {
                if toItem.multiID != current.multiID {
                    withAnimation {
                        userData.sectionList[toSectionIndex].multiList.insert(tempMulti, at: toItemInex)
                    }
                }
            }
        } else if oriSection == .list && toSection == .list && oriSectionIndex != nil {
            if oriSectionIndex == toSectionIndex {
                withAnimation {
                    userData.sectionList[oriSectionIndex].multiList.move(fromOffsets: IndexSet(integer: fromItemIndex),
                                                                         toOffset: toItemInex > fromItemIndex ? toItemInex+1 : toItemInex)
                }
            } else {
                if toItem.multiID != current.multiID && userData.sectionList[toSectionIndex].multiList.compactMap({$0.multiID}).contains(current.multiID) == false {
                    withAnimation {
                        userData.sectionList[toSectionIndex].multiList.insert(tempMulti, at: toItemInex)
                    }
                }
//                if userData.sectionList[oriSectionIndex].multiList[fromItemIndex].isTemp {
//                    if userData.sectionList[oriSectionIndex].multiList.filter({$0.isHidden == false && $0.isTemp == false}).count > 0 {
//                        withAnimation {
//                            userData.sectionList[oriSectionIndex].multiList.remove(at: fromItemIndex)
//                        }
//                    }
//                }
            }
        } else if toSection == .share {
            if userData.sectionList[oriSectionIndex].multiList[fromItemIndex].isTemp {
                if userData.sectionList[oriSectionIndex].multiList.filter({$0.isHidden == false && $0.isTemp == false}).count > 0 {
                    withAnimation {
                        userData.sectionList[oriSectionIndex].multiList.remove(at: fromItemIndex)
                    }
                }
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        print("dropped?")
        // case / orisectointype / toSectionType / fromsectionIndex(nil) / tosectionindex(nil) / fromMultiIndex / toMultiIndex /
        
        if let current = current {
            if oriSectionType == .share {
                if toSection.sectionID == userData.sectionShared.sectionID {
                    if let toMultiIndex = userData.sectionShared.multiList.firstIndex(of: toItem) {
                        withAnimation {
                            viewModel.moveMultiItem(moveType: .inline,
                                                    fromSectionType: .share,
                                                    fromMultiIndex: self.oriMultiIndex,
                                                    toMultiIndex: toMultiIndex,
                                                    toMoveItem: current)
                        }
                    }
                } else {
                    if let toMultiIndex = userData.sectionList[toSection.order].multiList.firstIndex(of: toItem) {
                        withAnimation {
                            viewModel.moveMultiItem(moveType: .shareToList,
                                                    fromSectionType: .share,
                                                    toSectionIndex: toSection.order,
                                                    fromMultiIndex: oriMultiIndex,
                                                    toMultiIndex: toMultiIndex,
                                                    toMoveItem: current)
                        }
                    }
                }
            } else {
                let count = userData.sectionList[toSection.order].multiList.filter({$0.isHidden == false && $0.isTemp == false}).count
                if oriSectionIndex == toSection.order {
                    if let toMultiIndex = userData.sectionList[toSection.order].multiList.firstIndex(of: toItem) {
                        withAnimation {
                            print(count)
                            viewModel.moveMultiItem(moveType: .inline,
                                                    fromSectionType: .list,
                                                    fromSectionIndex: self.oriSectionIndex,
                                                    toSectionIndex: self.oriSectionIndex,
                                                    fromMultiIndex: self.oriMultiIndex,
                                                    toMultiIndex: toMultiIndex,
                                                    toMoveItem: current)
                            userData.checkMultiListOrder(sectionIndex: toSection.order,
                                                         itemList: userData.sectionList[toSection.order].multiList)
                        }
                    }
                } else if oriSectionType == .list {
                    if let toMultiIndex = userData.sectionList[toSection.order].multiList.firstIndex(of: toItem) {
                        withAnimation {
                            viewModel.moveMultiItem(moveType: .listToList,
                                                    fromSectionType: .list,
                                                    fromSectionIndex: self.oriSectionIndex,
                                                    toSectionIndex: toSection.order,
                                                    fromMultiIndex: oriMultiIndex,
                                                    toMultiIndex: toMultiIndex,
                                                    toMoveItem: current)
                        }
                    }
                }
            }
        }
                
        if let sectionToCheck = userData.sectionList.firstIndex(of: toSection) {
            let multiList = userData.sectionList[sectionToCheck].multiList
            userData.checkMultiListOrder(sectionIndex: sectionToCheck, itemList: multiList)
        }
        
        self.current = nil
        self.fromSection = nil
        finishAction()
        return true
    }
}
