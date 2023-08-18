//
//  ListView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/16.
//

import SwiftUI

struct ListView: View {
    @StateObject var viewModel: ListViewModel
    // sectionList 프라퍼티
    @State var isAdding: Bool = false
    @FocusState var isFocused: Bool
    @State var sectionToAdd = ""
    @State var placeHolder = "추가할 섹션명을 입력해주세요."
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.primaryInverted)
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(viewModel.sectionList, id: \.sectionID) { section in
                        eachSectionView(section: section)
                    }
                }
                .padding(.top, 10)
            }
        }
        .simultaneousGesture(turnOffAddSectionGesture(isAdding: isAdding))
        .overlay(alignment: .bottomLeading) {
            addSectionButton(width: screenSize.width)
                .padding(.leading, 10)
                .padding(.bottom, 20)
        }
    }
}

// MARK: - [extension 1] SubViews
extension ListView {
    
    func eachSectionView(section: SectionList) -> some View {
        VStack(spacing: 10) {
            sectionView(section: section)
                .animation(.easeInOut, value: section.order)
                .padding(.horizontal, 10)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(section.multiList, id: \.multiID) { multiList in
                        let multiListViewModel = MultiListViewModel(content: sampleContent1)
                        MultiListView(viewModel: multiListViewModel, color: .colorSet[section.color])
                    }
                    .padding(.leading, 25)
                }
            }
        }
    }
    
    
    func sectionView(section: SectionList) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "triangle.fill")
                .rotationEffect(.degrees(90))
                .imageScale(.small)
            HStack(spacing: 20) {
                Text(section.sectionName)
                    .frame(height: 20)
                Spacer()
                buttonImage(image: "plus.circle.fill", colorNum: section.color) {
                    // 섹션에 멀티리스트 추가
                }
                buttonImage(image: "tray.full.fill", colorNum: section.color) {
                    // 섹션 보관함으로 이동
                }
                buttonImage(image: "gear", colorNum: section.color) {
                    // 섹션 설정
                }
            }
        }
    }
    
    func addSectionButton(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white)
            .shadow(color: .secondary, radius: 3, x: 0, y: 0)
            .overlay {
                HStack {
                    if isAdding {
                        TextField("", text: $sectionToAdd, axis: .horizontal)
                            .placeholder(when: sectionToAdd.isEmpty, alignment: .leading, placeholder: {
                                Text(placeHolder)
                                    .foregroundColor(.gray)
                            })
                            .foregroundColor(.black)
                            .focused($isFocused)
                    }
                    
                    Button {
                        if !isAdding {
                            turnOnAddSection()
                        } else {
                            if sectionToAdd == "" {
                                turnOffAddSection()
                            } else {
                                DispatchQueue.main.async {
                                    withAnimation {
                                        addNewSection(title: sectionToAdd)
                                    }
                                }
                            }
                        }
                    } label: {
                        ZStack {
                        Circle()
                            .fill(!isAdding ? .white : (sectionToAdd == "" ? Color.gray : Color.teal))
                            .frame(width: 30, height: 30)
                        Image(systemName: "plus")
                            .resizable()
                            .foregroundColor(isAdding ? .white : .teal)
                            .frame(width: 20, height: 20)
                            .rotationEffect(isAdding && sectionToAdd == "" ? .degrees(45) : .zero)
                        }
                    }
                    .buttonStyle(ScaleEffect(scale: 0.9))

                }
                .padding(.leading, 20)
                .padding(.trailing, isAdding ? 10 : 20)
            }
            .frame(height: 40)
            .frame(maxWidth: isAdding ? .infinity : 40)
            .padding(.bottom, isAdding ? 10 : 0)
    }
    
    
    func addNewSection(title: String) {
        let order = viewModel.sectionList.count
        let newSection = SectionList(order: order, sectionName: title, color: order)
        viewModel.addSectionToUser(section: newSection)
        turnOffAddSection()
    }
    
    func turnOnAddSection() {
        withAnimation(.easeInOut(duration: 0.45)) {
            self.isAdding = true
            self.placeHolder = "추가할 섹션명을 입력해주세요."
            self.isFocused = true
        }
    }
    
    func turnOffAddSection() {
        self.placeHolder = ""
        self.sectionToAdd = ""
        withAnimation(.easeInOut(duration: 0.45)) {
            self.isFocused = false
            self.isAdding = false
        }
    }
    
    func turnOnAddSectionGesture(isAdding: Bool) -> some Gesture {
        TapGesture()
            .onEnded { _ in
                if isAdding == false {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        self.isAdding = true
                        self.placeHolder = "추가할 섹션명을 입력해주세요."
                        self.isFocused = true
                    }
                }
            }
    }
    
    func turnOffAddSectionGesture(isAdding: Bool) -> some Gesture {
        TapGesture()
            .onEnded { _ in
                if isAdding {
                    self.placeHolder = ""
                    self.sectionToAdd = ""
                    withAnimation {
                        self.isAdding = false
                        self.isFocused = false
                    }
                }
            }
    }
    
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(viewModel: ListViewModel(user: sampleUser))
    }
}
