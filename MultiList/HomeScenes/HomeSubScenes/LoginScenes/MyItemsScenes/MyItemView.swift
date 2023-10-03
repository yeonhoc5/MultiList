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
    @State var contentString: String = ""
    
    // myItem 공통
    @State var myItem: MyItemModel!
    @Binding var itemNumber: Int
    @Binding var itemType: MyItemType
    @State var itemTitle: String = ""
    @State var selectedPhoto: [PhotosPickerItem] = []
    
    @State var isEditMode: Bool = true
    @Namespace var animationID
    
    // type 0. text
    @State var itemText: String = ""
    // type 2. photo
    @State var itemPhoto: UIImage! = nil
    
    init(userData: UserData, isShowingItemView: Binding<Bool>, itemType: Binding<MyItemType>, itemNumber: Binding<Int>, myItem: Binding<MyItemModel?>) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: MyItemViewModel(userData: userData))
        _itemType = itemType
        _itemNumber = itemNumber
        _isShowingItemView = isShowingItemView
    }
    
    var body: some View {
        NavigationView(content: {
            Rectangle().foregroundStyle(.clear)
                .onAppear(perform: {
                    assignMyItem(number: self.itemNumber)
                })
                .overlay(alignment: .leading) {
                    contentTypeView(type: self.itemType, itemNumber: itemNumber)
                    if self.isShowingContentAlert {
                        contentState(text: contentString ,onAppear: {
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                                withAnimation {
//                                    self.isShowingContentAlert = false
//                                }
//                            }
                        })
                    }
                }
                .overlay(alignment: .topTrailing) {
                    VStack(alignment: .trailing, content: {
                        titleView
                        if screenSize.width < screenSize.height {
                            Spacer()
                        }
                        buttonView(disable: (itemText == "" && itemPhoto == nil)
                                   || checkDisable() == .notChanged)
                    })
                    .padding(.horizontal, 20)
                    .frame(maxWidth: screenSize.width < screenSize.height ? .infinity : screenSize.width * 0.4)
                }
                .padding(.bottom, screenSize.width < screenSize.height ? 50 : 0)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(isEditMode ? "MyItem \(itemNumber+1)" : "")
                .toolbar {
                    if !isEditMode {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("수정하기") {
                                withAnimation {
                                    self.isEditMode = true
                                }
                            }
                        }
                    } else {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("삭제하기", role: .destructive) {
                                self.isShowingDeleteAlert = true
                            }
                        }
                    }
                }
        })
        .alert("MyItem \(itemNumber+1)를 삭제하시겠습니까?", isPresented: $isShowingDeleteAlert) {
            Button("삭제하기", role: .destructive) {
                withAnimation {
                    viewModel.deleteMyItem(itemNumber: self.itemNumber)
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
                        .padding(.horizontal, 20)
                case .image:
                    PhotosPickerView(userData: userData, 
                                     isShowingItemView: $isShowingItemView,
                                     itemNumber: .constant(itemNumber),
                                     itemPhoto: $itemPhoto,
                                     selectedPhoto: $selectedPhoto,
                                     isEditMode: $isEditMode,
                                     myItem: userData.myItems[itemNumber])
                }
            }
            .frame(maxWidth: max(screenSize.width, screenSize.height * 0.6))
            if screenSize.width > screenSize.height {
                Spacer()
            }
        })
    }
    
    
    var titleView: some View {
        HStack(alignment: .firstTextBaseline, content: {
            Spacer()
            Group {
                if isEditMode {
                    Text("타이틀 :")
                        .matchedGeometryEffect(id: "titleText", in: animationID)
                } else {
                    Text("MyItem \(itemNumber+1) :")
                        .matchedGeometryEffect(id: "titleText", in: animationID)
                }
            }
            .fontWeight(.semibold)
            Group {
                if isEditMode {
                    ZStack(content: {
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundStyle(Color.white)
                            .shadow(color: .black, radius: 1, x: 0, y: 0)
                        TextField("", text: $itemTitle)
                            .placeholder(when: itemTitle.isEmpty, alignment: .leading, placeholder: {
                                Text("MyItem \(itemNumber+1)")
                                    .foregroundStyle(Color.gray.opacity(0.5))
                            })
                            .matchedGeometryEffect(id: "title", in: animationID)
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
        Group {
            if self.myItem == nil || isEditMode {
                HStack(content: {
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
                    .matchedGeometryEffect(id: "button01", in: animationID)
                    buttonLogin(title: "저장", btncolor: disable ? .gray : .teal, textColor: .white) {
                        if self.myItem == nil {
                            let myItem = MyItemModel(title: itemTitle == "" ?
                                                     "MyItem \(itemNumber+1)" : itemTitle,
                                                     order: itemNumber,
                                                     type: itemType)
                            switch itemType {
                            case .text:
                                viewModel.saveMyItem(myItem: myItem, itemText: itemText) { _ in }
                            case .image:
                                guard let image = self.itemPhoto else { return }
                                viewModel.saveMyItem(myItem: myItem, itemPhoto: image) { bool in
                                    if bool {
                                        withAnimation {
                                            self.isShowingContentAlert = false
                                        }
                                    }
                                }
                                self.contentString = "사진을 서버에 저장 중입니다.\n앱을 종료할 시 사진이 제대로 업로드되지 않습니다."
                            }
                        } else {
                            let myItem = MyItemModel(id: myItem.id,
                                                     title: itemTitle == "" ?
                                                     "MyItem \(itemNumber+1)" : itemTitle,
                                                     order: itemNumber,
                                                     type: itemType)
                            switch itemType {
                            case .text:
                                if checkDisable() == .changeTitle {
                                    self.contentString = "타이틀을 수정하였습니다."
                                } else {
                                    self.contentString = "타이틀과 내용을 수정하였습니다."
                                }
                                viewModel.saveMyItem(myItem: myItem, itemText: itemText, saveMode: checkDisable()) { _ in }
                            case .image:
                                guard let image = self.itemPhoto else { return }
                                if checkDisable() == .changeTitle {
                                    self.contentString = "타이틀을 수정하였습니다."
                                } else {
                                    self.contentString = "사진을 서버에 저장 중입니다.\n앱을 종료할 시 사진이 제대로 업로드되지 않습니다."
                                }
                                viewModel.saveMyItem(myItem: myItem, itemPhoto: image, saveMode: checkDisable()) { bool in
                                    if bool {
                                        withAnimation {
                                            self.isShowingContentAlert = false
                                            self.contentString = ""
                                        }
                                    }
                                }
                                
                            }
                        }
                        withAnimation {
                            self.isShowingContentAlert = true
                            self.myItem = userData.myItems[itemNumber]
                            self.itemTitle = myItem.title
                            self.isEditMode = false
                        }
                    }
                    .disabled(disable)
                    .matchedGeometryEffect(id: "button02", in: animationID)
                })
            } else {
                HStack(content: {
                    buttonLogin(title: "닫기", 
                                btncolor: .orange,
                                textColor: .white) {
                        isShowingItemView = false
                        self.myItem = nil
                    }
                    .matchedGeometryEffect(id: "button01", in: animationID)
                    buttonLogin(title: self.myItem.type == .text ? "복사" : "저장",
                                btncolor: .orange,
                                textColor: .white) {
                        viewModel.saveTextAtClipboard(text: itemText) {
                            withAnimation {
                                self.contentString = "텍스트를 클립보드에 복사하였습니다."
                                self.isShowingContentAlert = true
                            }
                        }
                    }
                    .matchedGeometryEffect(id: "button02", in: animationID)
                })
            }
        }
        .frame(height: 50)
        .frame(maxWidth: screenSize.width < screenSize.height ? .infinity : 250)
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
    
    func contentState(text: String, onAppear: @escaping () -> Void) -> some View {
        ZStack(content: {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(.primary.opacity(0.7))
            Text(text)
                .foregroundStyle(Color.primaryInverted)
        })
        .frame(width: 300, height: 50)
        .onAppear(perform: {
            onAppear()
        })
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

#Preview {
    MyItemView(userData: UserData(),
               isShowingItemView: .constant(true),
               itemType: .constant(.text),
               itemNumber: .constant(1),
               myItem: .constant(nil))
}
