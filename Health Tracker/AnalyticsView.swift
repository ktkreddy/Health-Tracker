//
//  AnalyticsView.swift
//  Health Tracker
//
//  Created by Tarun Krishna Reddy Kolli on 9/26/24.
//


import SwiftUI
import Charts

struct AnalyticsView: View {
    @Binding var symptomsByDate: [Date: [SymptomEntry]]
    
    @State private var selectedSymptoms: [String] = []
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var endDate: Date = Date()
    
    let allSymptoms = [
        "Pelvic and/or abdominal pain",
        "Increased frequency and/or urgency to pee",
        "Feelings of increased abdominal size or bloating",
        "Able to feel a lump in the abdomen",
        "Difficulty eating and/or feeling full quickly",
        "Increased fatigue",
        "Weight loss",
        "Menstrual/vaginal discharge irregularities or bleeding after menopause",
        "Pain and/or bleeding associated with intercourse",
        "Other (e.g., leg swelling, difficulty breathing, back pain)"
    ]
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    Text("Symptom Analytics")
                        .font(.headline)
                        .padding()

                    HStack {
                        VStack {
                            Text("Start Date")
                                .font(.subheadline)
                            DatePicker("", selection: $startDate, displayedComponents: [.date])
                                .datePickerStyle(CompactDatePickerStyle())
                        }
                        .padding(.horizontal, geometry.size.width * 0.05)

                        VStack {
                            Text("End Date")
                                .font(.subheadline)
                            DatePicker("", selection: $endDate, displayedComponents: [.date])
                                .datePickerStyle(CompactDatePickerStyle())
                        }
                        .padding(.horizontal, geometry.size.width * 0.05)
                    }
                    .padding(.vertical, geometry.size.height * 0.02)

                    Menu {
                        ForEach(allSymptoms, id: \.self) { symptom in
                            Button(action: {
                                toggleSymptomSelection(symptom)
                            }) {
                                HStack {
                                    Text(symptom)
                                    if selectedSymptoms.contains(symptom) {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Select Symptoms")
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, geometry.size.width * 0.05)

                    if dateRangeData().isEmpty {
                        Text("No data available for the selected criteria")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, geometry.size.height * 0.02)
                    } else {
                        ScrollView {
                            Chart {
                                ForEach(dateRangeData(), id: \.id) { dateData in
                                    LineMark(
                                        x: .value("Date", dateData.date),
                                        y: .value("Count", dateData.count)
                                    )
                                    .interpolationMethod(.linear)
                                    .foregroundStyle(by: .value("Symptom", dateData.symptom))
                                    PointMark(
                                        x: .value("Date", dateData.date),
                                        y: .value("Count", dateData.count)
                                    )
                                    .symbol(by: .value("Symptom", dateData.symptom))
                                    .foregroundStyle(by: .value("Symptom", dateData.symptom))
                                    .symbolSize(50)
                                }
                            }
                            .frame(height: geometry.size.height * 0.4)
                            .padding(.horizontal, geometry.size.width * 0.05)
                            .padding(.vertical, geometry.size.height * 0.02)
                        }
                    }
                }
                .navigationTitle("Analytics")
                .padding(.horizontal, geometry.size.width * 0.05)
            }
        }
    }

    func toggleSymptomSelection(_ symptom: String) {
        if selectedSymptoms.contains(symptom) {
            selectedSymptoms.removeAll { $0 == symptom }
        } else {
            selectedSymptoms.append(symptom)
        }
    }

    func dateRangeData() -> [SymptomTimeSeriesData] {
        var result: [SymptomTimeSeriesData] = []
        var currentDate = Calendar.current.startOfDay(for: startDate)
        
        while currentDate <= Calendar.current.startOfDay(for: endDate) {
            if let symptoms = symptomsByDate[currentDate] {
                for symptom in symptoms where selectedSymptoms.isEmpty || selectedSymptoms.contains(symptom.symptom) {
                    result.append(SymptomTimeSeriesData(id: UUID(), symptom: symptom.symptom, date: currentDate, count: symptom.severity))
                }
            } else {
                for symptom in selectedSymptoms {
                    result.append(SymptomTimeSeriesData(id: UUID(), symptom: symptom, date: currentDate, count: 0))
                }
            }
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return result
    }
}

struct SymptomTimeSeriesData: Identifiable {
    let id: UUID
    let symptom: String
    let date: Date
    let count: Int
}
