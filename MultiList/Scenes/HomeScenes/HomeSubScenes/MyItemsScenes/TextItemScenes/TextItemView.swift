//
//  TextItemView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/26.
//

import SwiftUI

struct TextItemView: View {
    @ObservedObject var userData: UserData
    @StateObject var viewModel: TextItemViewModel
    @State var myItem: MyItemModel!
    
    @Binding var isEditMode: Bool
    
    @FocusState var isFocused
    @State var isShowingProgressView: Bool = false
    
    // myItem 공통
    @Binding var itemNumber: Int
    // type 0. 텍스트
    @Binding var itemText: String
    @Binding var isShowingItemView: Bool
    
    init(userData: UserData, isShowingItemView: Binding<Bool>, itemNumber: Binding<Int>, itemText: Binding<String>, isEditMode: Binding<Bool>, myItem: MyItemModel?) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: TextItemViewModel(userData: userData))
        _itemNumber = itemNumber
        _itemText = itemText
        _isShowingItemView = isShowingItemView
        _isEditMode = isEditMode
        self.myItem = myItem
    }
    
    var body: some View {
        Group {
            if #available(iOS 17, *) {
                textEditView
                    .onChange(of: isEditMode) { _, newValue in
                        self.isFocused = newValue
                    }
            } else {
                textEditView
                    .onChange(of: isEditMode, perform: { value in
                        self.isFocused = value
                    })
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    var textEditView: some View {
        TextEditor(text: self.isEditMode ? $itemText : .constant(myItem?.itemText ?? itemText))
            .foregroundStyle(isEditMode ? Color.black : Color.primary)
            .focused($isFocused)
            .scrollContentBackground(.hidden)
            .padding(10)
            .background(content: {
                isEditMode ? Color.white : Color.primaryInverted
            })
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .shadow(color: .black, radius: 1, x: 0, y: 0)
            .onAppear(perform: {
                self.isFocused = userData.myItems[itemNumber] == nil
            })
            .background {
                if !isEditMode {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(lineWidth: 0.4)
                        .foregroundStyle(Color.primary)
                }
            }
            
    }
    
}



//#Preview {
//    TextItemView(userData: UserData(), isShowingItemView: .constant(true), itemNumber: .constant(1), itemText: .constant(""), isEditMode: .constant(false), myItem: .constant(MyItemModel(title: "", order: 0, type: .text)))
//}
