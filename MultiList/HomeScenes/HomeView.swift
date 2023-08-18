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
    
    @State var isShowingProgressview: Bool = false

    @Namespace var homeView
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Rectangle()
                    .foregroundColor(.primaryInverted)
                OStack(alignment: .center, spacing: 0) {
//                    let loginViewModel = LoginViewModel()
                    LoginView(isShowingProgressView: $isShowingProgressview,
                              nameSpace: homeView)
                        .matchedGeometryEffect(id: "loginView", in: homeView)
                        .frame(maxWidth: screenSize.width < screenSize.height ? .infinity : screenSize.width * 0.3)
                        .frame(maxHeight: screenSize.width < screenSize.height ? 150 : .infinity)
                        .padding([.horizontal, .top], 10)
                        .padding(.bottom, screenSize.width < screenSize.height ? 0 : 10)
                    ListView(viewModel: ListViewModel())
                        .matchedGeometryEffect(id: "listView", in: homeView)
                        .opacity(homeViewModel.user == nil ? 0.4 : 1)
                        .overlay(alignment: .center) {
                            if homeViewModel.user == nil {
                                sampleMark
                                    .frame(width: 120, height: 80)
                                    .offset(y: 20)
                            }
                        }
                }
            }
            .navigationTitle("Multi List")
            .edgesIgnoringSafeArea(.bottom)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    let userSettingViewModel = UserSettingViewModel(user: homeViewModel.user)
                    userSettingView(viewModel: userSettingViewModel)
                }
            }
            .alert(homeViewModel.title,
                   isPresented: $homeViewModel.isShowingAlert) {
            } message: {
                Text(homeViewModel.message)
            }
            .overlay(content: {
                if homeViewModel.isShowingProgressView {
                    CustomProgressView()
                }
            })
        }
    }
    
}


// MARK: - [extension 1] SubViews
extension HomeView {
    
    func userSettingView(viewModel: UserSettingViewModel) -> some View {
        NavigationLink {
            UserSettingView(viewModel: viewModel)
        } label: {
            Image(systemName: "person.crop.circle")
                .tint(homeViewModel.user == nil ? .gray : .teal)
        }
    }
    
    var sampleMark: some View {
        ZStack {
            Rectangle().fill(Color.red.opacity(0.4))
            Rectangle().fill(Color.primaryInverted)
                .padding(5)
            
            Text("S A M P L E").foregroundColor(.red.opacity(0.4)).fontWeight(.bold)
        }
        
    }
    
}

// MARK: - [extension 2] functions
extension HomeView {
    
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
