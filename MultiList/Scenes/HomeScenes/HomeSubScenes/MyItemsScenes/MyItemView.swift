//
//  MyItemView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/26.
//

import SwiftUI
import PhotosUI
import FirebaseFirestore

struct MyItemView: View {
    @ObservedObject var userData: UserData
    @StateObject var viewModel: MyItemViewModel
    @Binding var isShowingItemView: Bool
    
    @State var isShowingProgressView: Bool = false
    @State var isShowingDeleteAlert: Bool = false
    @State var isShowingContentAlert: Bool = false
    @State var contentAlertString: String = ""
    
    // myItem 공통 프라퍼티
    @State var myItem: MyItemModel!
    @Binding var itemNumber: Int
    @Binding var itemType: MyItemType
    @State var itemTitle: String = ""
    @State var selectedPhoto: [PhotosPickerItem] = []
    @State var isEditMode: Bool = true
    @Namespace var animationID
    @FocusState var isFocused
    // type 0. text
    @State var itemText: String = ""
    // type 2. photo
    @State var itemPhoto: UIImage! = nil
    @State var photoSize: Double = 0
    @State var isShowingMenu: Bool = true
    
    init(userData: UserData, 
         isShowingItemView: Binding<Bool>,
         itemType: Binding<MyItemType>,
         itemNumber: Binding<Int>,
         myItem: Binding<MyItemModel?>) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: MyItemViewModel(userData: userData))
        _itemType = itemType
        _itemNumber = itemNumber
        _isShowingItemView = isShowingItemView
    }
    
    var body: some View {
        NavigationView(content: {
            GeometryReader(content: { geometry in
                ZStack(alignment: .trailing) {
                    // 0. 백그라운드
                    Rectangle()
                        .foregroundStyle(Color.primaryInverted)
                    // 1. 컨텐트 타입뷰
                    Group {
                        contentTypeView(type: self.itemType, itemNumber: itemNumber)
                            .matchedGeometryEffect(id: "contentView", in: animationID)
                        if self.isShowingContentAlert || viewModel.isShowingContentAlert {
                            // 1-1. 컨텐트 알럿
                            contentState(text: contentAlertString)
                        }
                    }
                    .frame(maxWidth: screenSize.width < screenSize.height ? screenSize.width : max(geometry.size.width, geometry.size.height) * 0.65)
                }
                .onTapGesture {
                    withAnimation {
                        if !isEditMode && myItem.type == .image {
                            isShowingMenu.toggle()
                        } else if isEditMode && myItem?.type == .text {
                            self.isFocused = false
                        }
                    }
                }
                .overlay(alignment: .topLeading) {
                    // 2. 타이틀 / 버튼뷰
                    if isShowingMenu {
                        OStack {
                            VStack(alignment: .leading, content: {
                                titleView
                                Spacer()
                                buttonView(disable: (itemText == "" && itemPhoto == nil)
                                           || checkDisable() == .notChanged)
                            })
                            .frame(maxWidth: screenSize.width < screenSize.height ? screenSize.width : max(screenSize.width, screenSize.height) * 0.25)
                            Spacer()
                                .frame(height: 20)
                        }
                        .padding(10)
                    }
                }
            })
            .onAppear(perform: {
                assignMyItem(number: self.itemNumber)
            })
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isShowingMenu {
                    if isEditMode && myItem != nil {
                        ToolbarItem(placement: .principal) {
                            myItemView
                        }
                    }
                    if !isEditMode {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("수정하기") {
                                withAnimation {
                                    self.isEditMode = true
                                }
                            }
                        }
                        ToolbarItem(placement: .topBarLeading) {
                            Button("삭제하기", role: .destructive) {
                                self.isShowingDeleteAlert = true
                            }
                            .tint(.colorSet[0])
                        }
                    } else {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("") {}
                        }
                    }
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("") {}
                    }
                }
            }
        })
        .alert("MyItem \(itemNumber+1)를 삭제하시겠습니까?", isPresented: $isShowingDeleteAlert) {
            Button("삭제하기", role: .destructive) {
                withAnimation {
                    userData.deleteMyItem(itemNumber: self.itemNumber)
                    assignNil()
                }
            }
        }
    }
}

extension MyItemView {
    
