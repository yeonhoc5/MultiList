//
//  LinkListView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/30.
//

import SwiftUI

enum AlertError: LocalizedError {
    case none
}

struct LinkListView: View {
    @ObservedObject var userData: UserData
    @ObservedObject var linkList: LinkList
    @StateObject var viewModel: LinkListViewModel
    
    @State var isPresented: Bool = false
    @State var listTitle: String = ""
    @State var navigationMove: Bool = false
    @Binding var newTitle: String
    
    @State var notHere: Bool = false
    // Row edit 프라퍼티
    @Binding var editMode: EditMode
    @Binding var isShowingTitleAlert: Bool
    @State var isShowingItemAlert: Bool = false
    @State var newString: String = ""
    @State var newURL: String = ""
    @State var editRow: LinkRow!

    @State var isShowingActionAlert: Bool = false
    
    @Namespace var animationID
    
    @Environment(\.openURL) var openURL
    
    init(userData: UserData, content: LinkList, editMode: Binding<EditMode>, isShowingTitleAlert: Binding<Bool>, newTitle: Binding<String>) {
        _userData = ObservedObject(wrappedValue: userData)
        _linkList = ObservedObject(wrappedValue: content)
        _viewModel = StateObject(wrappedValue: LinkListViewModel(userData: userData,
                                                                 linkListID: content.id))
        _newTitle = newTitle
        _editMode = editMode
        _isShowingTitleAlert = isShowingTitleAlert
    }
    
    var body: some View {
        OStack(alignment: .topOrLeading, spacing: 0) {
            ContentTitleView(title: linkList.title, isShowingTitleAlert: $isShowingTitleAlert, newTitle: $newTitle)
                .frame(maxWidth: screenSize.width < screenSize.height
                       ? .infinity : max(screenSize.width, screenSize.height) * 0.2)
                .padding(.bottom, 5)
            MaskAndOrderdListView(items: linkList.itemList, editMode: $editMode, rowContent: { item in
                HStack {
                    eachLinkItemView(item: item)
                }
            }, onTapAction: { item in
                settingEditRow(item: item)
                withAnimation {
                    if editMode != .active {
                        self.navigationMove = true
                    } else {
                        self.isShowingItemAlert = true
                    }
                }
            }, onMoveAction: { indexSet, int in
                viewModel.reOrdering(editCase: .reOder, onIndex: int, indexSet: indexSet)
            }, onDeleteAction: { indexSet in
                viewModel.deleteLinkRow(index: indexSet.first!)
            }, isPresentBlurView: isPresented || isShowingItemAlert || isShowingActionAlert,
                                  blurViewTapAction: {
                withAnimation {
                    isPresented ? self.turnOffAddSection() : (isShowingItemAlert ? isShowingItemAlert.toggle() : isShowingActionAlert.toggle())
                }
            }, isPresentAddBttn: $isPresented,
                                  addBttnPlaceHolder: "추가할 링크 주소를 입력해주세요.",
                                  bindingStirng: $listTitle) {
                viewModel.addLinkRow(count: linkList.itemList.count, string: listTitle)
            }
        }
        .navigationDestination(isPresented: $navigationMove) {
            if editMode != .active {
                if let row = editRow {
                    LinkWebView(url: row.url)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle(editRow.title)
                }
            }
        }
        .overlay(alignment: .center) {
            if isShowingItemAlert {
                CustomAlertView(isShowingAlert: $isShowingItemAlert,
                                title: "리스트 아이템을 수정합니다.",
                                text: $newString,
                                textEditor: $newURL) {
                    guard let row = editRow else { return }
                    withAnimation {
                        viewModel.modifyRow(itemID: row.id, index: row.order, newTitle: newString, newURL: newURL)
                    }
                }.shadow(color: .black, radius: 1, x: 0, y: 0)
          }
        }
        .overlay(content: {
            if isShowingActionAlert {
                VStack(content: {
                    Group {
                        Text(editRow.title)
                            .fontWeight(.bold)
                        Text(editRow.url)
                            .lineLimit(4, reservesSpace: false)
                    }
                    .foregroundStyle(Color.black)
                    .frame(alignment: .leading)
                    buttonRectangle(type: .textAndImage, 
                                    backgroundColor: .orange,
                                    foregroundColor: .white,
                                    text: "링크 복사하기", 
                                    image: "doc.on.doc.fill") {
                        viewModel.copyLinkToClipboard(text: editRow.url) {
                            withAnimation {
                                isShowingActionAlert = false
                            }
                        }
                    }
                    buttonRectangle(type: .textAndImage,
                                    backgroundColor: .orange,
                                    foregroundColor: .white,
                                    text: "사파리에서 링크 열기", 
                                    image: "safari.fill") {
                        withAnimation {
                            isShowingActionAlert = false
                        }
                        openURL(URL(string: editRow.url)!)
                    }
                })
                .padding(10)
                .frame(width: 300)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundStyle(Color.teal)
                }
            }
        })
    }
}

extension LinkListView {
    
    func eachLinkItemView(item: LinkRow) -> some View {
        HStack {
            Image(systemName: "square.and.arrow.up")
                .imageScale(.large)
                .foregroundStyle(editMode == .active ? Color.gray.opacity(0.4) : Color.teal)
                .onTapGesture {
                    if editMode != .active {
                        withAnimation {
                            editRow = item
                            isShowingActionAlert = true
                        }
                    }
                }
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
            if editMode != .active {
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundStyle(Color.teal)
            }
        }
        .foregroundColor(.black)
    }
    
    func settingEditRow(item: LinkRow) {
        self.editRow = item
        self.newString = item.title
        self.newURL = item.url
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
        LinkListView(userData: UserData(),
                     content: sampleLinkList,
                     editMode: .constant(.active),
                     isShowingTitleAlert: .constant(false), 
                     newTitle: .constant(""))
    }
}
