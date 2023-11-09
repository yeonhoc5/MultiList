//
//  SectionStorageView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/04.
//

import SwiftUI

struct SectionStorageView: View {
    @ObservedObject var userData: UserData
    @StateObject var viewModel: SectionStorageViewModel
    let color: Color
    @State var selectedFilter: MultiListType = .none
    @Namespace var animationoID
    
    
    // 멀티리스트 타이틀 수정
    @State var isShowingTitleAlert: Bool = false
    @State var editMultiList: MultiList!
    @State var newString: String = ""
    @State var placeholder: String = ""
    // 공유
    @State var isShowingSendShareSheet: Bool = false
    @State var multiListToShare: MultiList!
    @State var shareColor: Color!
    
    init(userData: UserData, section: SectionList, color: Color) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: SectionStorageViewModel(userData: userData, section: section))
        self.color = color
    }
    
    var body: some View {
        GeometryReader { geoProxy in
            let isVertical = screenSize.width < screenSize.height
            OStack(spacing: 0) {
            // 1. 필터링 버튼 스택 뷰
                sectionButtonStackView()
                    .frame(maxHeight: isVertical ? 50 : .infinity)
            // 2. 멀티리스트 뷰
                filteredMultiListView(filter: selectedFilter, isVertical: isVertical)
                    .frame(minWidth: geoProxy.size.width * 0.8)
                    .padding([.horizontal, .top], 10)
            }
        }
        .navigationTitle("보관함 : \(viewModel.section.sectionName)")
        .alert("타이틀을 수정합니다.", isPresented: $isShowingTitleAlert) {
            // 3. 멀티리스트 타이틀 수정 알럿뷰
            titleModifyAlertView
        }
        .fullScreenCover(isPresented: $isShowingSendShareSheet) {
            // 4. 멀티리스트 공유 뷰
            SendShareView(userData: userData,
                          multiList: $multiListToShare,
                          isShowingSheet: $isShowingSendShareSheet,
                          color: shareColor ?? .teal)
        }
    }
}

// MARK: - sub views
extension SectionStorageView {
    // 1. 필터링 버튼 스택 뷰
    @ViewBuilder
    func sectionButtonStackView() -> some View {
        let isVertical = screenSize.width < screenSize.height
        ScrollView(isVertical ? .horizontal : .vertical) {
            OStack(spacing: 10, isVerticalFirst: false) {
                let height = 30.0
                ForEach(MultiListType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0.3)) {
                            selectedFilter = type
                        }
                    } label: {
                        Text("\(type.rawValue) (\(viewModel.filteredSection(filter: type).count))")
                            .font(Font.system(.callout, design: .rounded, weight: .regular))
                            .foregroundColor(selectedFilter == type ? .white : .black)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 15)
                            .frame(height: height)
                            .background {
                                RoundedRectangle(cornerRadius: height / 2)
                                    .foregroundColor(selectedFilter == type ? .teal : .white)
                                    .shadow(color: .black, radius: 1, x: 0, y: 0)
                            }
                    }
                    .buttonStyle(ScaleEffect())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 20)
        }
    }
    
    // 2. 멀티리스트 뷰
    @ViewBuilder
    func filteredMultiListView(filter: MultiListType, isVertical: Bool) -> some View {
        let row = Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .bottom),
                        count: Int(((screenSize.width * (isVertical ? 1 : 0.8)) - 10) / 110))
        ScrollView {
            LazyVGrid(columns: row, spacing: 10, content: {
                ForEach(viewModel.filteredSection(filter: filter), id: \.self) { item in
                        multiListNavigationView(multiList: item, 
                                                section: viewModel.section)
                        .animation(.easeInOut, value: item.isHidden)
                        .overlay(alignment: .bottomLeading) {
                            Text("\(item.order)")
                                .foregroundStyle(Color.yellow)
                        }
                }
            })
            .padding(10)
        }
        .background(content: {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .black, radius: 1, x: 0, y: 0)
        })
    }
    
    // 3. 멀티리스트 타이틀 수정 알럿 뷰
    var titleModifyAlertView: some View {
        Group {
            TextField(placeholder, text: $newString)
                .submitLabel(.done)
                .onSubmit {
                    guard let multi = editMultiList else { return }
                    viewModel.modifyTitle(new: newString,
                                          multiList: multi,
                                          oriTitle: placeholder)
                    isShowingTitleAlert = false
                }
            Button("취소") {
                self.isShowingTitleAlert = false
            }
            Button("수정하기") {
                guard let multi = editMultiList else { return }
                viewModel.modifyTitle(new: newString,
                                      multiList: multi,
                                      oriTitle: placeholder)
                isShowingTitleAlert = false
            }
        }
    }
}
 
