//
//  CheckListView1.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/22.
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

struct CheckListView1: View {
    @StateObject var viewModel: CheckListViewModel
    @ObservedObject var checkList: CheckList
    @ObservedObject var userData: UserData
    
    let width = screenSize.width
    @State var isPresented: Bool = false
    @State var listTitle: String = ""
    @FocusState var isFocused: Bool
    
    @State var notHere: Bool = false
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
            Group {
                if checkList.itemList.count > 0 {
                    itemListView
                } else {
                    ListEmptyView(title: "버튼을 눌러 리스트를 추가해주세요.", image: "plus.circle.fill", checkBool: $notHere)
                }
            }
            .overlay(alignment: .center) {
                if isPresented {
                    blurViewWithTapAction {
                        self.turnOffAddSection()
                    }
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .overlay(alignment: .bottomLeading) {
                AddButton(width: width,
                          placeHolder: "추가할 리스트를 입력해주세요.",
                          isPresented: $isPresented,
                          string: $listTitle,
                          isFocused: $isFocused) {
                    viewModel.addCheckRow(index: checkList.itemList.count,
                                          string: listTitle)
                }
                .padding(.horizontal, 10)
            }
            .alert(Text("아이템의 타이틀을 수정합니다."), isPresented: $isShowingItemEditAlert) {
                TextField(newString, text: $newString)
                    .submitLabel(.done)
                    .onSubmit {
                        guard editRowIndex != nil else { return }
                        viewModel.modifyRowTitle(id: editRowID,
                                                 index: editRowIndex,
                                                 newString: newString) {
                            editRowID = nil
                            editRowIndex = nil
                            newString = ""
                            isShowingItemEditAlert = false
                        }
                    }
                Button("취소") {
                    isShowingItemEditAlert = false
                }
                Button("수정하기") {
                    guard editRowIndex != nil else { return }
                    viewModel.modifyRowTitle(id: editRowID,
                                             index: editRowIndex,
                                             newString: newString) {
                        editRowID = nil
                        editRowIndex = nil
                        newString = ""
                        isShowingItemEditAlert = false
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
        .onAppear {
            let emailArray = self.checkList.sharedPeople.compactMap({$0.userEmail})
            shareIndex = userData.friendList.filter({emailArray.contains($0.userEmail)}).compactMap({$0.order})
        }
    }
}
    

extension CheckListView1 {
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
    
    var itemListView: some View {
        ZStack {
            listMaskView(color: .white)
            List {
                ForEach(checkList.itemList) { item in
                    eachCheckView(item: item)
                        .offset(x: editMode == .active ? -38 : 0)
                        .overlay(alignment: .trailing, content: {
                            if editMode == .active {
                                Spacer()
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundColor(.teal)
                                    .imageScale(.large)
                            }
                        })
                    
                    .onTapGesture {
                        // editmode일 시 타이틀 수정 / 아닐 시 체크 토글
                        withAnimation {
                            if editMode == .active {
                                editRowID = item.id
                                editRowIndex = item.order
                                newString = item.title
                                isShowingItemEditAlert = true
                            } else {
                                if item.isDone {
                                    self.orderToCancel = [item.order]
                                    self.alertTitleType = .cancelOne
                                    self.isShowingItemCancelAlert = true
                                } else {
                                    viewModel.toggleCheckRow(indexSet: [item.order], bool: true)
                                }
                            }
                        }
                    }
                }
                .onMove(perform: { indexSet, int in
                    viewModel.reOrdering(editCase: .reOder, onIndex: int, indexSet: indexSet)
                })
                .onDelete(perform: { indexSet in
                    viewModel.deleteCheckRow(index: indexSet.first!)
                })
                .foregroundColor(.black)
                .listRowBackground(Color.white)
            }
            .listStyle(.plain)
            .environment(\.editMode, $editMode)
            .padding(20)
            
        }
        .mask {
            listMaskView()
                .padding(20)
        }
        .shadow(color: .black, radius: 1.5, x: 0, y: 0)
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
        .offset(x: editMode == .active ? 38 : 0)
        .padding(.leading, editMode == .active ? 0 : 10)
        .padding(.trailing, editMode == .active ? 20 : 0)
        .background(alignment: .leading, content: {
            Text(item.order < 9 ? "0\(item.order + 1)" : "\(item.order + 1)")
                .foregroundColor(.gray.opacity(editMode == .active ? 0.3 : 0.1))
                .font(Font.system(size: 50, weight: .black, design: .monospaced))
                .italic()
                .kerning(-5)
                .offset(x: -25, y: 5)
        })
        
    }
    
    
    var listEmptyView: some View {
        ZStack {
            Rectangle()
                .opacity(0)
                
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .imageScale(.large)
                    Text("버튼을 눌러 체크 아이템을 추가하세요.")
                }
                .onTapGesture {
                    withAnimation {
                        self.notHere = true
                    }
                }
                Text("여기 말구요, 아래 동그란 버튼이요.")
                    .opacity(notHere ? 1 : 0)
                    .onChange(of: notHere) { newValue in
                        if newValue == true {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    self.notHere = false
                                }
                            }
                        }
                    }
            }
            .foregroundColor(.secondary)
        }
    }
    
    func turnOffAddSection() {
        self.listTitle = ""
        withAnimation(.easeInOut(duration: 0.45)) {
            self.isFocused = false
            self.isPresented = false
        }
    }
}

struct CheckListView1_Previews: PreviewProvider {
    static var previews: some View {
        CheckListView1(userData: UserData(),
                      content: sampleCheckList,
                      editMode: .constant(.inactive),
                      shareIndex: .constant([]),
                      isShowingTitleAlert: .constant(false),
                      newTitle: .constant(""))
    }
}
