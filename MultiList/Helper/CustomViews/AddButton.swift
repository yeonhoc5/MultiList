//
//  AddButton.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/22.
//

import SwiftUI

struct AddButton: View {
    let width: CGFloat
    var placeHolder: String = ""
    @Binding var isPresented: Bool
    @Binding var string: String
    @FocusState.Binding var isFocused: Bool
    @State var tempPlaceHolder: String = ""
    let action: () -> Void
    
    @State var isEmpty: Bool = true
    
    
    public init(width: CGFloat,
                placeHolder: String,
                isPresented: Binding<Bool>,
                string: Binding<String>,
                isFocused: FocusState<Bool>.Binding,
                action: @escaping () -> Void) {
        self.width = width
        self.placeHolder = placeHolder
        self._isPresented = isPresented
        self._string = string
        self._isFocused = isFocused
        self.action = action
    }
    
    var body: some View {
//        ZStack {
//            // 그림자뷰
//            RoundedRectangle(cornerRadius: 20)
//                .fill(Color.primary.opacity(0.5))
//                .blur(radius: 4)
            // 뷰
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .overlay {
                    HStack {
                        if isPresented {
                            TextField("", text: $string, axis: .horizontal)
                                .placeholder(when: string.isEmpty, alignment: .leading, placeholder: {
                                    Text(tempPlaceHolder)
                                        .foregroundColor(.gray)
                                })
                                .foregroundColor(.black)
                                .focused($isFocused)
                                .submitLabel(.done)
                                .onSubmit {
                                    if string.trimmingCharacters(in: .whitespaces).count != 0 {
                                        withAnimation { self.action() }
                                    }
                                    self.turnOffAddField()
                                }
                                .onChange(of: string.count) { [oldValue = string.count] newValue in
                                    if newValue == 0 || newValue > oldValue {
                                        rotateButtonImage(stringCount: newValue)
                                    }
                                }
                        }
                        Button {
                            if !isPresented {
                                self.turnOnAddField()
                            } else {
                                if string.trimmingCharacters(in: .whitespaces).count != 0 {
                                    withAnimation { self.action() }
                                }
                                self.turnOffAddField()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(!isPresented ? .white : (isEmpty ? Color.gray : Color.teal))
                                Image(systemName: "plus")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(isPresented ? .white : .teal)
                                    .rotationEffect(isPresented && isEmpty ? .degrees(45) : .zero)
                            }
                        }
                        .buttonStyle(ScaleEffect(scale: 0.9))
                        .padding(.vertical, 5)
                        
                    }
                    .padding(.leading, 20)
                    .padding(.trailing, isPresented ? 5 : 20)
                }
//        }
        .frame(height: 40)
        .frame(maxWidth: isPresented ? .infinity : 40)
        .clipped()
        .shadow(color: .black.opacity(0.6), radius: 3.5, x: 0, y: 0)
        .padding(.bottom, isPresented ? 10 : 0)
    }
}

extension AddButton {
    
    func turnOnAddField() {
        withAnimation(.easeInOut(duration: 0.45)) {
            self.isPresented = true
            self.tempPlaceHolder = placeHolder
            self.isFocused = true
        }
    }
    
    func turnOffAddField() {
        self.tempPlaceHolder = ""
        self.string = ""
        withAnimation(.easeInOut(duration: 0.45)) {
            self.isFocused = false
            self.isPresented = false
        }
    }
    
    func rotateButtonImage(stringCount: Int) {
        if stringCount == 0 {
            withAnimation(.easeOut(duration: 0.2)) {
                isEmpty = true
            }
        } else {
            if isEmpty == true {
                withAnimation(.easeOut(duration: 0.2)) {
                    isEmpty = false
                }
            }
        }
    }
}

struct AddButton_Previews: PreviewProvider {
    static var previews: some View {
        AddButton(width: 100,
                  placeHolder: "추가할 리스트",
                  isPresented: .constant(true),
                  string: .constant("스트링"),
                  isFocused: FocusState<Bool>().projectedValue) {
            
        }
    }
}
