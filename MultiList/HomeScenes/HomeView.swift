//
//  HomeView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/07.
//

import SwiftUI
import FirebaseRemoteConfig

struct HomeView: View {
    @StateObject var homeViewModel = HomeViewModel()
    
    // sectionList 프라퍼티
    @State var sectionToAdd = ""
    @State var isAdding: Bool = false
    @FocusState var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Rectangle()
                    .foregroundColor(.primaryInverted)
                VStack {
                    LoginView(isShowingProgressView: $homeViewModel.isShowingProgressView,
                              isLoggedin: $homeViewModel.isLoggedIn)
                    .padding(10)
                    .alert(homeViewModel.title,
                           isPresented: $homeViewModel.isShowingAlert) {
                    } message: {
                        Text(homeViewModel.message)
                    }
                }
            }
            .onTapGesture {
                turnOffAddSection()
            }
            .overlay(alignment: .bottomLeading) {
                addSectionButton
            }
            .overlay(content: {
                if homeViewModel.isShowingProgressView {
                    loginProgressView
                }
            })
            .navigationTitle("Multi List")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    let userSettingViewModel = UserSettingViewModel(user: homeViewModel.user ?? sampleUser)
                    userSettingView(viewModel: userSettingViewModel)
                }
            }
        }
    }
    
}


// MARK: - [extension 1] SubViews
extension HomeView {
    
    var addSectionButton: some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .frame(width: isAdding ? screenSize.width - 60 : 50, height: 50)
                .shadow(color: .primary.opacity(0.6), radius: 3, x: 0, y: 0)
                .onTapGesture {
                    if !isAdding {
                        withAnimation(.easeInOut(duration: 0.45)) {
                            isAdding = true
                            isFocused = true
                        }
                    }
                }
            HStack {
                if isAdding {
                    TextField("", text: $sectionToAdd, axis: .horizontal)
                        .placeholder(when: sectionToAdd.isEmpty, alignment: .leading, placeholder: {
                            Text("추가할 섹션명을 입력해주세요.")
                                .foregroundColor(.teal)
                        })
                        .foregroundColor(.primaryInverted)
                        .focused($isFocused)
                }
                Image(systemName: "plus")
                    .resizable()
                    .foregroundColor(isAdding ? .blue : .gray)
                    .frame(width: 20, height: 20)
            }
            .padding(.horizontal, 20)
        }
        .padding(.leading, 10)
        .padding(.bottom, isAdding ? 20 : 0)
        .frame(width: isAdding ? screenSize.width - 20 : 50, height: 50)
    }
    
    func userSettingView(viewModel: UserSettingViewModel) -> some View {
        NavigationLink {
            UserSettingView(viewModel: viewModel)
        } label: {
            Image(systemName: "person.crop.circle")
                .tint(homeViewModel.user == nil ? .gray : .teal)
        }
    }
    
    var loginProgressView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 100, height: 100)
            ProgressView()
                .tint(.black)
                .progressViewStyle(.circular)
        }
    }
    
}

// MARK: - [extension 2] functions
extension HomeView {
    func turnOffAddSection() {
        if isAdding {
            withAnimation {
                isAdding = false
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
