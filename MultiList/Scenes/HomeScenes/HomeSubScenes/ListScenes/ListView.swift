//
//  ListView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/16.
//

import SwiftUI
import UniformTypeIdentifiers


struct ListView: View {
    @ObservedObject var userData: UserData
    @StateObject var viewModel: ListViewModel
    
    // sectionList Add 프라퍼티
    @State var isAdding: Bool = false
    @FocusState var isFocusedAdd: Bool
    @State var sectionToAdd = ""
    
    // sectionList edit 프라퍼티
    var isFocusedEdit: FocusState<Bool>.Binding
    @Binding var editSection: SectionList!
    @State var editSectionTitle: String = ""
    @State var editSectionColor: Int = 0
    @State var editSectionOrder: Int = 0
    
    // 공유 시트 프라퍼티
    @Binding var isShowingSendShareSheet: Bool
    @Binding var multiListToShare: MultiList!
    @State var shareColor: Color!
    
    // 네임스페이스
    @Namespace var sectionNamespace
    @Namespace var multiListNamespace
    @Namespace var sectionEnd
    
    // 멀티리스트 edit(타이틀 수정 / 삭제)
    @State var editMultiList: MultiList!
    @State var isShowingDeleteAlert: Bool = false
    @State var isShowingTitleAlert: Bool = false
    @State var newString: String = ""
    @State var placeholder: String = ""
    
    // 멀티리스트 edit(이동 / 삭제) 모드
    @Binding var isEditMode: Bool
    @State var isDraggingStarted: Bool = false
    @State var draggingItem: MultiList?
    @State var fromSection: SectionList?
    @State var isMoveFinished: Bool = true
    
    @State var oriSectiontype: SectionType!
    @State var oriSectionOrder: Int!
    @State var oriMultiOrder: Int!
    
