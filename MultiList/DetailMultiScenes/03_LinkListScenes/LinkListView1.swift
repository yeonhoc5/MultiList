//
//  LinkListView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/22.
//

import SwiftUI

struct LinkListView1: View {
    @StateObject var viewModel: LinkListViewModel
    @ObservedObject var linkList: LinkList
    @ObservedObject var userData: UserData
    
    let width = screenSize.width
    @State var isPresented: Bool = false
    @State var listTitle: String = ""
    @FocusState var isFocused: Bool
    
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
        Group {
            if linkList.itemList.count > 0 {
                ZStack {
                    listMaskView(color: .white)
                    List {
                        ForEach(linkList.itemList) { item in
                            eachLinkItemView(item: item)
                                .offset(x: editMode == .active ? -38 : 0)
                                .overlay(alignment: .trailing, content: {
                                    if editMode == .active {
                                        Image(systemName: "pencil.circle.fill")
                                            .foregroundColor(.teal)
                                            .imageScale(.large)
                                            .opacity(editMode == .active ? 1 : 0)
                                    }
                                })
                        }
                        .onMove(perform: { indexSet, int in
                            viewModel.reOrdering(editCase: .reOder, onIndex: int, indexSet: indexSet)
                        })
                        .onDelete { indexSet in
                            viewModel.deleteLinkRow(index: indexSet.first!)
                        }
                        .listRowBackground(Color.white)
                    }
                    .padding(20)
                    .environment(\.editMode, $editMode)
                    .listStyle(.plain)
                }
                .mask {
                    listMaskView(radius: 10)
                        .padding(20)
                }
                .shadow(color: .black, radius: 1.5, x: 0, y: 0)
            } else {
                ListEmptyView(title: "버튼을 눌러 리스트를 추가해주세요.", image: "plus.circle.fill", checkBool: $notHere)
            }
        }
        .overlay(alignment: .center) {
            if isPresented || isShowingItemAlert {
                blurViewWithTapAction {
                    isPresented ? self.turnOffAddSection() : self.isShowingItemAlert.toggle()
                }
            }
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
        .overlay(alignment: .bottomLeading) {
            AddButton(width: width,
                      placeHolder: "추가할 링크 주소를 입력해주세요.",
                      isPresented: $isPresented,
                      string: $listTitle,
                      isFocused: $isFocused) {
                viewModel.addLinkRow(count: linkList.itemList.count, string: listTitle)
            }
            .padding(.horizontal, 10)
        }
    }
    
}

extension LinkListView1 {
    
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
        .background(alignment: .leading, content: {
            Text(item.order < 9 ? "0\(item.order + 1)" : "\(item.order + 1)")
                .foregroundColor(.gray.opacity(editMode == .active ? 0.3 : 0.1))
                .font(Font.system(size: 50, weight: .black, design: .monospaced))
                .italic()
                .kerning(-5)
                .offset(x: -25, y: 5)
        })
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
                print("tapped")
            }
    }
    
    
    func turnOffAddSection() {
        self.listTitle = ""
        withAnimation(.easeInOut(duration: 0.45)) {
            self.isFocused = false
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

struct LinkListView1_Previews: PreviewProvider {
    static var previews: some View {
        LinkListView1(userData: UserData(),
                     content: sampleLinkList,
                     editMode: .constant(.active),
                     shareIndex: .constant([1]),
                     isShowingTitleAlert: .constant(false))
    }
}