extension SectionStorageView {
    // 2-1. 멀티리스트 티테일 뷰 네비게이션링크 View
    func multiListNavigationView(multiList: MultiList, section: SectionList) -> some View {
        return NavigationLink {
            DetailMultiListView(userData: self.userData, sectionUID: section.sectionID, multiList: multiList)
        } label: {
//            let width = viewModel.width / 5 > 100 ? 100 : viewModel.width / 5
            let width = 100.0
            Group {
                if !multiList.isSettingDone {
                    NotSettedView(userData: self.userData, multiList: multiList)
                } else if multiList.listType == .textList {
                    var content = userData.textList.first(where: {$0.id == multiList.multiID})
                    if let content = content {
                        SettedTextListView(userData: self.userData,
                                            textList: content,
                                            width: width)
                    } else {
                        loadingView(color: color, onAppear: {
                            content = userData.textList.first(where: {$0.id == multiList.multiID})
                        })
                    }
                } else if multiList.listType == .checkList {
                    var content = userData.checkList.first(where: {$0.id == multiList.multiID})
                    if let content = content {
                        SettedCheckListView(userData: self.userData,
                                            checkList: content,
                                            width: width)
                    } else {
                        loadingView(color: color, onAppear: {
                            content = userData.checkList.first(where: {$0.id == multiList.multiID})
                        })
                    }
                } else if multiList.listType == .linkList {
                    var content = userData.linkList.first(where: {$0.id == multiList.multiID})
                    if let content = content {
                        SettedLinkListView(userData: self.userData,
                                            linkList: content,
                                            width: width)
                    } else {
                        loadingView(color: color, onAppear: {
                            content = userData.linkList.first(where: {$0.id == multiList.multiID})
                        })
                    }
                }
            }
            .animation(.easeInOut, value: multiList.isSettingDone)
            .frame(width: width , height: width * 1.2)
            .contextMenu {
                contextMenuOnMultiList(section: section, multi: multiList)
            }
        }
        .buttonStyle(ScaleEffect())
    }
    
    func contextMenuOnMultiList(section: SectionList, multi: MultiList) -> some View {
        VStack {
            contextMenuItem(title: "이름 수정하기", image: "pencil") {
                if multi.listType == .checkList {
                    self.placeholder = userData.checkList.first(where: {$0.id == multi.multiID})?.title ?? ""
                } else if multi.listType == .linkList {
                    self.placeholder = userData.linkList.first(where: {$0.id == multi.multiID})?.title ?? ""
                }
                editMultiList = multi
                isShowingTitleAlert = true
            }
//                contextMenuItem(title: "복제하기", image: "doc.on.doc") {
//
//                }
            contextMenuItem(title: "공유하기", image: "square.and.arrow.up") {
                self.multiListToShare = multi
                self.shareColor = .colorSet[section.color % Color.colorSet.count]
                self.isShowingSendShareSheet = true
            }
            .disabled(userData.user?.accountType == .anonymousUser)
            Divider()
            contextMenuItem(title: "섹션으로 보내기", image: "tray.and.arrow.up.fill") {
                withAnimation {
                    viewModel.hiddenAtSectionStorage(sectionIndex: section.order, multiList: multi)
                }
            }
            Divider()
            contextMenuItem(title: "삭제하기", image: "trash", role: .destructive) {
                withAnimation {
                    viewModel.deleteMultiList(section: section, multi: multi)
                }
            }
        }
    }
}

struct SectionStorageViewswift_Previews: PreviewProvider {
    static var previews: some View {
        SectionStorageView(userData: UserData(), section: sampleList.first!, color: .teal)
    }
}
