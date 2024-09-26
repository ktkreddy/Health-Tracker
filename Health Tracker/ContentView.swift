import SwiftUI

struct SymptomEntry: Codable, Identifiable {
    var id = UUID()
    var symptom: String
    var note: String
    var stillExperiencing: Bool
    var severity: Int
}

struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var showingSymptomSheet = false
    @State private var symptomsByDate: [Date: [SymptomEntry]] = [:]

    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                
                Button("Add Symptom for Selected Date") {
                    showingSymptomSheet = true
                }
                .padding()
                .sheet(isPresented: $showingSymptomSheet) {
                    SymptomSelectionView(
                        selectedDate: $selectedDate,
                        symptomsByDate: $symptomsByDate,
                        saveSymptoms: saveSymptoms
                    )
                }
                
                List {
                    // Sort dates in descending order to show the latest symptoms at the top
                    ForEach(symptomsByDate.sorted(by: { $0.key > $1.key }), id: \.key) { date, symptoms in
                        Section(header: Text("\(formattedDate(date))")) {
                            ForEach(symptoms) { symptomData in
                                VStack(alignment: .leading) {
                                    Text(symptomData.symptom)
                                        .font(.headline)
                                    Text("Still experiencing: \(symptomData.stillExperiencing ? "Yes" : "No")")
                                        .font(.subheadline)
                                    Text("Severity: \(symptomData.severity)/10")
                                        .font(.subheadline)
                                    if !symptomData.note.isEmpty {
                                        Text("Note: \(symptomData.note)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .onDelete { indexSet in
                                deleteSymptom(at: indexSet, for: date)
                            }
                        }
                    }
                }
                
                NavigationLink(destination: AnalyticsView(symptomsByDate: $symptomsByDate)) {
                    Text("View Analytics")
                        .padding()
                }
            }
            .navigationTitle("Symptom Tracker")
            .onAppear(perform: loadSymptoms)
        }
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    func saveSymptoms() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(symptomsByDate) {
            UserDefaults.standard.set(encoded, forKey: "symptomsByDate")
        }
    }

    func loadSymptoms() {
        if let savedSymptoms = UserDefaults.standard.data(forKey: "symptomsByDate") {
            let decoder = JSONDecoder()
            if let loadedSymptoms = try? decoder.decode([Date: [SymptomEntry]].self, from: savedSymptoms) {
                symptomsByDate = loadedSymptoms
            }
        }
    }
    
    func deleteSymptom(at offsets: IndexSet, for date: Date) {
        guard let index = offsets.first else { return }
        symptomsByDate[date]?.remove(at: index)
        
        if symptomsByDate[date]?.isEmpty == true {
            symptomsByDate.removeValue(forKey: date)
        }
        
        saveSymptoms()
    }
}

struct SymptomSelectionView: View {
    @Binding var selectedDate: Date
    @Binding var symptomsByDate: [Date: [SymptomEntry]]
    var saveSymptoms: () -> Void
    
    @State private var selectedSymptom: String = ""
    @State private var symptomNote: String = ""
    @State private var stillExperiencing: Bool = false
    @State private var severity: Int = 1
    @Environment(\.presentationMode) var presentationMode
    
    let symptoms = [
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
            VStack {
                List(symptoms, id: \.self) { symptom in
                    Button(action: {
                        selectedSymptom = symptom
                    }) {
                        HStack {
                            Text(symptom)
                            Spacer()
                            if selectedSymptom == symptom {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                if !selectedSymptom.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Selected Symptom: \(selectedSymptom)")
                            .padding(.top)
                        
                        Toggle("Are you still experiencing this symptom?", isOn: $stillExperiencing)
                            .padding(.top)
                        
                        Stepper(value: $severity, in: 1...10) {
                            Text("Severity: \(severity)/10")
                        }
                        .padding(.top)
                        
                        TextField("Enter a note about the symptom (optional)", text: $symptomNote)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.top, 10)
                            .padding(.horizontal)
                    }
                    .padding()
                }
                
                Spacer()
                
                Button("Save Symptom") {
                    addSymptom()
                    saveSymptoms()
                    // Ensure UI updates before dismissing
                    DispatchQueue.main.async {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .disabled(selectedSymptom.isEmpty)
                .padding()
            }
            .navigationTitle("Select Symptom")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    func addSymptom() {
        let normalizedDate = Calendar.current.startOfDay(for: selectedDate)
        
        let newEntry = SymptomEntry(
            symptom: selectedSymptom,
            note: symptomNote,
            stillExperiencing: stillExperiencing,
            severity: severity
        )
        
        if symptomsByDate[normalizedDate] != nil {
            symptomsByDate[normalizedDate]?.append(newEntry)
        } else {
            symptomsByDate[normalizedDate] = [newEntry]
        }
    }
}
