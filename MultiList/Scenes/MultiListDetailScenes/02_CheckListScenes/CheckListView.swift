//
//  CheckListView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/21.
//

import SwiftUI

enum AlertTitle: String {
    case cancelOne = "선택한 항목의 체크를 해제합니다."
    case checkAll = "모든 항목을 체크합니다."
    case cancelAll = "모든 항목의 체크를 해제합니다."
    
    static func returnTitle(type: Self) -> String {
        return type.rawValue
    }
}

struct CheckListView: View {
    @StateObject var viewModel: CheckListViewModel
    @ObservedObject var checkList: CheckList
    @ObservedObject var userData: UserData
    
    @State var isPresented: Bool = false
    @State var listTitle: String = ""
    
    // Row edit 프라퍼티
    @Binding var editMode: EditMode
    @Binding var isShowingTitleAlert: Bool
    @Binding var newTitle: String
    @State var isShowingItemEditAlert: Bool = false
    @State var editRowID: UUID!
    @State var editRowIndex: Int!
    @State var newString: String = ""
    
    @State var alertTitleType: AlertTitle = .cancelOne
    @State var isShowingItemCancelAlert: Bool = false
    @State var orderToCancel: [Int]!
    
    @Namespace var animationID

    init(userData: UserData, content: CheckList, editMode: Binding<EditMode>, isShowingTitleAlert: Binding<Bool>, newTitle: Binding<String>) {
        _userData = ObservedObject(wrappedValue: userData)
        _checkList = ObservedObject(wrappedValue: content)
        _viewModel = StateObject(wrappedValue: CheckListViewModel(userData: userData, checkListID: content.id))
        _editMode = editMode
        _isShowingTitleAlert = isShowingTitleAlert
        _newTitle = newTitle
    }
    
    var body: some View {
        OStack(alignment: .topOrLeading, verticalSpacing: -10, horizontalSpacing: -10) {
            VStack(spacing: 5) {
                ContentTitleView(title: checkList.title, isShowingTitleAlert: $isShowingTitleAlert, newTitle: $newTitle)
                btnInContent(animationID: animationID)
            }
            .frame(maxWidth: screenSize.width < screenSize.height
                   ? .infinity : max(screenSize.width, screenSize.height) * 0.2)
            .padding(.bottom, 15)
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
            }.alert(Text("아이템의 타이틀을 수정합니다."), isPresented: $isShowingItemEditAlert) {
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
        OStack(verticalSpacing: 10, horizontalSpacing: 10, isVerticalFirst: false) {
            buttonLogin(title: "전체 체크하기", btncolor: editMode == .active ? .gray : .teal, textColor: .white) {
                if checkList.itemList.filter({ $0.isDone == false}).count > 0 {
                    self.orderToCancel = checkList.itemList.filter({ $0.isDone == false}).compactMap({$0.order})
                    self.alertTitleType = .checkAll
                    self.isShowingItemCancelAlert = true
                }
            }
            .matchedGeometryEffect(id: "button1", in: animationID)
            buttonLogin(title: "전체 해제하기", btncolor: editMode == .active ? .gray : .teal, textColor: .white) {
                if checkList.itemList.filter({ $0.isDone == true}).count > 0 {
                    self.orderToCancel = checkList.itemList.filter({ $0.isDone == true}).compactMap({$0.order})
                    self.alertTitleType = .cancelAll
                    self.isShowingItemCancelAlert = true
                }
            }
            .matchedGeometryEffect(id: "button2", in: animationID)
            buttonLogin(title: "체크한 항목 순서\n위로 올리기", btncolor: editMode == .active ? .gray : .teal, textColor: .white) {
                viewModel.reOrderCheckItems()
            }
            .matchedGeometryEffect(id: "button3", in: animationID)
        }
        .frame(maxHeight: screenSize.width < screenSize.height ? 50 : .infinity)
        .padding(.horizontal, 15)
        .opacity(checkList.itemList.count == 0 ? 0.5 : 1)
        .disabled(checkList.itemList.isEmpty || editMode == .active)
    }
    
    func eachCheckView(item: CheckRow) -> some View {
        HStack {
            checkMarkToggleView(order: item.order,
                                isDone: item.isDone,
                                isEditMode: editMode == .active)
            Text(item.title)
                .lineLimit(1)
        }
    }
    
    func checkMarkToggleView(order: Int, isDone: Bool, isEditMode: Bool) -> some View {
        ZStack {
            Image(systemName: "square")
                .opacity(isEditMode ? 0.2 : 1)
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
                  isShowingTitleAlert: .constant(false),
                  newTitle: .constant(""))
}
