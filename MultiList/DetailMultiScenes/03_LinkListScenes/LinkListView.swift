//
//  LinkListView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/30.
//

import SwiftUI

struct LinkListView: View {
    @StateObject var viewModel: LinkListViewModel
    @ObservedObject var linkList: LinkList
    @ObservedObject var userData: UserData
    
    @State var isPresented: Bool = false
    @State var listTitle: String = ""
    
    @State var notHere: Bool = false
    // Row edit 프라퍼티
    @Binding var editMode: EditMode
    @Binding var isShowingTitleAlert: Bool
    @State var isShowingItemAlert: Bool = false
    @State var newString: String = ""
    @State var newURL: String = ""
    @State var editRow: LinkRow!
    
    @Binding var shareIndex: [Int]
    
    init(userData: UserData, content: LinkList, editMode: Binding<EditMode>, shareIndex: Binding<[Int]>, isShowingTitleAlert: Binding<Bool>) {
        _userData = ObservedObject(wrappedValue: userData)
        _linkList = ObservedObject(wrappedValue: content)
        _viewModel = StateObject(wrappedValue: LinkListViewModel(userData: userData,
                                                                 linkListID: content.id))
        _editMode = editMode
        _shareIndex = shareIndex
        _isShowingTitleAlert = isShowingTitleAlert
    }
    
    var body: some View {
        MaskAndOrderdListView(items: linkList.itemList, editMode: $editMode, rowContent: { item in
            eachLinkItemView(item: item)
        }, onTapAction: { item in
            
        }, onMoveAction: { indexSet, int in
            viewModel.reOrdering(editCase: .reOder, onIndex: int, indexSet: indexSet)
        }, onDeleteAction: { indexSet in
            viewModel.deleteLinkRow(index: indexSet.first!)
        }, isPresentBlurView: isPresented || isShowingItemAlert,
                              blurViewTapAction: {
            isPresented ? self.turnOffAddSection() : self.isShowingItemAlert.toggle()
        }, isPresentAddBttn: $isPresented, 
                              addBttnPlaceHolder: "추가할 링크 주소를 입력해주세요.",
                              bindingStirng: $listTitle) {
            guard let row = editRow else { return }
            viewModel.modifyRow(itemID: row.id,
                                newTitle: newString,
                                newURL: newURL)
        }
          .overlay(alignment: .center) {
              if isShowingItemAlert {
                  CustomAlertView(isShowingAlert: $isShowingItemAlert,
                                  title: "리스트 아이템을 수정합니다.",
                                  text: $newString,
                                  textEditor: $newURL) {
                      guard let row = editRow else { return }
                      viewModel.modifyRow(itemID: row.id,
                                          newTitle: newString,
                                          newURL: newURL)
                  }
              }
          }
    }
    
}

extension LinkListView {
    
    func eachLinkItemView(item: LinkRow) -> some View {
        NavigationLink {
            LinkWebView(linkHistory: [item.url], url: item.url)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(item.title)
        } label: {
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(.white.opacity(0.1))
                Group {
                    if item.title != "" {
                        Text(item.title)
                        + Text("  (\(item.url))")
                            .foregroundColor(.gray)
                    } else {
                        Text(item.url)
                    }
                }
                .lineLimit(1)
                .offset(x: editMode == .active ? 38 : 0)
            }
            .foregroundColor(.black)
            .padding(.leading, editMode == .active ? 0 : 10)
        }
        .disabled(editMode == .active)
        .overlay {
            Color.white.opacity(editMode == .active ? 0.0001 : 0)
                .onTapGesture {
                    editRow = item
                    newString = item.title
                    newURL = item.url
                    withAnimation {
                        isShowingItemAlert = true
                    }
                }
        }
    }
    
    func editRowGesture(item: LinkRow) -> some Gesture {
        TapGesture()
            .onEnded { _ in
                if editMode == .active {
                    newString = item.title
                    newURL = item.url
                    withAnimation {
                        isShowingItemAlert = true
                    }
                }
            }
    }
    
    
    func turnOffAddSection() {
        self.listTitle = ""
        withAnimation(.easeInOut(duration: 0.45)) {
            self.isPresented = false
        }
    }
    
    func listEditButton(name: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Circle()
                .frame(width: 30, height: 30)
                .foregroundColor(.teal)
                .overlay {
                    Text(name)
                        .font(.caption2)
                        .foregroundColor(.white)
                }
        }

    }
}

struct LinkListView_Previews: PreviewProvider {
    static var previews: some View {
        LinkListView1(userData: UserData(),
                     content: sampleLinkList,
                     editMode: .constant(.active),
                     shareIndex: .constant([1]),
                     isShowingTitleAlert: .constant(false))
    }
}
