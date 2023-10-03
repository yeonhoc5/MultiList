//
//  CheckListImge.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/22.
//

import SwiftUI

struct CheckListImge: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .foregroundColor(.white)
                .shadow(color: .secondary, radius: 1, x: 0, y: 0)
            VStack(spacing: 20) {
                Text("체크 리스트")
                    .foregroundColor(.black)
                    .bold()
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(0..<2) { int in
                        HStack(alignment: .bottom) {
                            Image(systemName: "checkmark.circle.fill")
                            Rectangle()
                                .frame(height: 1)
                        }
                        
                    }
                    ForEach(0..<2) { int in
                        HStack(alignment: .bottom) {
                            Image(systemName: "circle")
                            Rectangle()
                                .frame(height: 1)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct CheckListImge_Previews: PreviewProvider {
    static var previews: some View {
        CheckListImge()
    }
}
