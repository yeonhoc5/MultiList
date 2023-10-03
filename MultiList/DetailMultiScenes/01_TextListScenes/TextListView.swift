//
//  TextListView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/18.
//

import SwiftUI

struct TextListView: View {
    @StateObject var viewModel: TextListViewModel
    @ObservedObject var textList: TextList
    @ObservedObject var userData: UserData
    
    @State var isPresented: Bool = false
    @State var listTitle: String = ""
    @FocusState var isFocused: Bool
    
    // Row edit 프라퍼티
    @Binding var editMode: EditMode
    @Binding var isShowingTitleAler: Bool
    @Binding var newTitle: String
    @State var isShowingItemEditAlert: Bool = false
    @State var editRowID: UUID!
    @State var editRowIndex: Int!
    @State var newString: String = ""
    
    @State var alertTitleType: AlertTitle = .cancelOne
    @State var isShowingItemCancelAlert: Bool = false
    @State var orderToCancel: [Int]!
    
    @Binding var shareIndex: [Int]
    
    @Namespace var animationID
    
    init(userData: UserData, content: TextList, editMode: Binding<EditMode>, shareIndex: Binding<[Int]>, isShowingTitleAlert: Binding<Bool>, newTitle: Binding<String>) {
        _userData = ObservedObject(wrappedValue: userData)
        _textList = ObservedObject(wrappedValue: content)
        _viewModel = StateObject(wrappedValue: TextListViewModel(userData: userData, textListID: content.id))
        _editMode = editMode
        _shareIndex = shareIndex
        _isShowingTitleAler = isShowingTitleAlert
        _newTitle = newTitle
    }
    
    
    var body: some View {
        MaskAndOrderdListView(items: textList.itemList,
                              editMode: $editMode, 
                              rowContent: { item in
            eachTextView(item: item)
        }, onTapAction: { item in
            withAnimation {
                if editMode == .active {
                    editTextRow(item: item)
                }
            }
        }, onMoveAction: { indexSet, int in
//             viewModel.reOrdering(editCase: .reOder, onIndex: int, indexSet: indexSet)
        }, onDeleteAction: { indexSet in
//             viewModel.deleteCheckRow(index: indexSet.first!)
        }, isPresentBlurView: isPresented,
                              blurViewTapAction: {
            self.turnOffAddSection()
        }, isPresentAddBttn: $isPresented,
                              addBttnPlaceHolder: "추가할 리스트를 입력해주세요.",
                              bindingStirng: $listTitle) {
            viewModel.addTextRow(index: textList.itemList.count,
                                 string: listTitle)
        }.onAppear {
              let emailArray = self.textList.sharedPeople.compactMap({$0.userEmail})
              shareIndex = userData.friendList.filter({emailArray.contains($0.userEmail)}).compactMap({$0.order})
          }
        .alert(Text("아이템의 타이틀을 수정합니다."), isPresented: $isShowingItemEditAlert) {
            TextField(newString, text: $newString)
                .submitLabel(.done)
                .onSubmit {
                    guard editRowIndex != nil else { return }
//                        viewModel.modifyRowTitle(id: editRowID,
//                                                 index: editRowIndex,
//                                                 newString: newString) {
                    returnEditRowNil()
                }
        }
    }
}
    
// extension 1: subView
extension TextListView {
    
    func eachTextView(item: TextRow) -> some View {
        HStack {
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(.white.opacity(0.1))
                Text("\(item.title) (\(item.order))")
                    .lineLimit(1)
            }
        }
    }
}

// extension 1: function
extension TextListView {
    func editTextRow(item: TextRow) {
        editRowID = item.id
        editRowIndex = item.order
        newString = item.title
        isShowingItemEditAlert = true
    }
    
    func turnOffAddSection() {
        self.listTitle = ""
        withAnimation(.easeInOut(duration: 0.45)) {
            self.isFocused = false
            self.isPresented = false
        }
    }
    
    func returnEditRowNil() {
        editRowID = nil
        editRowIndex = nil
        newString = ""
        isShowingItemEditAlert = false
    }
}

struct TextListView_Previews: PreviewProvider {
    static var previews: some View {
        TextListView(userData: UserData(), content: TextList(title: "오늘은"), editMode: .constant(.inactive), shareIndex: .constant([]), isShowingTitleAlert: .constant(false), newTitle: .constant(""))
    }
}
