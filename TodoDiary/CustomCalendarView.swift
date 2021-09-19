//
//  CustomCalendarView.swift
//  TodoDiary
//
//  Created by Yu on 2021/09/19.
//

import SwiftUI

struct CustomCalendarView: View {
    
    var calendarProtocol: CalendarProtocol
    let changeFrag: Int
    
    //カレンダーに表示する年と月
    @State var showYear = 0
    @State var showMonth = 0
    
    let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    @State var showDays: [Int] = []
    
    var body: some View {
        VStack {
            
            //曜日を表示
            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 7)) {
                ForEach((0..<weekDays.count), id: \.self) { index in
                    Text("\(weekDays[index])")
                        .font(.subheadline)
                        .frame(alignment: .center)
                        .foregroundColor(.secondary)
                }
            }
            
            //日を表示
            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 7)) {
                ForEach((0..<showDays.count), id: \.self) { index in
                    if showDays[index] == 0 {
                        Text("")
                            .foregroundColor(.clear)
                    } else if showDays[index] == today() {
                        Text("\(showDays[index])")
                            .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                    } else {
                        Text("\(showDays[index])")
                            .fontWeight(.light)
                    }
                }
                .frame(height: 50, alignment: .center)
                .font(.subheadline)
            }
            .onAppear {
                showYear = calendarProtocol.getShowYear()
                showMonth = calendarProtocol.getShowMonth()
                showDays = daysOfMonth(inputYear: showYear, inputMonth: showMonth)
            }
            .onChange(of: changeFrag, perform: { _ in
                showYear = calendarProtocol.getShowYear()
                showMonth = calendarProtocol.getShowMonth()
                showDays = daysOfMonth(inputYear: showYear, inputMonth: showMonth)
            })
            
        }
    }
    
    func today() -> Int {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.component(.day, from: Date())
    }
    
    //当月の日の配列 例: [0, 0, 0, 1, 2, 3, ...]
    func daysOfMonth(inputYear: Int, inputMonth: Int) -> [Int] {
        
        //当月の日数を取得
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = inputYear
        components.month = inputMonth + 1
        components.day = 0
        let date = calendar.date(from: components)!
        let dayCount = calendar.component(.day, from: date)
        
        //当月一日の曜日を取得 Sat: 1, Sun: 2, Mon: 3... Fri: 7
        let firstDate = calendar.date(from: DateComponents(year: inputYear, month: inputMonth, day: 1, hour: 21, minute: 0, second: 0))!
        let firstWeekday = calendar.component(.weekday, from: firstDate)

        //当月の全ての日の配列を生成
        var days: [Int] = []
        
        //当月一日の曜日を元に、当月開始日まで0で埋めていく
        switch firstWeekday {
        case 2:
            days.append(0)
        case 3:
            days += [0, 0]
        case 4:
            days += [0, 0, 0]
        case 5:
            days += [0, 0, 0, 0]
        case 6:
            days += [0, 0, 0, 0, 0]
        case 7:
            days += [0, 0, 0, 0, 0, 0]
        default:
            break
        }
        
        //残りの日を当月日数分埋めていく
        for index in (1...dayCount) {
            days.append(index)
        }
        
        return days
    }
    
}
