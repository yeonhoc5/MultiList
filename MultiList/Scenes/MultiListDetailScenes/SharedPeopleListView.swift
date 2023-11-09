//
//  SharedPeopleListView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/15.
//

import SwiftUI

struct SharedPeopleListView: View {
    @Environment(\.dismiss) var mode
    @ObservedObject var userData: UserData
    @StateObject var viewModel: SharedPeopleListViewModel
    var sharedPeople: [Person]
    var title: String
    
    @State var isShowingAddFriendMenu: Bool = false
    
    init(userData: UserData, sharedPeople: [Person], title: String) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: SharedPeopleListViewModel(userData: userData))
        self.sharedPeople = sharedPeople
        self.title = title
    }
    
    var body: some View {
        OStack(spacing: 10) {
            // 1. 나와 내 친구
            FriendSectionView(personCase: .friend)
//            Divider()
            // 2. 친구가 아닌 공유자
            FriendSectionView(personCase: .notfriend)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(content: {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    self.mode.callAsFunction()
                }, label: {
                    HStack(content: {
                        Image(systemName: "chevron.left")
                        Text("[\(title)] 공유자 : 나 + \(sharedPeople.count)명")
                    })
                })
            }
        })
    }
}


enum PersonCase: String {
    case me = "Me"
    case friend = "친구"
    case notfriend = "친구 아님"
}

extension SharedPeopleListView {
    
    func FriendSectionView(personCase: PersonCase) -> some View {
        VStack {
            HStack {
                Text(personCase == .friend ? "나와 친구" : "친구가 아닌 공유자")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(personCase == .friend ? Color.teal : Color.white)
                Spacer()
            }
            GeometryReader { geoProxy in
                let item = Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .center), count: geoProxy.size.width > 450 ? (Int(geoProxy.size.width) - 50) / 150 : 2)
                let filteredFriends = sharedPeople.filter({ userData.friendList.compactMap({ $0.userEmail }).contains($0.userEmail) == (personCase == .friend) })
                LazyVGrid(columns: item, spacing: 10) {
                    if personCase == .friend {
                        // 1. 내 카드
                        personCardView(friend: Person(id: userData.user.userUID,
                                                      userName: userData.user.userNickName,
                                                      userEmail: userData.user.userEmail,
                                                      isEditable: true),
                                       personCase: .me)
                    }
                    ForEach(filteredFriends, id: \.userEmail) { friend in
                        if personCase == .friend {
                            personCardView(friend: friend, personCase: personCase)
                        } else {
                            Menu {
                                contextMenuItem(title: "내 친구 하기", image: "person.fill.badge.plus") {
                                    let friend = Friend(uid: friend.id, order: 0, userEmail: friend.userEmail, userNickName: friend.userName)
                                    userData.addFriendToMyInfo(friend: friend)
                                }
                            } label: {
                                personCardView(friend: friend, personCase: personCase)
                            }
                            .buttonStyle(ScaleEffect(scale: 0.9))
                        }
                    }
                }
            }
//            if personCase == .notfriend {
//                Button(action: {
//
//                }, label: {
//                    ZStack(content: {
//                        Group {
//                            RoundedRectangle(cornerRadius: 10)
//                                .fill(Color.primaryInverted)
//                            RoundedRectangle(cornerRadius: 10)
//                                .stroke(style: .init(lineWidth: 0.5, dash: [5.0]))
//                                .shadow(color: .black, radius: 1.5, x: 0, y: 1.3)
//                        }
//                        .frame(height: 70)
//                        Image(systemName: "plus")
//                            .foregroundStyle(Color.gray)
//                    })
//                })
//                .buttonStyle(ScaleEffect(scale: 0.9))
//            }
        }
        .padding(10)
        .background {
            Group {
                if personCase == .friend {
                    Color.primaryInverted
                } else {
                    Color.teal//.opacity(0.3)
                }
            }
            .ignoresSafeArea()
        }
    }
    
    
    func personCardView(friend: Person, personCase: PersonCase! = .friend) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(personCase == .notfriend ? .white : .teal)//.opacity(0.3))
            .frame(height: 70)
            .shadow(color: personCase == .notfriend ? .primaryInverted : .clear,
                    radius: 0.5, x: 0, y: 0)
            .overlay(alignment: .leading) {
                ZStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(personCase == .friend ? userData.friendList.filter({ $0.userEmail == friend.userEmail}).first?.userNickName ?? friend.userName : friend.userName)
                            .font(.callout)
                            .foregroundColor(.black)
                        Text(friend.userEmail)
                            .font(.caption)
                            .foregroundColor(.black)
                    }
                }
                .padding(15)
            }
            .overlay(alignment: .topTrailing) {
                if personCase == .me {
                    Text(personCase.rawValue)
                        .font(.caption)
                        .fontWeight(.black)
                        .padding([.top, .trailing], 5)
                        .foregroundStyle(Color.primaryInverted)
                }
            }
    }
}

struct SharedPeopleListView_Previews: PreviewProvider {
    static var previews: some View {
        SharedPeopleListView(userData: UserData(), sharedPeople: [], title: "샘플 리스트")
    }
}
