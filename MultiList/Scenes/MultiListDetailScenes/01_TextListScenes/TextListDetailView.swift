//
//  TextListDetailView.swift
//  MultiList
//
//  Created by yeonhoc5 on 11/6/23.
//


import SwiftUI
import PhotosUI
import FirebaseFirestore

struct TextListDetailView: View {
    @ObservedObject var userData: UserData
    @StateObject var viewModel: TextListDetailViewModel
    
    @State var textRow: TextRow!
    @State var contentText: String = ""
    
    @Binding var isShowingItemView: Bool
    
    @State var isShowingProgressView: Bool = false
    @State var isShowingDeleteAlert: Bool = false
    @State var isShowingContentAlert: Bool = false
    @State var contentAlertString: String = ""
    
    @State var isEditMode: Bool = true
    @Namespace var animationID
    @FocusState var isFocused
    
    @State var contentState: String = ""
    
    init(userData: UserData,
         textRow: TextRow,
         isShowingItemView: Binding<Bool>) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: TextListDetailViewModel(userData: userData, textListID: textRow.id))
        _isShowingItemView = isShowingItemView
        self.textRow = textRow
        self.contentText = textRow.content
    }
    
    var body: some View {
        NavigationView(content: {
            GeometryReader(content: { geometry in
                ZStack(alignment: .trailing) {
                    // 0. 백그라운드
                    Rectangle()
                        .foregroundStyle(Color.primaryInverted)
                    // 1. 컨텐트 타입뷰
                    OStack {
                        Group {
                            textEditView
                            .matchedGeometryEffect(id: "contentView", in: animationID)
                            if self.isShowingContentAlert {
                                // 1-1. 컨텐트 알럿
                                contentState(text: contentAlertString)
                            }
                        }
                        buttonView(disable: false)
                            .frame(maxWidth: screenSize.width < screenSize.height ? .infinity : screenSize.width * 0.1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
                .onTapGesture {
                    withAnimation {
                        self.isFocused = false
                    }
                }
            })
            .navigationBarTitleDisplayMode(.inline)
        })
        .alert("내용을 삭제하시겠습니까?", isPresented: $isShowingDeleteAlert) {
            Button("삭제하기", role: .destructive) {
                withAnimation {
                    assignNil()
                }
            }
        }
    }
}

extension TextListDetailView {
    
    var textEditView: some View {
        TextEditor(text: $contentText)
            .foregroundStyle(isEditMode ? Color.black : Color.primary)
            .focused($isFocused)
            .scrollContentBackground(.hidden)
            .padding(10)
            .background(content: {
                isEditMode ? Color.white : Color.primaryInverted
            })
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .shadow(color: .black, radius: 1, x: 0, y: 0)
            .background {
                if !isEditMode {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(lineWidth: 0.4)
                        .foregroundStyle(Color.primary)
                }
            }
            
    }
    
    @ViewBuilder
    func buttonView(disable: Bool) -> some View {
        OStack(isVerticalFirst: false) {
                // 0. 취소 버튼( 아이템 없을 시 / 수정 모드 시)
                Group {
                    if textRow?.content == ""  {
                        // 0-1. 저장하기
                        buttonSave(disable: disable)
                    } else {
                        // 0.2 수정하기 (아이템 있을 시)
                        buttonResave(disable: disable)
                    }
                }
                .disabled(disable)
                .matchedGeometryEffect(id: "button02", in: animationID)
        }
        .frame(maxHeight: screenSize.width < screenSize.height ? 50 : 150)
    }
    
    func assignNil() {
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
    
    func checkDisable() -> Bool {
//        if textRow.content == "" {
//            return .notChanged
//        } else {
//            return
//        }
        return false
    }
    
    func checkContent() -> Bool {
        return textRow?.content != ""
    }
}


// 버튼
extension TextListDetailView {
    
    // 0-1. 저장 버튼
    func buttonSave(disable: Bool) -> some View {
        buttonLogin(title: "저장", btncolor: disable ? .gray : .teal, textColor: .white) {
            
            DispatchQueue.main.async {
                withAnimation {
                    self.isShowingContentAlert = true
                    self.isEditMode = false
                }
            }
        }
    }
    
    // 1-2. EditMode
    // 1-2-1. 취소 버튼: 0-1과 동일
    // 1-2-2. 수정저장하기 버튼
    func buttonResave(disable: Bool) -> some View {
        buttonLogin(title: "저장", btncolor: disable ? .gray : .teal, textColor: .white) {
            
            DispatchQueue.main.async {
                withAnimation {
                    self.isShowingContentAlert = true
                    self.isEditMode = false
                }
            }
        }
    }
}


#Preview {
    TextListDetailView(userData: UserData(), textRow: TextRow(order: 0, title: "가나다라", content: "마바사아 자차카"), isShowingItemView: .constant(false))
}
