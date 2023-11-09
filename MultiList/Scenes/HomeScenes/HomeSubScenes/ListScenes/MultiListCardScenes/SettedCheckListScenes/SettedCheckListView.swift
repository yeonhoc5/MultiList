//
//  SettedCheckListView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/11.
//

import SwiftUI
import PieChart

struct SettedCheckListView: View {
    @ObservedObject var userData: UserData
    @ObservedObject var checkList: CheckList
    @StateObject var viewModel: SettedCheckListViewModel
    
    let color: Color = .colorSet[0]
    let width: CGFloat
    
    init(userData: UserData, checkList: CheckList, width: CGFloat) {
        _userData = ObservedObject(wrappedValue: userData)
        _checkList = ObservedObject(wrappedValue: checkList)
        _viewModel = StateObject(wrappedValue: SettedCheckListViewModel(userData: userData,
                                                                        checkList: checkList))
        self.width = width
    }
    
    var body: some View {
        GeometryReader { proxy in
            backgroundCardView
                .overlay(alignment: .bottom) {
                    contentTypeView(proxy: proxy)
                }
                .overlay(alignment: .bottomTrailing) {
                    if viewModel.returningSharingcount() >= 2 {
                        shareMark(width: width * 0.35)
                            .offset(x: width * 0.07, y: width * 0.1)
                    }
                }
                .overlay(alignment: .topLeading) {
                    titleView(isDone: checkList.isDone, title: checkList.title,
                                  total: checkList.itemList.count,
                                  doneCount: checkList.itemList.filter({$0.isDone == true}).count)
                }
            
        }
    }
}


extension SettedCheckListView {
    // 1. 배경 카드
    var backgroundCardView: some View {
        RoundedRectangle(cornerRadius: 5)
            .foregroundColor(color)
    }
    // 2. 리스트 타입별 Preview
    @ViewBuilder
    func contentTypeView(proxy: GeometryProxy) -> some View {
        let total = checkList.itemList.count
        let doneCount = checkList.itemList.filter { $0.isDone }.count
        ZStack(alignment: .bottom) {
            ZStack(alignment: .center) {
                chartView(checkList: checkList, geo: proxy)
                    .padding(.horizontal, 5)
                fractionalView(total: total, doneCount: doneCount)
            }
            .frame(height: width)
            if total > 0 && doneCount == total{
                completeView
            }
        }
    }
    
    // 2-1. 로딩 뷰
    var loadingView: some View {
        Text("Loading...")
            .foregroundColor(.white.opacity(0.5))
            .font(.caption)
            .padding(.bottom, 10)
    }
    
    
    // 3. 타이틀뷰
    func titleView(isDone: Bool! = false, title: String, total: Int = 0, doneCount: Int = 0) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)
                .bold()
                .foregroundColor(total == doneCount || isDone ? .black.opacity(0.6) : .black)
                .padding([.leading, .top], 5)
        }
    }
    // 4. 0/0
    func fractionalView(total: Int, doneCount: Int) -> some View {
        VStack {
            Text("\(doneCount)")
                .offset(x: -6, y: 15)
            Text("/")
                .rotationEffect(.radians(1/3))
                .font(.system(size: 20))
                .offset(x: 0, y: -1)
            Text("\(total)")
                .offset(x: 6, y: -15)
        }
        .foregroundColor(.white)
        .font(.caption)
        .fontWeight(.ultraLight)
    }
//     5. 차트뷰
    @ViewBuilder
    func chartView(checkList: CheckList, geo: GeometryProxy) -> some View {
        let ratioSpace = 0.5 * (1 - (Double(checkList.itemList.count) * 0.05))
        let config = PieChart.Configuration(space: checkList.itemList.count == 0 ? 0 :
                                                max(0.0, ratioSpace),
                                            hole: 0.5,
                                            pieSizeRatio: 0.9)
        PieChart(values: Array(repeating: 1, count: checkList.itemList.count == 0 ? 1 : checkList.itemList.count),
                 colors: checkList.itemList.count == 0 ? [.white.opacity(0.4)] : checkList.itemList.map { $0.isDone ? .yellow : .white },
                 backgroundColor: color, configuration: config)
        .frame(height: geo.size.width)
    }
    // 6. 완료뷰
    var completeView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .foregroundColor(.white.opacity(0.7))
            Text("Complete!")
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            .foregroundColor(.black)
            .bold()
            .rotationEffect(.degrees(-20))
            .offset(CGSize(width: 0, height: 8))
        }
    }
}

struct SettedCheckListView_Previews: PreviewProvider {
    static var previews: some View {
        SettedCheckListView(userData: UserData(),
                            checkList: sampleCheckList,
                            width: min(screenSize.width, screenSize.height) / 5)
    }
}