    func contentTypeView(type: MyItemType, itemNumber: Int) -> some View {
        HStack(content: {
            Group {
                switch type {
                case .text:
                    TextItemView(userData: userData,
                                 isShowingItemView: $isShowingItemView,
                                 itemNumber: .constant(itemNumber),
                                 itemText: $itemText,
                                 isEditMode: $isEditMode,
                                 myItem: userData.myItems[itemNumber])
                        .padding(.horizontal, 10)
                        .padding(.vertical, screenSize.width < screenSize.height ? 100 : 10)
                case .image:
                    VStack {
                        PhotosPickerView(userData: userData,
                                         isShowingItemView: $isShowingItemView,
                                         itemNumber: .constant(itemNumber),
                                         itemPhoto: $itemPhoto,
                                         selectedPhoto: $selectedPhoto,
                                         isEditMode: $isEditMode,
                                         myItem: userData.myItems[itemNumber],
                                         photoSize: $photoSize)
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                        .onAppear {
                            if itemPhoto == nil && myItem != nil {
                                viewModel.reloadPhoto(itemID: myItem.id, itemOrder: itemNumber)
                            }
                        }
                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            }
        })
    }
    
    
    var myItemView: some View {
        Text("MyItem \(itemNumber+1)")
    }
    
    var titleView: some View {
        HStack(alignment: .firstTextBaseline, content: {
            Group {
                if isEditMode {
                    Text("타이틀 :")
//                        .matchedGeometryEffect(id: "titleText", in: animationID)
                } else {
                    Text("MyImte \(itemNumber+1) :")
//                        .matchedGeometryEffect(id: "titleText", in: animationID)
                }
            }
            .transition(.asymmetric(insertion: .slide, removal: .push(from: .trailing)))
            .fontWeight(.semibold)
            Group {
                if isEditMode {
                    ZStack(content: {
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundStyle(Color.white)
                            .shadow(color: .black, radius: 1, x: 0, y: 0)
                        TextField("", text: $itemTitle)
                            .focused($isFocused)
                            .placeholder(when: itemTitle.isEmpty, alignment: .leading, placeholder: {
                                Text("MyItem \(itemNumber+1)")
                                    .foregroundStyle(Color.gray.opacity(0.5))
                                    .matchedGeometryEffect(id: "title", in: animationID)
                            })
                            
                            .minimumScaleFactor(0.5)
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 10)
                    })
                } else {
                    Text(myItem?.title ?? itemTitle)
                        .matchedGeometryEffect(id: "title", in: animationID)
                        .minimumScaleFactor(0.5)
                }
            }
            .font(Font.system(.largeTitle, design: .rounded, weight: .bold))
            .frame(height: 50, alignment: .leading)
        })
    }
    
    @ViewBuilder
    func buttonView(disable: Bool) -> some View {
        OStack(isVerticalFirst: false) {
            if self.myItem == nil || isEditMode {
                // 0. 취소 버튼( 아이템 없을 시 / 수정 모드 시)
                buttonCancel
                    .matchedGeometryEffect(id: "button01", in: animationID)
                Group {
                    if myItem == nil  {
                        // 0-1. 저장하기
                        buttonSave(disable: disable)
                    } else {
                        // 0.2 수정하기 (아이템 있을 시)
                        buttonResave(disable: disable)
                    }
                }
                .disabled(disable)
                .matchedGeometryEffect(id: "button02", in: animationID)
            } else {
                Group {
                    if myItem.type == .text {
                        buttonClipboard
                    } else if myItem.type == .image {
                        buttonSaveToPhone
                    }
                }
                .matchedGeometryEffect(id: "button01", in: animationID)
                // 1. 닫기 버튼( 아이템 보기모드 시)
                buttonClose
                    .matchedGeometryEffect(id: "button02", in: animationID)
            }
        }
        .frame(maxHeight: screenSize.width < screenSize.height ? 50 : 150)
    }
    
    func assignMyItem(number: Int) {
        if let myItem = userData.myItems[itemNumber] {
            self.myItem = myItem
            self.itemTitle = myItem.title
            if myItem.type == .text {
                self.itemText = myItem.itemText
            } else if myItem.type == .image {
                itemPhoto = myItem.itemPhoto
            }
            isEditMode = false
        }
    }
    
    func assignNil() {
        self.itemTitle = ""
        self.itemText = ""
        self.myItem = nil
        self.isEditMode = true
        self.isShowingItemView = false
    }
    
    func contentState(text: String) -> some View {
        ZStack(content: {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(.primary.opacity(0.7))
            Text(text)
                .foregroundStyle(Color.primaryInverted)
        })
        .frame(width: 300, height: 50)
//        .onAppear(perform: {
//            onAppear()
//        })
    }
    
    func checkDisable() -> ItemSaveMode {
        guard let myItem = myItem else { return .saveFirst }
        if myItem.title == self.itemTitle {
            return checkContent() ? .changeContent : .notChanged
        } else {
            return checkContent() ? .changeAll : .changeTitle
        }
    }
    
    func checkContent() -> Bool {
        if myItem.type == .text {
            return myItem.itemText != self.itemText
        } else if myItem.type == .image {
            return myItem.itemPhoto != self.itemPhoto
        } else {
            return true
        }
    }
}


// 버튼
extension MyItemView {
    
