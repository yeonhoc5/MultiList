//
//  CustomAlertView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/30.
//

import SwiftUI

struct CustomAlertView: View {
    @Binding var isShowingAlert: Bool
    var title: String = "리스트 아이템을 수정합니다."
    var placeHolder: String = "이름을 입력해주세요."
    @Binding var text: String
    @Binding var textEditor: String
    let action: () -> Void
    
    var body: some View {
            VStack {
                Text(title)
                    .font(.title2)
                    .padding(.bottom, 10)
                HStack {
                    Text("이름")
                        .frame(width: 40)
                    ZStack {
                        RoundedRectangle(cornerRadius: 5).fill(Color.white)
                        TextField(text.count == 0 ? placeHolder : text, text: $text)
                            .padding(.horizontal, 5)
                    }
                }
                .frame(height: 40)
                HStack(alignment: .top) {
                    Text("URL")
                        .frame(width: 40)
                    TextEditor(text: $textEditor)
                        .frame(height: 100)
                        .cornerRadius(5)
                }
                .padding(.bottom, 10)
                
                HStack {
                    buttonLogin(title: "취소", btncolor: .teal, textColor: .black) {
                        text = ""
                        textEditor = ""
                        self.isShowingAlert = false
                    }
                    buttonLogin(title: "확인", btncolor: .teal, textColor: .black) {
                        action()
                        self.isShowingAlert = false
                    }
                }
                .frame(height: 40)
            }
            .padding(20)
            .frame(width: 300)
            .background {
                BlurView(style: .prominent)
                    .blur(radius: 4)
                BlurView(style: .prominent)
            }
            .cornerRadius(20)
        
    }
}

struct CustomAlertView_Previews: PreviewProvider {
    static var previews: some View {
        CustomAlertView(isShowingAlert: .constant(false), title: "아이템 정보를 수정합니다.", placeHolder: "", text: .constant("구글"), textEditor: .constant("https://google.com")) {
            
        }
    }
}
