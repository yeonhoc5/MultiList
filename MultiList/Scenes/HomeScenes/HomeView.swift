//
//  HomeView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/07.
//

import SwiftUI
import FirebaseRemoteConfig

struct HomeView: View {
    @EnvironmentObject var userData: UserData
    @StateObject var viewModel = HomeViewModel()
    
    @State var isShowingProgressView: Bool = false
    @State var isShowingShareSheet: Bool = false
    @State var isShowingSendShareSheet: Bool = false
    @State var multiListToShare: MultiList!
    @State var isEditMode: Bool = false
    
    @State var editSection: SectionList!
    @FocusState var isFocused: Bool
    
    // myItem Properties
    @State var isShowingMyItemSheet: Bool = false
    @State var myItemNumber: Int = 0
    @State var selectedItemType: MyItemType = .text
    
    @Namespace var homeView
    
    @State var badgeManager = AppAlertBadgeManager(application: UIApplication.shared)
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Rectangle()
                    .foregroundColor(.primaryInverted)
                OStack(alignment: .center, verticalSpacing: -20, horizontalSpacing: 10) {
                    if !isEditMode {
                        ZStack {
                            Rectangle().fill(.clear)
                            // 1. 로그인 & 마이 아이템 뷰
                            LoginView(userData: userData,
                                      isShowingProgressView: $isShowingProgressView,
                                      isShowingMyItemSheet: $isShowingMyItemSheet,
                                      myItemNumber: $myItemNumber,
                                      selectedItemType: $selectedItemType,
                                      nameSpace: homeView)
                            .matchedGeometryEffect(id: "loginView", in: homeView)
                            .padding(.horizontal, 10)
                            .padding(.top, 5)
                            .padding(.bottom, viewModel.isVertical ? 0 : 10)
                            .disabled(isShowingProgressView || isEditMode)
                            if isEditMode || editSection != nil {
                                blurViewWithTapAction {
                                    withAnimation {
                                        if isEditMode {
                                            isEditMode = false
                                        } else if editSection != nil{
                                            editSection = nil
                                            isFocused = false
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: viewModel.isVertical ? .infinity : screenSize.width * 0.3)
                        .frame(maxHeight: viewModel.isVertical ? screenSize.height * 0.18 : .infinity)
                        .ignoresSafeArea(.keyboard, edges: .all)
                        .zIndex(1)
                        .transition(.move(edge: screenSize.width < screenSize.height ? .top : .leading).combined(with: .opacity))
                    }
                    // 2. 멀티 리스트 뷰
                    ListView(userData: userData,
                             isEditMode: $isEditMode,
                             isShowingSendShareSheet: $isShowingSendShareSheet,
                             editSection: $editSection,
                             multiListToShare: $multiListToShare,
                             isFocusedEdit: $isFocused)
                        .matchedGeometryEffect(id: "listView", in: homeView)
                        .zIndex(0)
                        .padding(.top, isEditMode ? 1 : 10)
                }
            }
            .navigationTitle("Multi List")
            .navigationSplitViewColumnWidth(screenSize.width * 0.4)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    shareSheetButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    editModeButton
                }
            }
            .overlay(content: {
                if isShowingProgressView {
                    CustomProgressView()
                }
            })
            .alert(viewModel.title,
                   isPresented: $viewModel.isShowingAlert) {
            } message: {
                Text(viewModel.message)
            }
            .sheet(isPresented: $isShowingShareSheet) {
                ShareListSheetView(userData: userData, isShowingSheet: $isShowingShareSheet)
            }
            .onChange(of: userData.user == nil) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isShowingProgressView = false
                }
            }
            .onChange(of: userData.sharedMultiList.count) { int in
                if int >= 1 {
                    badgeManager.setAlertBadge(number: int)
                } else if int == 0 {
                    badgeManager.resetAlertBadgetNumber()
                }
            }
        }
        .tint(Color.teal)
    }
    
}

extension HomeView {
    
    var shareSheetButton: some View {
        Button {
            isShowingShareSheet = true
        } label: {
            sharedMultiListButton
        }
    }

    var editModeButton: some View {
        Button {
            if userData.user != nil {
                withAnimation {
                    isEditMode.toggle()
                }
            }
        } label: {
            HStack(spacing: 0) {
                if !isEditMode {
                    Text("E").matchedGeometryEffect(id: "text1", in: homeView)
                    Text("d").matchedGeometryEffect(id: "text2", in: homeView)
                    Text("i").matchedGeometryEffect(id: "text3", in: homeView)
                    Text("t").matchedGeometryEffect(id: "text4", in: homeView)
                } else {
                    Text("D").matchedGeometryEffect(id: "text1", in: homeView)
                    Text("o").matchedGeometryEffect(id: "text2", in: homeView)
                    Text("n").matchedGeometryEffect(id: "text3", in: homeView)
                    Text("e").matchedGeometryEffect(id: "text4", in: homeView)
                }
            }
            .foregroundColor(userData.user == nil ? .gray : .primary)
            .animation(.interpolatingSpring(duration: 0.4, bounce: 0.6, initialVelocity: 0.2), value: isEditMode)
            .frame(width: 50)
        }
    }
    
    var sharedMultiListButton: some View {
        ZStack {
            Image(systemName: "doc")
//                .imageScale(.large)
                .overlay(alignment: .center) {
                    Image(systemName: "arrow.up.arrow.down")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 8)
                        .offset(y: 2)
                }
                .foregroundColor(userData.user == nil ? .gray : .primary)
        }
        .overlay(alignment: .topTrailing) {
            let alertCount = userData.sharedMultiList.filter({ $0.shareResult == .undetermined }).count
            if (userData.user != nil && alertCount > 0) {
                ZStack {
                    Circle().fill(Color.red)
                    Text("\(alertCount)")
                        .foregroundColor(.white)
                        .font(.caption)
                        .padding(2)
                }
                .frame(width: 18)
                .offset(x: 4, y: -2)
            }
        }
    }
    

}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