    // 0. 아이템 없을 시
    // 0-1. 취소 버튼
    var buttonCancel: some View {
        buttonLogin(title: "취소") {
            if myItem == nil {
                isShowingItemView = false
            } else {
                itemTitle = myItem.title
                switch myItem.type {
                case .text:
                    itemText = myItem.itemText
                case .image:
                    itemPhoto = myItem.itemPhoto
                    selectedPhoto = []
                }
                withAnimation {
                    isEditMode = false
                }
            }
        }
    }
    // 0-2. 저장 버튼
    func buttonSave(disable: Bool) -> some View {
        buttonLogin(title: "저장", btncolor: disable ? .gray : .teal, textColor: .white) {
            let myItem = MyItemModel(title: itemTitle == "" ?
                                     "MyItem \(itemNumber+1)" : itemTitle,
                                     order: itemNumber,
                                     type: itemType)
            switch itemType {
            case .text:
                viewModel.saveMyItem(myItem: myItem, itemText: itemText) { _ in
                    self.contentAlertString = "저장되었습니다."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            self.isShowingContentAlert = false
                            self.contentAlertString = ""
                        }
                    }
                }
            case .image:
                guard let image = self.itemPhoto else { return }
                viewModel.saveMyItem(myItem: myItem, itemPhoto: image) { bool in
                    if bool {
                        self.contentAlertString = "업로드를 완료했습니다."
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                self.isShowingContentAlert = false
                                self.contentAlertString = ""
                            }
                        }
                    }
                }
                self.contentAlertString = "사진을 서버에 저장 중입니다.\n앱을 종료할 시 업로드되지 않을 수 있습니다."
            }
            DispatchQueue.main.async {
                withAnimation {
                    self.isShowingContentAlert = true
                    self.myItem = userData.myItems[itemNumber]
                    self.itemTitle = myItem.title
                    self.isEditMode = false
                }
            }
        }
    }
    
    
    // 1. 아이템 있을 시
    // 1-1. 보기 모드
    // 1-1-1. 닫기 버튼
    var buttonClose: some View {
        buttonLogin(title: "닫기", btncolor: .orange, textColor: .white) {
            isShowingItemView = false
            self.myItem = nil
        }
    }
    // 1-1-2. 컨텐츠 버튼 (텍스트 : 복사 / 사진 : 사진첩에저장)
    var buttonClipboard: some View {
        buttonLogin(title: "클립보드에 복사",
                    btncolor: .orange,
                    textColor: .white) {
            viewModel.saveTextAtClipboard(text: itemText) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.isShowingContentAlert = false
                }
            }
            DispatchQueue.main.async {
                withAnimation {
                    self.contentAlertString = "텍스트를 클립보드에 복사하였습니다."
                    self.isShowingContentAlert = true
                }
            }
        }
    }
    var buttonSaveToPhone: some View {
        buttonLogin(title: "핸드폰 사진첩에 저장",
                    btncolor: .orange,
                    textColor: .white) {
            if let photo = itemPhoto {
                
                viewModel.savePhotoAtPhotoAlbum(image: photo) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.isShowingContentAlert = false
                    }
                }
                DispatchQueue.main.async {
                    withAnimation {
                        self.contentAlertString = "사진을 사진첩에 저장했습니다."
                        self.isShowingContentAlert = true
                    }
                }
            } else {
                withAnimation {
                    self.contentAlertString = "사진을 읽지 못했습니다."
                    self.isShowingContentAlert = true
                }
            }
        }
    }
    
    
    // 1-2. EditMode
    // 1-2-1. 취소 버튼: 0-1과 동일
    // 1-2-2. 수정저장하기 버튼
    func buttonResave(disable: Bool) -> some View {
        buttonLogin(title: "저장", btncolor: disable ? .gray : .teal, textColor: .white) {
            let myItem = MyItemModel(id: myItem.id,
                                     title: itemTitle == "" ?
                                     "MyItem \(itemNumber+1)" : itemTitle,
                                     order: itemNumber,
                                     type: itemType)
            switch itemType {
            case .text:
                if checkDisable() == .changeTitle {
                    self.contentAlertString = "타이틀을 수정하였습니다."
                } else if checkDisable() == .changeContent {
                    self.contentAlertString = "내용을 수정하였습니다."
                } else {
                    self.contentAlertString = "타이틀과 내용을 수정하였습니다."
                }
                viewModel.saveMyItem(myItem: myItem, itemText: itemText, saveMode: checkDisable()) { bool in
                    withAnimation {
                        self.contentAlertString = "업로드를 완료했습니다."
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.isShowingContentAlert = false
                            self.contentAlertString = ""
                        }
                    }
                }
            case .image:
                guard let image = self.itemPhoto else {
                    return
                }
                if checkDisable() == .changeTitle {
                    self.contentAlertString = "타이틀을 수정하였습니다."
                } else {
                    self.contentAlertString = "사진을 서버에 저장 중입니다.\n앱을 종료할 시 업로드되지 않을 수 있습니다."
                }
                viewModel.saveMyItem(myItem: myItem, itemPhoto: image, saveMode: checkDisable()) { bool in
                    DispatchQueue.main.async {
                        withAnimation {
                            self.contentAlertString = bool ? "업로드를 완료했습니다." : "업로드를 실패했습니다."
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            print("step 2")
                            self.isShowingContentAlert = false
                            self.contentAlertString = ""
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                print("step 1")
                withAnimation {
                    self.isShowingContentAlert = true
                    self.myItem = userData.myItems[itemNumber]
                    self.itemTitle = myItem.title
                    self.isEditMode = false
                }
            }
        }
    }
}


#Preview {
    MyItemView(userData: UserData(),
               isShowingItemView: .constant(true),
               itemType: .constant(.text),
               itemNumber: .constant(1),
               myItem: .constant(nil))
}
