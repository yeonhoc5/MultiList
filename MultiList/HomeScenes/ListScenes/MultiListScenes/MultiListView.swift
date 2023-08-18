//
//  MultiListView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/18.
//

import SwiftUI

struct MultiListView: View {
    @ObservedObject var viewModel: MultiListViewModel
    let color: Color
    
    let size: CGSize = CGSize(width: 120, height: 150)
    
    var body: some View {
        let total = 0
        let doneCount = 0
        
        return ZStack(alignment: .bottom) {
            backgroundCardView
            ZStack {
//                chartView(total: total)
                fractionalView(total: total, doneCount: doneCount)
                    .padding(.top, 40)
                    .padding(.bottom, 5)
            }
            if doneCount == total {
                completeView
            }
        }
        .frame(width: size.width, height: size.height)
        .overlay(alignment: .topLeading) {
            titleView(title: viewModel.content.title, total: total, doneCount: doneCount)
        }
    }
}

extension MultiListView {
    
    var backgroundCardView: some View {
        RoundedRectangle(cornerRadius: 5)
            .foregroundColor(color)
    }
    
    func fractionalView(total: Int, doneCount: Int) -> some View {
        VStack {
            Text("\(doneCount)")
                .offset(CGSize(width: -10, height: 15))
            Text("/")
                .rotationEffect(.radians(1/3))
                .font(.system(size: 20))
            Text("\(total)")
                .offset(CGSize(width: 10, height: -15))
        }
        .font(.system(size: 15))
        .fontWeight(.ultraLight)
    }
    
    var completeView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .foregroundColor(.white.opacity(0.7))
            VStack(spacing: 5) {
                Text("mission")
                Text("Complete!")
            }
            .foregroundColor(.black)
            .bold()
            .rotationEffect(.degrees(-20))
            .offset(CGSize(width: 0, height: 15))
        }
    }
    
    func titleView(title: String, total: Int, doneCount: Int) -> some View {
        HStack {
            Text(title)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)
                .bold()
                .foregroundColor(total == doneCount ? .black : .white)
                .padding([.leading, .top], 5)
        }
    }
}


struct MultiListView_Previews: PreviewProvider {
    static var previews: some View {
        MultiListView(viewModel: MultiListViewModel(content: sampleContent1), color: .colorSet[0])
    }
}
