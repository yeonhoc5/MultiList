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
    @State var isEditMode: Bool = false
    // myItem Properties
    @State var isShowingMyItemSheet: Bool = false
    @State var myItemNumber: Int = 0
    @State var selectedItemType: MyItemType = .text
    
    @Namespace var homeView
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Rectangle()
                    .foregroundColor(.primaryInverted)
                OStack(alignment: .center, spacing: 0) {
                    LoginView(userData: userData,
                              isShowingProgressView: $isShowingProgressView,
                              isShowingMyItemSheet: $isShowingMyItemSheet,
                              myItemNumber: $myItemNumber,
                              selectedItemType: $selectedItemType,
                              nameSpace: homeView)
                        .matchedGeometryEffect(id: "loginView", in: homeView)
                        .frame(maxWidth: viewModel.isVertical ? .infinity : screenSize.width * 0.3)
                        .frame(maxHeight: viewModel.isVertical ? screenSize.height * 0.18 : .infinity)
                        .padding(.horizontal, 10)
                        .padding(.top, 5)
                        .padding(.bottom, viewModel.isVertical ? 0 : 10)
                        .zIndex(1)
                    ListView(userData: userData, isEditMode: $isEditMode)
                        .matchedGeometryEffect(id: "listView", in: homeView)
                        .zIndex(0)
                }
            }
            .navigationTitle("Multi List")
            .navigationSplitViewColumnWidth(screenSize.width * 0.4)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    shareSheetButton
                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    editModeButton
//                }
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
                ShareSheetView(userData: userData, isShowingSheet: $isShowingShareSheet)
            }
            .onChange(of: userData.user == nil) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isShowingProgressView = false
                }
            }
        }
        .tint(Color.teal)
//        .ignoresSafeArea(.keyboard, edges: .bottom)
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
            isEditMode.toggle()
        } label: {
            if !isEditMode {
                Image(systemName: "gearshape")
                    .imageScale(.large)
                    .foregroundColor(userData.user == nil ? .gray : .primary)
            } else {
                Text("Done")
                    .foregroundColor(userData.user == nil ? .gray : .primary)
            }
            
        }
    }
    
    var sharedMultiListButton: some View {
        ZStack {
            Image(systemName: "doc")
                .imageScale(.large)
                .overlay(alignment: .center) {
                    Image(systemName: "arrow.up.arrow.down")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 8)
                        .offset(y: 2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(userData.user == nil ? .gray : .primary)
        }
        .overlay(alignment: .topTrailing) {
            let alertCount = userData.sharedMultiList.filter({ $0.shareResult == .undetermined }).count
            if (userData.user != nil && alertCount > 0) || userData.user == nil {
                ZStack {
                    Circle().fill(Color.red)
                    Text("\(userData.user != nil ? alertCount : sampleShareMulti.count)")
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
