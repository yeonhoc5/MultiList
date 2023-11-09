//
//  TextListView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/18.
//

import SwiftUI

struct TextListView: View {
    @ObservedObject var userData: UserData
    @ObservedObject var textList: TextList
    @StateObject var viewModel: TextListViewModel
    
    @State var isPresented: Bool = false
    @State var listTitle: String = ""
    @FocusState var isFocused: Bool
    @State var navigationMove: Bool = false
    
    // Row edit 프라퍼티
    @Binding var editMode: EditMode
    @Binding var isShowingTitleAlert: Bool
    @Binding var newTitle: String
    @State var isShowingItemEditAlert: Bool = false
    
    @State var editRow: TextRow!
    @State var newString: String = ""
    
    @State var alertTitleType: AlertTitle = .cancelOne
    @State var isShowingItemCancelAlert: Bool = false
    @State var orderToCancel: [Int]!
    
    @Namespace var animationID
    
    init(userData: UserData, content: TextList, editMode: Binding<EditMode>, isShowingTitleAlert: Binding<Bool>, newTitle: Binding<String>) {
        _userData = ObservedObject(wrappedValue: userData)
        _textList = ObservedObject(wrappedValue: content)
        _viewModel = StateObject(wrappedValue: TextListViewModel(userData: userData,
                                                                 textListID: content.id))
        _editMode = editMode
        _isShowingTitleAlert = isShowingTitleAlert
        _newTitle = newTitle
    }
    
    var body: some View {
        OStack(alignment: .topOrLeading, verticalSpacing: 0, horizontalSpacing: 0) {
            // 1. 타이틀 뷰
            ContentTitleView(title: textList.title, isShowingTitleAlert: $isShowingTitleAlert, newTitle: $newTitle)
                .frame(maxWidth: screenSize.width < screenSize.height
                       ? .infinity : max(screenSize.width, screenSize.height) * 0.2)
                .padding(.bottom, 5)
            // 2. 리스튜 뷰
            MaskAndOrderdListView(items: textList.itemList, 
                                  editMode: $editMode,
                                  rowContent: { item in
                eachTextView(item: item)
            }, onTapAction: { item in
                settingTextRow(item: item)
                    withAnimation {
                        if editMode == .active {
                            isShowingItemEditAlert = true
                        } else {
                            navigationMove = true
                        }
                    }
            }, onMoveAction: { indexSet, int in
                 viewModel.reOrdering(editCase: .reOder, 
                                      onIndex: int,
                                      indexSet: indexSet)
            }, onDeleteAction: { indexSet in
                 viewModel.deleteTextRow(index: indexSet.first!)
            }, isPresentBlurView: isPresented,
                                  blurViewTapAction: {
                self.turnOffAddSection()
            }, isPresentAddBttn: $isPresented,
                                  addBttnPlaceHolder: "추가할 리스트를 입력해주세요.",
                                  bindingStirng: $listTitle) {
                viewModel.addTextRow(index: textList.itemList.count,
                                     string: listTitle)
            }
        }
//        .navigationDestination(isPresented: $navigationMove) {
//            if editMode != .active {
//                if let row = editRow {
//                TextListDetailView(userData: userData, textRow: row, isShowingItemView: $navigationMove)
//                        .navigationBarTitleDisplayMode(.inline)
//                        .navigationTitle(row.title)
//                }
//            }
//        }
        .alert(Text("아이템의 타이틀을 수정합니다."), isPresented: $isShowingItemEditAlert) {
            // 3. 아이템 수정 알럿 뷰
            itemModifyAlertView
        }
    }
}
    
// MARK: - 1: sub Views
extension TextListView {
    // 3. 아이템 수정 알럿 뷰
    var itemModifyAlertView: some View {
        Group {
            TextField(newString, text: $newString)
                .submitLabel(.done)
                .onSubmit {
                    guard editRow != nil else { return }
                    viewModel.modifyRowTitle(id: editRow.id,
                                             index: editRow.order,
                                             newString: newString) {
                        returnEditRowNil()
                        isShowingItemEditAlert = false
                    }
                }
            Button("취소") {
                returnEditRowNil()
            }
            Button("수정하기") {
                guard editRow != nil else { return }
                viewModel.modifyRowTitle(id: editRow.id,
                                         index: editRow.order,
                                         newString: newString) {
                    returnEditRowNil()
                }
            }
        }
    }
    
    func eachTextView(item: TextRow) -> some View {
        HStack {
            Text(item.title)
                .lineLimit(1)
//            if editMode != .active {
                Spacer()
//                Image(systemName: "chevron.right")
//                    .font(.body)
//                    .foregroundStyle(Color.teal)
//                    
//            }
        }
    }
}

// MARK: - 2: function
extension TextListView {
    func settingTextRow(item: TextRow) {
        editRow = item
        newString = item.title
    }
    
    func turnOffAddSection() {
        self.listTitle = ""
        withAnimation(.easeInOut(duration: 0.45)) {
            self.isFocused = false
            self.isPresented = false
        }
    }
    
    func returnEditRowNil() {
        editRow = nil
        newString = ""
        isShowingItemEditAlert = false
    }
}

struct TextListView_Previews: PreviewProvider {
    static var previews: some View {
        TextListView(userData: UserData(),
                     content: TextList(title: "오늘은"),
                     editMode: .constant(.inactive),
                     isShowingTitleAlert: .constant(false),
                     newTitle: .constant(""))
    }
}
