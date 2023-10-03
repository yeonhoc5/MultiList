//
//  DetailMultiListView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/21.
//

import SwiftUI

struct DetailMultiListView: View {
    @StateObject var viewModel: DetailMultiListViewModel
    @ObservedObject var userData: UserData
    
    @State var selectedType: MultiListType!
    @State var editMode: EditMode = .inactive
    @State var isShowingAlert: Bool = false
    @State var newString: String = ""
    @State var shareIndex: [Int] = []
    
    init(userData: UserData, sectionUID: UUID, multiList: MultiList) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: DetailMultiListViewModel(userData: userData, sectionUID: sectionUID, multiList: multiList))
    }
    
    var body: some View {
        if !viewModel.multiList.isSettingDone {
            settingContentView
                .navigationTitle("리스트 Setting")
        } else {
            settedContentView(multiList: viewModel.multiList, isShowingTitleAlert: $isShowingAlert)
                .navigationTitle(viewModel.contentTitle)
                .toolbarBackground(Color.primaryInverted, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            if shareIndex.count > 0 {
                                buttonSharePeople
                            }
//                            buttonTitle
                            buttonEdit
                            
                        }
                    }
                }
                .alert("타이틀을 수정합니다.", isPresented: $isShowingAlert) {
                    TextField(newString, text: $newString)
                        .submitLabel(.done)
                        .onSubmit {
                            viewModel.modifyTitle(new: newString)
                            isShowingAlert = false
                        }
                    Button("취소") {
                        self.isShowingAlert = false
                    }
                    Button("수정하기") {
                        viewModel.modifyTitle(new: newString)
                        isShowingAlert = false
                        self.editMode = .inactive
                    }
                }
        }
    }
    
    // toolbar 아이템 1
    var buttonTitle: some View {
        Button {
            newString = viewModel.contentTitle
            isShowingAlert = true
        } label: {
            Text("Title")
        }
    }
    // toolbar 아이템 2
    var buttonEdit: some View {
        Button {
            if self.editMode == .inactive {
                withAnimation {
                    self.editMode = .active
                }
            } else {
                withAnimation {
                    self.editMode = .inactive
                }
            }
        } label: {
            Text(self.editMode == .active ? "Done" : "Edit")
                .frame(width: 45)
        }
    }
    
    // toolbar 아이템 2
    var buttonSharePeople: some View {
        NavigationLink {
            SharedPeopleListView(userData: self.userData, sharedPeople: self.shareIndex)
        } label: {
            ZStack {
                Image(systemName: "person.2.fill")
                    .frame(width: 45)
                Text("\(shareIndex.count)")
                    .fontDesign(.rounded)
                    .bold()
                    .offset(x: 20)
                
            }
        }
    }
}

extension DetailMultiListView {
    var settingContentView: some View {
        ZStack {
            Rectangle().foregroundColor(Color(uiColor: UIColor.systemGray6))
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.selectedType = nil
                    }
                }
            VStack(spacing: 0) {
                Group {
                    HStack(spacing: 0) {
                        textListView
                        checkListView
                    }
                    HStack(spacing: 0) {
                        linkListView
                        reservationListView
                    }
                }
                .frame(height: screenSize.width * 0.5)
                .clipped()
                .shadow(color: .primary, radius: 2, x: 1, y: 1)
                buttonLogin(title: selectedType == nil ? "세팅할 리스트를 선택해주세요." : (selectedType == .reservationList ? "준비 중입니다." : "세팅하기"),
                            btncolor: selectedType == nil ? .gray : (selectedType == .reservationList ? .gray : .teal)) {
                    withAnimation {
                        guard let type = selectedType else { return }
                        viewModel.settingContent(type: type)
                    }
                }
                .disabled(selectedType == nil || selectedType == .reservationList)
                .frame(height: 40)
                .padding(.top, screenSize.width < screenSize.height ? 40 : 10)
            }
            .padding(.vertical, screenSize.width < screenSize.height ? 80 : 10)
            .padding(.horizontal, 40)
        }
    }
    
    @ViewBuilder
    func settedContentView(multiList: MultiList, isShowingTitleAlert: Binding<Bool>) -> some View {
        if multiList.listType == .textList {
            if let content = userData.textList.first(where: {$0.id == multiList.multiID}) {
                TextListView(userData: userData,
                              content: content,
                              editMode: $editMode,
                              shareIndex: $shareIndex,
                              isShowingTitleAlert: $isShowingAlert,
                              newTitle: $newString)
                    .onAppear {
                        viewModel.contentTitle = content.title
                    }
            }
        } else if multiList.listType == .checkList {
            if let content = userData.checkList.first(where: {$0.id == multiList.multiID}) {
                CheckListView(userData: userData,
                              content: content,
                              editMode: $editMode,
                              shareIndex: $shareIndex,
                              isShowingTitleAlert: $isShowingAlert,
                              newTitle: $newString)
                    .onAppear {
                        viewModel.contentTitle = content.title
                    }
            }
        } else if multiList.listType == .linkList {
            if let content = userData.linkList.first(where: {$0.id == multiList.multiID}) {
                LinkListView(userData: userData,
                             content: content,
                             editMode: $editMode,
                             shareIndex: $shareIndex,
                             isShowingTitleAlert: $isShowingAlert)
                    .onAppear {
                        viewModel.contentTitle = content.title
                    }
            }
        } else {
            Rectangle()
                .foregroundColor(.green)
        }
    }
}


extension DetailMultiListView {
    var textListView: some View {
        buttonCardView(label: TextListImage(), id: .textList, selectedType: selectedType) {
            withAnimation(.easeInOut(duration: 0.1)) {
                selectedType = selectedType == .textList ? nil : .textList
            }
        }
    }
    var checkListView: some View {
        buttonCardView(label: CheckListImge(), id: .checkList, selectedType: selectedType) {
            withAnimation(.easeInOut(duration: 0.1)) {
                selectedType = selectedType == .checkList ? nil : .checkList
            }
        }
    }
    var linkListView: some View {
        buttonCardView(label: LinkListImage(), id: .linkList, selectedType: selectedType) {
            withAnimation(.easeInOut(duration: 0.1)) {
                selectedType = selectedType == .linkList ? nil : .linkList
            }
        }
    }
    var reservationListView: some View {
        buttonCardView(label: ReservationListImage(), id: .reservationList, selectedType: selectedType) {
            withAnimation(.easeInOut(duration: 0.1)) {
                selectedType = selectedType == .reservationList ? nil : .reservationList
            }
        }
    }
}

//struct DetailMultiListView_Previews: PreviewProvider {
//    static var previews: some View {
//        DetailMultiListView(viewModel: DetailMultiListViewModel(multiList: sampleCheckList))
//    }
//}