    @State var moveToDetail: Bool = false
    @State var moveToMulti: MultiList!

    
    init(userData: UserData, isEditMode: Binding<Bool>, isShowingSendShareSheet: Binding<Bool>,
         editSection: Binding<SectionList?>, multiListToShare: Binding<MultiList?>, isFocusedEdit: FocusState<Bool>.Binding) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: ListViewModel(userData: userData))
        _isEditMode = isEditMode
        _isShowingSendShareSheet = isShowingSendShareSheet
        _editSection = editSection
        _multiListToShare = multiListToShare
        self.isFocusedEdit = isFocusedEdit
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // 1. 배경
                backgroundView
                // 2. 리스트뷰
                ScrollView {
                    ScrollViewReader { scrollProxy in
                        ZStack {
                            backgroundView
                            VStack(alignment: .leading, spacing: 10) {
                                if let sectionShared = userData.sectionShared {
                                    if sectionShared.multiList.count > 0 {
                                        sectionListView(sectionType: .share,
                                                        sectionList: userData.user != nil ? [sectionShared] : sampleList,
                                                        animationName: multiListNamespace)
//                                        .animation(.default,
//                                                   value: sectionShared.multiList.count == 0)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                        .mask {
                                            RoundedRectangle(cornerRadius: 5)
                                                .foregroundStyle(Color.primary)
                                                .padding([.horizontal], 11)
                                        }
                                    }
                                }
                                sectionListView(sectionList: userData.user != nil ?
                                                userData.sectionList : sampleList,
                                                animationName: multiListNamespace)
                                additionalSpace()
                                    .id(sectionEnd)
//                                    .onTapGesture {
//                                        withAnimation {
//                                            isEditMode = false
//                                        }
//                                    }
                            }
                            .padding(.top, screenSize.width < screenSize.height ? 30 : 10)
                            .onChange(of: userData.sectionList.count) { [oldValue = userData.sectionList.count] newValue in
                                if newValue > oldValue && oldValue != 0 {
                                    withAnimation {
                                        scrollProxy.scrollTo(sectionEnd, anchor: .bottom)
                                    }
                                }
                            }
                            .onChange(of: isEditMode) { bool in
                                // 각 섹션 마지막에 템프 멀티리스트 추가 (for 사용자 이동을 편하게 하기 위해)
                                tempAtEachSection(isEditMode: bool)
                                if !bool {
                                    draggingItem = nil
                                }
//                                for i in 0..<userData.sectionList.count {
//                                    userData.checkMultiListOrder(sectionIndex: i,
//                                                                 itemList: userData.sectionList[i].multiList)
//                                }
                            }
                        }
                    }
                }
            }
            .opacity(userData.user == nil || editSection != nil ? 0.4 : 1)
            .overlay(alignment: .center) {
                sampleMarkORAddSectionBlurView
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .overlay {
                ZStack {
                    if editSection != nil {
                        blurViewWithTapAction {
                            withAnimation {
                                editSection = nil
                                isFocusedEdit.wrappedValue = false
                            }
                        }
                    }
                    editSectionView(section: editSection)
                        .frame(maxWidth: 400, maxHeight: 100)
                        .offset(y: editSection == nil ? proxy.size.height + 100 : 0)
                        .opacity(editSection == nil ? 0 : 1)
                        .padding(.horizontal, screenSize.width < screenSize.height ? 10 : 50)
                        .padding(.vertical, 80)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if !isEditMode {
                    AddButton(width: screenSize.width,
                              placeHolder: "추가할 그룹명을 입력해주세요.",
                              isPresented: $isAdding,
                              string: $sectionToAdd,
                              isFocused: $isFocusedAdd) {
                        if userData.user != nil {
                            viewModel.addSectionToUser(string: sectionToAdd)
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.bottom, 10)
                    .transition(.move(edge: screenSize.width < screenSize.height ? .leading : .bottom).combined(with: .opacity))
                }
            }
            .fullScreenCover(isPresented: $isShowingSendShareSheet) {
                SendShareView(userData: userData,
                              multiList: $multiListToShare,
                              isShowingSheet: $isShowingSendShareSheet,
                              color: shareColor ?? .teal)
            }
            .alert("하위 리스트 삭제 경고", isPresented: $isShowingDeleteAlert) {
                deleteAlertView
            } message: {
                deleteAlertMessage(section: editSection)
            }
            .alert("타이틀을 수정합니다.", isPresented: $isShowingTitleAlert) {
                titleEditView
            }
        }
    }
    
}

extension ListView {
    // 배경
    var backgroundView: some View {
        Rectangle()
            .fill(Color.primaryInverted)
    }
    // 오버레이 : 샘플마크 or addSection 블러뷰
    @ViewBuilder
    var sampleMarkORAddSectionBlurView: some View {
        if userData.user == nil {
            SampleMark()
                .frame(width: 150, height: 80)
                .offset(y: -40)
        }
        if isAdding {
            blurViewWithTapAction {
                self.turnOffAddSection()
            }
        }
    }
    
    var titleEditView: some View {
        Group {
            TextField(placeholder, text: $newString)
                .submitLabel(.done)
                .onSubmit {
                    guard let multi = editMultiList else { return }
                    viewModel.modifyTitle(new: newString,
                                          multiList: multi,
                                          oriTitle: placeholder)
                    isShowingTitleAlert = false
                }
            Button("취소") {
                self.isShowingTitleAlert = false
            }
            Button("수정하기") {
                guard let multi = editMultiList else { return }
                viewModel.modifyTitle(new: newString,
                                      multiList: multi,
                                      oriTitle: placeholder)
                isShowingTitleAlert = false
            }
        }
    }
    
    var deleteAlertView: some View {
        Button(role: .destructive) {
            viewModel.deleteSectionList(section: editSection) {
                withAnimation {
                    self.editSection = nil
                    isFocusedEdit.wrappedValue = false
                }
            }
        } label: {
            Text("삭제하기")
        }
    }
        
