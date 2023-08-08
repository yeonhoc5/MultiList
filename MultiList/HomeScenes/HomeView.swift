//
//  HomeView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/07.
//

import SwiftUI
import FirebaseRemoteConfig


struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                LoginView(isLoggedin: $viewModel.isLoggedIn)
                    .alert(viewModel.title,
                           isPresented: $viewModel.isLoggedIn) {
                    } message: {
                        Text(viewModel.message)
                    }
            }
            .navigationTitle("멀티 List")
            .toolbar {
                if viewModel.isLoggedIn {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
        }
        
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
