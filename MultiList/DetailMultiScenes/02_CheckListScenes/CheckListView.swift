//
//  CheckListView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/21.
//

import SwiftUI

struct CheckListView: View {
    @StateObject var viewModel: CheckListViewModel
    @ObservedObject var checkList: CheckList
    @ObservedObject var userData: UserData
    
    @State var isPresented: Bool = false
    @State var listTitle: String = ""
    
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
    
    init(userData: UserData, content: CheckList, editMode: Binding<EditMode>, shareIndex: Binding<[Int]>, isShowingTitleAlert: Binding<Bool>, newTitle: Binding<String>) {
        _userData = ObservedObject(wrappedValue: userData)
        _checkList = ObservedObject(wrappedValue: content)
        _viewModel = StateObject(wrappedValue: CheckListViewModel(userData: userData, checkListID: content.id))
        _editMode = editMode
        _shareIndex = shareIndex
        _isShowingTitleAler = isShowingTitleAlert
        _newTitle = newTitle
    }
    
    var body: some View {
        OStack {
            btnInContent(animationID: animationID)
                .frame(maxWidth: screenSize.width < screenSize.height
                       ? .infinity : max(screenSize.width, screenSize.height) * 0.2)
                .padding(.bottom, 20)
            MaskAndOrderdListView(items: checkList.itemList, editMode: $editMode, rowContent: { item in
                eachCheckView(item: item)
            }, onTapAction: { item in
                if editMode == .active {
                    editCheckRow(item: item)
                } else {
                    if item.isDone {
                        cancleCheckRowDone(item: item)
                    } else {
                        viewModel.toggleCheckRow(indexSet: [item.order], bool: true)
                    }
                }
            }, onMoveAction: { indexSet, int in
                viewModel.reOrdering(editCase: .reOder, onIndex: int, indexSet: indexSet)
            }, onDeleteAction: { indexSet in
                viewModel.deleteCheckRow(index: indexSet.first!)
            }, isPresentBlurView: isPresented,
                                  blurViewTapAction: {
                self.turnOffAddSection()
            }, isPresentAddBttn: $isPresented,
                                  addBttnPlaceHolder: "추가할 리스트를 입력해주세요.",
                                  bindingStirng: $listTitle) {
                viewModel.addCheckRow(index: checkList.itemList.count,
                                      string: listTitle)
            }.onAppear {
                let emailArray = self.checkList.sharedPeople.compactMap({$0.userEmail})
                shareIndex = userData.friendList.filter({emailArray.contains($0.userEmail)}).compactMap({$0.order})
            }
            .alert(Text("아이템의 타이틀을 수정합니다."), isPresented: $isShowingItemEditAlert) {
                TextField(newString, text: $newString)
                    .submitLabel(.done)
                    .onSubmit {
                        guard editRowIndex != nil else { return }
                        viewModel.modifyRowTitle(id: editRowID,
                                                 index: editRowIndex,
                                                 newString: newString) {
                            returnEditRowNil()
                        }
                    }
                Button("취소") {
                    returnEditRowNil()
                }
                Button("수정하기") {
                    guard editRowIndex != nil else { return }
                    viewModel.modifyRowTitle(id: editRowID,
                                             index: editRowIndex,
                                             newString: newString) {
                        returnEditRowNil()
                    }
                }
            }
            .alert(AlertTitle.returnTitle(type: alertTitleType), isPresented: $isShowingItemCancelAlert) {
                Button("취소", role: .cancel) {
                    orderToCancel = nil
                    isShowingItemCancelAlert = false
                }
                Button(alertTitleType == .checkAll ? "체크하기" : "해제하기", role: .destructive) {
                    viewModel.toggleCheckRow(indexSet: orderToCancel,
                                             bool: alertTitleType == .checkAll ? true : false)
                    orderToCancel = nil
                }
            }
        }
    }
}
    
// extension 1: subView
extension CheckListView {
    func btnInContent(animationID: Namespace.ID) -> some View {
        OStack(spacing: 10, isVerticalFirst: false) {
            if editMode == .inactive {
                buttonLogin(title: "전체 체크하기", btncolor: .teal, textColor: .white) {
                    if checkList.itemList.filter({ $0.isDone == false}).count > 0 {
                        self.orderToCancel = checkList.itemList.filter({ $0.isDone == false}).compactMap({$0.order})
                        self.alertTitleType = .checkAll
                        self.isShowingItemCancelAlert = true
                    }
                }
                .matchedGeometryEffect(id: "button1", in: animationID)
                buttonLogin(title: "전체 해제하기", btncolor: .teal, textColor: .white) {
                    if checkList.itemList.filter({ $0.isDone == true}).count > 0 {
                        self.orderToCancel = checkList.itemList.filter({ $0.isDone == true}).compactMap({$0.order})
                        self.alertTitleType = .cancelAll
                        self.isShowingItemCancelAlert = true
                    }
                }
                .matchedGeometryEffect(id: "button2", in: animationID)
            } else {
                buttonLogin(title: "타이틀 수정하기", btncolor: .orange, textColor: .white) {
                    newTitle = checkList.title
                    isShowingTitleAler = true
                }
                .matchedGeometryEffect(id: "button1", in: animationID)
                buttonLogin(title: "전체 지우기", btncolor: .orange, textColor: .white) {

                }
                .matchedGeometryEffect(id: "button2", in: animationID)
            }
            
        }
        .frame(maxHeight: screenSize.width < screenSize.height ? 50 : .infinity)
        .padding(.horizontal, 15)
        .padding(.top, 20)
        .padding(.bottom, 0)
        .opacity(checkList.itemList.count == 0 ? 0.5 : 1)
        .disabled(checkList.itemList.isEmpty)
    }
    
    func eachCheckView(item: CheckRow) -> some View {
        HStack {
            checkMarkToggleView(order: item.order,
                                isDone: item.isDone,
                                isEditMode: editMode == .active)
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(.white.opacity(0.1))
                Text("\(item.title) (\(item.order))")
                    .lineLimit(1)
            }
        }
    }
    
    func checkMarkToggleView(order: Int, isDone: Bool, isEditMode: Bool) -> some View {
        ZStack {
            Image(systemName: "square")
                .opacity(isEditMode ? 0 : 1)
                .imageScale(.large)
            if isDone {
                checkMarkView(color: isEditMode ? .gray : .red, fontWeight: .semibold)
                    .imageScale(.large)
                    .background{
                        checkMarkView(color: .white, fontWeight: .black)
                            .imageScale(.large)
                    }
            }
        }
    }
    
}

// extension 1: function
extension CheckListView {
    func editCheckRow(item: CheckRow) {
        editRowID = item.id
        editRowIndex = item.order
        newString = item.title
        isShowingItemEditAlert = true
    }
    
    func cancleCheckRowDone(item: CheckRow) {
        self.orderToCancel = [item.order]
        self.alertTitleType = .cancelOne
        self.isShowingItemCancelAlert = true
    }
    
    
    func turnOffAddSection() {
        self.listTitle = ""
        withAnimation(.easeInOut(duration: 0.45)) {
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

#Preview {
    CheckListView(userData: UserData(),
                  content: sampleCheckList,
                  editMode: .constant(.inactive),
                  shareIndex: .constant([]),
                  isShowingTitleAlert: .constant(false),
                  newTitle: .constant(""))
}