    func deleteAlertMessage(section: SectionList!) -> some View {
        if editSection?.multiList.filter({$0.isHidden == false}).count ?? 0 > 0 {
            return Text("\n그룹에 1개 이상의 세팅된 멀티리스트가 있습니다.\n그룹 삭제 시 모두 삭제됩니다.")
        } else {
            return Text("\n그룹 보관함에 1개 이상의 세팅된 멀티리스트가 있습니다.\n그룹 삭제 시 모두 삭제됩니다.")
        }
    }
}

// MARK: - [extension 1] SubViews
extension ListView {
    
    // 1. sectionListVStackView
    func sectionListView(sectionType: SectionType! = .list, sectionList: [SectionList], animationName: Namespace.ID) -> some View {
        ForEach(sectionList, id: \.sectionID) { section in
            VStack(spacing: 0) {
                sectionTitleView(sectionType: sectionType, section: section)
                    .animation(.easeInOut, value: section.order)
                    .padding(.trailing, 15)
                    .padding(.leading, 10)
                multiListHStackView(sectionType: sectionType, section: section, animationName: animationName)
//                    .onDrop(of: [UTType.text],
//                        delegate: DragRelocateDelegate(userData: userData,
//                                                       viewModel: viewModel,
//                                                       toSection: section,
//                                                       toItem: section.multiList.last ?? nil,
//                                                       oriSectionType: self.oriSectiontype,
//                                                       oriSectionIndex: self.oriSectionOrder,
//                                                       oriMultiIndex: self.oriMultiOrder,
//                                                       fromSection: $fromSection,
//                                                       current: $draggingItem,
//                                                       action: {
//                        self.isMoveFinished = true
//                        self.isDraggingStarted = false
//                        self.fromSection = nil
//                        self.draggingItem = nil
//                    }))
            }
            .matchedGeometryEffect(id: section.order, in: sectionNamespace)
            .background {
                if sectionType == .share {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(lineWidth: 0.4)
                        .foregroundStyle(Color.primary)
                        .padding([.horizontal], 11)
                }
            }
        }
    }
    // 1-1 sectionTitleView
    func sectionTitleView(sectionType: SectionType, section: SectionList) -> some View {
        HStack(spacing: 5) {
            if sectionType == .list {
                Image(systemName: !isEditMode ? "square.fill" : "square")
                    .imageScale(.medium)
                    .foregroundStyle(!isEditMode ? Color.primary : Color.gray)
                    .overlay {
                        Text("\(section.order + 1)")
                            .foregroundStyle(!isEditMode ? Color.primaryInverted : .gray)
                            .font(.caption2)
                    }
            }
            HStack(spacing: 15) {
                Text(section.sectionName)
                    .frame(height: 20)
                    .foregroundStyle(sectionType == .share ? Color.primaryInverted : (isEditMode ? .gray : .primary))
                    .padding(.horizontal, sectionType == .list ? 0 : 10)
                    .background {
                        if sectionType == .share {
                            RoundedRectangle(cornerRadius: 3)
                                .foregroundStyle(!isEditMode ? Color.primary : .gray)
                                .padding(.leading, 1)
                        }
                    }
                Spacer()
                if !isEditMode {
                    Text("Total \(section.multiList.filter({ $0.isHidden == false && $0.isTemp == false}).count)")
                        .foregroundStyle(Color.gray)
                    .frame(height: 20)
                } else {
                    if sectionType == .share {
                        Text("이 그룹은 리스트를 모두 옮기면 가려집니다.")
                            .font(.caption)
                            .foregroundStyle(Color.gray)
                    }
                }
                if sectionType == .list {
                    if !isEditMode {
                        // 섹션에 멀티리스트 추가
                        buttonImage(image: "plus.circle.fill", color: .gray) {
                            withAnimation {
                                viewModel.addMultiList(section: section)
                            }
                        }
                        // 섹션 보관함 보기
                        let trayImage = section.multiList.filter({$0.isHidden == true}).count > 0 ? "tray.full.fill" : "tray.fill"
                        NavigationLink {
                            SectionStorageView(userData: userData, section: section, color: .colorSet[section.color % Color.colorSet.count])
                        } label: {
                            Image(systemName: trayImage)
                                .imageScale(.large)
                                .foregroundStyle(Color.gray)
                        }
                        // 섹션 설정 (삭제 / 이름 / 순서 / 색상 변경)
                        buttonImage(image: "gearshape.fill", color: .gray) {
                            withAnimation {
                                editSectionTitle = section.sectionName
                                editSectionColor = section.color
                                editSectionOrder = section.order
                                editSection = section
                            }
                        }
                    } else {
                        HStack(spacing: 20, content: {
                            if section.order != (userData.sectionList.count-1) {
                                Button(action: {
                                    viewModel.editSectionList(sectionList: section,
                                                              title: section.sectionName,
                                                              order: section.order+1,
                                                              color: section.color)
                                }, label: {
                                    Image(systemName: "arrowtriangle.down.fill")
                                        .resizable()
                                        .fontWeight(.light)
                                        .frame(width: 20, height: 15)
                                        .shadow(color: .black, radius: 0.3, x: 1, y: 1)
                                })
                                .buttonStyle(ScaleEffect(scale: 0.8))
                                .foregroundStyle(.primary)
                            }
                            if section.order != 0 {
                                Button(action: {
                                    viewModel.editSectionList(sectionList: section,
                                                              title: section.sectionName,
                                                              order: section.order-1,
                                                              color: section.color)
                                }, label: {
                                    Image(systemName: "arrowtriangle.up.fill")
                                        .resizable()
                                        .fontWeight(.light)
                                        .frame(width: 20, height: 15)
                                        .shadow(color: .black, radius: 0.3, x: 0, y: 0)
                                })
                                .buttonStyle(ScaleEffect(scale: 0.8))
                                .foregroundStyle(.primary)
                                
                            } else {
                                RoundedRectangle(cornerRadius: 5)
                                    .foregroundStyle(Color.primaryInverted)
                                    .frame(width: 20, height: 15)
                            }
                        })
                    }
                }
            }
        }
    }
    // 1-2. multiListStackView
    func multiListHStackView(sectionType: SectionType! = .list, section: SectionList, animationName: Namespace.ID) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { scrollProxy in
                HStack(spacing: 10) {
                    let frontMultiList = section.multiList.filter({ $0.isHidden == false })
                    ForEach(frontMultiList, id: \.self) { multiList in
                        multiListNavigationView(sectionType: sectionType,
                                                multiList: multiList,
                                                section: section)
                        .opacity(multiList.isTemp || (isEditMode &&
                                 (draggingItem?.multiID == multiList.multiID)) ? 0.001 : 1)
//                        .overlay(alignment: .bottomLeading) {
//                            Text("\(multiList.order)")
//                                .foregroundStyle(Color.yellow)
//                        }
//                        .overlay(alignment: .topLeading) {
//                            if isEditMode && draggingItem?.multiID != multiList.multiID && !multiList.isTemp {
//                                let width = min(screenSize.width, screenSize.height) / 4 > 100 ? 100 : min(screenSize.width, screenSize.height) / 4
//                                minusMark(width: width)
//                            }
//                        }
                        .onDrag {
                            if isEditMode {
                                withAnimation {
                                    fromSection = section
                                    draggingItem = multiList
                                }
                                if isMoveFinished {
                                    self.oriSectiontype = sectionType
                                    self.oriSectionOrder = section.order
                                    self.oriMultiOrder = multiList.order
                                    self.isMoveFinished = false
                                    isDraggingStarted = false
                                }
                                return NSItemProvider(object: String(multiList.multiID.uuidString) as NSString)
                            } else {
                                return NSItemProvider()
                            }
                        } preview: {
                            multiListNavigationView(sectionType: sectionType, multiList: multiList, section: section)
                        }
                        .onDrop(of: [UTType.text],
                            delegate: DragRelocateDelegate(userData: userData,
                                                           viewModel: viewModel,
                                                           toSection: section,
                                                           toItem: multiList,
                                                           oriSectionType: self.oriSectiontype,
                                                           oriSectionIndex: self.oriSectionOrder,
                                                           oriMultiIndex: self.oriMultiOrder,
                                                           fromSection: $fromSection,
                                                           current: $draggingItem,
                                                           action: {
                            self.isMoveFinished = true
                            self.isDraggingStarted = false
                            self.fromSection = nil
                            self.draggingItem = nil
                        }))
//                        .contextMenu(actions: [
//                            UIAction(title: "action", handler: { _ in
//                                draggingItem = nil
//                                isDraggingStarted = false
//                            })
//                        ], willEnd: {
//                            print("context ended")
//                            draggingItem = multiList
//                            isDraggingStarted = true
//                        }, willDisplay: {
//                            print("will display")
//                        })
                    }
                    .padding(.vertical, 10)
                }
                .padding(.leading, 25)
                .padding(.trailing, 10)
                .animation(.default, value: userData.sectionList)
                .onChange(of: section.multiList.count) { [oldValue = section.multiList.count] newValue in
                    if newValue > oldValue && oldValue > 0 {
                        withAnimation {
                            scrollProxy.scrollTo(section.multiList[oldValue - 1].multiID, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    // 1-2-1. multiList Card View
    func multiListNavigationView(sectionType: SectionType! = .list, multiList: MultiList, section: SectionList) -> some View {
        let width = min(screenSize.width, screenSize.height) / 5 > 100 ? 100 : min(screenSize.width, screenSize.height) / 5
        let color: Color = .colorSet[section.color % Color.colorSet.count]
        return NavigationLink {
            if !isEditMode {
                DetailMultiListView(userData: self.userData, sectionUID: section.sectionID, multiList: multiList)
            }
        } label: {
            typePreview(multiList: multiList, color: color, width: width)
        }
        .animation(.easeInOut, value: multiList.isSettingDone)
        .frame(width: width , height: width * 1.2)
        .buttonStyle(ScaleEffect())
        .disabled(isEditMode)
        .rotationEffect(.degrees(isEditMode ? 3 : 0))
        .animation(
            isEditMode ? Animation.easeInOut(duration: 0.1).repeatForever(autoreverses: true) : .default
            , value: isEditMode)
        .contextMenu {
            if !isEditMode {
                contextMenuOnMultiList(sectionType: sectionType, section: section, multi: multiList)
            }
        }
    }
    
    @ViewBuilder
    func typePreview(multiList: MultiList, color: Color, width: CGFloat) -> some View {
        switch multiList.listType {
        case .textList:
            if userData.user == nil {
                SettedTextListView(userData: userData, textList: sampleTextList, width: width)
            } else {
                var content = userData.textList.first(where: {$0.id == multiList.multiID})
                if let content = content {
                    SettedTextListView(userData: self.userData, textList: content, width: width)
                } else {
                    loadingView(color: .gray, onAppear: {
                        content = userData.textList.first(where: {$0.id == multiList.multiID})
                    })
                }
            }
        case .checkList:
            if userData.user == nil {
                SettedCheckListView(userData: userData, checkList: sampleCheckList, width: width)
            } else {
                var content = userData.checkList.first(where: {$0.id == multiList.multiID})
                if let content = content {
                    SettedCheckListView(userData: self.userData, checkList: content, width: width)
                } else {
                    loadingView(color: .gray, onAppear: {
                        content = userData.checkList.first(where: {$0.id == multiList.multiID})
                    })
                }
            }
        case .linkList:
            if userData.user == nil {
                SettedLinkListView(userData: userData, linkList: sampleLinkList, width: width)
            } else {
                var content = userData.linkList.first(where: {$0.id == multiList.multiID})
                if let content = content {
                    SettedLinkListView(userData: self.userData, linkList: content, width: width)
                } else {
                    loadingView(color: .gray, onAppear: {
                        content = userData.linkList.first(where: {$0.id == multiList.multiID})
                    })
                }
            }
        default:
            NotSettedView(userData: self.userData, multiList: multiList)
        }
    }
    
    
    // 2. section Edit View
    func editSectionView(section: SectionList!) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.secondary.opacity(0.7))
                .blur(radius: 3)
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.primaryInverted)
            VStack(alignment: .leading, spacing: 15) {
                // 1. "섹션 수정" 표지 && 삭제
                HStack {
                    Text("그룹 수정")
                        .font(.title3).bold()
                    Spacer()
                    Button {
                        if section.multiList.filter({$0.isSettingDone == true}).count > 0 {
                            isShowingDeleteAlert = true
                        } else {
                            viewModel.deleteSectionList(section: section) {
                                withAnimation {
                                    self.editSection = nil
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(ScaleEffect(scale: 0.8))
                }
                // 2. 섹션 이름 수정뷰
                HStack(spacing: 20) {
                    Text("그룹명")
                        .foregroundColor(.secondary)
                    TextField(section?.sectionName ?? "", text: $editSectionTitle)
                        .frame(height: 30)
                        .padding(.horizontal, 10)
                        .foregroundStyle(Color.black)
                        .focused(isFocusedEdit)
                        .background {
                            RoundedRectangle(cornerRadius: 5)
                                .foregroundStyle(Color.white)
                                .shadow(color: .black, radius: 1, x: 0, y: 0)
                        }
                }
                // 2. 섹션 순서 수정뷰
                HStack(spacing: 20) {
                    Text("순   서")
                        .foregroundColor(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(userData.user != nil ? viewModel.userData.sectionList : sampleList, id: \.sectionID) { section in
                                ZStack {
                                    Circle()
                                        .foregroundColor(.white)
                                        .frame(width: 30, height: 30)
                                        .shadow(color: .black, radius: 1, x: 0, y: 0)
                                    Text("\(section.order + 1)")
                                        .foregroundColor(.black)
                                    if section.order == editSectionOrder {
                                            Image(systemName: "checkmark")
                                                .imageScale(.large)
                                                .foregroundColor(.teal)
                                                .font(.caption)
                                                .fontWeight(.black)
                                    }
                                    if section.order == editSection?.order {
                                        nowMark
                                    }
                                }
                                .onTapGesture {
                                    self.editSectionOrder = section.order
                                }
                            }
                        }
                        .padding(5)
                    }
                }
                
                // 3. 수정 / 취소 버튼
                HStack {
                    let disabled = editSectionTitle.trimmingCharacters(in: .whitespacesAndNewlines) == section?.sectionName
                                && editSectionOrder == section?.order
                                && editSectionColor == section?.color
                    buttonLogin(title: "취소") {
                        withAnimation {
                            editSection = nil
                            isFocusedEdit.wrappedValue = false
                        }
                    }
                    buttonLogin(title: "수정하기", btncolor: disabled ? .gray : .teal) {
                        viewModel.editSectionList(sectionList: section, title: editSectionTitle, order: editSectionOrder, color: editSectionColor)
                        withAnimation {
                            editSection = nil
                            isFocusedEdit.wrappedValue = false
                        }
                    }
                    .disabled(disabled)
                }
                .frame(height: 40)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, screenSize.width < screenSize.height ? 40 : 15)
        }
    }
    
    
    func contextMenuOnMultiList(sectionType: SectionType! = .list, section: SectionList, multi: MultiList) -> some View {
        VStack {
            if multi.isSettingDone {
                contextMenuItem(title: "이름 수정하기", image: "pencil") {
                    if multi.listType == .textList {
                        let title = userData.textList.first(where: {$0.id == multi.multiID})?.title ?? ""
                        self.placeholder = title
                        self.newString = title
                    } else if multi.listType == .checkList {
                        let title = userData.checkList.first(where: {$0.id == multi.multiID})?.title ?? ""
                        self.placeholder = title
                        self.newString = title
                    } else if multi.listType == .linkList {
                        let title = userData.linkList.first(where: {$0.id == multi.multiID})?.title ?? ""
                        self.placeholder = title
                        self.newString = title
                    }
                    editMultiList = multi
                    isShowingTitleAlert = true
                }
//                contextMenuItem(title: "복제하기", image: "doc.on.doc") {
//
//                }
                contextMenuItem(title: "공유하기", image: "square.and.arrow.up") {
                    self.multiListToShare = multi
                    self.shareColor = .colorSet[section.color % Color.colorSet.count]
                    self.isShowingSendShareSheet = true
                }
                .disabled(userData.user?.accountType == .anonymousUser)
                
                if sectionType == .list {
                    Divider()
                    contextMenuItem(title: "섹션 보관함으로 이동", image: "tray.and.arrow.down.fill") {
                        viewModel.moveAtSectionStorage(sectionIndex: section.order,
                                                         multiList: multi)
                    }
                }
            } else {
                contextMenuItem(title: "1. 텍스트리스트 세팅하기", image: "text.alignleft") {
                    viewModel.settingContent(type: .textList, section: section, multiList: multi)
                    self.draggingItem = nil
                }
                contextMenuItem(title: "2. 체크리스트 세팅하기", image: "checkmark.circle.fill") {
                    viewModel.settingContent(type: .checkList, section: section, multiList: multi)
                    self.draggingItem = nil
                }
                contextMenuItem(title: "3. 링크리스트 세팅하기", image: "link") {
                    viewModel.settingContent(type: .linkList, section: section, multiList: multi)
                    self.draggingItem = nil
                }
            }
            Divider()
            contextMenuItem(title: "삭제하기", image: "trash", role: .destructive) {
                withAnimation {
                    viewModel.deleteMultiList(sectionType: section.order == 10000 ? .share : .list, section: section, multi: multi)
                }
            }
        }
    }
}


extension ListView {
    func tempAtEachSection(isEditMode: Bool) {
        if isEditMode {
            for i in 0..<userData.sectionList.count where userData.sectionList[i].multiList.filter({ $0.isTemp == false && $0.isHidden == false }).count == 0 {
                let section = userData.sectionList[i]
                let tempMulti = MultiList(multiID: UUID(),
                                          order: section.multiList.filter({ $0.isTemp == false && $0.isHidden == false }).count,
                                          listType: .none,
                                          isTemp: true)
                withAnimation {
                    userData.sectionList[i].multiList.append(tempMulti)
                }
            }
        } else {
            for i in 0..<userData.sectionList.count {
                let section = userData.sectionList[i]
                for j in section.multiList  {
                    withAnimation {
                        if j.isTemp {
                            if let tempIndex = userData.sectionList[i].multiList.firstIndex(of: j) {
                                userData.sectionList[i].multiList.remove(at: tempIndex)
                            }
                        }
                    }
                }
            }
        }
    }
    
//    func draggingGesture(geometry: GeometryProxy) -> some Gesture {
//        DragGesture(minimumDistance: 50)
//            .onChanged { value in
//                if value.translation.width > 50 || value.translation.height > 50 {
//                    print("ok start")
//                    self.isDraggingStarted = true
//                    
//                } else {
//                    print("not enough")
//                    self.isDraggingStarted = false
//                }
//            }
//            .onEnded { value in
//                print("hm")
//                self.isDraggingStarted = false
//            }
    var longPressGestuer: some Gesture {
        LongPressGesture(minimumDuration: 3)
            .onEnded { _ in
                isEditMode = true
                print("Ok enough")
            }
    }
    
    func turnOffAddSection() {
        self.sectionToAdd = ""
        withAnimation(.easeInOut(duration: 0.45)) {
            self.isFocusedAdd = false
            self.isAdding = false
        }
    }
    
    func longPressGesture() -> some Gesture {
        LongPressGesture(minimumDuration: 2.5, maximumDistance: 10.0)
            .onEnded { _ in
                self.isEditMode = true
            }
    }
    
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(userData: UserData(),
                 isEditMode: .constant(false),
                 isShowingSendShareSheet: .constant(false),
                 editSection: .constant(nil),
                 multiListToShare: .constant(nil),
                 isFocusedEdit: FocusState<Bool>().projectedValue)
    }
}


