//
//  SharedPeopleListView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/15.
//

import SwiftUI

struct SharedPeopleListView: View {
    @ObservedObject var userData: UserData
    @StateObject var viewModel: SharedPeopleListViewModel
    var sharedPeople: [Int]
    
    init(userData: UserData, sharedPeople: [Int]) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: SharedPeopleListViewModel(userData: userData))
        self.sharedPeople = sharedPeople
    }
    
    
    var body: some View {
        GeometryReader { geoProxy in
            let item = Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .bottom), count: (Int(geoProxy.size.width) - 50) / 150)
            LazyVGrid(columns: item, spacing: 10) {
                ForEach(userData.friendList.filter({ self.sharedPeople.contains($0.order) }), id: \.userEmail) { friend in
                    Button {
                        
                    } label: {
                        personCardView(friend: friend)
                    }
                    .buttonStyle(ScaleEffect())
                }
            }
        }
    }
}

extension SharedPeopleListView {
    func personCardView(friend: Friend) -> some View {
        return RoundedRectangle(cornerRadius: 10)
            .fill(.white)
            .frame(height: 70)
            .shadow(color: .black, radius: 1.5, x: 0, y: 1.3)
            .overlay {
                VStack(alignment: .leading, spacing: 8) {
                    Text(friend.userNickName)
                        .font(.callout)
                        .foregroundColor(.black)
                    Text(friend.userEmail)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
    }
}

struct SharedPeopleListView_Previews: PreviewProvider {
    static var previews: some View {
        SharedPeopleListView(userData: UserData(), sharedPeople: [])
    }
}
