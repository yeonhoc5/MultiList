//
//  ListEmptyView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/28.
//

import SwiftUI

struct ListEmptyView: View {
    var title: String
    var image: String!
    
    @Binding var checkBool: Bool
    
    var body: some View {
        ZStack {
            Rectangle()
                .opacity(0)
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    if let image = image {
                        Image(systemName: image)
                            .imageScale(.large)
                    }
                    Text(title)
                }
                .onTapGesture {
                    withAnimation {
                        self.checkBool = true
                    }
                }
                Text("여기 말구요, 아래 동그란 버튼이요.")
                    .opacity(checkBool ? 1 : 0)
                    .onChange(of: checkBool) { newValue in
                        if newValue == true {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    self.checkBool = false
                                }
                            }
                        }
                    }
            }
            .foregroundColor(.gray)
        }
    }
}

struct ListEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        ListEmptyView(title: "타이틀", image: "plus.circle.fill", checkBool: .constant(true))
    }
}
