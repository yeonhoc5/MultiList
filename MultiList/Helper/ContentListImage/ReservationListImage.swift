//
//  ReservationListImage.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/30.
//

import SwiftUI

struct ReservationListImage: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .foregroundColor(.white)
                .shadow(color: .secondary, radius: 1, x: 0, y: 0)
            VStack(spacing: 20) {
                Text("예약 리스트")
                    .foregroundColor(.black)
                    .bold()
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(1..<3) { int in
                        Text("D-\(int) [00월 00일 0요일]")
                            .foregroundStyle(Color.colorSet[0])
                            .font(.caption)
                        ForEach(0..<int) { ints in
                            HStack(alignment: .bottom) {
                                Text("\(int + ints).")
                                Text("00:00")
                                Rectangle()
                                    .frame(height: 1)
                            }
                            .padding(.leading, 10)
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
        }
    }
}

#Preview {
    ReservationListImage()
}
