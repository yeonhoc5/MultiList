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

    // sectionList 프라퍼티
    @State var isAdding: Bool = false
    @FocusState var isFocusedAdd: Bool
    @State var sectionToAdd = ""
    // sectionList edit
    @State var editSection: SectionList!
    @State var editSectionTitle: String = ""
    @State var editSectionColor: Int = 0
    @State var editSectionOrder: Int = 0
    // 공유
    @State var isShowingSharePepleSheet: Bool = false
    @State var multiListToShare: MultiList!
    @State var shareColor: Color!
    // 네임스페이스
    @Namespace var sectionNamespace
    @Namespace var multiListNamespace
    @Namespace var sectionEnd
    
    // 멀티리스트 edit 모드
    @Binding var isEditMode: Bool
    @State var isShowingDeleteAlert: Bool = false
    @State var isShowingTitleAlert: Bool = false
    @State var editMultiList: MultiList!
    @State var newString: String = ""
    @State var placeholder: String = ""
    
    @State var draggingItem: MultiList?
    @State var fromSection: SectionList?
    @State var isMoveFinished: Bool = true
    
    @State var oriSectiontype: SectionType!
    @State var oriSectionOrder: Int!
    @State var oriMultiOrder: Int!
    
    
    init(userData: UserData, isEditMode: Binding<Bool>) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: ListViewModel(userData: userData))
        _isEditMode = isEditMode
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // 1. 배경
                backgroundView
                // 2. 리스트뷰
                ScrollView {
                    ScrollViewReader { scrollProxy in
                        VStack(alignment: .leading, spacing: 15) {
                            if let sectionShared = userData.sectionShared {
                                if sectionShared.multiList.count > 0 {
                                    sectionListView(sectionType: .share, sectionList: userData.user != nil ? [sectionShared] : sampleList,
                                                    animationName: multiListNamespace)
                                    .animation(.default, value: sectionShared.multiList.count == 0)
                                }
                            }
                            sectionListView(sectionList: userData.user != nil ? userData.sectionList : sampleList,
                                            animationName: multiListNamespace)
                            additionalSpace()
                                .id(sectionEnd)
                        }
                        .padding(.top, screenSize.width < screenSize.height ? 20 : 10)
                        .onChange(of: userData.sectionList.count) { [oldValue = userData.sectionList.count] newValue in
                            if newValue > oldValue && oldValue != 0 {
                                withAnimation {
                                    scrollProxy.scrollTo(sectionEnd, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
            .opacity(userData.user == nil || editSection != nil ? 0.4 : 1)
            .overlay(alignment: .center) {
                sampleMarkORAddSectionBlurView
            }
            .overlay {
                ZStack {
                    if editSection != nil {
                        blurViewWithTapAction { withAnimation { editSection = nil } }
                    }
                    editSectionView(section: editSection)
                        .frame(maxWidth: 400, maxHeight: 400)
                        .offset(y: editSection == nil ? proxy.size.height + 100 : 0)
                        .padding(.horizontal, screenSize.width < screenSize.height ? 10 : 50)
                        .padding(.vertical, 80)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .overlay(alignment: .bottomLeading) {
                AddButton(width: screenSize.width,
                          placeHolder: "추가할 섹션명을 입력해주세요.",
                          isPresented: $isAdding,
                          string: $sectionToAdd,
                          isFocused: $isFocusedAdd) {
                    if userData.user != nil {
                        viewModel.addSectionToUser(string: sectionToAdd)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 10)
            }
            .fullScreenCover(isPresented: $isShowingSharePepleSheet) {
                SharePeopleListView(userData: userData,
                                    multiList: $multiListToShare,
                                    isShowingSheet: $isShowingSharePepleSheet,
                                    color: shareColor ?? .teal)
            }
            .alert("하위 리스트 삭제 경고", isPresented: $isShowingDeleteAlert) {
                Button(role: .destructive) {
                    viewModel.deleteSectionList(section: editSection) {
                        withAnimation {
                            self.editSection = nil
                        }
                    }
                } label: {
                    Text("삭제하기")
                }

            } message: {
                if editSection?.multiList.filter({$0.isHidden == false}).count ?? 0 > 0 {
                    Text("\n섹션에 1개 이상의 세팅된 멀티리스트가 있습니다.\n섹션 삭제 시 모두 삭제됩니다.")
                } else {
                    Text("\n섹션 보관함에 1개 이상의 세팅된 멀티리스트가 있습니다.\n섹션 삭제 시 모두 삭제됩니다.")
                }
            }
            .alert("타이틀을 수정합니다.", isPresented: $isShowingTitleAlert) {
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
    }
    
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
    
}

// MARK: - [extension 1] SubViews
extension ListView {
    
    // 1. sectionListVStackView
    func sectionListView(sectionType: SectionType! = .list, sectionList: [SectionList], animationName: Namespace.ID) -> some View {
        ForEach(sectionList, id: \.sectionID) { section in
            VStack(spacing: 0) {
                sectionTitleView(sectionType: sectionType, section: section)
                    .animation(.easeInOut, value: section.order)
                    .padding(.horizontal, 15)
                multiListHStackView(sectionType: sectionType, section: section, animationName: animationName)
            }
            .matchedGeometryEffect(id: section.order, in: sectionNamespace)
        }
    }
    // 1-1 sectionTitleView
    func sectionTitleView(sectionType: SectionType, section: SectionList) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "triangle.fill")
                .rotationEffect(.degrees(90))
                .imageScale(.small)
            HStack(spacing: 15) {
                Text("\(section.sectionName) (\(section.order))")
                    .frame(height: 20)
                    .foregroundColor(.primary)
                Spacer()
                Text("Total \(section.multiList.filter({ $0.isHidden == false }).count)")
//                    .foregroundColor(.colorSet[section.color % Color.colorSet.count])
                    .foregroundStyle(Color.numberingGray)
                .frame(height: 20)
                if sectionType == .list {
                    // 섹션에 멀티리스트 추가
                    buttonImage(image: "plus.circle.fill", color: .numberingGray) {
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
//                            .foregroundColor(Color.colorSet[section.color])
                            .foregroundStyle(Color.numberingGray)
                    }
                    // 섹션 설정 (삭제 / 이름 / 순서 / 색상 변경)
                    buttonImage(image: "gearshape.fill", color: .numberingGray) {
                        withAnimation {
                            editSectionTitle = section.sectionName
                            editSectionColor = section.color
                            editSectionOrder = section.order
                            editSection = section
                        }
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
                    let frontMultiList = section.multiList.filter({$0.isHidden == false })
                    ForEach(frontMultiList, id: \.self) { multiList in
                        multiListNavigationView(sectionType: sectionType,
                                                multiList: multiList,
                                                section: section)
//                        .matchedGeometryEffect(id: multiList.multiID, in: animationName)
                        .buttonStyle(ScaleEffect())
                        .opacity(draggingItem?.multiID == multiList.multiID ? 0.05 : 1)
                        .overlay(alignment: .bottomLeading) {
                            Text("\(multiList.order)")
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                        .overlay(alignment: .topLeading) {
                            if isEditMode {
                                Image(systemName: "minus.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .symbolRenderingMode(.multicolor)
//                                        .foregroundColor(.red)
                                    .offset(x: -5, y: -5)
                            }
                        }
                        .onDrag {
                            fromSection = section
                            draggingItem = multiList
                            
                            if isMoveFinished {
                                self.oriSectiontype = sectionType
                                self.oriSectionOrder = section.order
                                self.oriMultiOrder = multiList.order
                                self.isMoveFinished = false
                            }
                            return NSItemProvider(object: String(multiList.multiID.uuidString) as NSString)
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
                            self.fromSection = nil
                            self.draggingItem = nil
                        }))
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
                .onSubmit {
                    self.isMoveFinished = true
                    self.fromSection = nil
                    self.draggingItem = nil
                }
            }
        }
    }

    // 1-2-1. multiList Card View
    func multiListNavigationView(sectionType: SectionType! = .list, multiList: MultiList, section: SectionList) -> some View {
        let width = min(screenSize.width, screenSize.height) / 5 > 100 ? 100 : min(screenSize.width, screenSize.height) / 5
        let color: Color = .colorSet[section.color % Color.colorSet.count]
        return NavigationLink {
            DetailMultiListView(userData: self.userData, sectionUID: section.sectionID, multiList: multiList)
        } label: {
            Group {
                if !multiList.isSettingDone {
                    NotSettedView(userData: self.userData, 
                                  color: color,
                                  multiList: multiList)
                } else if multiList.listType == .textList {
                    var content = userData.textList.first(where: {$0.id == multiList.multiID})
                    if let content = content {
                        SettedTextListView(userData: self.userData,
                                           textList: content,
                                           color: color,
                                           width: width)
                    } else {
                        loadingView(color: color)
                            .onAppear {
                                content = userData.textList.first(where: {$0.id == multiList.multiID})
                            }
                    }
                } else if multiList.listType == .checkList {
                    var content = userData.checkList.first(where: {$0.id == multiList.multiID})
                    if let content = content {
                        SettedCheckListView(userData: self.userData,
                                            checkList: content,
                                            color: color,
                                            width: width)
                    } else {
                        loadingView(color: color)
                            .onAppear {
                                content = userData.checkList.first(where: {$0.id == multiList.multiID})
                            }
                    }
                } else if multiList.listType == .linkList {
                    var content = userData.linkList.first(where: {$0.id == multiList.multiID})
                    if let content = content {
                        SettedLinkListView(userData: self.userData,
                                            linkList: content,
                                            color: color,
                                            width: width)
                    } else {
                        loadingView(color: color)
                            .onAppear {
                                content = userData.linkList.first(where: {$0.id == multiList.multiID})
                            }
                    }
                }
            }
            .animation(.easeInOut, value: multiList.isSettingDone)
            .frame(width: width , height: width * 1.2)
//            .rotationEffect(.degrees(isEditMode ? 5 : 0))
//            .animation(Animation.easeInOut(duration: 0.1).repeatForever(autoreverses: true), value: isEditMode.toggle())
//            .simultaneousGesture(longPressGesture(action: {
//                withAnimation {
//                    self.multiEditMode = true
//                }
//            }))
            .contextMenu {
                contextMenuOnMultiList(sectionType: sectionType, section: section, multi: multiList)
            }
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
                    Text("섹션 수정")
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
                    Text("섹션명")
                        .foregroundColor(.secondary)
                    TextField(section?.sectionName ?? "", text: $editSectionTitle)
                        .frame(height: 30)
                        .padding(.horizontal, 10)
                        .background {
                            RoundedRectangle(cornerRadius: 5)
                                .foregroundColor(.gray.opacity(0.1))
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
                                        .foregroundColor(.gray.opacity(0.1))
                                        .frame(width: 30, height: 30)
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
                // 2. 섹션 색상 수정뷰
                HStack(alignment: .top, spacing: 20) {
                        Text("컬   러")
                            .foregroundColor(.secondary)
                    PaletteView(selectedIndex: $editSectionColor,
                                currentColor: editSection?.color ?? 0)
                }
                .padding(.bottom, 10)
                
                
                // 3. 수정 / 취소 버튼
                HStack {
                    let disabled = editSectionTitle == section?.sectionName
                                && editSectionOrder == section?.order
                                && editSectionColor == section?.color
                    buttonLogin(title: "취소") {
                        withAnimation {
                            editSection = nil
                        }
                    }
                    buttonLogin(title: "수정하기", btncolor: disabled ? .gray : .teal) {
                        viewModel.editSectionList(sectionList: section, title: editSectionTitle, order: editSectionOrder, color: editSectionColor)
                        withAnimation {
                            editSection = nil
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
                    if multi.listType == .checkList {
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
                    self.isShowingSharePepleSheet = true
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
                contextMenuItem(title: "1. 체크리스트 세팅하기", image: "square.and.arrow.up") {
                    viewModel.settingContent(type: .checkList, section: section, multiList: multi)
                }
                contextMenuItem(title: "2. 링크리스트 세팅하기", image: "square.and.arrow.up") {
                    viewModel.settingContent(type: .linkList, section: section, multiList: multi)
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
    func turnOffAddSection() {
        self.sectionToAdd = ""
        withAnimation(.easeInOut(duration: 0.45)) {
            self.isFocusedAdd = false
            self.isAdding = false
        }
    }
    
    func longPressGesture(action: @escaping () -> Void) -> some Gesture {
        LongPressGesture(minimumDuration: 3.0, maximumDistance: 10.0)
    }
    
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(userData: UserData(), isEditMode: .constant(true))
    }
}

struct DragRelocateDelegate: DropDelegate {
    @ObservedObject var userData: UserData
    @ObservedObject var viewModel: ListViewModel
    let toSection: SectionList
    let toItem: MultiList
    @Binding var fromSection: SectionList?
    @Binding var current: MultiList?
    
    let oriSectionType: SectionType!
    let oriSectionIndex: Int!
    let oriMultiIndex: Int!
    
    let finishAction: () -> Void
    
    init(userData: UserData, viewModel: ListViewModel, toSection: SectionList, toItem: MultiList,
         oriSectionType: SectionType! = nil, oriSectionIndex: Int! = nil, oriMultiIndex: Int! = nil, fromSection: Binding<SectionList?>, current: Binding<MultiList?>, action: @escaping () -> Void) {
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
        
//        if toSection.sectionID == fromSection.sectionID {
//            if toItem != nil {
//                
//            } else if toItem == nil {
//                
//            }
//        } else {
//            
//        }
        
        
        if fromSection.sectionID == userData.sectionShared.sectionID {
            // 1. shared에서 shared로 (순서만 이동)
            guard let fromIndex = userData.sectionShared.multiList.firstIndex(of: current) else { return }
            if toSection.sectionID == fromSection.sectionID {
                guard let toIndex = userData.sectionShared.multiList.firstIndex(of: toItem) else { return }
                moveItem(oriSection: .share, fromItemIndex: fromIndex, current: current,
                         toSection: .share, toItemInex: toIndex, toItem: toItem)
            } else {
                // 2. shared에서 sectionList로 (섹션 이동)
                guard let toSectionIndex = userData.sectionList.firstIndex(of: toSection),
                      let toIndex = userData.sectionList[toSectionIndex].multiList.firstIndex(of: toItem) else { return }
                moveItem(oriSection: .share, fromItemIndex: fromIndex, current: current,
                         toSection: .list, toSectionIndex: toSectionIndex, toItemInex: toIndex, toItem: toItem)
                self.fromSection = userData.sectionList[toSectionIndex]
            }
        } else {
            // 2. sectionList에서 sectionList로
            if toSection.sectionID == userData.sectionShared.sectionID {
                guard let fromSectionIndex = userData.sectionList.firstIndex(of: fromSection),
                      let fromIndex = userData.sectionList[fromSectionIndex].multiList.firstIndex(of: current),
                      let toIndex = userData.sectionShared.multiList.firstIndex(of: toItem) else { return }
                moveItem(oriSection: .list, oriSectionIndex: fromSectionIndex, fromItemIndex: fromIndex, current: current,
                         toSection: .share, toItemInex: toIndex, toItem: toItem)
                self.fromSection = userData.sectionShared
            } else {
                guard let fromSectionIndex = userData.sectionList.firstIndex(of: fromSection),
                      let toSectionIndex = userData.sectionList.firstIndex(of: toSection) else { return }
                guard let fromIndex = userData.sectionList[fromSectionIndex].multiList.firstIndex(of: current),
                      let toIndex = userData.sectionList[toSectionIndex].multiList.firstIndex(of: toItem) else { return }
                moveItem(oriSection: .list, oriSectionIndex: fromSectionIndex, fromItemIndex: fromIndex, current: current,
                         toSection: .list, toSectionIndex: toSectionIndex, toItemInex: toIndex, toItem: toItem)
                self.fromSection = userData.sectionList[toSectionIndex]
            }
        }
    }
    
    func moveItem(oriSection: SectionType, oriSectionIndex: Int! = nil, fromItemIndex: Int, current: MultiList,
                  toSection: SectionType, toSectionIndex: Int! = nil, toItemInex: Int, toItem: MultiList) {
        let tempMulti = MultiList(multiID: current.multiID, order: current.order, listType: .checkList, isTemp: true)
        if oriSection == .share && toSection == .share {

            userData.sectionShared.multiList.move(fromOffsets: IndexSet(integer: fromItemIndex),
                                                  toOffset: toItemInex > fromItemIndex ? toItemInex + 1 : toItemInex)
            
        } else if oriSection == .share && toSection == .list && toSectionIndex != nil {
            if toItem.multiID != current.multiID {
                userData.sectionList[toSectionIndex].multiList.insert(tempMulti, at: toItemInex)
//                userData.sectionList[toSectionIndex].multiList.insert(current, at: toItemInex)
    //            userData.sectionShared.multiList.remove(at: fromItemIndex)
                
            }
        } else if oriSection == .list && toSection == .list && oriSectionIndex != nil && toSectionIndex != nil {
            if oriSectionIndex == toSectionIndex {
                                
                userData.sectionList[oriSectionIndex].multiList.move(fromOffsets: IndexSet(integer: fromItemIndex),
                                                      toOffset: toItemInex > fromItemIndex ? toItemInex + 1 : toItemInex)
                
            } else {
                if toItem.multiID != current.multiID && userData.sectionList[toSectionIndex].multiList.compactMap({$0.multiID}).contains(current.multiID) == false {
                    userData.sectionList[toSectionIndex].multiList.insert(tempMulti, at: toItemInex)
    //                userData.sectionList[oriSectionIndex].multiList.remove(at: fromItemIndex)
//                    userData.sectionList[toSectionIndex].multiList.insert(current, at: toItemInex)
                 
                }
                if userData.sectionList[oriSectionIndex].multiList[fromItemIndex].isTemp {
                    userData.sectionList[oriSectionIndex].multiList.remove(at: fromItemIndex)
                }
                
            }
        } else if toSection == .share {
            if userData.sectionList[oriSectionIndex].multiList[fromItemIndex].isTemp {
                userData.sectionList[oriSectionIndex].multiList.remove(at: fromItemIndex)
            }
            
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        
        // case / orisectointype / toSectionType / fromsectionIndex(nil) / tosectionindex(nil) / fromMultiIndex / toMultiIndex /
        
        if let current = current {
            if oriSectionType == .share {
                if toSection.sectionID == userData.sectionShared.sectionID {
                    if let toMultiIndex = userData.sectionShared.multiList.firstIndex(of: toItem) {
                        viewModel.moveMultiItem(moveType: .inline,
                                                fromSectionType: .share,
                                                fromMultiIndex: self.oriMultiIndex,
                                                toMultiIndex: toMultiIndex,
                                                toMoveItem: current)
                    }
                } else {
                    if let toMultiIndex = userData.sectionList[toSection.order].multiList.firstIndex(of: toItem) {
                        viewModel.moveMultiItem(moveType: .shareToList,
                                                fromSectionType: .share,
                                                toSectionIndex: toSection.order,
                                                fromMultiIndex: oriMultiIndex,
                                                toMultiIndex: toMultiIndex,
                                                toMoveItem: current)
                    }
                }
            } else {
                if oriSectionIndex == toSection.order {
                    if let toMultiIndex = userData.sectionList[oriSectionIndex].multiList.firstIndex(of: toItem) {
                        viewModel.moveMultiItem(moveType: .inline,
                                                fromSectionType: .list,
                                                fromSectionIndex: self.oriSectionIndex,
                                                toSectionIndex: self.oriSectionIndex,
                                                fromMultiIndex: self.oriMultiIndex,
                                                toMultiIndex: toMultiIndex,
                                                toMoveItem: current)
                    }
                } else if oriSectionType == .list {
                    if let toMultiIndex = userData.sectionList[toSection.order].multiList.firstIndex(of: toItem) {
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
        
        self.current = nil
        self.fromSection = nil
        
        finishAction()
        return true
    }
}
