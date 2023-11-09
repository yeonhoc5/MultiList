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
    @State var sharedPeople: [Person] = []
    
    init(userData: UserData, sectionUID: UUID, multiList: MultiList) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: DetailMultiListViewModel(userData: userData,
                                                                        sectionUID: sectionUID,
                                                                        multiList: multiList))
    }
    
    var body: some View {
        Group {
            switch viewModel.multiList.isSettingDone {
            case false:
                // 1. 컨텐츠 세팅하기 뷰
                settingContentView
                    .navigationTitle("리스트 Setting")
            case true:
                // 2. 세팅한 뷰
                settedContentView(multiList: viewModel.multiList, 
                                  isShowingTitleAlert: $isShowingAlert)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(Color.primaryInverted, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            HStack {
                                if sharedPeople.count > 0 {
                                    buttonSharePeople
                                }
                                buttonEdit
                            }
                        }
                    }
            default: EmptyView()
            }
        }
        .alert("타이틀을 수정합니다.", isPresented: $isShowingAlert) {
            // 3. 타이틀 수정 알럿 뷰
            titleModifyAlertView
        }
    }
}

// MARK: - Main Sub Views
extension DetailMultiListView {
    // 1. 컨텐츠 세팅하기 뷰
    var settingContentView: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color(uiColor: UIColor.systemGray6))
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.selectedType = nil
                    }
                }
                VStack {
                    OStack(spacing: 0) {
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
                        .frame(height: max(screenSize.width, screenSize.height) * 0.25)
                        .clipped()
                        .shadow(color: .primary, radius: 2, x: 1, y: 1)
                    }
                    buttonLogin(title: selectedType == nil ? "세팅할 리스트를 선택해주세요." : (selectedType == .reservationList ? "준비 중입니다." : "세팅하기"),
                                btncolor: selectedType == nil ? .gray : (selectedType == .reservationList ? .gray : .teal)) {
                        withAnimation {
                            guard let type = selectedType else { return }
                            viewModel.settingContent(type: type)
                        }
                    }
                    .disabled(selectedType == nil || selectedType == .reservationList)
                    .frame(height: 40)
                    .padding(12)

            }
            .padding(.vertical, screenSize.width < screenSize.height ? 80 : 10)
            .padding(.horizontal, 40)
        }
    }
    // 2. 세팅한 뷰
    @ViewBuilder
    func settedContentView(multiList: MultiList, isShowingTitleAlert: Binding<Bool>) -> some View {
        if multiList.listType == .textList {
            if let content = userData.textList.first(where: {$0.id == multiList.multiID}) {
                TextListView(userData: userData,
                              content: content,
                              editMode: $editMode,
                              isShowingTitleAlert: $isShowingAlert,
                              newTitle: $newString)
                    .onAppear {
                        viewModel.contentTitle = content.title
                        self.sharedPeople = content.sharedPeople.filter({$0.id != self.userData.user.userUID})
                    }
            }
        } else if multiList.listType == .checkList {
            if let content = userData.checkList.first(where: {$0.id == multiList.multiID}) {
                CheckListView(userData: userData,
                              content: content,
                              editMode: $editMode,
                              isShowingTitleAlert: $isShowingAlert,
                              newTitle: $newString)
                    .onAppear {
                        viewModel.contentTitle = content.title
                        self.sharedPeople = content.sharedPeople.filter({$0.id != self.userData.user.userUID})
                    }
            }
        } else if multiList.listType == .linkList {
            if let content = userData.linkList.first(where: {$0.id == multiList.multiID}) {
                LinkListView(userData: userData,
                             content: content,
                             editMode: $editMode,
                             isShowingTitleAlert: $isShowingAlert,
                             newTitle: $newString)
                    .onAppear {
                        viewModel.contentTitle = content.title
                        self.sharedPeople = content.sharedPeople.filter({$0.id != self.userData.user.userUID})
                    }
            }
        } else {
            Rectangle()
                .foregroundColor(.green)
        }
    }
    
    // 3. 타이틀 수정 알럿 뷰
    var titleModifyAlertView: some View {
        Group {
            TextField(newString, text: $newString)
                .submitLabel(.done)
                .onSubmit {
                    withAnimation {
                        viewModel.modifyTitle(new: newString)
                    }
                    isShowingAlert = false
                }
            Button("취소") {
                self.isShowingAlert = false
            }
            Button("수정하기") {
                withAnimation {
                    viewModel.modifyTitle(new: newString)
                    self.editMode = .inactive
                }
                isShowingAlert = false
            }
        }
    }
}

// MARK: - sub Views
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
            withAnimation {
                editMode = editMode == .inactive ? .active : .inactive
            }
        } label: {
            Text(self.editMode == .active ? "Done" : "Edit")
                .frame(width: 45)
        }
    }
    
    // toolbar 아이템 2
    var buttonSharePeople: some View {
        NavigationLink {
            SharedPeopleListView(userData: self.userData, sharedPeople: self.sharedPeople, title: viewModel.contentTitle)
        } label: {
            ZStack {
                Image(systemName: "person.2.fill")
                    .frame(width: 45)
                Text("\(sharedPeople.count)")
                    .fontDesign(.rounded)
                    .bold()
                    .offset(x: 20)
            }
        }
    }
}

struct DetailMultiListView_Previews: PreviewProvider {
    static var previews: some View {
        DetailMultiListView(userData: UserData(),
                            sectionUID: UUID(),
                            multiList: sampleMultiList1)
    }
}
